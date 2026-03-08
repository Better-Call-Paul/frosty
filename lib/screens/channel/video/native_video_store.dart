import 'dart:async';

import 'package:better_native_video_player/better_native_video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frosty/apis/twitch_api.dart';
import 'package:frosty/apis/twitch_gql_api.dart';
import 'package:frosty/models/channel.dart';
import 'package:frosty/models/playback_access_token.dart';
import 'package:frosty/models/stream.dart';
import 'package:frosty/screens/channel/video/video_player_interface.dart';
import 'package:frosty/screens/settings/stores/auth_store.dart';
import 'package:frosty/screens/settings/stores/settings_store.dart';
import 'package:frosty/services/cookie_extractor.dart';
import 'package:mobx/mobx.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'native_video_store.g.dart';

class NativeVideoStore = NativeVideoStoreBase with _$NativeVideoStore;

abstract class NativeVideoStoreBase with Store implements VideoPlayerInterface {
  static int _nextId = 0;

  final String userLogin;
  final String userId;
  final TwitchApi twitchApi;
  final TwitchGqlApi twitchGqlApi;
  final AuthStore authStore;

  @override
  final SettingsStore settingsStore;

  @readonly
  NativeVideoPlayerController? _controller;

  Timer? _overlayTimer;
  Timer? _latencyTimer;
  DateTime? _lastStreamInfoUpdate;
  Future<void>? _streamInfoRequest;
  bool _overlayWasVisibleBeforePip = true;

  List<NativeVideoPlayerQuality> _qualityObjects = [];
  var _firstTimeSettingQuality = true;
  int? _pendingQualityIndex;

  StreamSubscription<bool>? _pipSub;
  StreamSubscription<List<NativeVideoPlayerQuality>>? _qualitiesSub;

  @readonly
  var _paused = true;

  @readonly
  var _overlayVisible = true;

  @readonly
  StreamTwitch? _streamInfo;

  @readonly
  Channel? _offlineChannelInfo;

  @readonly
  var _availableStreamQualities = <String>[];

  @readonly
  var _streamQualityIndex = 0;

  @override
  String get streamQuality =>
      _availableStreamQualities.elementAtOrNull(_streamQualityIndex) ?? 'Auto';

  @readonly
  String? _latency;

  @readonly
  var _isInPipMode = false;

  @readonly
  String? _error;

  String? _hlsUrl;

  NativeVideoStoreBase({
    required this.userLogin,
    required this.userId,
    required this.twitchApi,
    required this.twitchGqlApi,
    required this.authStore,
    required this.settingsStore,
  }) {
    _controller = NativeVideoPlayerController(
      id: _nextId++,
      autoPlay: true,
      showNativeControls: false,
    );
    _controller!.addActivityListener(_handleActivityEvent);
    _scheduleOverlayHide();
    updateStreamInfo();
    _initPlayer();
  }

  @action
  Future<void> _initPlayer() async {
    try {
      // Prefer web cookie token (works with web Client-ID) for ad-free playback.
      // Fall back to direct cookie extraction if AuthStore hasn't resolved it yet.
      var authToken = authStore.gqlToken;
      authToken ??= await CookieExtractor.extractTwitchAuthToken();
      late final PlaybackAccessToken token;
      try {
        token = await twitchGqlApi.getPlaybackAccessToken(
          login: userLogin,
          authToken: authToken,
        );
      } catch (_) {
        if (authToken != null) {
          token = await twitchGqlApi.getPlaybackAccessToken(
            login: userLogin,
          );
        } else {
          rethrow;
        }
      }

      _hlsUrl = twitchGqlApi.buildHlsUrl(login: userLogin, token: token);

      await _controller!.initialize();

      _pipSub = _controller!.isPipEnabledStream.listen((isPip) {
        runInAction(() {
          if (isPip && !_isInPipMode) {
            _overlayWasVisibleBeforePip = _overlayVisible;
            _isInPipMode = true;
            _overlayTimer?.cancel();
            _overlayVisible = true;
          } else if (!isPip && _isInPipMode) {
            _isInPipMode = false;
            if (_overlayWasVisibleBeforePip) {
              _scheduleOverlayHide();
            } else {
              _overlayVisible = false;
            }
          }
        });
      });

      _qualitiesSub = _controller!.qualitiesStream.listen((qualities) {
        runInAction(() {
          // Filter out the plugin's auto entry (we add our own) and deduplicate.
          final seen = <String>{};
          final filtered = qualities
              .where((q) => !q.isAuto && seen.add(q.label))
              .toList();

          // Reverse so highest quality comes first.
          _qualityObjects = filtered.reversed.toList();
          _availableStreamQualities = [
            'Auto',
            ..._qualityObjects.map((q) => q.label),
          ];

          if (_firstTimeSettingQuality && qualities.isNotEmpty) {
            _firstTimeSettingQuality = false;
            if (settingsStore.defaultToHighestQuality) {
              _pendingQualityIndex = 1;
            } else {
              SharedPreferences.getInstance().then((prefs) {
                final lastQuality = prefs.getString('last_stream_quality');
                if (lastQuality != null) {
                  final index = _availableStreamQualities.indexOf(lastQuality);
                  if (index != -1) _pendingQualityIndex = index;
                }
              });
            }
          }
        });
      });

      await _controller!.loadUrl(url: _hlsUrl!);
      await _controller!.configureForLivePlayback();

      _startLatencyPolling();

      runInAction(() {
        _error = null;
      });
    } catch (e) {
      runInAction(() {
        _error =
            'Native player failed to load. Try the standard player in Settings.';
      });
      debugPrint('NativeVideoStore init error: $e');
    }
  }

  void _handleActivityEvent(PlayerActivityEvent event) {
    runInAction(() {
      switch (event.state) {
        case PlayerActivityState.playing:
          _paused = false;
          if (_pendingQualityIndex != null) {
            final index = _pendingQualityIndex!;
            _pendingQualityIndex = null;
            _setStreamQualityIndex(index);
          }
        case PlayerActivityState.paused:
        case PlayerActivityState.stopped:
        case PlayerActivityState.completed:
        case PlayerActivityState.idle:
          _paused = true;
        default:
          break;
      }
    });
  }

  void _startLatencyPolling() {
    _latencyTimer?.cancel();
    if (settingsStore.autoSyncChatDelay) {
      settingsStore.syncedChatDelay = 0;
    }
    _latencyTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) async {
        final seconds = await _controller?.getLatencyToLive();
        if (seconds == null) return;
        final rounded = seconds.round();

        runInAction(() {
          _latency = '${rounded}s';
        });

        if (!settingsStore.autoSyncChatDelay) return;

        // Only update when unset or drifted by >2s to avoid restarting
        // the chat countdown on minor fluctuations.
        final current = settingsStore.syncedChatDelay;
        if (current == 0 || (seconds - current).abs() > 2) {
          settingsStore.syncedChatDelay = seconds;
        }
      },
    );
  }

  void _scheduleOverlayHide([Duration delay = const Duration(seconds: 5)]) {
    _overlayTimer?.cancel();

    if (_isInPipMode) {
      _overlayVisible = true;
      return;
    }

    _overlayTimer = Timer(delay, () {
      if (_isInPipMode) return;
      runInAction(() {
        _overlayVisible = false;
      });
    });
  }

  @override
  @action
  void handleVideoTap() {
    if (_isInPipMode) {
      _overlayVisible = true;
      return;
    }

    _overlayTimer?.cancel();

    if (_overlayVisible) {
      _overlayVisible = false;
    } else {
      updateStreamInfo(forceUpdate: true);
      _overlayVisible = true;
      _scheduleOverlayHide();
    }
  }

  @override
  void handlePausePlay() {
    if (_controller == null) return;
    if (_paused) {
      _controller!.play();
    } else {
      _controller!.pause();
    }
  }

  @override
  @action
  void handleToggleOverlay() {
    if (settingsStore.toggleableOverlay) {
      HapticFeedback.mediumImpact();
      settingsStore.showOverlay = !settingsStore.showOverlay;

      if (settingsStore.showOverlay) {
        _overlayVisible = true;
        _scheduleOverlayHide(const Duration(seconds: 3));
      }
    }
  }

  @override
  @action
  Future<void> handleRefresh() async {
    HapticFeedback.lightImpact();
    _paused = true;
    _firstTimeSettingQuality = true;
    _pendingQualityIndex = null;
    _isInPipMode = false;
    _availableStreamQualities = [];
    _qualityObjects = [];
    _error = null;

    _latencyTimer?.cancel();
    _pipSub?.cancel();
    _qualitiesSub?.cancel();
    _controller?.removeActivityListener(_handleActivityEvent);
    _controller?.dispose();
    _controller = NativeVideoPlayerController(
      id: _nextId++,
      autoPlay: true,
      showNativeControls: false,
    );
    _controller!.addActivityListener(_handleActivityEvent);

    await _initPlayer();
    updateStreamInfo();
  }

  @override
  void requestPictureInPicture() {
    _controller?.enterPictureInPicture();
  }

  @override
  @action
  void togglePictureInPicture() {
    if (_isInPipMode) {
      _controller?.exitPictureInPicture();
    } else {
      _controller?.enterPictureInPicture();
    }
  }

  @override
  @action
  Future<void> updateStreamQualities() async {
    // Qualities are populated automatically via qualitiesStream.
  }

  @override
  @action
  Future<void> setStreamQuality(String quality) async {
    final index = _availableStreamQualities.indexOf(quality);
    if (index == -1) return;
    await _setStreamQualityIndex(index);
  }

  @action
  Future<void> _setStreamQualityIndex(int index) async {
    _streamQualityIndex = index;
    if (_controller == null) return;

    if (index == 0) {
      // 'Auto' — reset to adaptive quality
      await _controller!.setQuality(NativeVideoPlayerQuality.auto());
    } else {
      final qualityIndex = index - 1;
      if (qualityIndex < _qualityObjects.length) {
        await _controller!.setQuality(_qualityObjects[qualityIndex]);
      }
    }
  }

  @override
  @action
  Future<void> updateStreamInfo({bool forceUpdate = false}) async {
    if (_streamInfoRequest != null) {
      await _streamInfoRequest;
      return;
    }

    final now = DateTime.now();
    if (!forceUpdate && _lastStreamInfoUpdate != null) {
      final timeSince = now.difference(_lastStreamInfoUpdate!);
      if (timeSince.inSeconds < 5) return;
    }

    _lastStreamInfoUpdate = now;

    final request = _updateStreamInfoInternal();
    _streamInfoRequest = request;

    try {
      await request;
    } finally {
      if (identical(_streamInfoRequest, request)) {
        _streamInfoRequest = null;
      }
    }
  }

  Future<void> _updateStreamInfoInternal() async {
    try {
      _streamInfo = await twitchApi.getStream(userLogin: userLogin);
      _offlineChannelInfo = null;
    } catch (e) {
      _overlayTimer?.cancel();
      _streamInfo = null;
      _paused = true;

      try {
        _offlineChannelInfo = await twitchApi.getChannel(userId: userId);
      } catch (_) {
        _offlineChannelInfo = null;
      }
    }
  }

  @override
  @action
  void handleAppResume() {
    if (!settingsStore.showVideo) {
      updateStreamInfo(forceUpdate: true);
    }
  }

  @override
  @action
  void dispose() {
    _overlayTimer?.cancel();
    _latencyTimer?.cancel();
    _pipSub?.cancel();
    _qualitiesSub?.cancel();

    _controller?.removeActivityListener(_handleActivityEvent);
    _controller?.dispose();
    _controller = null;
  }
}
