import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rss_feed_reader/database/database.dart';
import 'package:rss_feed_reader/providers/network.dart';
import 'package:rss_feed_reader/utils/misc_functions.dart';

final selectedFeedProvider =
    StreamProvider.autoDispose.family<FeedData, int>((ref, _id) {
  final db = ref.watch(rssDatabase);
  return (db.select(db.feed)..where((tbl) => tbl.id.equals(_id))).watchSingle();
});

class FeedListItem extends ConsumerWidget {
  final int feedId;
  const FeedListItem({required this.feedId});
  Widget _tileItem(BuildContext context, ScopedReader watch, FeedData feed) =>
      Container(
        constraints: BoxConstraints.expand(height: 60),
        child: Stack(children: [
          Positioned(
            right: 0,
            child: PopupMenuButton(
                itemBuilder: (_) => <PopupMenuItem<String>>[
                      new PopupMenuItem<String>(
                          child: IconButton(
                              icon: Icon(Icons.refresh),
                              onPressed: () async {
                                RSSNetwork.updateFeed(watch(rssDatabase), feed);
                                Navigator.pop(context, "Refresh");
                              } //debugPrint('update: ${await watch(rssDatabase).updateFeed(null, null, null, null, null, null, DateTime.now().millisecondsSinceEpoch, null, feed.id)}'),
                              ),
                          value: 'Refresh'),
                      new PopupMenuItem<String>(
                          child: IconButton(
                              icon: Icon(Icons.color_lens), onPressed: null),
                          value: 'Color'),
                      new PopupMenuItem<String>(
                          child: IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () {
                                context.read(rssDatabase).updateFeed(
                                    feed.title,
                                    feed.url,
                                    feed.description,
                                    feed.link,
                                    feed.language,
                                    feed.category,
                                    feed.ttl,
                                    feed.lastBuildDate,
                                    feed.pubDate,
                                    -1,
                                    feed.id);
                                Navigator.pop(context, "Delete");
                              }),
                          value: 'Delete'),
                    ]),
          ),
          Positioned(
            left: 30,
            top: 0,
            child: Container(
              padding: EdgeInsets.all(5),
              decoration: BoxDecoration(
                  color: Theme.of(context).appBarTheme.backgroundColor,
                  border: Border.all(color: Colors.deepPurple, width: 2),
                  borderRadius: BorderRadius.circular(5)),
              child: Center(
                  child: Text(
                feed.title,
                style: Theme.of(context).textTheme.button,
              )),
            ),
          ),
          Positioned(
            left: 30,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.lightBlue),
                  borderRadius: BorderRadius.circular(5)),
              child: Text(dateTimeFormat(DateTime.fromMillisecondsSinceEpoch(
                  feed.lastBuildDate ?? 0))),
            ),
          ),
        ]),
      );

  @override
  Widget build(BuildContext context, ScopedReader watch) {
    final feedRef = watch(selectedFeedProvider(feedId));
    return feedRef.when(
        data: (feed) => Card(
            margin: EdgeInsets.all(0), child: _tileItem(context, watch, feed)),
        loading: () => ListTile(
            leading: const CircularProgressIndicator(),
            title: const Text('Laster inn...')),
        error: (error, _) => ListTile(title: Text('Feil: $error')));
  }
}
