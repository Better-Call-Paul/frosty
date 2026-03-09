import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:frosty/apis/twitch_gql_api.dart';
import 'package:frosty/models/gql_chat_comment.dart';
import 'package:frosty/models/irc.dart';
import 'package:frosty/screens/channel/chat/chat_render_context.dart';
import 'package:frosty/screens/channel/chat/stores/chat_assets_store.dart';
import 'package:frosty/screens/settings/stores/auth_store.dart';
import 'package:frosty/screens/settings/stores/settings_store.dart';
import 'package:mobx/mobx.dart';

part 'vod_chat_store.g.dart';

class VodChatStore = VodChatStoreBase with _$VodChatStore;

abstract class VodChatStoreBase with Store implements ChatRenderContext {
  /// The total maximum amount of messages in chat.
  static const _messageLimit = 5000;

  /// The maximum amount of messages to render when autoscroll is enabled.
  static const _renderMessageLimit = 100;

  @override
  final ChatAssetsStore assetsStore;

  @override
  final AuthStore auth;

  @override
  final SettingsStore settings;

  @override
  final String channelId;

  @override
  final revealedMessageIds = ObservableSet<String>();

  final TwitchGqlApi twitchGqlApi;
  final String videoId;

  /// The scroll controller that controls auto-scroll and resume-scroll behavior.
  final scrollController = ScrollController();

  /// The amount of messages to free (remove) when the [_messageLimit] is reached.
  final _messagesToRemove = (_messageLimit * 0.2).toInt();

  /// The periodic timer used for batching chat message re-renders.
  Timer? _messageBufferTimer;

  /// The list of chat messages to add once autoscroll is resumed.
  final messageBuffer = ObservableList<IRCMessage>();

  /// Timer used for dismissing the notification.
  Timer? _notificationTimer;

  /// Fetched GQL comments waiting to be advanced based on playback position.
  final _commentBuffer = Queue<GqlChatComment>();

  /// Cursor for fetching the next page of comments.
  String? _nextCursor;

  /// Whether we're currently fetching comments from the API.
  bool _isFetching = false;

  /// The last rendered content offset to avoid duplicates.
  int _lastRenderedOffset = -1;

  /// A notification message to display above the chat.
  @readonly
  String? _notification;

  /// The list of chat messages to render and display.
  @readonly
  var _messages = ObservableList<IRCMessage>();

  /// If the chat should automatically scroll/jump to the latest message.
  @readonly
  var _autoScroll = true;

  /// Current playback position in seconds.
  @observable
  int playbackPosition = 0;

  /// Whether the store has been initialized.
  @readonly
  var _isInitialized = false;

  /// The list of chat messages that should be rendered. Used to prevent jank when resuming scroll.
  @computed
  List<IRCMessage> get renderMessages {
    // If autoscroll is disabled, render ALL messages in chat.
    // The second condition is to prevent an out of index error with sublist.
    if (!_autoScroll || _messages.length < _renderMessageLimit) {
      return _messages;
    }

    // When autoscroll is enabled, only show the first [_renderMessageLimit] messages.
    return _messages.sublist(_messages.length - _renderMessageLimit);
  }

  VodChatStoreBase({
    required this.assetsStore,
    required this.auth,
    required this.settings,
    required this.channelId,
    required this.twitchGqlApi,
    required this.videoId,
  });

  Future<void> init() async {
    await Future.wait([
      assetsStore.init().then((_) => _loadAssets()),
      _fetchComments(contentOffsetSeconds: 0),
    ]);
    _startMessageBufferTimer();
    _setupScrollListener();
    _isInitialized = true;
  }

  Future<void> _loadAssets() async {
    await assetsStore.assetsFuture(
      channelId: channelId,
      headers: auth.headersTwitch,
      onEmoteError: (error) {
        debugPrint(error.toString());
        return <dynamic>[];
      },
      onBadgeError: (error) {
        debugPrint(error.toString());
        return <dynamic>[];
      },
      showTwitchEmotes: settings.showTwitchEmotes,
      showTwitchBadges: settings.showTwitchBadges,
      show7TVEmotes: settings.show7TVEmotes,
      showBTTVEmotes: settings.showBTTVEmotes,
      showBTTVBadges: settings.showBTTVBadges,
      showFFZEmotes: settings.showFFZEmotes,
      showFFZBadges: settings.showFFZBadges,
    );
  }

  void _startMessageBufferTimer() {
    _messageBufferTimer = Timer.periodic(
      const Duration(milliseconds: 200),
      (_) => addMessages(),
    );
  }

  void _setupScrollListener() {
    scrollController.addListener(() {
      if (!scrollController.hasClients) return;
      final isAtBottom = scrollController.offset <= 0;
      if (isAtBottom != _autoScroll) {
        _autoScroll = isAtBottom;
        if (_autoScroll) addMessages();
      }
    });
  }

  @action
  void addMessages() {
    if (!_autoScroll || messageBuffer.isEmpty) return;

    _messages.addAll(messageBuffer);
    messageBuffer.clear();

    if (_messages.length > _messageLimit) {
      _messages.removeRange(0, _messagesToRemove);
    }
  }

  /// Re-enables [_autoScroll] and jumps to the latest message.
  @action
  void resumeScroll() {
    _autoScroll = true;

    scrollController.jumpTo(0);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollController.jumpTo(0);
    });
  }

  @override
  @action
  void revealMessage(String id) {
    revealedMessageIds.add(id);
  }

  @override
  @action
  void updateNotification(String message) {
    _notificationTimer?.cancel();
    _notification = message;
    _notificationTimer = Timer(const Duration(seconds: 5), () {
      _notification = null;
    });
  }

  @action
  void clearNotification() {
    _notificationTimer?.cancel();
    _notification = null;
  }

  /// Called from the JS channel with the current video position.
  @action
  void updatePlaybackPosition(int offsetSeconds) {
    final previousPosition = playbackPosition;
    playbackPosition = offsetSeconds;

    // Seek detection: if position jumped significantly, re-fetch.
    final delta = offsetSeconds - previousPosition;
    if (delta < -5 || delta > 10) {
      handleSeek(offsetSeconds);
      return;
    }

    // Advance comments from buffer to messageBuffer.
    _advanceComments(offsetSeconds);

    // Pre-fetch when running low.
    if (_commentBuffer.length < 50 && !_isFetching && _nextCursor != null) {
      _fetchComments(cursor: _nextCursor);
    }
  }

  void _advanceComments(int offsetSeconds) {
    while (_commentBuffer.isNotEmpty &&
        _commentBuffer.first.contentOffsetSeconds <= offsetSeconds) {
      final comment = _commentBuffer.removeFirst();
      if (comment.contentOffsetSeconds > _lastRenderedOffset ||
          _lastRenderedOffset == -1) {
        _lastRenderedOffset = comment.contentOffsetSeconds;
        messageBuffer.add(IRCMessage.fromGqlComment(comment));
      }
    }
  }

  /// Handles an explicit seek to [offsetSeconds], clearing state and re-fetching.
  @action
  Future<void> handleSeek(int offsetSeconds) async {
    playbackPosition = offsetSeconds;
    _commentBuffer.clear();
    messageBuffer.clear();
    _messages.clear();
    _lastRenderedOffset = -1;
    _nextCursor = null;
    await _fetchComments(contentOffsetSeconds: offsetSeconds);
  }

  Future<void> _fetchComments({
    int? contentOffsetSeconds,
    String? cursor,
  }) async {
    if (_isFetching) return;
    _isFetching = true;
    try {
      final response = await twitchGqlApi.getVideoComments(
        videoId: videoId,
        contentOffsetSeconds: contentOffsetSeconds,
        cursor: cursor,
      );
      _commentBuffer.addAll(response.comments);
      if (response.hasNextPage) {
        _nextCursor = response.cursor;
      } else {
        _nextCursor = null;
      }
    } catch (e) {
      debugPrint('Failed to fetch VOD comments: $e');
    } finally {
      _isFetching = false;
    }
  }

  void dispose() {
    _messageBufferTimer?.cancel();
    _notificationTimer?.cancel();
    scrollController.dispose();
  }
}
