import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:frosty/screens/channel/vod/stores/vod_list_store.dart';
import 'package:frosty/screens/channel/vod/vod_card.dart';
import 'package:frosty/utils/context_extensions.dart';
import 'package:frosty/widgets/alert_message.dart';

class VodList extends StatefulWidget {
  final String userId;
  final String displayName;

  const VodList({
    super.key,
    required this.userId,
    required this.displayName,
  });

  @override
  State<VodList> createState() => _VodListState();
}

class _VodListState extends State<VodList> {
  late final VodListStore _store = VodListStore(
    twitchApi: context.twitchApi,
    userId: widget.userId,
  );

  @override
  void initState() {
    super.initState();
    _store.fetchVideos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.displayName} — Past broadcasts')),
      body: Observer(
        builder: (context) {
          if (_store.error.isNotEmpty && _store.videos.isEmpty) {
            return Center(
              child: AlertMessage(message: _store.error),
            );
          }

          if (_store.videos.isEmpty && !_store.isLoading) {
            return const Center(
              child: AlertMessage(message: 'No past broadcasts found'),
            );
          }

          return RefreshIndicator.adaptive(
            onRefresh: _store.refresh,
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollEndNotification &&
                    notification.metrics.extentAfter < 200) {
                  _store.fetchMore();
                }
                return false;
              },
              child: ListView.builder(
                itemCount: _store.videos.length + (_store.isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _store.videos.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator.adaptive(),
                      ),
                    );
                  }
                  return VodCard(video: _store.videos[index]);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
