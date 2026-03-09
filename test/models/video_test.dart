import 'package:flutter_test/flutter_test.dart';
import 'package:frosty/models/video.dart';

void main() {
  group('VideoTwitch', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'id': '12345',
        'stream_id': '67890',
        'user_id': '111',
        'user_login': 'testuser',
        'user_name': 'TestUser',
        'title': 'Test Stream VOD',
        'created_at': '2024-01-15T10:30:00Z',
        'published_at': '2024-01-15T10:30:00Z',
        'duration': '3h26m15s',
        'thumbnail_url':
            'https://static-cdn.jtvnw.net/cf_vods/abc/%{width}x%{height}.jpg',
        'view_count': 12345,
      };

      final video = VideoTwitch.fromJson(json);

      expect(video.id, '12345');
      expect(video.streamId, '67890');
      expect(video.userId, '111');
      expect(video.userLogin, 'testuser');
      expect(video.userName, 'TestUser');
      expect(video.title, 'Test Stream VOD');
      expect(video.createdAt, '2024-01-15T10:30:00Z');
      expect(video.publishedAt, '2024-01-15T10:30:00Z');
      expect(video.duration, '3h26m15s');
      expect(video.thumbnailUrl, contains('%{width}'));
      expect(video.viewCount, 12345);
    });

    test('fromJson handles null streamId', () {
      final json = {
        'id': '12345',
        'stream_id': null,
        'user_id': '111',
        'user_login': 'testuser',
        'user_name': 'TestUser',
        'title': 'Test',
        'created_at': '2024-01-15T10:30:00Z',
        'published_at': '2024-01-15T10:30:00Z',
        'duration': '1h0m0s',
        'thumbnail_url': '',
        'view_count': 0,
      };

      final video = VideoTwitch.fromJson(json);
      expect(video.streamId, isNull);
    });
  });

  group('VideosTwitch', () {
    test('fromJson parses data list and pagination', () {
      final json = {
        'data': [
          {
            'id': '1',
            'stream_id': null,
            'user_id': '111',
            'user_login': 'user',
            'user_name': 'User',
            'title': 'Title',
            'created_at': '2024-01-01T00:00:00Z',
            'published_at': '2024-01-01T00:00:00Z',
            'duration': '1h0m0s',
            'thumbnail_url': '',
            'view_count': 100,
          },
        ],
        'pagination': {'cursor': 'abc123'},
      };

      final videos = VideosTwitch.fromJson(json);
      expect(videos.data.length, 1);
      expect(videos.data.first.id, '1');
      expect(videos.pagination['cursor'], 'abc123');
    });

    test('fromJson handles empty data', () {
      final json = {
        'data': <Map<String, dynamic>>[],
        'pagination': <String, String>{},
      };

      final videos = VideosTwitch.fromJson(json);
      expect(videos.data, isEmpty);
    });
  });

  group('parseTwitchDuration', () {
    test('parses hours, minutes, and seconds', () {
      expect(
        parseTwitchDuration('3h26m15s'),
        const Duration(hours: 3, minutes: 26, seconds: 15),
      );
    });

    test('parses minutes and seconds only', () {
      expect(
        parseTwitchDuration('45m30s'),
        const Duration(minutes: 45, seconds: 30),
      );
    });

    test('parses seconds only', () {
      expect(
        parseTwitchDuration('30s'),
        const Duration(seconds: 30),
      );
    });

    test('parses hours and minutes only', () {
      expect(
        parseTwitchDuration('2h10m'),
        const Duration(hours: 2, minutes: 10),
      );
    });

    test('returns Duration.zero for empty string', () {
      expect(parseTwitchDuration(''), Duration.zero);
    });
  });
}
