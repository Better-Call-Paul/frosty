import 'package:flutter/foundation.dart';
import 'package:frosty/apis/twitch_api.dart';
import 'package:frosty/models/video.dart';
import 'package:mobx/mobx.dart';

part 'vod_list_store.g.dart';

class VodListStore = VodListStoreBase with _$VodListStore;

abstract class VodListStoreBase with Store {
  final TwitchApi twitchApi;
  final String userId;

  @readonly
  var _videos = ObservableList<VideoTwitch>();

  @readonly
  var _isLoading = false;

  @readonly
  var _error = '';

  String? _cursor;
  bool _hasMore = true;

  VodListStoreBase({
    required this.twitchApi,
    required this.userId,
  });

  @action
  Future<void> fetchVideos() async {
    _isLoading = true;
    _error = '';
    try {
      final response = await twitchApi.getVideos(userId: userId);
      _videos = response.data.asObservable();
      _cursor = response.pagination['cursor'];
      _hasMore = response.data.length >= 20;
    } catch (e) {
      _error = e.toString();
      debugPrint('Failed to fetch VODs: $e');
    } finally {
      _isLoading = false;
    }
  }

  @action
  Future<void> fetchMore() async {
    if (_isLoading || !_hasMore || _cursor == null) return;
    _isLoading = true;
    try {
      final response = await twitchApi.getVideos(
        userId: userId,
        cursor: _cursor,
      );
      _videos.addAll(response.data);
      _cursor = response.pagination['cursor'];
      _hasMore = response.data.length >= 20;
    } catch (e) {
      debugPrint('Failed to fetch more VODs: $e');
    } finally {
      _isLoading = false;
    }
  }

  @action
  Future<void> refresh() async {
    _cursor = null;
    _hasMore = true;
    await fetchVideos();
  }
}
