import 'package:flutter_test/flutter_test.dart';
import 'package:frosty/models/gql_chat_comment.dart';
import 'package:frosty/models/irc.dart';

void main() {
  group('GqlChatComment', () {
    test('fromGqlNode parses a complete comment', () {
      final node = {
        'id': 'comment-1',
        'contentOffsetSeconds': 120,
        'commenter': {
          'id': 'user-123',
          'displayName': 'TestUser',
          'login': 'testuser',
        },
        'message': {
          'userColor': '#FF0000',
          'userBadges': [
            {'setID': 'subscriber', 'version': '12'},
          ],
          'fragments': [
            {'text': 'Hello world ', 'emote': null},
            {
              'text': 'Kappa',
              'emote': {'emoteID': '25'},
            },
          ],
        },
      };

      final comment = GqlChatComment.fromGqlNode(node);

      expect(comment.id, 'comment-1');
      expect(comment.contentOffsetSeconds, 120);
      expect(comment.commenterLogin, 'testuser');
      expect(comment.commenterDisplayName, 'TestUser');
      expect(comment.commenterId, 'user-123');
      expect(comment.userColor, '#FF0000');
      expect(comment.userBadges.length, 1);
      expect(comment.userBadges.first.setId, 'subscriber');
      expect(comment.userBadges.first.version, '12');
      expect(comment.messageFragments.length, 2);
      expect(comment.messageFragments[0].text, 'Hello world ');
      expect(comment.messageFragments[0].emote, isNull);
      expect(comment.messageFragments[1].text, 'Kappa');
      expect(comment.messageFragments[1].emote!.emoteId, '25');
    });

    test('fromGqlNode handles deleted commenter (null)', () {
      final node = {
        'id': 'comment-2',
        'contentOffsetSeconds': 60,
        'commenter': null,
        'message': {
          'userColor': null,
          'userBadges': <Map<String, dynamic>>[],
          'fragments': [
            {'text': 'deleted message', 'emote': null},
          ],
        },
      };

      final comment = GqlChatComment.fromGqlNode(node);

      expect(comment.commenterLogin, isNull);
      expect(comment.commenterDisplayName, isNull);
      expect(comment.commenterId, isNull);
      expect(comment.userColor, isNull);
      expect(comment.userBadges, isEmpty);
    });
  });

  group('GqlChatResponse', () {
    test('fromJson parses a valid response', () {
      final json = {
        'data': {
          'video': {
            'comments': {
              'edges': [
                {
                  'node': {
                    'id': 'c1',
                    'contentOffsetSeconds': 10,
                    'commenter': {
                      'id': 'u1',
                      'displayName': 'User1',
                      'login': 'user1',
                    },
                    'message': {
                      'userColor': '#00FF00',
                      'userBadges': <Map<String, dynamic>>[],
                      'fragments': [
                        {'text': 'hello', 'emote': null},
                      ],
                    },
                  },
                  'cursor': 'cursor-abc',
                },
              ],
              'pageInfo': {'hasNextPage': true},
            },
          },
        },
      };

      final response = GqlChatResponse.fromJson(json);

      expect(response.comments.length, 1);
      expect(response.comments.first.id, 'c1');
      expect(response.hasNextPage, isTrue);
      expect(response.cursor, 'cursor-abc');
    });

    test('fromJson throws on GQL errors', () {
      final json = {
        'errors': [
          {'message': 'Something went wrong'},
        ],
        'data': null,
      };

      expect(
        () => GqlChatResponse.fromJson(json),
        throwsA(isA<Exception>()),
      );
    });

    test('fromJson handles null video (VOD not found)', () {
      final json = {
        'data': {'video': null},
      };

      final response = GqlChatResponse.fromJson(json);
      expect(response.comments, isEmpty);
      expect(response.hasNextPage, isFalse);
    });
  });

  group('IRCMessage.fromGqlComment', () {
    test('converts comment to IRCMessage with correct tags', () {
      final comment = GqlChatComment(
        id: 'msg-1',
        contentOffsetSeconds: 300,
        commenterLogin: 'testuser',
        commenterDisplayName: 'TestUser',
        commenterId: 'user-123',
        userColor: '#FF0000',
        userBadges: [
          const GqlChatBadge(setId: 'subscriber', version: '3'),
          const GqlChatBadge(setId: 'moderator', version: '1'),
        ],
        messageFragments: [
          const GqlChatFragment(text: 'Hello world'),
        ],
      );

      final irc = IRCMessage.fromGqlComment(comment);

      expect(irc.command, Command.privateMessage);
      expect(irc.user, 'testuser');
      expect(irc.tags['display-name'], 'TestUser');
      expect(irc.tags['user-id'], 'user-123');
      expect(irc.tags['id'], 'msg-1');
      expect(irc.tags['color'], '#FF0000');
      expect(irc.tags['badges'], 'subscriber/3,moderator/1');
      expect(irc.tags['tmi-sent-ts'], '300000');
      expect(irc.message, 'Hello world');
      expect(irc.split, ['Hello', 'world']);
      expect(irc.localEmotes, isNull);
    });

    test('populates localEmotes for Twitch emotes', () {
      final comment = GqlChatComment(
        id: 'msg-2',
        contentOffsetSeconds: 10,
        commenterLogin: 'user',
        commenterDisplayName: 'User',
        commenterId: 'u1',
        userBadges: [],
        messageFragments: [
          const GqlChatFragment(text: 'Hey '),
          const GqlChatFragment(
            text: 'Kappa',
            emote: GqlChatEmote(emoteId: '25'),
          ),
          const GqlChatFragment(text: ' nice'),
        ],
      );

      final irc = IRCMessage.fromGqlComment(comment);

      expect(irc.message, 'Hey Kappa nice');
      expect(irc.localEmotes, isNotNull);
      expect(irc.localEmotes!['Kappa'], isNotNull);
      expect(irc.localEmotes!['Kappa']!.name, 'Kappa');
      expect(irc.localEmotes!['Kappa']!.url, contains('25'));
    });

    test('handles deleted commenter', () {
      final comment = GqlChatComment(
        id: 'msg-3',
        contentOffsetSeconds: 0,
        userBadges: [],
        messageFragments: [
          const GqlChatFragment(text: 'deleted message'),
        ],
      );

      final irc = IRCMessage.fromGqlComment(comment);

      expect(irc.tags['display-name'], 'Deleted User');
      expect(irc.user, isNull);
      expect(irc.tags['user-id'], '');
    });
  });
}
