import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vectordesk_flutter/vectordesk_flutter.dart';

const _orgId = 'orgA';
const _uid = 'anonUid';
const _chatId = 'guest_${_uid}_$_orgId';

void main() {
  late FakeFirebaseFirestore firestore;

  setUp(() {
    firestore = FakeFirebaseFirestore();
  });

  VectorDeskClient client({String? personaId}) => VectorDeskClient.forTesting(
        orgId: _orgId,
        personaId: personaId,
        firestore: firestore,
        userId: _uid,
      );

  Future<Map<String, dynamic>?> chatData() async =>
      (await firestore.collection('chats').doc(_chatId).get()).data();

  test('sendMessage creates the conversation at its fixed id when absent',
      () async {
    await client(personaId: 'p1').sendMessage('hi');

    final chats = await firestore.collection('chats').get();
    expect(chats.docs.map((d) => d.id), [_chatId]);

    final data = (await chatData())!;
    expect(data.keys.toSet(), {
      'orgId',
      'externalUserId',
      'status',
      'channel',
      'integrationId',
      'createdAt',
      'lastMessageAt',
      'unreadCount',
      'humanTakeover',
      'personaId',
    });
    expect(data['orgId'], _orgId);
    expect(data['externalUserId'], _uid);
    expect(data['channel'], 'flutter_app');
    expect(data['integrationId'], 'flutter_app');
    expect(data['personaId'], 'p1');
  });

  test('sendMessage writes only a user message and bumps lastMessageAt',
      () async {
    final c = client();
    await c.sendMessage('first');
    await c.sendMessage('second');

    final messages = await firestore
        .collection('chats')
        .doc(_chatId)
        .collection('messages')
        .get();
    expect(messages.docs, hasLength(2));
    for (final m in messages.docs) {
      expect(m.data().keys.toSet(), {'content', 'senderType', 'createdAt'});
      expect(m.data()['senderType'], 'user');
    }
    expect(messages.docs.map((m) => m.data()['content']).toSet(),
        {'first', 'second'});
    expect((await chatData())!['lastMessageAt'], isA<Timestamp>());
  });

  test('an existing conversation is reused, not overwritten', () async {
    await firestore.collection('chats').doc(_chatId).set({
      'orgId': _orgId,
      'externalUserId': _uid,
      'status': 'active',
      'channel': 'flutter_app',
      'integrationId': 'flutter_app',
      'unreadCount': 3,
      'humanTakeover': true,
      'summary': 'written by the server',
    });

    await client().sendMessage('hello again');

    final data = (await chatData())!;
    expect(data['unreadCount'], 3);
    expect(data['humanTakeover'], true);
    expect(data['summary'], 'written by the server');
    expect(data['lastMessageAt'], isA<Timestamp>());
    expect(data.containsKey('createdAt'), isFalse);
  });

  test('sending to a closed conversation reopens it', () async {
    await firestore.collection('chats').doc(_chatId).set({
      'orgId': _orgId,
      'externalUserId': _uid,
      'status': 'closed',
      'channel': 'flutter_app',
      'integrationId': 'flutter_app',
      'unreadCount': 2,
      'humanTakeover': true,
      'summary': 'written by the server',
    });

    await client().sendMessage('are you there?');

    final data = (await chatData())!;
    expect(data['status'], 'active');
    expect(data['lastMessageAt'], isA<Timestamp>());
    expect(data['unreadCount'], 2);
    expect(data['humanTakeover'], true);
    expect(data['summary'], 'written by the server');
    expect(data['channel'], 'flutter_app');
    final messages = await firestore
        .collection('chats')
        .doc(_chatId)
        .collection('messages')
        .get();
    expect(messages.docs.single.data()['content'], 'are you there?');
  });

  test('a different personaId updates only personaId', () async {
    await firestore.collection('chats').doc(_chatId).set({
      'orgId': _orgId,
      'status': 'active',
      'personaId': 'old',
    });

    await client(personaId: 'new').sendMessage('hi');

    final data = (await chatData())!;
    expect(data['personaId'], 'new');
    expect(data['orgId'], _orgId);
    expect(data['status'], 'active');
  });

  test('conversations from the previous protocol are not picked up', () async {
    await firestore.collection('chats').doc('guest_legacy-uuid').set({
      'orgId': _orgId,
      'userId': _uid,
      'status': 'active',
      'channel': 'flutter_app',
    });

    await client().sendMessage('hi');

    final legacyMessages = await firestore
        .collection('chats')
        .doc('guest_legacy-uuid')
        .collection('messages')
        .get();
    expect(legacyMessages.docs, isEmpty);
    expect(await chatData(), isNotNull);
    expect((await chatData())!.containsKey('userId'), isFalse);
  });

  test('chatStream emits the conversation messages', () async {
    final c = client();
    await c.sendMessage('streamed');

    final messages = await c.chatStream.firstWhere((m) => m.isNotEmpty);
    expect(messages.single.text, 'streamed');
    expect(messages.single.sender, 'user');
    c.dispose();
  });
}
