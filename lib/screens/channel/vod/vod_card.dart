import 'dart:math';

import 'package:flutter/material.dart';
import 'package:frosty/constants.dart';
import 'package:frosty/models/video.dart';
import 'package:frosty/screens/channel/vod/vod_player.dart';
import 'package:frosty/utils/context_extensions.dart';
import 'package:frosty/widgets/frosty_cached_network_image.dart';
import 'package:frosty/widgets/skeleton_loader.dart';

/// A tappable card widget that displays a VOD's thumbnail and details.
class VodCard extends StatelessWidget {
  final VideoTwitch video;

  const VodCard({super.key, required this.video});

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h${minutes.toString().padLeft(2, '0')}m${seconds.toString().padLeft(2, '0')}s';
    }
    return '${minutes}m${seconds.toString().padLeft(2, '0')}s';
  }

  String _formatRelativeDate(String createdAt) {
    final date = DateTime.tryParse(createdAt);
    if (date == null) return createdAt;

    final now = DateTime.now().toUtc();
    final difference = now.difference(date);

    if (difference.inDays >= 365) {
      final years = difference.inDays ~/ 365;
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays >= 30) {
      final months = difference.inDays ~/ 30;
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays >= 1) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final thumbnailWidth = min((size.width * pixelRatio) ~/ 3, 1920);
    final thumbnailHeight = min((thumbnailWidth * (9 / 16)).toInt(), 1080);

    final duration = parseTwitchDuration(video.duration);

    final thumbnailUrl = video.thumbnailUrl
        .replaceFirst('%{width}', '$thumbnailWidth')
        .replaceFirst('%{height}', '$thumbnailHeight');

    final thumbnail = AspectRatio(
      aspectRatio: 16 / 9,
      child: thumbnailUrl.isEmpty
          ? Container(color: Colors.black12)
          : FrostyCachedNetworkImage(
              imageUrl: thumbnailUrl,
              placeholder: (context, url) => const SkeletonLoader(
                borderRadius: kCardBorderRadius,
              ),
              useOldImageOnUrlChange: true,
            ),
    );

    final fontColor = DefaultTextStyle.of(context).style.color;
    const subFontSize = 14.0;

    final imageSection = ClipRRect(
      borderRadius: kCardBorderRadius,
      child: Stack(
        alignment: AlignmentDirectional.bottomEnd,
        children: [
          thumbnail,
          Container(
            margin: const EdgeInsets.all(3),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 0.5,
              ),
            ),
            child: Text(
              _formatDuration(duration),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: context.frostyColors.overlayOnSurface,
              ),
            ),
          ),
        ],
      ),
    );

    final vodInfoSection = Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 2,
        children: [
          Tooltip(
            message: video.title.trim(),
            preferBelow: false,
            child: Text(
              video.title.trim(),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: fontColor,
              ),
            ),
          ),
          Text(
            _formatRelativeDate(video.createdAt),
            style: TextStyle(
              fontSize: subFontSize,
              color: fontColor?.withValues(alpha: 0.8),
            ),
          ),
          Text(
            '${_formatViewCount(video.viewCount)} views',
            style: TextStyle(
              fontSize: subFontSize,
              color: fontColor?.withValues(alpha: 0.8),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VodPlayer(
            videoId: video.id,
            channelId: video.userId,
            title: video.title,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          top: 8,
          bottom: 8,
          left: 16 + MediaQuery.of(context).padding.left,
          right: 16 + MediaQuery.of(context).padding.right,
        ),
        child: Row(
          children: [
            Flexible(child: imageSection),
            Flexible(flex: 2, child: vodInfoSection),
          ],
        ),
      ),
    );
  }

  String _formatViewCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
