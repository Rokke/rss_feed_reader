import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rss_feed_reader/models/tweet_encoding.dart';
import 'package:rss_feed_reader/providers/tweet_list.dart';
import 'package:rss_feed_reader/utils/color_constants.dart';
import 'package:rss_feed_reader/utils/misc_functions.dart';

class TwitterWidget extends ConsumerWidget {
  TwitterWidget({Key? key}) : super(key: key);
  static double TWITTER_LIST_WIDTH = 400;

  static Widget tweetContainer(BuildContext context, TweetEncode tweet, {bool isRetweet = false}) => Container(
        child: Stack(
          children: [
            Positioned(
              child: Container(
                margin: EdgeInsets.only(bottom: 5, left: 25),
                decoration: BoxDecoration(
                  border: Border.all(width: 2),
                  borderRadius: BorderRadius.circular(5),
                  color: tweet.isRetweet ? ColorContants.BodyTweetRetweet : ColorContants.BodyTweet,
                ),
                child: Container(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                          constraints: BoxConstraints.tightFor(width: TWITTER_LIST_WIDTH - 80),
                          color: tweet.isRetweet ? ColorContants.TitleTweetRetweet : ColorContants.TitleTweet,
                          child: Row(
                            children: [
                              Flexible(child: Center(child: Text('${tweet.parentUser.name}(${tweet.parentUser.username})', style: Theme.of(context).textTheme.subtitle2))),
                              Padding(
                                padding: const EdgeInsets.only(right: 2),
                                child: Text(
                                  '${smartDateTime(tweet.created_at)}',
                                  style: Theme.of(context).textTheme.caption,
                                ),
                              ),
                            ],
                          )),
                      if (tweet.isRetweet) tweetContainer(context, tweet.retweet!, isRetweet: true),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(
                          constraints: BoxConstraints.tightFor(width: TWITTER_LIST_WIDTH - 80),
                          margin: EdgeInsets.only(left: 2),
                          child: Linkify(
                            text: '${tweet.text}',
                            onOpen: (link) => launchURL(link.text),
                            style: Theme.of(context).textTheme.caption,
                          ),
                        ),
                        if (!isRetweet)
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
            if (tweet.parentUser.profile_image_url.isNotEmpty)
              Positioned(
                  child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: tweet.parentUser.profile_image_url,
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
        return SizeTransition(sizeFactor: animation, child: tweetContainer(context, twitterHead.tweets[index]));
      },
      key: twitterHead.tweetKey,
    );
  }
}
