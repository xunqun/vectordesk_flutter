import 'package:cloud_firestore/cloud_firestore.dart';

/// Wire-level details of how the SDK talks to the VectorDesk backend.
///
/// Kept separate from [VectorDeskClient] so the document ids and payloads the
/// SDK sends can be unit tested without a Firebase app. Not exported from the
/// package library.
class VectorDeskProtocol {
  VectorDeskProtocol._();

  /// Collection that holds conversations.
  static const String chatsCollection = 'chats';

  /// Sub-collection of a conversation that holds its messages.
  static const String messagesCollection = 'messages';

  /// Channel and integration identifier written on conversations created by
  /// this SDK.
  static const String channel = 'flutter_app';

  /// Maximum message length the SDK sends; longer text is truncated.
  static const int maxMessageLength = 2050;

  /// The fixed conversation id for an anonymous user in an organization:
  /// `guest_<uid>_<orgId>`.
  ///
  /// Each anonymous user has exactly one conversation per organization, and
  /// the SDK reads it directly by this id instead of querying for it.
  static String guestChatId({required String uid, required String orgId}) {
    if (uid.isEmpty) {
      throw ArgumentError.value(uid, 'uid', 'must not be empty');
    }
    if (orgId.isEmpty) {
      throw ArgumentError.value(orgId, 'orgId', 'must not be empty');
    }
    return 'guest_${uid}_$orgId';
  }

  /// Fields written when the conversation document does not exist yet.
  ///
  /// The conversation is owned through its id, so no `userId` field is sent.
  static Map<String, Object> newChatData({
    required String orgId,
    required String uid,
    String? personaId,
  }) {
    return {
      'orgId': orgId,
      'externalUserId': uid,
      'status': 'active',
      'channel': channel,
      'integrationId': channel,
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessageAt': FieldValue.serverTimestamp(),
      'unreadCount': 0,
      'humanTakeover': false,
      if (personaId != null) 'personaId': personaId,
    };
  }

  /// Update sent when an existing conversation uses a different persona.
  static Map<String, Object> personaUpdate(String personaId) {
    return {'personaId': personaId};
  }

  /// A message written by the end user. Agent and bot messages are written by
  /// the server, never by the SDK.
  static Map<String, Object> userMessageData(String text) {
    final content = text.length > maxMessageLength
        ? text.substring(0, maxMessageLength)
        : text;
    return {
      'content': content,
      'senderType': 'user',
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// Update sent on the conversation after a user message is written.
  ///
  /// Also reopens the conversation if it was closed or archived.
  static Map<String, Object> lastMessageUpdate() {
    return {
      'lastMessageAt': FieldValue.serverTimestamp(),
      'status': 'active',
    };
  }
}
