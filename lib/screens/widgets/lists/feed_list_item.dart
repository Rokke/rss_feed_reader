import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:rss_feed_reader/database/database.dart';
import 'package:rss_feed_reader/providers/network.dart';
import 'package:rss_feed_reader/screens/widgets/lists/article_list_item.dart';
import 'package:rss_feed_reader/screens/widgets/popups/update_feed.dart';
import 'package:rss_feed_reader/utils/misc_functions.dart';
import 'package:rss_feed_reader/screens/widgets/feed_widget.dart';
import 'package:rss_feed_reader/utils/popup_card.dart';

final selectedFeedProvider = StreamProvider.autoDispose.family<FeedData, int>((ref, _id) {
  final db = ref.watch(rssDatabase);
  return (db.select(db.feed)..where((tbl) => tbl.id.equals(_id))).watchSingle();
});
final numberOfFeedsProvider = StreamProviderFamily<int, int>((ref, id) {
  final db = ref.watch(rssDatabase);
  return db.numberOfArticlesStatus(id, ref.watch(filterShowArticleStatus).state).watchSingle();
});

const MENU_ITEMS = const [
  {'text': 'Oppdater RSS', 'icon': Icons.refresh, 'value': 'update'},
  {'text': 'Endre RSS', 'icon': Icons.edit, 'value': 'edit'},
  {'text': 'Merk alle lest', 'icon': Icons.visibility, 'value': 'read'},
  {'text': 'Slett RSS', 'icon': Icons.delete, 'value': 'delete'},
];

class FeedListItem extends ConsumerWidget {
  static final _log = Logger('FeedListItem');
  final int feedId;
  const FeedListItem({required this.feedId});

  @override
  Widget build(BuildContext context, ScopedReader watch) {
    final feedRef = watch(selectedFeedProvider(feedId));
    return feedRef.when(
        data: (feed) {
          final favImage = watch(feedFavIdProvider(feed.id!));
          final selected = watch(selectedFeedId);
          final isSelected = selected.state == feed.id;
          ValueNotifier<bool> isLoading = ValueNotifier(false);
          final numberOfUnreadArticles = watch(numberOfFeedsProvider(feedId));
          return Card(
              elevation: isSelected ? 0 : 6,
              margin: EdgeInsets.all(0),
              child: Container(
                color: isSelected ? Colors.blue[800] : null,
                constraints: BoxConstraints.expand(height: 55),
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
                                  case 'edit':
                                    () async {
                                      final feedCompanion = await Navigator.of(context).push(HeroDialogRoute(builder: (context) {
                                        return UpdateFeedPopup(feed);
                                      }));
                                      if (feedCompanion is FeedCompanion) {
                                        final result = await context.read(rssDatabase).updateFeed(feed.id!, feedCompanion);
                                        _log.fine('update feed($feedCompanion): $result'); //{await db.update(db.feed).updateFeed(ret.title, ret.url, ret.description, ret.link, ret.language, ret.category, ret.ttl, ret.lastBuildDate, ret.pubDate, ret.status, ret.lastCheck, ret.id)}');
                                      } else
                                        debugPrint('Cancelled: $feedCompanion');
                                    }();
                                    break;
                                  case 'update':
                                    () async {
                                      isLoading.value = true;
                                      await RSSNetwork.updateFeed(watch(rssDatabase), feed);
                                      isLoading.value = false;
                                    }();
                                    break;
                                  case 'delete':
                                    context.read(rssDatabase).deleteFeed(feed.id!);
                                    break;
                                  case 'read':
                                    context.read(rssDatabase).markAllRead(feedId);
                                    break;
                                }
                              },
                            ),
                    ),
                  ),
                  Positioned(
                    left: 50,
                    top: 0,
                    child: Row(
                      children: [
                        Container(
                            padding: EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                            decoration: BoxDecoration(color: Theme.of(context).appBarTheme.backgroundColor, border: Border.all(color: Colors.deepPurple, width: 2), borderRadius: BorderRadius.circular(15)),
                            child: Text(feed.id.toString(), style: Theme.of(context).textTheme.button)),
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                          decoration: BoxDecoration(color: Theme.of(context).appBarTheme.backgroundColor, border: Border.all(color: Colors.deepPurple, width: 2), borderRadius: BorderRadius.circular(5)),
                          child: Center(
                              child: Text(
                            feed.title,
                            style: Theme.of(context).textTheme.button,
                          )),
                        ),
                        Container(
                            padding: EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                            decoration: BoxDecoration(color: Theme.of(context).accentColor, border: Border.all(color: Colors.purple, width: 2), borderRadius: BorderRadius.circular(15)),
                            child: Text((numberOfUnreadArticles.when(data: (val) => val.toString(), loading: () => '?', error: (_, __) => 'E')), style: TextStyle(color: Theme.of(context).primaryColor))),
                      ],
                    ),
                  ),
                  if (feed.link != null)
                    Positioned(
                      top: 12,
                      left: 10,
                      child: GestureDetector(
                        onTap: () => selected.state = isSelected ? null : feed.id,
                        child: favImage.when(
                            data: (fav) => fav != null
                                ? CachedNetworkImage(
                                    imageUrl: fav.url,
                                    fit: BoxFit.fitWidth,
                                    alignment: Alignment.center,
                                    width: 30,
                                    errorWidget: (_, __, ___) => Container(),
                                  )
                                : Icon(Icons.visibility),
                            loading: () => Icon(Icons.cloud_download_outlined),
                            error: (error, _) {
                              return Icon(Icons.error);
                            }),
                      ),
                    ),
                  if ((feed.lastBuildDate ?? 0) > 0)
                    Positioned(
                      left: 60,
                      bottom: 0,
                      child: Container(
                        decoration: BoxDecoration(border: Border.all(color: Colors.lightBlue), borderRadius: BorderRadius.circular(5)),
                        child: Text(dateTimeFormat(DateTime.fromMillisecondsSinceEpoch(feed.lastBuildDate ?? 0))),
                      ),
                    ),
                  Positioned(
                    right: 3,
                    bottom: 0,
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(border: Border.all(color: Colors.lightBlue), borderRadius: BorderRadius.circular(5)),
                          child: Text(timeSinceNow(feed.lastCheck ?? 0)),
                        ),
                        if (feed.ttl != null)
                          Container(
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(color: Theme.of(context).appBarTheme.backgroundColor, border: Border.all(color: Colors.deepPurple, width: 2), borderRadius: BorderRadius.circular(5)),
                              child: Text(feed.ttl.toString(), style: Theme.of(context).textTheme.button)),
                      ],
                    ),
                  ),
                ]),
              ));
        },
        loading: () => ListTile(leading: const CircularProgressIndicator(), title: const Text('Laster inn...')),
        error: (error, _) => ListTile(title: Text('Feil: $error')));
  }
}
