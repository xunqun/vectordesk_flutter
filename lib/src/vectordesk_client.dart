import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'models.dart';
import 'vectordesk_firebase_options.dart';

class VectorDeskClient {
  final String orgId;
  final String? personaId;

  FirebaseApp? _app;
  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;
  String? _userId;

  static VectorDeskClient? _instance;

  /// Get or initialize shared singleton instance for convenience.
  static VectorDeskClient getInstance({required String orgId, String? personaId}) {
    if (_instance != null &&
        (_instance!.orgId != orgId || _instance!.personaId != personaId)) {
      _instance!.dispose();
      _instance = null;
    }
    _instance ??= VectorDeskClient(orgId: orgId, personaId: personaId);
    return _instance!;
  }

  VectorDeskClient({required this.orgId, this.personaId});

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

  Future<void> _doInitialize({FirebaseOptions? options, String? appName}) async {
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

  Future<String> _getOrCreateChatId() async {
    if (_userId == null) throw Exception('Not initialized');

    final q = await _firestore!
        .collection('chats')
        .where('orgId', isEqualTo: orgId)
        .where('userId', isEqualTo: _userId)
        .where('status', isEqualTo: 'active')
        .get();

    if (q.docs.isNotEmpty) {
      final docs = q.docs.toList();
      docs.sort((a, b) {
        final aTime = (a.data()['lastMessageAt'] as Timestamp?)?.toDate() ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = (b.data()['lastMessageAt'] as Timestamp?)?.toDate() ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      final doc = docs.first;
      if (personaId != null && doc.data()['personaId'] != personaId) {
        await doc.reference.update({'personaId': personaId});
      }
      return doc.id;
    }

    final newChatId = 'guest_${const Uuid().v4()}';
    await _firestore!.collection('chats').doc(newChatId).set({
      'orgId': orgId,
      'userId': _userId,
      'externalUserId': _userId,
      'status': 'active',
      'channel': 'flutter_app',
      'integrationId': 'flutter_app',
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessageAt': FieldValue.serverTimestamp(),
      'unreadCount': 0,
      'humanTakeover': false,
      if (personaId != null) 'personaId': personaId,
    });
    return newChatId;
  }

  void _setupMessageListener(String chatId) {
    if (_firestoreSub != null) return;

    _firestoreSub = _firestore!
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      final messages = snapshot.docs
          .map((d) => VectorDeskMessage.fromFirestore(d))
          .toList();

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

  Future<void> sendMessage(String text) async {
    if (text.length > 2050) {
      // ignore: avoid_print
      print('[VectorDeskClient] Truncating overly long message');
      text = text.substring(0, 2050);
    }
    final chatId = await _getOrCreateChatId();
    await _firestore!
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'content': text,
      'senderType': 'user',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _firestore!.collection('chats').doc(chatId).update({
      'lastMessageAt': FieldValue.serverTimestamp(),
    });
  }

  void dispose() {
    _firestoreSub?.cancel();
    _firestoreSub = null;
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

