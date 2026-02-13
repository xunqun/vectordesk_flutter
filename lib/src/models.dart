import 'package:cloud_firestore/cloud_firestore.dart';

class VectorDeskMessage {
  final String id;
  final String text;
  final String sender;
  final DateTime createdAt;

  VectorDeskMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.createdAt,
  });

  factory VectorDeskMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VectorDeskMessage(
      id: doc.id,
      text: data['content'] ?? '',
      sender: data['senderType'] == 'user' ? 'user' : 'agent',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
