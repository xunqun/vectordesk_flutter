// The field sets asserted here mirror the backend's security-rule contract
// for guest conversations. The authoritative rules compatibility tests live in
// the backend repository, not here.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vectordesk_flutter/src/vectordesk_protocol.dart';

void main() {
  group('guestChatId', () {
    test('is guest_<uid>_<orgId>', () {
      expect(
        VectorDeskProtocol.guestChatId(uid: 'anonUid123', orgId: 'org456'),
        'guest_anonUid123_org456',
      );
    });

    test('puts the uid before the orgId', () {
      final id = VectorDeskProtocol.guestChatId(uid: 'u', orgId: 'o');
      expect(id, startsWith('guest_u_'));
      expect(id, endsWith('_o'));
    });

    test('is stable for the same user and organization', () {
      expect(
        VectorDeskProtocol.guestChatId(uid: 'u1', orgId: 'o1'),
        VectorDeskProtocol.guestChatId(uid: 'u1', orgId: 'o1'),
      );
      expect(
        VectorDeskProtocol.guestChatId(uid: 'u1', orgId: 'o1'),
        isNot(VectorDeskProtocol.guestChatId(uid: 'u1', orgId: 'o2')),
      );
    });

    test('rejects empty components', () {
      expect(() => VectorDeskProtocol.guestChatId(uid: '', orgId: 'o'),
          throwsArgumentError);
      expect(() => VectorDeskProtocol.guestChatId(uid: 'u', orgId: ''),
          throwsArgumentError);
    });
  });

  group('newChatData', () {
    test('has exactly the allowed fields and no userId', () {
      final data = VectorDeskProtocol.newChatData(
          orgId: 'org1', uid: 'uid1', personaId: 'persona1');
      expect(
        data.keys.toSet(),
        {
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
        },
      );
      expect(data.containsKey('userId'), isFalse);
      expect(data['orgId'], 'org1');
      expect(data['externalUserId'], 'uid1');
      expect(data['status'], 'active');
      expect(data['channel'], 'flutter_app');
      expect(data['integrationId'], 'flutter_app');
      expect(data['unreadCount'], 0);
      expect(data['humanTakeover'], false);
      expect(data['personaId'], 'persona1');
      expect(data['createdAt'], isA<FieldValue>());
      expect(data['lastMessageAt'], isA<FieldValue>());
    });

    test('omits personaId when none is configured', () {
      final data = VectorDeskProtocol.newChatData(orgId: 'org1', uid: 'uid1');
      expect(data.containsKey('personaId'), isFalse);
      expect(data.containsKey('userId'), isFalse);
    });
  });

  group('userMessageData', () {
    test('is a user message with content and a server timestamp only', () {
      final data = VectorDeskProtocol.userMessageData('hello');
      expect(data.keys.toSet(), {'content', 'senderType', 'createdAt'});
      expect(data['content'], 'hello');
      expect(data['senderType'], 'user');
      expect(data['createdAt'], isA<FieldValue>());
    });

    test('truncates overly long text', () {
      final data = VectorDeskProtocol.userMessageData(
          'a' * (VectorDeskProtocol.maxMessageLength + 10));
      expect((data['content'] as String).length,
          VectorDeskProtocol.maxMessageLength);
    });
  });

  test('conversation updates touch only their own fields', () {
    final update = VectorDeskProtocol.lastMessageUpdate();
    expect(update.keys.toSet(), {'lastMessageAt', 'status'});
    expect(update['lastMessageAt'], isA<FieldValue>());
    expect(update['status'], 'active');
    expect(VectorDeskProtocol.personaUpdate('p2'), {'personaId': 'p2'});
  });
}
