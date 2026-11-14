import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'models.dart';
import 'vectordesk_firebase_options.dart';
import 'vectordesk_protocol.dart';

class VectorDeskClient {
  final String orgId;
  final String? personaId;

  FirebaseApp? _app;
  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;
  String? _userId;

  static VectorDeskClient? _instance;

  /// Get or initialize shared singleton instance for convenience.
  static VectorDeskClient getInstance(
      {required String orgId, String? personaId}) {
    if (_instance != null &&
        (_instance!.orgId != orgId || _instance!.personaId != personaId)) {
      _instance!.dispose();
      _instance = null;
    }
    _instance ??= VectorDeskClient(orgId: orgId, personaId: personaId);
    return _instance!;
  }

  VectorDeskClient({required this.orgId, this.personaId});

  /// Creates a client that uses [firestore] and an already signed-in anonymous
  /// [userId] instead of initializing Firebase. For tests only.
  @visibleForTesting
  VectorDeskClient.forTesting({
    required this.orgId,
    this.personaId,
    required FirebaseFirestore firestore,
    required String userId,
  })  : _firestore = firestore,
        _userId = userId {
    _initFuture = Future<void>.value();
  }

  Future<void>? _initFuture;

  // Unread count and background notification streams
  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  bool _isChatActive = false;
  bool get isChatActive => _isChatActive;

  final StreamController<int> _unreadCountController =
      StreamController<int>.broadcast();
  Stream<int> get unreadCountStream => _unreadCountController.stream;

  final StreamController<VectorDeskMessage> _newMessageController =
      StreamController<VectorDeskMessage>.broadcast();
  Stream<VectorDeskMessage> get onNewMessage => _newMessageController.stream;

  StreamController<List<VectorDeskMessage>>? _messagesController;
  Stream<List<VectorDeskMessage>>? _chatStream;

  StreamSubscription<QuerySnapshot>? _firestoreSub;
  List<VectorDeskMessage>? _currentMessages;
  List<VectorDeskMessage>? get currentMessages => _currentMessages;
  final Set<String> _processedMessageIds = {};
  bool _isInitialLoad = true;
  bool _hasLoadedInitialMessages = false;

  Future<void> initialize({FirebaseOptions? options, String? appName}) {
    _initFuture ??= _doInitialize(options: options, appName: appName);
    return _initFuture!;
  }

  Future<void> _doInitialize(
      {FirebaseOptions? options, String? appName}) async {
    // Default to embedded options if not provided
    final opts = options ?? VectorDeskFirebaseOptions.currentPlatform;

    // Check if the default Firebase app [DEFAULT] is already initialized.
    bool defaultAppExists = false;
    try {
      Firebase.app(); // Throws if [DEFAULT] does not exist
      defaultAppExists = true;
    } catch (_) {
      defaultAppExists = false;
    }

    final name = appName ?? (defaultAppExists ? 'VectorDesk' : '[DEFAULT]');

    try {
      if (name == '[DEFAULT]') {
        _app = Firebase.app();
      } else {
        _app = Firebase.app(name);
      }
    } catch (e) {
      if (name == '[DEFAULT]') {
        _app = await Firebase.initializeApp(options: opts);
      } else {
        _app = await Firebase.initializeApp(name: name, options: opts);
      }
    }

    _auth = FirebaseAuth.instanceFor(app: _app!);
    _firestore = FirebaseFirestore.instanceFor(app: _app!);

    if (_auth!.currentUser != null) {
      try {
        await _auth!.currentUser!.getIdToken(true);
      } catch (e) {
        try {
          await _auth!.signOut();
        } catch (_) {}
      }
    }

    if (_auth!.currentUser == null || !_auth!.currentUser!.isAnonymous) {
      try {
        if (_auth!.currentUser != null) {
          await _auth!.signOut();
        }
        await _auth!.signInAnonymously();
      } on FirebaseAuthException catch (e) {
        if (e.code == 'admin-restricted-operation') {
          throw Exception(
              'VectorDesk: Anonymous auth is disabled in your Firebase project. Please enable it in the Firebase Console -> Authentication -> Sign-in method.');
        } else {
          rethrow;
        }
      } catch (e) {
        rethrow;
      }
    }
    _userId = _auth!.currentUser!.uid;
  }

  /// Sets whether the chat widget UI is currently active (visible to user).
  /// When set to true, unread count is reset to 0.
  void setChatActive(bool active) {
    _isChatActive = active;
    if (active) {
      _unreadCount = 0;
      _unreadCountController.add(0);
    }
  }

  /// Manually reset unread message count to 0.
  void clearUnreadCount() {
    _unreadCount = 0;
    _unreadCountController.add(0);
  }

  /// The id of this user's conversation in [orgId], once initialized.
  ///
  /// The SDK keeps exactly one conversation per anonymous user and
  /// organization; see [VectorDeskProtocol.guestChatId].
  String? get chatId => _userId == null
      ? null
      : VectorDeskProtocol.guestChatId(uid: _userId!, orgId: orgId);

  Future<String>? _chatIdFuture;

  /// Resolves this user's conversation, creating it when absent.
  ///
  /// Concurrent callers share one in-flight lookup so the conversation is
  /// created at most once; a failed lookup is retried on the next call.
  Future<String> _getOrCreateChatId() {
    final future = _chatIdFuture ??= _resolveChatId();
    future.then<void>((_) {}, onError: (Object _) {
      if (identical(_chatIdFuture, future)) _chatIdFuture = null;
    });
    return future;
  }

  Future<String> _resolveChatId() async {
    final uid = _userId;
    if (uid == null || _firestore == null) throw Exception('Not initialized');

    final id = VectorDeskProtocol.guestChatId(uid: uid, orgId: orgId);
    final ref =
        _firestore!.collection(VectorDeskProtocol.chatsCollection).doc(id);

    final snapshot = await ref.get();
    if (snapshot.exists) {
      await _syncPersona(ref, snapshot.data());
      return id;
    }

    try {
      await ref.set(VectorDeskProtocol.newChatData(
        orgId: orgId,
        uid: uid,
        personaId: personaId,
      ));
    } on FirebaseException {
      // The conversation may have been created by another session of the same
      // user in the meantime; use it if so.
      final retry = await ref.get();
      if (!retry.exists) rethrow;
      await _syncPersona(ref, retry.data());
    }
    return id;
  }

  Future<void> _syncPersona(
      DocumentReference<Map<String, dynamic>> ref, Map<String, dynamic>? data) {
    final persona = personaId;
    if (persona == null || data?['personaId'] == persona) {
      return Future<void>.value();
    }
    return ref.update(VectorDeskProtocol.personaUpdate(persona));
  }

  void _setupMessageListener(String chatId) {
    if (_firestoreSub != null) return;

    _firestoreSub = _firestore!
        .collection(VectorDeskProtocol.chatsCollection)
        .doc(chatId)
        .collection(VectorDeskProtocol.messagesCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      final messages =
          snapshot.docs.map((d) => VectorDeskMessage.fromFirestore(d)).toList();

      _currentMessages = messages;
      _hasLoadedInitialMessages = true;
      _messagesController?.add(messages);

      if (_isInitialLoad) {
        for (final doc in snapshot.docs) {
          _processedMessageIds.add(doc.id);
        }
        _isInitialLoad = false;
      } else {
        for (final change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final msg = VectorDeskMessage.fromFirestore(change.doc);
            if (!_processedMessageIds.contains(msg.id)) {
              _processedMessageIds.add(msg.id);

              if (msg.sender != 'user') {
                if (!_isChatActive) {
                  _unreadCount++;
                  _unreadCountController.add(_unreadCount);
                }
                _newMessageController.add(msg);
              }
            }
          }
        }
      }
    }, onError: (error) {
      _messagesController?.addError(error);
    });
  }

  /// Start background monitoring for incoming messages without opening the UI widget.
  Future<void> startBackgroundListener(
      {FirebaseOptions? options, String? appName}) async {
    await initialize(options: options, appName: appName);
    final chatId = await _getOrCreateChatId();
    _setupMessageListener(chatId);
  }

  Stream<List<VectorDeskMessage>> get chatStream {
    _chatStream ??= _buildChatStream();
    return _chatStream!;
  }

  Stream<List<VectorDeskMessage>> _buildChatStream() {
    late StreamController<List<VectorDeskMessage>> controller;
    controller = StreamController<List<VectorDeskMessage>>.broadcast(
      onListen: () {
        if (_hasLoadedInitialMessages && _currentMessages != null) {
          final msgs = _currentMessages!;
          Future.microtask(() {
            if (controller.hasListener && !controller.isClosed) {
              controller.add(msgs);
            }
          });
        }
        Future.microtask(() async {
          try {
            await initialize();
            final chatId = await _getOrCreateChatId();
            _setupMessageListener(chatId);
          } catch (e) {
            if (!controller.isClosed) {
              controller.addError(e);
            }
          }
        });
      },
    );
    _messagesController = controller;
    return controller.stream;
  }

  /// Sends [text] as a user message in this user's conversation, creating the
  /// conversation first if needed. Text longer than
  /// [VectorDeskProtocol.maxMessageLength] characters is truncated.
  Future<void> sendMessage(String text) async {
    if (text.length > VectorDeskProtocol.maxMessageLength) {
      // ignore: avoid_print
      print('[VectorDeskClient] Truncating overly long message');
    }
    final chatId = await _getOrCreateChatId();
    final chatRef =
        _firestore!.collection(VectorDeskProtocol.chatsCollection).doc(chatId);
    try {
      await chatRef
          .collection(VectorDeskProtocol.messagesCollection)
          .add(VectorDeskProtocol.userMessageData(text));
      await chatRef.update(VectorDeskProtocol.lastMessageUpdate());
    } on FirebaseException {
      // Look the conversation up again on the next attempt, in case it was
      // removed on the server.
      _chatIdFuture = null;
      rethrow;
    }
  }

  void dispose() {
    _firestoreSub?.cancel();
    _firestoreSub = null;
    _chatIdFuture = null;
    _unreadCountController.close();
    _newMessageController.close();
    _messagesController?.close();
    _messagesController = null;
    _chatStream = null;
    _currentMessages = null;
    if (_instance == this) {
      _instance = null;
    }
  }
}
