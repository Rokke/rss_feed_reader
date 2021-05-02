import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
// These imports are only needed to open the database
import 'package:moor/ffi.dart';
// import 'package:flutter/material.dart';
import 'package:moor/moor.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:rss_feed_reader/models/tweet_encoding.dart';
import 'package:rss_feed_reader/models/xml_mapper/channel_mapper.dart';
import 'package:rss_feed_reader/providers/network.dart';

part 'database.g.dart';

final rssDatabase = Provider<AppDb>((ref) {
  print('rss');
  return AppDb();
});

@UseMoor(
  // relative import for the moor file. Moor also supports `package:`
  // imports
  include: {'tables.moor'},
)
class AppDb extends _$AppDb {
  final _log = Logger('AppDb');
  AppDb() : super(_openConnection());

  @override
  int get schemaVersion => 6;
  Future<int> updateActiveStatus(int feedId, List<int> activeIds) async {
    return (update(article)..where((tbl) => tbl.active.equals(true) & tbl.parent.equals(feedId) & tbl.id.isNotIn(activeIds))).write(ArticleCompanion(active: Value(false)));
  }

  Stream<FeedFavData?> fetchFavForFeed(int feedId) {
    return (select(feedFav)..where((tbl) => tbl.feedId.equals(feedId))).watchSingleOrNull();
  }

  // updateFeedInfo(FeedCompanion feedCompanion, int feedId) {
  //   (update(feed)..where((tbl) => tbl.id.equals(feedId))).write(feedCompanion);
  // }
  Future<int> insertFeed(String url, ChannelMapper channel, int? currentEpocMs, String? favImageUrl) async {
    final newId = await into(feed).insert(channel.toFeedCompanion().copyWith(url: Value(url), lastCheck: Value(currentEpocMs)));
    if (favImageUrl != null) await into(feedFav).insert(FeedFavCompanion.insert(feedId: newId, url: favImageUrl));
    return newId;
  }

  Future<int> updateFeed(int feedId, FeedCompanion feedCompanion) => (update(feed)..where((tbl) => tbl.id.equals(feedId))).write(feedCompanion);
  Future<int> deleteFeed(int feedId) => (delete(feed)..where((tbl) => tbl.id.equals(feedId))).go();
  Future<int> markAllRead(int feedId) => (update(article)..where((tbl) => tbl.parent.equals(feedId))).write(ArticleCompanion(status: Value(ArticleTableStatus.READ)));
  Future<FeedData?> fetchFeed(int id) => (select(feed)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  Stream<List<FeedData>> feeds() => (select(feed)
        // ..where((tbl) => tbl.status.isSmallerOrEqualValue( ArticleTableStatus.READ))
        ..orderBy([(tbl) => OrderingTerm.asc(tbl.title)]))
      .watch();

  Future<int> insertArticle(ArticleCompanion articleCompanion) async => into(article).insert(articleCompanion);
  Future<int> updateArticleStatus({required int articleId, int status = ArticleTableStatus.READ}) => (update(article)..where((tbl) => tbl.id.equals(articleId))).write(ArticleCompanion(status: Value(status)));
  Stream<List<ArticleData>> articles({int? feedId, required int status}) => feedId == null
      ? ((select(article)
            ..where((tbl) => tbl.status.equals(status))
            ..orderBy([(tbl) => status == ArticleTableStatus.READ ? OrderingTerm.desc(tbl.pubDate) : OrderingTerm.asc(tbl.pubDate)])))
          .watch()
      : (select(article)
            ..where((tbl) => tbl.parent.equals(feedId) & tbl.status.equals(status))
            ..orderBy([(tbl) => status == ArticleTableStatus.READ ? OrderingTerm.desc(tbl.pubDate) : OrderingTerm.asc(tbl.pubDate)]))
          .watch();

  Stream<ArticleData> fetchArticle({required int articleId}) => (select(article)..where((tbl) => tbl.id.equals(articleId))).watchSingle();

  Future<int> updateFeedFav(int feedFavId, FeedFavCompanion feedFavCompanion) => (update(feedFav)..where((tbl) => tbl.id.equals(feedFavId))).write(feedFavCompanion);

  Future<int> insertCategory(CategoryCompanion categoryCompanion) => into(category).insert(categoryCompanion);
  Future<int> updateCategory({required categoryId, required CategoryCompanion categoryCompanion}) => (update(category)..where((tbl) => tbl.id.equals(categoryId))).write(categoryCompanion);
  Stream<CategoryData> fetchCategory({required int categoryId}) => (select(category)..where((tbl) => tbl.id.equals(categoryId))).watchSingle();
  Stream<CategoryData?> fetchCategoryByName({required String categoryName}) => (select(category)..where((tbl) => tbl.name.equals(categoryName))).watchSingleOrNull();
  // numberOfUnreadArticles() => article.id.count(filter: article.status.equals(0) | article.status.equals(null));
  Stream<List<TweetUserData>> tweetUsers() => (select(tweetUser)..orderBy([(tbl) => OrderingTerm.asc(tbl.username)])).watch();
  Future<List<TweetData>> tweets({int status = TweetTableStatus.UNREAD}) => (select(tweet)
        ..where((tbl) => tbl.status.equals(status))
        ..orderBy([(tbl) => OrderingTerm.desc(tbl.tweetId)]))
      .get();
  Future<bool> insertTweet(TweetEncode tweetEncode) async {
    int? retweetId;
    if (tweetEncode.retweet != null) {
      retweetId = await into(retweet).insert(RetweetCompanion.insert(
          tweetUserId: tweetEncode.retweet!.parentUser.tweetUserId,
          title: tweetEncode.retweet!.text,
          createdAt: tweetEncode.retweet!.created_at.millisecondsSinceEpoch,
          username: tweetEncode.retweet!.parentUser.username,
          name: tweetEncode.retweet!.parentUser.name,
          profileUrl: Value(tweetEncode.retweet!.parentUser.profile_image_url)));
    }
    into(tweet).insert(TweetCompanion.insert(parent: tweetEncode.parentUser.id!, title: tweetEncode.text, createdAt: tweetEncode.created_at.millisecondsSinceEpoch, tweetId: Value(tweetEncode.id), retweetId: Value(retweetId)));
    return true;
  }

  Future<int> insertTweetUser(TweetUserCompanion newUser) async {
    final newId = await into(tweetUser).insert(newUser);
    return newId;
  }

  // Future<bool> createAndUpdateTweets(int parent, List<TweetCompanion> tweetsFound) async {
  //   final tweetDataActive = await (select(tweet)..where((tbl) => tbl.active.equals(true) & tbl.parent.equals(parent))).get(); // tbl.tweetId.isNotIn(tweetsFound.map((e) => e.tweetId.value).toList()))).get();
  //   debugPrint('fetchNewTweets(active: $tweetDataActive, ${tweetsFound.map((e) => e.tweetId)})');
  //   final tweetToCreate = tweetsFound
  //       .where((tweetData) => !tweetDataActive.any((tf) {
  //             if (tweetData.tweetId.value == tf.tweetId) {
  //               tweetDataActive.remove(tf);
  //               return true;
  //             }
  //             return false;
  //           }))
  //       .toList();
  //   debugPrint('tweetToCreate: $tweetToCreate, inactivate: $tweetDataActive');
  //   for (int i = 0; i < tweetToCreate.length; i++) await insertTweet(tweetToCreate[i]);
  //   return true;
  // }

  // Future<int> insertTweet(TweetCompanion tweetCompanion) async => into(tweet).insert(tweetCompanion);
  // Future<int> updateTweetStatus({required int id, int status = ArticleTableStatus.READ}) => (update(tweet)..where((tbl) => tbl.id.equals(id))).write(TweetCompanion(status: Value(status)));
  Future<int> updateTweetStatus(int id) => (update(tweet)..where((tbl) => tbl.tweetId.equals(id))).write(TweetCompanion(status: Value(TweetTableStatus.READ)));
  Future<TweetUserData?> fetchTweetUser(int id) => (select(tweetUser)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  // Stream<List<TweetData>> tweets() => select(tweet).watch();
  extractJSON(String filename) async {
    _log.info('extractJSON($filename)');
    final res = await select(feed).join([innerJoin(feedFav, feedFav.feedId.equalsExp(feed.id))]).get();
    final json = res.map((row) => {'url': row.readTable(feed).url, 'fav': row.readTable(feedFav).url}).toList();
    File(filename).writeAsStringSync(jsonEncode(json));
  }

  Future<int> deleteAllReadArticles({int? feedId}) =>
      feedId == null ? (delete(article)..where((tbl) => tbl.active.equals(true) & tbl.status.equals(ArticleTableStatus.READ))).go() : (delete(article)..where((tbl) => tbl.active.equals(true) & tbl.parent.equals(feedId) & tbl.status.equals(ArticleTableStatus.READ))).go();

  Future<int> importJSON(String filename) async {
    _log.info('importJSON($filename)');
    int amount = 0;
    final file = File(filename);
    if (file.existsSync()) {
      final json = jsonDecode(file.readAsStringSync());
      if (json is List) {
        for (int i = 0; i < json.length; i++) {
          if (json[i]['url'] != null) {
            await RSSNetwork.updateFeed(this, FeedData(title: '', url: json[i]['url']), imgUrl: json[i]['fav']);
            amount++;
          }
        }
      }
    }
    return amount;
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
      onCreate: (Migrator m) => m.createAll(),
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 4) {
          _log.info('migration version<4: $from');
          throw InvalidDataException('DB migration not supported');
        }
        if (from < 5) {
          _log.info('migration version<5: $from');
          m.createTable(tweetUser);
          m.createTable(tweet);
        } else if (from < 6) {
          _log.info('migration version<6: $from');
          customUpdate('UPDATE tweet_user SET last_check=0');
          m.renameColumn(tweetUser, 'last_check', tweetUser.sinceId);
          await m.drop(tweet);
          await m.createTable(tweet);
          m.createTable(retweet);
          // final feedFavMigrate = await select(feedFav).get();
          // feedFavMigrate.forEach((fav) {
          //   into(feedFav).insert(fav);
          // });
        }
      });
}

LazyDatabase _openConnection() {
  // the LazyDatabase util lets us find the right location for the file async.
  return LazyDatabase(() async {
    // put the database file, called db.sqlite here, into the documents folder
    // for your app.
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, kReleaseMode ? 'rss_db.sqlite' : 'rss_db_debug.sqlite'));
    return VmDatabase(file);
  });
}

abstract class ArticleTableStatus {
  static const READ = -1;
  static const UNREAD = 0;
  static const FAVORITE = 1;
}

abstract class TweetTableStatus {
  static const READ = -1;
  static const UNREAD = 0;
  static const RETWEET = 1;
}
