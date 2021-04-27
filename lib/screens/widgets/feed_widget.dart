import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rss_feed_reader/database/database.dart';
import 'package:rss_feed_reader/models/rss_tree.dart';
import 'package:rss_feed_reader/providers/tweet_list.dart';
import 'package:rss_feed_reader/screens/widgets/lists/feed_list_item.dart';
import 'package:rss_feed_reader/screens/widgets/popups/add_feed.dart';
import 'package:rss_feed_reader/screens/widgets/twitter_user_widget.dart';
import 'package:rss_feed_reader/utils/popup_card.dart';

final feedProvider = FutureProvider<List<FeedData>>((ref) {
  final db = ref.watch(rssDatabase);
  return db.feeds().first;
});
final selectedFeedId = StateProvider<int?>((ref) => null);
final filterShowArticleStatus = StateProvider<int>((ref) => 0);
final filterShowTitleText = StateProvider<String>((ref) => '');
final selectedFeedStatusArticlesCount = StreamProvider<int>((ref) {
  final db = ref.watch(rssDatabase);
  final filter = ref.watch(filterShowArticleStatus);
  return db.numberOfArticlesStatus(ref.watch(selectedFeedId).state, filter.state).watchSingle();
});

class FeedView extends ConsumerWidget {
  const FeedView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, ScopedReader watch) {
    final feedRef = watch(feedProvider);
    debugPrint('dato: ${DateTime.tryParse("2021-04-06T15:50:23+0100")}');
    return Container(
      color: Theme.of(context).appBarTheme.backgroundColor,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Container(
          constraints: BoxConstraints(maxHeight: 120),
          child: DrawerHeader(
            child: Container(
              padding: EdgeInsets.all(4),
              child: Stack(
                children: [
                  Container(constraints: BoxConstraints.expand(height: 30), child: Text('RSS Feeder', style: Theme.of(context).textTheme.headline6)),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Hero(
                      tag: AddFeedPopup.HERO_TAG,
                      child: Material(
                          child: SingleChildScrollView(
                        child: Container(
                          child: ElevatedButton.icon(
                              onPressed: () async {
                                final ret = await Navigator.of(context).push(HeroDialogRoute(builder: (context) {
                                  return AddFeedPopup();
                                }));
                                if (ret is String && ret.length > 1)
                                  Navigator.of(context).pop();
                                else
                                  debugPrint('Ugyldig valg');
                              },
                              icon: Icon(Icons.add_circle),
                              label: Text('Ny RSS/Twitter')),
                        ),
                      )),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    child: Container(
                      child: ElevatedButton.icon(
                          onPressed: () {
                            context.read(rssProvider).findFeedToUpdate();
                            Navigator.pop(context);
                          },
                          icon: Icon(Icons.add_circle),
                          label: Text('Oppdater RSS')),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      ElevatedButton.icon(
                          onPressed: () {
                            () async {
                              final amountImported = context.read(rssDatabase).importJSON('D://downloads//extract.json');
                              ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
                                content: Text('Importerte $amountImported RSS feeds'),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                              ));
                            }();
                            Navigator.pop(context);
                          },
                          icon: Icon(Icons.import_contacts),
                          label: Text('Import RSS')),
                      SizedBox(width: 4),
                      ElevatedButton.icon(
                          onPressed: () {
                            context.read(rssDatabase).extractJSON('D://downloads//extract.json');
                            Navigator.pop(context);
                          },
                          icon: Icon(Icons.upload_file),
                          label: Text('Extract RSS')),
                    ]),
                  ),
                ],
              ),
            ),
          ),
        ),
        Flexible(
            child: feedRef.when(
                data: (feeds) {
                  debugPrint('feedRef rebuild');
                  return DrawerListItems(feeds);
                },
                loading: () => CircularProgressIndicator(),
                error: (error, _) => Container(child: Text('error: $error')))),
      ]),
    );
  }
}

class DrawerListItems extends ConsumerWidget {
  final List<FeedData> feeds;
  DrawerListItems(this.feeds, {Key? key}) : super(key: key);
  final ValueNotifier<bool> feedSelected = ValueNotifier(true);

  @override
  Widget build(BuildContext context, ScopedReader watch) {
    final twitterRef = watch(providerTweetHeader);
    return ValueListenableBuilder(
      valueListenable: feedSelected,
      builder: (context, bool isFeed, child) => Column(
        children: [
          if (twitterRef.tweetUsers.length > 0)
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              ElevatedButton.icon(
                onPressed: !feedSelected.value ? () => feedSelected.value = true : null,
                icon: Icon(Icons.rss_feed, color: Colors.red),
                label: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('RSS (${feeds.length})'),
                ),
              ),
              ElevatedButton.icon(
                  onPressed: feedSelected.value ? () => feedSelected.value = false : null,
                  icon: Image(
                    image: AssetImage('assets/images/twitter.png'),
                    color: Colors.blue,
                  ),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text('Twitter (${twitterRef.tweetUsers.length})'),
                  )),
            ]),
          Flexible(
            child: isFeed
                ? ListView.builder(
                    itemCount: feeds.length,
                    itemBuilder: (BuildContext context, int index) {
                      return Container(margin: EdgeInsets.symmetric(horizontal: 10, vertical: 3), child: FeedListItem(feedId: feeds[index].id!));
                    },
                  )
                : TwitterUserWidget(),
          ),
        ],
      ),
    );
  }
}
