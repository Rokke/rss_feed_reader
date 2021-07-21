import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rss_feed_reader/models/feed_encode.dart';
import 'package:rss_feed_reader/providers/feed_list.dart';
import 'package:rss_feed_reader/providers/tweet_list.dart';
import 'package:rss_feed_reader/screens/widgets/lists/feed_list_item.dart';
import 'package:rss_feed_reader/screens/widgets/twitter_user_widget.dart';

class DrawerListItems extends ConsumerWidget {
  final List<FeedEncode> feeds;
  DrawerListItems(this.feeds, {Key? key}) : super(key: key);
  final ValueNotifier<bool> feedSelected = ValueNotifier(true);

  @override
  Widget build(BuildContext context, ScopedReader watch) {
    final twitterRef = watch(providerTweetHeader);
    return ValueListenableBuilder(
      valueListenable: feedSelected,
      builder: (context, bool isFeed, child) => Column(
        children: [
          if (twitterRef.tweetUsers.isNotEmpty)
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              ElevatedButton.icon(
                onPressed: !feedSelected.value ? () => feedSelected.value = true : null,
                icon: const Icon(Icons.rss_feed, color: Colors.red),
                label: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('RSS (${feeds.length})'),
                ),
              ),
              ElevatedButton.icon(
                  onPressed: feedSelected.value ? () => feedSelected.value = false : null,
                  icon: const Image(
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
                ? AnimatedList(
                    shrinkWrap: true,
                    key: context.read(providerFeedHeader).feedKey,
                    initialItemCount: feeds.length,
                    itemBuilder: (BuildContext context, int index, animation) {
                      return SizeTransition(sizeFactor: animation, child: Container(margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3), child: FeedListItem(feed: feeds[index])));
                    },
                  )
                : const TwitterUserWidget(),
          ),
        ],
      ),
    );
  }
}
