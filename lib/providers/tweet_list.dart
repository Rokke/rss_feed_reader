import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moor/moor.dart';
import 'package:rss_feed_reader/database/database.dart';
import 'package:rss_feed_reader/models/tweet_encoding.dart';
import 'package:rss_feed_reader/providers/network.dart';
import 'package:rss_feed_reader/screens/widgets/twitter_widget.dart';

final providerTweetHeader = Provider<TweetListHeader>((ref) {
  return TweetListHeader(ref.watch(rssDatabase));
});
const int TWITTER_CHECKINTERVAL = 600000;

class TweetListHeader {
  final _listTweetKey = GlobalKey<AnimatedListState>(), _listTweetUserKey = GlobalKey<AnimatedListState>();
  final AppDb db;
  final List<int> readIds = [];
  final List<TweetEncode> tweets = [];
  final List<TweetUserEncode> tweetUsers = [];
  bool isInitialized = false;

  TweetListHeader(this.db) {
    _init();
  }
  _init() async {
    isInitialized = false;
    readIds.addAll((await (db.select(db.tweet)..orderBy([(tbl) => OrderingTerm.asc(tbl.tweetId)])).get()).map((e) => e.tweetId));
    tweetUsers.addAll((await (db.select(db.tweetUser)..orderBy([(tbl) => OrderingTerm.asc(tbl.username)])).get()).map((e) => TweetUserEncode.fromDB(e)));
    isInitialized = true;
  }

  // void _newTweetUserListReceived(List<TweetUserData> newTweetUserList) {
  //   debugPrint('_newTweetUserListReceived($newTweetUserList)');
  //   if (tweetUsers.length == 0)
  //     tweetUsers.addAll(newTweetUserList);
  //   else {
  //     final List<int> idsThatWasNotFound = tweetUsers.map((e) => e.id!).toList();
  //     newTweetUserList.forEach((newUser) {
  //       final foundExistingUserIndex = tweetUsers.indexWhere((existingUser) => existingUser.tweetUserId == newUser.tweetUserId);
  //       if (foundExistingUserIndex >= 0) {
  //         idsThatWasNotFound.remove(tweetUsers[foundExistingUserIndex]);
  //       } else
  //         _addNewSortedUser(newUser);
  //     });
  //     idsThatWasNotFound.forEach((id) {
  //       final foundIndex = tweetUsers.indexWhere((element) => element.id! == id);
  //       if (foundIndex >= 0) {
  //         _listTweetUserKey.currentState?.removeItem(foundIndex, (context, animation) => TwitterUserWidget.tweetUserContainer(context, tweetUsers[foundIndex]));
  //         tweetUsers.removeAt(foundIndex);
  //       }
  //     });
  //   }
  // }

  int _addNewSortedUser(TweetUserEncode newUser) {
    final sortIndex = tweetUsers.indexWhere((existingUser) => existingUser.username.compareTo(newUser.username) > 0);
    if (sortIndex >= 0) {
      tweetUsers.insert(sortIndex, newUser);
      _listTweetUserKey.currentState?.insertItem(sortIndex - 1);
      return sortIndex;
    } else {
      tweetUsers.add(newUser);
      _listTweetUserKey.currentState?.insertItem(tweetUsers.length - 1);
    }
    return tweetUsers.length - 1;
  }

  Future<bool> checkAndUpdateTweet() async {
    final tweetUser = tweetUsers.fold(
        null,
        (TweetUserEncode? previousValue, element) => previousValue == null
            ? element
            : element.lastCheck < previousValue.lastCheck
                ? element
                : previousValue);
    if (tweetUser?.id != null) {
      if (tweetUser!.lastCheck + TWITTER_CHECKINTERVAL < DateTime.now().millisecondsSinceEpoch) {
        final allTweetsFromUser = await RSSNetwork.fetchUserTweets(db, tweetUser);
        // read(unreadArticles).state.changeValue(addedFeeds);
        updateTweetsFromUser(allTweetsFromUser);
        tweetUser.lastCheck = DateTime.now().millisecondsSinceEpoch;
        return true;
      } else
        debugPrint('No need to update twitter: $tweetUser');
    } else
      debugPrint('illegal tweet: $tweetUser');
    return false;
  }

  void addNewUser(TweetUserEncode newUser) async {
    if (!tweetUsers.any((element) => element.id == newUser.id)) {
      _addNewSortedUser(newUser);
      newUser.id = await db.insertTweetUser(newUser.toTweetUserCompanionInsert());
    } else
      debugPrint('addNewUser($newUser)-exist');
  }

  void updateTweetsFromUser(List<TweetEncode> newTweetsReceived) async {
    for (int i = 0; i < newTweetsReceived.length; i++) {
      if (!readIds.contains(newTweetsReceived[i].id) && !newTweetsReceived[i].isReply) {
        if (!tweets.any((element) => newTweetsReceived[i].id == element.id)) {
          debugPrint('addNewTweet(${newTweetsReceived[i]})-new');
          // tweets.insert(0, newTweetsReceived[i]);
          tweets.add(newTweetsReceived[i]);
          _listTweetKey.currentState!.insertItem(tweets.length - 1, duration: Duration(milliseconds: 500));
          await Future.delayed(Duration(milliseconds: 200));
        } else
          debugPrint('addNewTweet(${newTweetsReceived[i]})-in list');
      } else
        debugPrint('addNewTweet(${newTweetsReceived[i]})-ignored');
    }
  }

  void removeTweet(int twitterId) async {
    final index = tweets.indexWhere((element) => element.id == twitterId);
    if (index >= 0) {
      db.insertTweet(TweetCompanion.insert(tweetId: Value(twitterId), parent: tweets[index].tweetUserId));
      readIds.add(twitterId);
      final twitterUser = fetchUserInfo(tweets[index].tweetUserId);
      final cachedItem = tweets[index];
      _listTweetKey.currentState!.removeItem(index, (context, animation) => SizeTransition(sizeFactor: animation, child: TwitterWidget.tweetContainer(context, cachedItem, twitterUser)), duration: Duration(milliseconds: 500));
      tweets.removeAt(index);
    } else
      debugPrint('Invalid id: $twitterId');
  }

  TweetUserEncode fetchUserInfo(int tweetUserId) => tweetUsers.firstWhere((element) => element.tweetUserId == tweetUserId);

  GlobalKey<AnimatedListState> get tweetKey => _listTweetKey;
  GlobalKey<AnimatedListState> get tweetUserKey => _listTweetUserKey;
}
