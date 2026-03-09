import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:frosty/screens/channel/chat/stores/chat_assets_store.dart';
import 'package:frosty/screens/channel/chat/widgets/chat_message.dart';
import 'package:frosty/screens/channel/vod/stores/vod_chat_store.dart';
import 'package:frosty/utils/context_extensions.dart';
import 'package:frosty/widgets/frosty_notification.dart';
import 'package:frosty/widgets/frosty_scrollbar.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

/// VOD player + chat replay screen.
///
/// Layout matches the live channel view [VideoChat]: no AppBar,
/// video on top (16:9), chat below (expanded).
class VodPlayer extends StatefulWidget {
  final String videoId;
  final String channelId;
  final String title;

  const VodPlayer({
    super.key,
    required this.videoId,
    required this.channelId,
    required this.title,
  });

  @override
  State<VodPlayer> createState() => _VodPlayerState();
}

class _VodPlayerState extends State<VodPlayer> {
  late final VodChatStore _vodChatStore;
  late final WebViewController _webViewController;

  String get _videoUrl =>
      'https://player.twitch.tv/?video=v${widget.videoId}&parent=frosty&muted=false';

  @override
  void initState() {
    super.initState();

    _vodChatStore = VodChatStore(
      assetsStore: ChatAssetsStore(
        twitchApi: context.twitchApi,
        bttvApi: context.bttvApi,
        ffzApi: context.ffzApi,
        sevenTVApi: context.sevenTVApi,
        globalAssetsStore: context.globalAssetsStore,
      ),
      auth: context.authStore,
      settings: context.settingsStore,
      channelId: widget.channelId,
      twitchGqlApi: context.twitchGqlApi,
      videoId: widget.videoId,
    );

    _vodChatStore.init();
    _initWebView();
  }

  void _initWebView() {
    // Platform-specific params for autoplay.
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _webViewController =
        WebViewController.fromPlatformCreationParams(params)
          ..setBackgroundColor(Colors.black)
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..addJavaScriptChannel(
            'VodPosition',
            onMessageReceived: (message) {
              final text = message.message;
              if (text.startsWith('seek:')) {
                final seconds =
                    double.tryParse(text.substring(5))?.toInt() ?? 0;
                _vodChatStore.handleSeek(seconds);
              } else {
                final seconds = double.tryParse(text)?.toInt() ?? 0;
                _vodChatStore.updatePlaybackPosition(seconds);
              }
            },
          )
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageFinished: (url) async {
                if (!url.contains('player.twitch.tv')) return;
                await _injectPositionTracker();
              },
            ),
          );

    // Android: disable user gesture requirement for autoplay.
    if (_webViewController.platform is AndroidWebViewController) {
      (_webViewController.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    _webViewController.loadRequest(Uri.parse(_videoUrl));
  }

  Future<void> _injectPositionTracker() async {
    // Wait for the video element to be available, then poll currentTime
    // and listen for seek events.
    await _webViewController.runJavaScript('''
(function() {
  function tryAttach() {
    var video = document.querySelector('video');
    if (!video) {
      setTimeout(tryAttach, 500);
      return;
    }
    setInterval(function() {
      VodPosition.postMessage(Math.floor(video.currentTime).toString());
    }, 1000);
    video.addEventListener('seeked', function() {
      VodPosition.postMessage('seek:' + Math.floor(video.currentTime).toString());
    });
  }
  tryAttach();
})();
''');
  }

  Widget _buildWebView() {
    if (Platform.isAndroid &&
        WebViewPlatform.instance is AndroidWebViewPlatform) {
      return WebViewWidget.fromPlatformCreationParams(
        params: AndroidWebViewWidgetCreationParams(
          controller: _webViewController.platform,
          displayWithHybridComposition:
              !context.settingsStore.useTextureRendering,
        ),
      );
    }
    return WebViewWidget(controller: _webViewController);
  }

  Widget _buildChatList() {
    return Observer(
      builder: (context) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: _vodChatStore.settings.messageScale.textScaler,
          ),
          child: DefaultTextStyle(
            style: context.defaultTextStyle.copyWith(
              fontSize: _vodChatStore.settings.fontSize,
            ),
            child: Stack(
              alignment: AlignmentDirectional.bottomCenter,
              children: [
                FrostyScrollbar(
                  controller: _vodChatStore.scrollController,
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom,
                  ),
                  child: Observer(
                    builder: (context) {
                      final messages = _vodChatStore.renderMessages;
                      return ListView.builder(
                        reverse: true,
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).padding.bottom,
                        ),
                        addAutomaticKeepAlives: false,
                        controller: _vodChatStore.scrollController,
                        itemCount: messages.length,
                        itemBuilder: (context, index) => ChatMessage(
                          ircMessage:
                              messages[messages.length - 1 - index],
                          chatStore: _vodChatStore,
                        ),
                      );
                    },
                  ),
                ),
                _buildResumeScrollButton(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildResumeScrollButton() {
    return Builder(
      builder: (context) {
        return AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.only(
            left: 4,
            top: 4,
            right: 4,
            bottom: MediaQuery.of(context).padding.bottom,
          ),
          child: Observer(
            builder: (_) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: _vodChatStore.autoScroll
                    ? null
                    : ElevatedButton.icon(
                        onPressed: _vodChatStore.resumeScroll,
                        icon: const Icon(Icons.arrow_downward_rounded),
                        label: Text(
                          _vodChatStore.messageBuffer.isNotEmpty
                              ? '${_vodChatStore.messageBuffer.length} new ${_vodChatStore.messageBuffer.length == 1 ? 'message' : 'messages'}'
                              : 'Resume scroll',
                          style: const TextStyle(
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: _buildWebView(),
            ),
            Expanded(
              child: Stack(
                children: [
                  _buildChatList(),
                  Observer(
                    builder: (_) => AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: _vodChatStore.notification != null
                          ? Align(
                              alignment: Alignment.topCenter,
                              child: FrostyNotification(
                                message: _vodChatStore.notification!,
                                onDismissed: _vodChatStore.clearNotification,
                              ),
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _vodChatStore.dispose();
    super.dispose();
  }
}
