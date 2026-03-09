import 'package:json_annotation/json_annotation.dart';

part 'video.g.dart';

/// Object for Twitch VODs (past broadcasts).
@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class VideoTwitch {
  final String id;
  final String? streamId;
  final String userId;
  final String userLogin;
  final String userName;
  final String title;
  final String createdAt;
  final String publishedAt;
  final String duration;
  final String thumbnailUrl;
  final int viewCount;

  const VideoTwitch(
    this.id,
    this.streamId,
    this.userId,
    this.userLogin,
    this.userName,
    this.title,
    this.createdAt,
    this.publishedAt,
    this.duration,
    this.thumbnailUrl,
    this.viewCount,
  );

  factory VideoTwitch.fromJson(Map<String, dynamic> json) =>
      _$VideoTwitchFromJson(json);
}

@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class VideosTwitch {
  final List<VideoTwitch> data;
  final Map<String, String> pagination;

  const VideosTwitch(this.data, this.pagination);

  factory VideosTwitch.fromJson(Map<String, dynamic> json) =>
      _$VideosTwitchFromJson(json);
}

/// Parses a Twitch duration string like "3h26m15s" into a [Duration].
Duration parseTwitchDuration(String duration) {
  final regex = RegExp(r'(?:(\d+)h)?(?:(\d+)m)?(?:(\d+)s)?');
  final match = regex.firstMatch(duration);
  if (match == null) return Duration.zero;

  final hours = int.tryParse(match.group(1) ?? '') ?? 0;
  final minutes = int.tryParse(match.group(2) ?? '') ?? 0;
  final seconds = int.tryParse(match.group(3) ?? '') ?? 0;

  return Duration(hours: hours, minutes: minutes, seconds: seconds);
}
