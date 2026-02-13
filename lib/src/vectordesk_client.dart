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
    // Default to 'vectordesk' app name if not provided, to isolate from host app
    final name = appName ?? 'vectordesk';

    // Default to embedded options if not provided
    final opts = options ?? VectorDeskFirebaseOptions.currentPlatform;

    try {
      _app = Firebase.app(name);
    } catch (e) {
      // App not initialized yet, initialize it
      _app = await Firebase.initializeApp(name: name, options: opts);
    }

    _auth = FirebaseAuth.instanceFor(app: _app!);
    _firestore = FirebaseFirestore.instanceFor(app: _app!);

    // Anonymous Auth
    if (_auth!.currentUser == null) {
      try {
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

    // Query active chat for this user and org
    // Note: This logic mimics the Web Widget's logic.
    // For simplicity in this SDK preview, we might just list messages from a known chat ID
    // or we need to find the chat ID first.

    // In the real implementation, we need to find the chat doc first.
    // Let's assume for now we look for the most recent active chat.

    return _firestore!
        .collection('chats')
        .where('orgId', isEqualTo: orgId)
        .where('userId', isEqualTo: _userId)
        .where('status', isEqualTo: 'active')
        .orderBy('lastMessageAt', descending: true)
        .limit(1)
        .snapshots()
        .asyncMap((chatQuery) async {
      if (chatQuery.docs.isEmpty) {
        return [];
      }
      final chatId = chatQuery.docs.first.id;

      // Better approach: Switch to streaming the messages subcollection of the found chat.
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
      }).first; // This is tricky regarding stream transformation.
      // For a robust SDK, we need a better state management.
    });
  }

  // Simplified Stream approach for MVP:
  // 1. Get or Create Chat ID
  Future<String> _getOrCreateChatId() async {
    if (_userId == null) throw Exception('Not initialized');

    final q = await _firestore!
        .collection('chats')
        .where('orgId', isEqualTo: orgId)
        .where('userId', isEqualTo: _userId)
        .where('status', isEqualTo: 'active')
        .orderBy('lastMessageAt', descending: true)
        .limit(1)
        .get();

    if (q.docs.isNotEmpty) {
      return q.docs.first.id;
    }

    // Create new
    final newChatId = 'guest_${const Uuid().v4()}';
    await _firestore!.collection('chats').doc(newChatId).set({
      'orgId': orgId,
      'userId': _userId, // Kept for legacy/internal SDK use
      'externalUserId': _userId, // CRITICAL: Required by Chat model & RAG
      'status': 'active',
      'channel': 'flutter_app', // Important
      'integrationId': 'flutter_app', // Consistent with channel
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessageAt': FieldValue.serverTimestamp(),
      'unreadCount': 0, // Initialize unread count
      if (personaId != null) 'agentPersonaId': personaId,
    });
    return newChatId;
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
