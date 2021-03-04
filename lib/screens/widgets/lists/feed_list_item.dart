import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rss_feed_reader/database/database.dart';
import 'package:rss_feed_reader/providers/network.dart';

final selectedFeedProvider =
    StreamProvider.autoDispose.family<FeedData, int>((ref, _id) {
  final db = ref.watch(rssDatabase);
  return (db.select(db.feed)..where((tbl) => tbl.id.equals(_id))).watchSingle();
});

class FeedListItem extends ConsumerWidget {
  final int feedId;
  const FeedListItem({required this.feedId});
  ListTile _tileItem(ScopedReader watch, FeedData feed) => ListTile(
        tileColor: Colors.green,
        trailing: PopupMenuButton(
            itemBuilder: (_) => <PopupMenuItem<String>>[
                  new PopupMenuItem<String>(
                      child: IconButton(
                          icon: Icon(Icons.refresh),
                          onPressed: () async => RSSNetwork.updateFeed(
                              watch(rssDatabase),
                              feed) //debugPrint('update: ${await watch(rssDatabase).updateFeed(null, null, null, null, null, null, DateTime.now().millisecondsSinceEpoch, null, feed.id)}'),
                          ),
                      value: 'Refresh'),
                  new PopupMenuItem<String>(
                      child: IconButton(
                          icon: Icon(Icons.color_lens), onPressed: null),
                      value: 'Color'),
                  new PopupMenuItem<String>(
                      child:
                          IconButton(icon: Icon(Icons.delete), onPressed: null),
                      value: 'Delete'),
                ]),
        /*IconButton(
                  icon: Icon(Icons.refresh),
                  padding: EdgeInsets.only(top: 1),
                  alignment: Alignment.topCenter,
                  onPressed: () async => RSSNetwork.updateFeed(
                      watch(rssDatabase),
                      feed) //debugPrint('update: ${await watch(rssDatabase).updateFeed(null, null, null, null, null, null, DateTime.now().millisecondsSinceEpoch, null, feed.id)}'),
                  ),*/
        dense: true,
        title: Text(feed.title),
        subtitle: Text(
            '${DateTime.fromMillisecondsSinceEpoch(feed.lastBuildDate ?? 0)}\n${feed.language}-${feed.link}'),
        isThreeLine: true,
      );

  @override
  Widget build(BuildContext context, ScopedReader watch) {
    final feedRef = watch(selectedFeedProvider(feedId));
    return feedRef.when(
        data: (feed) => _tileItem(watch, feed),
        loading: () => ListTile(
            leading: const CircularProgressIndicator(),
            title: const Text('Laster inn...')),
        error: (error, _) => ListTile(title: Text('Feil: $error')));
  }
}
