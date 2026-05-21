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

  VectorDeskClient({required this.orgId, this.personaId});

  Future<void> initialize({FirebaseOptions? options, String? appName}) async {
    // Default to embedded options if not provided
    final opts = options ?? VectorDeskFirebaseOptions.currentPlatform;

    // Check if there is already a default Firebase app initialized in the host app.
    // If not, we fall back to initializing the '[DEFAULT]' app to prevent [core/no-app] errors.
    final hasDefaultApp = Firebase.apps.any((app) => app.name == '[DEFAULT]');
    final name = appName ?? (hasDefaultApp ? 'vectordesk' : '[DEFAULT]');

    try {
      if (name == '[DEFAULT]') {
        _app = Firebase.app();
      } else {
        _app = Firebase.app(name);
      }
    } catch (e) {
      // App not initialized yet, initialize it
      if (name == '[DEFAULT]') {
        _app = await Firebase.initializeApp(options: opts);
      } else {
        _app = await Firebase.initializeApp(name: name, options: opts);
      }
    }

    _auth = FirebaseAuth.instanceFor(app: _app!);
    _firestore = FirebaseFirestore.instanceFor(app: _app!);

    // Anonymous Auth - Ensure we are using an anonymous session.
    // If the host app is logged in (e.g. via shared credentials), we might inherit
    // their authenticated session which lacks permissions for vectordesk.
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

  Stream<List<VectorDeskMessage>> messagesStream() {
    if (_userId == null) return Stream.value([]);

    final chatId = 'guest_${orgId}_${_userId}';
    return _firestore!
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => VectorDeskMessage.fromFirestore(doc))
          .toList();
    });
  }

  // Simplified Stream approach for MVP:
  // 1. Get or Create Chat ID
  Future<String> _getOrCreateChatId() async {
    if (_userId == null) throw Exception('Not initialized');

    final chatId = 'guest_${orgId}_${_userId}';
    final docRef = _firestore!.collection('chats').doc(chatId);
    final doc = await docRef.get();

    if (doc.exists) {
      // Update personaId if it has changed
      if (personaId != null && doc.data()?['personaId'] != personaId) {
        await docRef.update({'personaId': personaId});
      }
      return chatId;
    }

    // Create new
    await docRef.set({
      'orgId': orgId,
      'userId': _userId, // Kept for legacy/internal SDK use
      'externalUserId': _userId, // CRITICAL: Required by Chat model & RAG
      'status': 'active',
      'channel': 'flutter_app', // Important
      'integrationId': 'flutter_app', // Consistent with channel
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessageAt': FieldValue.serverTimestamp(),
      'unreadCount': 0, // Initialize unread count
      'humanTakeover': false,
      if (personaId != null) 'personaId': personaId,
    });
    return chatId;
  }

  Stream<List<VectorDeskMessage>> get chatStream async* {
    await initialize(); // Ensure initialized
    final chatId = await _getOrCreateChatId();

    yield* _firestore!
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((d) => VectorDeskMessage.fromFirestore(d))
            .toList());
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

    // Update lastMessageAt
    await _firestore!.collection('chats').doc(chatId).update({
      'lastMessageAt': FieldValue.serverTimestamp(),
    });
  }
}
