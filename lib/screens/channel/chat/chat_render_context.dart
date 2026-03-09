import 'package:frosty/screens/channel/chat/stores/chat_assets_store.dart';
import 'package:frosty/screens/settings/stores/auth_store.dart';
import 'package:frosty/screens/settings/stores/settings_store.dart';
import 'package:mobx/mobx.dart';

/// Minimal interface for rendering chat messages.
///
/// Implemented by both [ChatStore] (live chat) and [VodChatStore] (VOD replay)
/// so that [ChatMessage] can render messages from either source.
abstract class ChatRenderContext {
  ChatAssetsStore get assetsStore;
  AuthStore get auth;
  SettingsStore get settings;
  String get channelId;
  ObservableSet<String> get revealedMessageIds;
  void revealMessage(String id);
  void updateNotification(String message);
}
