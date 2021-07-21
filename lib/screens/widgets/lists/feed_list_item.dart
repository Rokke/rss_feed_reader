import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rss_feed_reader/models/feed_encode.dart';
import 'package:rss_feed_reader/providers/feed_list.dart';
import 'package:rss_feed_reader/screens/widgets/popups/update_feed.dart';
import 'package:rss_feed_reader/utils/misc_functions.dart';
import 'package:rss_feed_reader/utils/popup_card.dart';

// final selectedFeedProvider = StreamProvider.autoDispose.family<FeedData, int>((ref, _id) {
//   final db = ref.watch(rssDatabase);
//   return (db.select(db.feed)..where((tbl) => tbl.id.equals(_id))).watchSingle();
// });
// final numberOfFeedsProvider = StreamProviderFamily<int, int>((ref, id) {
//   final db = ref.watch(rssDatabase);
//   return db.numberOfArticlesStatus(id, ref.watch(filterShowArticleStatus).state).watchSingle();
// });

const MENU_ITEMS = [
  {'text': 'Oppdater RSS', 'icon': Icons.refresh, 'value': 'update'},
  {'text': 'Endre RSS', 'icon': Icons.edit, 'value': 'edit'},
  {'text': 'Merk alle lest', 'icon': Icons.visibility, 'value': 'read'},
  {'text': 'Slett RSS', 'icon': Icons.delete, 'value': 'delete'},
];

class FeedListItem extends StatelessWidget {
  // static final _log = Logger('FeedListItem');
  final FeedEncode feed;
  final bool isSelected;
  const FeedListItem({required this.feed, this.isSelected = false});

  static Widget feedContainer(BuildContext context, FeedEncode feed, {bool isSelected = false}) {
    final isLoading = ValueNotifier(false);
    final feedProvider = context.read(providerFeedHeader);
    return Card(
        elevation: isSelected ? 0 : 6,
        margin: const EdgeInsets.all(0),
        child: ValueListenableBuilder(
          valueListenable: isLoading,
          builder: (context, bool loading, child) => Container(
            color: isSelected ? Colors.blue[800] : null,
            constraints: const BoxConstraints.expand(height: 55),
            child: Stack(children: [
              Positioned(
                right: 0,
                child: loading
                    ? const CircularProgressIndicator()
                    : PopupMenuButton(
                        itemBuilder: (_) => MENU_ITEMS
                            .map((e) => PopupMenuItem(
                                value: e['value'],
                                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                  Text(e['text'].toString()),
                                  Icon(e['icon'] as IconData?),
                                ])))
                            .toList(),
                        onSelected: (val) {
                          switch (val) {
                            case 'edit':
                              Navigator.of(context).push(HeroDialogRoute(builder: (context) {
                                return UpdateFeedPopup(feed);
                              })).then((value) {
                                if (value == true) {
                                  isLoading.value = true;
                                  isLoading.value = false;
                                }
                              });
                              break;
                            case 'update':
                              isLoading.value = true;
                              () async {
                                await feedProvider.updateOrCreateFeed(feed);
                                isLoading.value = false;
                              }();
                              break;
                            case 'delete':
                              feedProvider.removeFeed(feed.id!);
                              break;
                            case 'read':
                              feedProvider.markAllRead(feed.id!);
                              break;
                          }
                        },
                      ),
              ),
              Positioned(
                left: 50,
                top: 0,
                child: Row(
                  children: [
                    Container(
                        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                        decoration: BoxDecoration(color: Theme.of(context).appBarTheme.backgroundColor, border: Border.all(color: Colors.deepPurple, width: 2), borderRadius: BorderRadius.circular(15)),
                        child: Text(feed.id.toString(), style: Theme.of(context).textTheme.button)),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                      decoration: BoxDecoration(color: Theme.of(context).appBarTheme.backgroundColor, border: Border.all(color: Colors.deepPurple, width: 2), borderRadius: BorderRadius.circular(5)),
                      child: Center(
                          child: Text(
                        feed.title,
                        style: Theme.of(context).textTheme.button,
                      )),
                    ),
                    Container(
                        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                        decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondary, border: Border.all(color: Colors.purple, width: 2), borderRadius: BorderRadius.circular(15)),
                        child: ValueListenableBuilder(valueListenable: feedProvider.numberOfArticleNotifier, builder: (context, int amount, _) => Text(amount.toString(), style: TextStyle(color: Theme.of(context).primaryColor)))),
                  ],
                ),
              ),
              if (feed.link != null)
                Positioned(
                  top: 12,
                  left: 1,
                  child: /* GestureDetector(
                  onTap: () => selected.state = isSelected ? null : feed.id,
                  child: */
                      feed.feedFav != null
                          ? CachedNetworkImage(
                              imageUrl: feed.feedFav!,
                              fit: BoxFit.scaleDown,
                              height: 30,
                              width: 50,
                              errorWidget: (_, __, ___) => Container(),
                            )
                          : const Icon(Icons.rss_feed),
                  // ),
                ),
              if ((feed.lastBuildDate) > 0)
                Positioned(
                  left: 60,
                  bottom: 0,
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(border: Border.all(color: Colors.lightBlue), borderRadius: BorderRadius.circular(5)),
                        child: Text(dateTimeFormat(DateTime.fromMillisecondsSinceEpoch(feed.lastBuildDate))),
                      ),
                      if (feed.lastError != null) Container(color: Colors.red, child: Text(feed.lastError!, style: const TextStyle(fontSize: 8))),
                    ],
                  ),
                ),
              Positioned(
                right: 3,
                bottom: 0,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(border: Border.all(color: Colors.lightBlue), borderRadius: BorderRadius.circular(5)),
                      child: Text(timeSinceNow(feed.lastCheck)),
                    ),
                    Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(color: Theme.of(context).appBarTheme.backgroundColor, border: Border.all(color: Colors.deepPurple, width: 2), borderRadius: BorderRadius.circular(5)),
                        child: Text(feed.ttl.toString(), style: Theme.of(context).textTheme.button)),
                  ],
                ),
              ),
            ]),
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    // final feedRef = watch(selectedFeedProvider(feedId));
    // final selected = watch(selectedFeedId);
    // final isSelected = selected.state == feed.id;
    // final numberOfUnreadArticles = watch(numberOfFeedsProvider(feedId));
    return feedContainer(context, feed, isSelected: isSelected);
  }
}
