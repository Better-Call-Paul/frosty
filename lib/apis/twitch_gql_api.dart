import 'dart:math';

import 'package:dio/dio.dart';
import 'package:frosty/apis/base_api_client.dart';
import 'package:frosty/constants.dart';
import 'package:frosty/models/gql_chat_comment.dart';
import 'package:frosty/models/playback_access_token.dart';

/// Twitch GQL API client for playback access tokens and VOD chat.
///
/// Uses the Twitch web client ID for playback tokens and the mobile
/// client ID for VOD chat (bypasses Client-Integrity checks).
class TwitchGqlApi extends BaseApiClient {
  TwitchGqlApi(Dio dio) : super(dio, 'https://gql.twitch.tv');

  /// Fetches a playback access token for the given channel [login].
  ///
  /// When [authToken] is provided, the request is authenticated which may
  /// grant ad-free playback for subscribers and Turbo users.
  Future<PlaybackAccessToken> getPlaybackAccessToken({
    required String login,
    String? authToken,
  }) async {
    final headers = <String, String>{
      'Client-ID': twitchGqlClientId,
      if (authToken != null) 'Authorization': 'OAuth $authToken',
    };

    final body = {
      'operationName': 'PlaybackAccessToken_Template',
      'query':
          'query PlaybackAccessToken_Template(\$login: String!, \$isLive: Boolean!, \$vodID: ID!, \$isVod: Boolean!, \$playerType: String!) { streamPlaybackAccessToken(channelName: \$login, params: {platform: "web", playerBackend: "mediaplayer", playerType: \$playerType}) @include(if: \$isLive) { value signature __typename } videoPlaybackAccessToken(id: \$vodID, params: {platform: "web", playerBackend: "mediaplayer", playerType: \$playerType}) @include(if: \$isVod) { value signature __typename } }',
      'variables': {
        'isLive': true,
        'login': login,
        'isVod': false,
        'vodID': '',
        'playerType': 'site',
      },
    };

    final response = await post<JsonMap>(
      '/gql',
      data: body,
      headers: headers,
    );

    return PlaybackAccessToken.fromGqlResponse(response);
  }

  /// Builds the HLS stream URL for the given channel [login] and [token].
  String buildHlsUrl({
    required String login,
    required PlaybackAccessToken token,
  }) {
    final random = Random().nextInt(999999);
    final encodedToken = Uri.encodeComponent(token.value);

    return 'https://usher.ttvnw.net/api/channel/hls/$login.m3u8'
        '?sig=${token.signature}'
        '&token=$encodedToken'
        '&allow_source=true'
        '&allow_audio_only=true'
        '&fast_bread=true'
        '&supported_codecs=h264'
        '&platform=web'
        '&playlist_include_framerate=true'
        '&p=$random';
  }

  /// Fetches VOD chat comments for the given [videoId].
  ///
  /// Pass [contentOffsetSeconds] for initial fetch at a position, or
  /// [cursor] for pagination from a previous response.
  Future<GqlChatResponse> getVideoComments({
    required String videoId,
    int? contentOffsetSeconds,
    String? cursor,
  }) async {
    final headers = <String, String>{
      'Client-ID': twitchGqlMobileClientId,
    };

    final variables = <String, dynamic>{
      'videoID': videoId,
    };
    if (cursor != null) {
      variables['cursor'] = cursor;
    } else {
      variables['contentOffsetSeconds'] = contentOffsetSeconds ?? 0;
    }

    final body = {
      'operationName': 'VideoCommentsByOffsetOrCursor',
      'variables': variables,
      'extensions': {
        'persistedQuery': {
          'version': 1,
          'sha256Hash':
              'b70a3591ff0f4e0313d126c6a1502d79a1c02baebb288227c582044aa76adf6a',
        },
      },
    };

    final response = await post<JsonMap>(
      '/gql',
      data: body,
      headers: headers,
    );

    return GqlChatResponse.fromJson(response);
  }
}
