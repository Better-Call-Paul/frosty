import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosty/apis/twitch_gql_api.dart';
import 'package:frosty/constants.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

void main() {
  late Dio dio;
  late DioAdapter dioAdapter;
  late TwitchGqlApi api;

  setUp(() {
    dio = Dio(BaseOptions());
    dioAdapter = DioAdapter(dio: dio);
    api = TwitchGqlApi(dio);
  });

  group('getVideoComments', () {
    test('fetches comments by content offset', () async {
      dioAdapter.onPost(
        'https://gql.twitch.tv/gql',
        (server) => server.reply(200, {
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
                        'userColor': '#FF0000',
                        'userBadges': <Map<String, dynamic>>[],
                        'fragments': [
                          {'text': 'hello', 'emote': null},
                        ],
                      },
                    },
                    'cursor': 'cursor-1',
                  },
                ],
                'pageInfo': {'hasNextPage': true},
              },
            },
          },
        }),
        data: {
          'operationName': 'VideoCommentsByOffsetOrCursor',
          'variables': {
            'videoID': 'v123',
            'contentOffsetSeconds': 0,
          },
          'extensions': {
            'persistedQuery': {
              'version': 1,
              'sha256Hash':
                  'b70a3591ff0f4e0313d126c6a1502d79a1c02baebb288227c582044aa76adf6a',
            },
          },
        },
        headers: {'Client-ID': twitchGqlMobileClientId},
      );

      final response = await api.getVideoComments(
        videoId: 'v123',
        contentOffsetSeconds: 0,
      );

      expect(response.comments, hasLength(1));
      expect(response.comments.first.id, 'c1');
      expect(response.comments.first.commenterLogin, 'user1');
      expect(response.hasNextPage, isTrue);
      expect(response.cursor, 'cursor-1');
    });

    test('fetches comments by cursor', () async {
      dioAdapter.onPost(
        'https://gql.twitch.tv/gql',
        (server) => server.reply(200, {
          'data': {
            'video': {
              'comments': {
                'edges': [
                  {
                    'node': {
                      'id': 'c2',
                      'contentOffsetSeconds': 20,
                      'commenter': {
                        'id': 'u2',
                        'displayName': 'User2',
                        'login': 'user2',
                      },
                      'message': {
                        'userColor': null,
                        'userBadges': <Map<String, dynamic>>[],
                        'fragments': [
                          {'text': 'world', 'emote': null},
                        ],
                      },
                    },
                    'cursor': 'cursor-2',
                  },
                ],
                'pageInfo': {'hasNextPage': false},
              },
            },
          },
        }),
        data: {
          'operationName': 'VideoCommentsByOffsetOrCursor',
          'variables': {
            'videoID': 'v123',
            'cursor': 'cursor-1',
          },
          'extensions': {
            'persistedQuery': {
              'version': 1,
              'sha256Hash':
                  'b70a3591ff0f4e0313d126c6a1502d79a1c02baebb288227c582044aa76adf6a',
            },
          },
        },
        headers: {'Client-ID': twitchGqlMobileClientId},
      );

      final response = await api.getVideoComments(
        videoId: 'v123',
        cursor: 'cursor-1',
      );

      expect(response.comments, hasLength(1));
      expect(response.comments.first.id, 'c2');
      expect(response.hasNextPage, isFalse);
    });

    test('handles null video (VOD not found)', () async {
      dioAdapter.onPost(
        'https://gql.twitch.tv/gql',
        (server) => server.reply(200, {
          'data': {'video': null},
        }),
        data: {
          'operationName': 'VideoCommentsByOffsetOrCursor',
          'variables': {
            'videoID': 'nonexistent',
            'contentOffsetSeconds': 0,
          },
          'extensions': {
            'persistedQuery': {
              'version': 1,
              'sha256Hash':
                  'b70a3591ff0f4e0313d126c6a1502d79a1c02baebb288227c582044aa76adf6a',
            },
          },
        },
        headers: {'Client-ID': twitchGqlMobileClientId},
      );

      final response = await api.getVideoComments(
        videoId: 'nonexistent',
        contentOffsetSeconds: 0,
      );

      expect(response.comments, isEmpty);
      expect(response.hasNextPage, isFalse);
    });

    test('throws on GQL errors', () async {
      dioAdapter.onPost(
        'https://gql.twitch.tv/gql',
        (server) => server.reply(200, {
          'errors': [
            {'message': 'Something went wrong'},
          ],
          'data': null,
        }),
        data: {
          'operationName': 'VideoCommentsByOffsetOrCursor',
          'variables': {
            'videoID': 'v123',
            'contentOffsetSeconds': 0,
          },
          'extensions': {
            'persistedQuery': {
              'version': 1,
              'sha256Hash':
                  'b70a3591ff0f4e0313d126c6a1502d79a1c02baebb288227c582044aa76adf6a',
            },
          },
        },
        headers: {'Client-ID': twitchGqlMobileClientId},
      );

      expect(
        () => api.getVideoComments(
          videoId: 'v123',
          contentOffsetSeconds: 0,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
