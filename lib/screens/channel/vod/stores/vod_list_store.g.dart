// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vod_list_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$VodListStore on VodListStoreBase, Store {
  late final _$_videosAtom = Atom(
    name: 'VodListStoreBase._videos',
    context: context,
  );

  ObservableList<VideoTwitch> get videos {
    _$_videosAtom.reportRead();
    return super._videos;
  }

  @override
  ObservableList<VideoTwitch> get _videos => videos;

  @override
  set _videos(ObservableList<VideoTwitch> value) {
    _$_videosAtom.reportWrite(value, super._videos, () {
      super._videos = value;
    });
  }

  late final _$_isLoadingAtom = Atom(
    name: 'VodListStoreBase._isLoading',
    context: context,
  );

  bool get isLoading {
    _$_isLoadingAtom.reportRead();
    return super._isLoading;
  }

  @override
  bool get _isLoading => isLoading;

  @override
  set _isLoading(bool value) {
    _$_isLoadingAtom.reportWrite(value, super._isLoading, () {
      super._isLoading = value;
    });
  }

  late final _$_errorAtom = Atom(
    name: 'VodListStoreBase._error',
    context: context,
  );

  String get error {
    _$_errorAtom.reportRead();
    return super._error;
  }

  @override
  String get _error => error;

  @override
  set _error(String value) {
    _$_errorAtom.reportWrite(value, super._error, () {
      super._error = value;
    });
  }

  late final _$fetchVideosAsyncAction = AsyncAction(
    'VodListStoreBase.fetchVideos',
    context: context,
  );

  @override
  Future<void> fetchVideos() {
    return _$fetchVideosAsyncAction.run(() => super.fetchVideos());
  }

  late final _$fetchMoreAsyncAction = AsyncAction(
    'VodListStoreBase.fetchMore',
    context: context,
  );

  @override
  Future<void> fetchMore() {
    return _$fetchMoreAsyncAction.run(() => super.fetchMore());
  }

  late final _$refreshAsyncAction = AsyncAction(
    'VodListStoreBase.refresh',
    context: context,
  );

  @override
  Future<void> refresh() {
    return _$refreshAsyncAction.run(() => super.refresh());
  }

  @override
  String toString() {
    return '''

    ''';
  }
}
