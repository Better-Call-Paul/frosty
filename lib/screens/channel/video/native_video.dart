import 'package:better_native_video_player/better_native_video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:frosty/screens/channel/video/native_video_store.dart';

/// Native video player widget backed by AVPlayerViewController (iOS)
/// and ExoPlayer (Android).
class NativeVideo extends StatelessWidget {
  final NativeVideoStore nativeVideoStore;

  const NativeVideo({super.key, required this.nativeVideoStore});

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
        final controller = nativeVideoStore.controller;
        final error = nativeVideoStore.error;

        final isOffline =
            !nativeVideoStore.loading &&
            nativeVideoStore.streamInfo == null &&
            error == null;

        return ColoredBox(
          color: Colors.black,
          child: Stack(
            children: [
              if (controller != null && !isOffline)
                NativeVideoPlayer(
                  key: ObjectKey(controller),
                  controller: controller,
                ),
              if (error != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      error,
                      style: const TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              if (isOffline)
                const Center(
                  child: Text(
                    'Offline',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
