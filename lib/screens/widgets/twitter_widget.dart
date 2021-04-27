import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rss_feed_reader/models/tweet_encoding.dart';
import 'package:rss_feed_reader/providers/tweet_list.dart';

class TwitterWidget extends ConsumerWidget {
  TwitterWidget({Key? key}) : super(key: key);
  static double TWITTER_LIST_WIDTH = 400;
  static String smartDateTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff > Duration(days: 100)) return '${dt.year}-${dt.month}-${dt.day}';
    if (diff > Duration(days: 20)) return '${dt.month}-${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, "0")}';
    if (diff > Duration(hours: 20))
      return '${dt.day} ${dt.hour.toString().padLeft(2, "0")}:${dt.minute.toString().padLeft(2, "0")}:${dt.second.toString().padLeft(2, "0")}';
    else
      return '${dt.hour}:${dt.minute}:${dt.second}';
  }

  static Widget tweetContainer(BuildContext context, TweetEncode tweet, TweetUserEncode user) => Container(
        child: Stack(
          children: [
            Positioned(
              child: Container(
                margin: EdgeInsets.only(bottom: 5, left: 25),
                decoration: BoxDecoration(
                  border: Border.all(width: 2),
                  borderRadius: BorderRadius.circular(5),
                  color: Color(0xE0311B92),
                ),
                child: Container(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                          constraints: BoxConstraints.tightFor(width: TWITTER_LIST_WIDTH - 80),
                          color: Color(0x8F5E35B1),
                          child: Row(
                            children: [
                              Flexible(child: Center(child: Text('${user.name}(${user.username})', style: Theme.of(context).textTheme.subtitle2))),
                              Text(
                                '${smartDateTime(tweet.created_at)}',
                                style: Theme.of(context).textTheme.caption,
                              ),
                            ],
                          )),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(
                          constraints: BoxConstraints.tightFor(width: TWITTER_LIST_WIDTH - 80),
                          margin: EdgeInsets.only(left: 2),
                          child: Linkify(
                            text: '${tweet.text}',
                            onOpen: (link) => print('${link.text}'),
                            style: Theme.of(context).textTheme.caption,
                          ),
                        ),
                        ClipOval(
                          child: Container(
                            height: 35,
                            width: 35,
                            decoration: BoxDecoration(
                              color: Colors.green[900],
                            ),
                            child: IconButton(
                              onPressed: () => context.read(providerTweetHeader).removeTweet(tweet.id),
                              icon: Icon(Icons.playlist_add_check),
                              color: Colors.green[100],
                              splashRadius: 20,
                              iconSize: 20,
                            ),
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
                child: ClipOval(
              child: CachedNetworkImage(
                imageUrl: user.profile_image_url,
                height: 35,
                fit: BoxFit.scaleDown,
              ),
            )),
          ],
        ),
      );
  @override
  Widget build(BuildContext context, ScopedReader watch) {
    final twitterHead = watch(providerTweetHeader);
    debugPrint('${twitterHead.tweets.length}, twitterHead.fetchUserInfo(twitterHead.tweets[index].tweetUserId)');
    return AnimatedList(
      reverse: true,
      initialItemCount: twitterHead.tweets.length,
      itemBuilder: (BuildContext context, int index, animation) {
        return SizeTransition(sizeFactor: animation, child: tweetContainer(context, twitterHead.tweets[index], twitterHead.fetchUserInfo(twitterHead.tweets[index].tweetUserId)));
      },
      key: twitterHead.tweetKey,
    );
  }
}
