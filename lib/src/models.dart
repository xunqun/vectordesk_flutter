import 'package:cloud_firestore/cloud_firestore.dart';

class VectorDeskAttachment {
  final String type;
  final String url;

  VectorDeskAttachment({required this.type, required this.url});

  factory VectorDeskAttachment.fromMap(Map<String, dynamic> map) {
    return VectorDeskAttachment(
      type: map['type'] ?? '',
      url: map['url'] ?? '',
    );
  }
}

class VectorDeskMessage {
  final String id;
  final String text;
  final String sender;
  final DateTime createdAt;
  final List<VectorDeskAttachment> attachments;

  VectorDeskMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.createdAt,
    this.attachments = const [],
  });

  factory VectorDeskMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rawAttachments = data['attachments'] as List<dynamic>?;
    return VectorDeskMessage(
      id: doc.id,
      text: data['content'] ?? '',
      sender: data['senderType'] == 'user' ? 'user' : 'agent',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      attachments: rawAttachments
              ?.map((e) =>
                  VectorDeskAttachment.fromMap(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}
