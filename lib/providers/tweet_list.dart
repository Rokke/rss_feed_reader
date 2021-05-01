import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:moor/moor.dart';
import 'package:collection/collection.dart';
import 'package:rss_feed_reader/database/database.dart';
import 'package:rss_feed_reader/models/tweet_encoding.dart';
import 'package:rss_feed_reader/providers/network.dart';
import 'package:rss_feed_reader/screens/widgets/twitter_widget.dart';

final providerTweetHeader = Provider<TweetListHeader>((ref) {
  return TweetListHeader(ref.watch(rssDatabase));
});
const int TWITTER_CHECKINTERVAL = 600000;

class TweetListHeader {
  static final _log = Logger('TweetListHeader');
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

  Future<bool> checkAndUpdateTweet({bool isAuto = false}) async {
    final tweetUser = tweetUsers.fold(
        null,
        (TweetUserEncode? previousValue, element) => previousValue == null
            ? element
            : element.id != null && element.lastCheck < previousValue.lastCheck
                ? element
                : previousValue);
    if (tweetUser?.id != null) {
      if (tweetUser!.lastCheck + TWITTER_CHECKINTERVAL < DateTime.now().millisecondsSinceEpoch) {
        await refreshTweetsFromUser(tweetUser, isAuto: isAuto);
        return true;
      } else
        _log.fine('No need to update twitter: $tweetUser');
    } else
      _log.warning('checkAndUpdateTweet()-illegal tweet: $tweetUser');
    return false;
  }

  Future<void> refreshTweetsFromUser(TweetUserEncode tweetUser, {bool isAuto = false}) async {
    final allTweetsFromUser = await RSSNetwork.fetchUserTweets(tweetUser);
    // read(unreadArticles).state.changeValue(addedFeeds);
    if (allTweetsFromUser != null) await updateTweetsFromUser(allTweetsFromUser);
    tweetUser.lastCheck = DateTime.now().millisecondsSinceEpoch + (!isAuto || !tweetUser.isFirstTime ? 0 : (TWITTER_CHECKINTERVAL / 2 - Random().nextInt(TWITTER_CHECKINTERVAL)).toInt()); // Sprer tweetsjekkene utover
  }

  void addNewUser(TweetUserEncode newUser) async {
    if (!tweetUsers.any((element) => element.id == newUser.id)) {
      _addNewSortedUser(newUser);
      newUser.id = await db.insertTweetUser(newUser.toTweetUserCompanionInsert());
    } else
      debugPrint('addNewUser($newUser)-exist');
  }

  // Future<void> readTweet(int tweetId, int index) async {
  //   final newTweet = await RSSNetwork.fetchTweet(tweetId);
  //   if (newTweet?.parentUser != null) {
  //     final foundUserInList = fetchUserInfo(newTweet!.parentUser.tweetUserId);
  //     if (foundUserInList != null) newTweet.parentUser = foundUserInList;
  //     _insertNewTweet(newTweet, index: index);
  //   }
  // }

  Future<void> updateTweetsFromUser(TweetFullDecode tweetFullDecode) async {
    int newItems = 0;
    for (int i = 0; i < tweetFullDecode.tweets.length; i++) {
      if (!readIds.contains(tweetFullDecode.tweets[i].id)) {
        if (!tweets.any((element) => tweetFullDecode.tweets[i].id == element.id)) {
          try {
            if (newItems++ == 0 && Platform.isWindows) Process.runSync('pwsh', ['-c', 'Invoke-Command', '-ScriptBlock', '{[System.Console]::Beep(2000,100); [System.Console]::Beep(3000,100)}']);
          } catch (err) {
            _log.warning('updateTweetsFromUser()-error playing sound: $err');
          }
          _log.info('updateTweetsFromUser(${tweetFullDecode.tweets[i]})-new');
          // tweets.insert(0, newTweetsReceived[i]);
          _insertNewTweet(tweetFullDecode.tweets[i]);
          // _listTweetKey.currentState!.insertItem(tweets.length - 1, duration: Duration(milliseconds: 500));
          await Future.delayed(Duration(milliseconds: 200));
        } else
          _log.fine('updateTweetsFromUser(${tweetFullDecode.tweets[i]})-in list');
      } else
        _log.fine('updateTweetsFromUser(${tweetFullDecode.tweets[i]})-ignored');
    }
  }

  _insertNewTweet(TweetEncode newTweet, {int index = -1}) {
    if (index < 0)
      tweets.add(newTweet);
    else
      tweets.insert(index, newTweet);
    _listTweetKey.currentState!.insertItem((index < 0 ? tweets.length - 1 : index), duration: Duration(milliseconds: 500));
  }

  void removeTweet(int twitterId) async {
    final index = tweets.indexWhere((element) => element.id == twitterId);
    if (index >= 0) {
      if (tweets[index].parentUser.id != null) {
        db.insertTweet(TweetCompanion.insert(tweetId: Value(twitterId), parent: tweets[index].parentUser.tweetUserId));
        readIds.add(twitterId);
      }
      // final twitterUser = fetchUserInfo(tweets[index].tweetUserId);
      final cachedItem = tweets[index];
      _listTweetKey.currentState!.removeItem(index, (context, animation) => SizeTransition(sizeFactor: animation, child: TwitterWidget.tweetContainer(context, cachedItem)), duration: Duration(milliseconds: 500));
      tweets.removeAt(index);
    } else
      _log.warning('removeTweet($twitterId)-Invalid id');
  }

  TweetUserEncode? fetchUserInfo(int tweetUserId) => tweetUsers.firstWhereOrNull((element) => element.tweetUserId == tweetUserId);

  GlobalKey<AnimatedListState> get tweetKey => _listTweetKey;
  GlobalKey<AnimatedListState> get tweetUserKey => _listTweetUserKey;
}
