import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rss_feed_reader/database/database.dart';
import 'package:rss_feed_reader/providers/network.dart';
import 'package:rss_feed_reader/utils/misc_functions.dart';
import 'package:rss_feed_reader/screens/widgets/feed_widget.dart';

final selectedFeedProvider = StreamProvider.autoDispose.family<FeedData, int>((ref, _id) {
  final db = ref.watch(rssDatabase);
  return (db.select(db.feed)..where((tbl) => tbl.id.equals(_id))).watchSingle();
});

const MENU_ITEMS = const [
  {'text': 'Oppdater RSS', 'icon': Icons.refresh, 'value': 'update'},
  {'text': 'Slett RSS', 'icon': Icons.delete, 'value': 'delete'}
];

class FeedListItem extends ConsumerWidget {
  final int feedId;
  const FeedListItem({required this.feedId});

  @override
  Widget build(BuildContext context, ScopedReader watch) {
    final feedRef = watch(selectedFeedProvider(feedId));
    return feedRef.when(
        data: (feed) {
          final selected = watch(selectedFeedId);
          final isSelected = selected.state == feed.id;
          ValueNotifier<bool> isLoading = ValueNotifier(false);
          return Card(
              elevation: isSelected ? 0 : 6,
              margin: EdgeInsets.all(0),
              child: Container(
                color: isSelected ? Colors.blue[800] : null,
                constraints: BoxConstraints.expand(height: 60),
                child: Stack(children: [
                  Positioned(
                    right: 0,
                    child: ValueListenableBuilder(
                      valueListenable: isLoading,
                      builder: (context, bool loading, child) => loading
                          ? CircularProgressIndicator()
                          : PopupMenuButton(
                              itemBuilder: (_) => MENU_ITEMS
                                  .map((e) => PopupMenuItem(
                                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                        Text(e['text'] as String),
                                        Icon(e['icon'] as IconData),
                                      ]),
                                      value: e['value'] as String))
                                  .toList(),
                              onSelected: (val) {
                                switch (val) {
                                  case 'update':
                                    () async {
                                      isLoading.value = true;
                                      await RSSNetwork.updateFeed(watch(rssDatabase), feed);
                                      isLoading.value = false;
                                    }();
                                    break;
                                  case 'delete':
                                    context.read(rssDatabase).updateFeed(feed.title, feed.url, feed.description, feed.link, feed.language, feed.category, feed.ttl, feed.lastBuildDate, feed.pubDate, -1, feed.id);
                                    break;
                                }
                              },
                            ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    child: GestureDetector(
                      onTap: () => selected.state = selected.state == feed.id ? null : feed.id,
                      child: Container(
                        padding: EdgeInsets.all(5),
                        decoration: BoxDecoration(color: Theme.of(context).appBarTheme.backgroundColor, border: Border.all(color: Colors.deepPurple, width: 2), borderRadius: BorderRadius.circular(5)),
                        child: Center(
                            child: Text(
                          feed.title,
                          style: Theme.of(context).textTheme.button,
                        )),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 30,
                    bottom: 0,
                    child: Container(
                      decoration: BoxDecoration(border: Border.all(color: Colors.lightBlue), borderRadius: BorderRadius.circular(5)),
                      child: Text(dateTimeFormat(DateTime.fromMillisecondsSinceEpoch(feed.lastBuildDate ?? 0))),
                    ),
                  ),
                ]),
              ));
        },
        loading: () => ListTile(leading: const CircularProgressIndicator(), title: const Text('Laster inn...')),
        error: (error, _) => ListTile(title: Text('Feil: $error')));
  }
}
