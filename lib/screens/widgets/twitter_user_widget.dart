import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rss_feed_reader/models/tweet_encoding.dart';
import 'package:rss_feed_reader/providers/tweet_list.dart';

class TwitterUserWidget extends ConsumerWidget {
  TwitterUserWidget({Key? key}) : super(key: key);
  static Widget tweetUserContainer(BuildContext context, TweetUserEncode tweetUser, {Function()? onRefresh}) => Container(
      margin: EdgeInsets.symmetric(vertical: 1),
      padding: EdgeInsets.only(left: 2),
      decoration: BoxDecoration(
        border: Border.all(width: 2),
        borderRadius: BorderRadius.circular(5),
        color: Color(0xE0311B92),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(color: Color(0x8F5E35B1), child: Center(child: Text('${tweetUser.name}(${tweetUser.username})', style: Theme.of(context).textTheme.subtitle2))),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            if (onRefresh != null) IconButton(onPressed: onRefresh, icon: Icon(Icons.refresh)),
            Flexible(
                child: Text(
              '${tweetUser.name}',
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
                child: CachedNetworkImage(imageUrl: tweetUser.profile_image_url, height: 50, fit: BoxFit.scaleDown),
              ),
            ),
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
        return SizeTransition(sizeFactor: animation, child: tweetUserContainer(context, tweetHead.tweetUsers[index], onRefresh: () => tweetHead.refreshTweetsFromUser(tweetHead.tweetUsers[index])));
      },
      key: tweetHead.tweetUserKey,
    );
  }
}
