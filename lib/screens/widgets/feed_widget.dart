import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rss_feed_reader/database/database.dart';
import 'package:rss_feed_reader/providers/network.dart';
import 'package:rss_feed_reader/screens/widgets/lists/feed_list_item.dart';
import 'package:rss_feed_reader/screens/widgets/popups/add_feed.dart';
import 'package:rss_feed_reader/utils/popup_card.dart';

final feedProvider = StreamProvider<List<FeedData>>((ref) {
  final db = ref.watch(rssDatabase);
  return db.feeds().watch();
});
final selectedFeedId = StateProvider<int?>((ref) => null);

class FeedView extends ConsumerWidget {
  const FeedView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, ScopedReader watch) {
    final feedRef = watch(feedProvider);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      DrawerHeader(
        child: Container(
          padding: EdgeInsets.all(4),
          color: Theme.of(context).appBarTheme.backgroundColor,
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
                            if (ret is String && ret.length > 10)
                              RSSNetwork.updateFeed(context.read(rssDatabase), FeedData(title: '', url: ret));
                            else
                              debugPrint('Ugyldig URL: $ret');
                          },
                          icon: Icon(Icons.add_circle),
                          label: Text('Ny RSS')),
                    ),
                  )),
                ),
              ),
            ],
          ),
        ),
      ),
      Flexible(
          child: feedRef.when(
              data: (feed) => Card(
                  color: Colors.deepPurple[900],
                  child: ListView.builder(
                    itemCount: feed.length,
                    itemBuilder: (BuildContext context, int index) {
                      return Container(margin: EdgeInsets.all(5), child: FeedListItem(feedId: feed[index].id!));
                    },
                  )),
              loading: () => CircularProgressIndicator(),
              error: (error, _) => Container(child: Text('error: $error')))),
    ]);
  }
}
