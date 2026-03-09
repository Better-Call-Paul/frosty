// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vod_chat_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$VodChatStore on VodChatStoreBase, Store {
  Computed<List<IRCMessage>>? _$renderMessagesComputed;

  @override
  List<IRCMessage> get renderMessages =>
      (_$renderMessagesComputed ??= Computed<List<IRCMessage>>(
        () => super.renderMessages,
        name: 'VodChatStoreBase.renderMessages',
      )).value;

  late final _$_notificationAtom = Atom(
    name: 'VodChatStoreBase._notification',
    context: context,
  );

  String? get notification {
    _$_notificationAtom.reportRead();
    return super._notification;
  }

  @override
  String? get _notification => notification;

  @override
  set _notification(String? value) {
    _$_notificationAtom.reportWrite(value, super._notification, () {
      super._notification = value;
    });
  }

  late final _$_messagesAtom = Atom(
    name: 'VodChatStoreBase._messages',
    context: context,
  );

  ObservableList<IRCMessage> get messages {
    _$_messagesAtom.reportRead();
    return super._messages;
  }

  @override
  ObservableList<IRCMessage> get _messages => messages;

  @override
  set _messages(ObservableList<IRCMessage> value) {
    _$_messagesAtom.reportWrite(value, super._messages, () {
      super._messages = value;
    });
  }

  late final _$_autoScrollAtom = Atom(
    name: 'VodChatStoreBase._autoScroll',
    context: context,
  );

  bool get autoScroll {
    _$_autoScrollAtom.reportRead();
    return super._autoScroll;
  }

  @override
  bool get _autoScroll => autoScroll;

  @override
  set _autoScroll(bool value) {
    _$_autoScrollAtom.reportWrite(value, super._autoScroll, () {
      super._autoScroll = value;
    });
  }

  late final _$playbackPositionAtom = Atom(
    name: 'VodChatStoreBase.playbackPosition',
    context: context,
  );

  @override
  int get playbackPosition {
    _$playbackPositionAtom.reportRead();
    return super.playbackPosition;
  }

  @override
  set playbackPosition(int value) {
    _$playbackPositionAtom.reportWrite(value, super.playbackPosition, () {
      super.playbackPosition = value;
    });
  }

  late final _$_isInitializedAtom = Atom(
    name: 'VodChatStoreBase._isInitialized',
    context: context,
  );

  bool get isInitialized {
    _$_isInitializedAtom.reportRead();
    return super._isInitialized;
  }

  @override
  bool get _isInitialized => isInitialized;

  @override
  set _isInitialized(bool value) {
    _$_isInitializedAtom.reportWrite(value, super._isInitialized, () {
      super._isInitialized = value;
    });
  }

  late final _$VodChatStoreBaseActionController = ActionController(
    name: 'VodChatStoreBase',
    context: context,
  );

  @override
  void addMessages() {
    final _$actionInfo = _$VodChatStoreBaseActionController.startAction(
      name: 'VodChatStoreBase.addMessages',
    );
    try {
      return super.addMessages();
    } finally {
      _$VodChatStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void resumeScroll() {
    final _$actionInfo = _$VodChatStoreBaseActionController.startAction(
      name: 'VodChatStoreBase.resumeScroll',
    );
    try {
      return super.resumeScroll();
    } finally {
      _$VodChatStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void revealMessage(String id) {
    final _$actionInfo = _$VodChatStoreBaseActionController.startAction(
      name: 'VodChatStoreBase.revealMessage',
    );
    try {
      return super.revealMessage(id);
    } finally {
      _$VodChatStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateNotification(String message) {
    final _$actionInfo = _$VodChatStoreBaseActionController.startAction(
      name: 'VodChatStoreBase.updateNotification',
    );
    try {
      return super.updateNotification(message);
    } finally {
      _$VodChatStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void clearNotification() {
    final _$actionInfo = _$VodChatStoreBaseActionController.startAction(
      name: 'VodChatStoreBase.clearNotification',
    );
    try {
      return super.clearNotification();
    } finally {
      _$VodChatStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updatePlaybackPosition(int offsetSeconds) {
    final _$actionInfo = _$VodChatStoreBaseActionController.startAction(
      name: 'VodChatStoreBase.updatePlaybackPosition',
    );
    try {
      return super.updatePlaybackPosition(offsetSeconds);
    } finally {
      _$VodChatStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
playbackPosition: ${playbackPosition},
renderMessages: ${renderMessages}
    ''';
  }
}
