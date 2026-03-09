// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VideoTwitch _$VideoTwitchFromJson(Map<String, dynamic> json) => VideoTwitch(
  json['id'] as String,
  json['stream_id'] as String?,
  json['user_id'] as String,
  json['user_login'] as String,
  json['user_name'] as String,
  json['title'] as String,
  json['created_at'] as String,
  json['published_at'] as String,
  json['duration'] as String,
  json['thumbnail_url'] as String,
  (json['view_count'] as num).toInt(),
);

VideosTwitch _$VideosTwitchFromJson(Map<String, dynamic> json) => VideosTwitch(
  (json['data'] as List<dynamic>)
      .map((e) => VideoTwitch.fromJson(e as Map<String, dynamic>))
      .toList(),
  Map<String, String>.from(json['pagination'] as Map),
);
