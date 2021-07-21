import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:news_common/tweet_encode.dart';
import 'package:rss_feed_reader/providers/tweet_list.dart';

class TwitterUserWidget extends ConsumerWidget {
  const TwitterUserWidget({Key? key}) : super(key: key);
  void _deleteTweetUser(BuildContext context, int index, TweetListHeader tweetHead) {
    debugPrint('_deleteTweetUser($index)');
    final _removeItem = _createListItem(context, tweetHead, index);
    tweetHead.tweetUserKey.currentState?.removeItem(index, (context, animation) => SizeTransition(sizeFactor: animation, child: _removeItem));
    (tweetHead.db.delete(tweetHead.db.tweetUser)..where((tbl) => tbl.id.equals(tweetHead.tweetUsers[index].id))).go();
    tweetHead.tweetUsers.removeAt(index);
  }

  static Widget tweetUserContainer(BuildContext context, TweetUserEncode tweetUser, {Function()? onRefresh, Function()? onDelete}) => Container(
      margin: const EdgeInsets.symmetric(vertical: 1),
      padding: const EdgeInsets.only(left: 2),
      decoration: BoxDecoration(
        border: Border.all(width: 2),
        borderRadius: BorderRadius.circular(5),
        color: const Color(0xE0311B92),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(color: const Color(0x8F5E35B1), child: Center(child: Text('${tweetUser.name}(${tweetUser.username})', style: Theme.of(context).textTheme.subtitle2))),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            if (onRefresh != null) IconButton(onPressed: onRefresh, icon: const Icon(Icons.refresh)),
            Flexible(
                child: Text(
              tweetUser.name,
              style: Theme.of(context).textTheme.caption,
              // linkStyle: Theme.of(context).textTheme.caption!.copyWith(color: Colors.red),
              // style: Theme.of(context).textTheme.caption!.copyWith(color: Colors.black),
            )),
            Text('${tweetUser.sinceId}'),
            ClipOval(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.green[900],
                ),
                child: CachedNetworkImage(imageUrl: tweetUser.profileImageUrl, height: 50, fit: BoxFit.scaleDown),
              ),
            ),
            if (onDelete != null) IconButton(onPressed: onDelete, icon: const Icon(Icons.delete)),
          ]),
        ],
      ));

  @override
  Widget build(BuildContext context, ScopedReader watch) {
    final tweetHead = watch(providerTweetHeader);
    debugPrint('twitterUserWidget(${tweetHead.tweetUsers.length})');
    return AnimatedList(
      initialItemCount: tweetHead.tweetUsers.length,
      itemBuilder: (BuildContext context, int index, animation) {
        return SizeTransition(sizeFactor: animation, child: _createListItem(context, tweetHead, index));
      },
      key: tweetHead.tweetUserKey,
    );
  }

  Widget _createListItem(BuildContext context, TweetListHeader tweetHead, int index) => tweetUserContainer(context, tweetHead.tweetUsers[index], onRefresh: () => tweetHead.refreshTweetsFromUser(tweetHead.tweetUsers[index]), onDelete: () => _deleteTweetUser(context, index, tweetHead));
}
