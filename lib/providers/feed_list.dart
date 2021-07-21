import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:moor/moor.dart';
import 'package:pedantic/pedantic.dart';
import 'package:rss_feed_reader/database/database.dart';
import 'package:rss_feed_reader/models/feed_encode.dart';
import 'package:rss_feed_reader/providers/network.dart' as network;
import 'package:rss_feed_reader/screens/widgets/lists/article_list_item.dart';
import 'package:rss_feed_reader/screens/widgets/lists/feed_list_item.dart';
import 'package:rss_feed_reader/utils/misc_functions.dart';

final providerFeedHeader = Provider<FeedListHeader>((ref) {
  return FeedListHeader(ref.watch(rssDatabase));
});

class FeedListHeader {
  static final _log = Logger('FeedListHeader');
  final _listFeedKey = GlobalKey<AnimatedListState>();
  final GlobalKey<AnimatedListState> _listArticleKey = GlobalKey<AnimatedListState>();
  final AppDb db;
  // final List<int> readIds = [];
  List<ArticleEncode> articles = [];
  List<FeedEncode> feeds = [];
  int status = ArticleTableStatus.UNREAD;
  int? _lastRemovedId;
  final hasUndoItem = ValueNotifier(false);
  ValueNotifier<bool> isInitialized = ValueNotifier(false);
  ValueNotifier<int> selectedArticleIndexNotifier = ValueNotifier(-1);
  bool selectNextArticle() {
    if (selectedArticleIndexNotifier.value < articles.length - 1) {
      ++selectedArticleIndexNotifier.value;
    } else {
      return false;
    }
    return true;
  }

  bool selectPreviousArticle() {
    if (selectedArticleIndexNotifier.value > 0) {
      --selectedArticleIndexNotifier.value;
    } else {
      return false;
    }
    return true;
  }

  ValueNotifier<int> numberOfArticleNotifier = ValueNotifier(0);
  void _updateAmountOfShownArticles() => numberOfArticleNotifier.value = articles.length;
  ArticleEncode? get selectedArticle => selectedArticleIndexNotifier.value >= 0 ? articles[selectedArticleIndexNotifier.value] : null;
  // ignore: avoid_setters_without_getters
  set changeSelectedArticle(int index) {
    if (index < articles.length) selectedArticleIndexNotifier.value = index;
  }

  FeedListHeader(this.db) {
    reloadFeeds();
  }
  Future<void> reloadFeeds() async {
    _log.info('reloadFeeds()');
    isInitialized.value = false;
    final lastFound = DateTime.now().millisecondsSinceEpoch;
    feeds = (await db.feeds()).map((e) => FeedEncode.fromDB(e)).toList();
    for (final feed in feeds) {
      feed.activeArticles = (await db.fetchActiveArticles(feed.id!)).map<ArticleActiveRead>((f) => ArticleActiveRead(id: f.id, url: f.url, lastFoundEpoch: lastFound)).toList();
      debugPrint('active({$feed.id}): ${feed.activeArticles.length}');
    }
    articles = (await db.articles()).map((e) => ArticleEncode.fromDB(e, feeds)).toList();
    debugPrint('_init(), feeds from db: ${feeds.length}');
    _updateAmountOfShownArticles();
    isInitialized.value = true;
  }

  Future<bool> findFeedToUpdate({int waitTimeSeconds = 0}) async {
    var oldest = -1;
    for (var i = 0; i < feeds.length; i++) {
      if (oldest == -1 || feeds[i].earliestMillisecondsSinceEpoch < feeds[oldest].earliestMillisecondsSinceEpoch) oldest = i;
      if (feeds[oldest].lastCheck == 0) break;
    }
    if (oldest >= 0 && feeds[oldest].earliestMillisecondsSinceEpoch < DateTime.now().millisecondsSinceEpoch) {
      if (waitTimeSeconds > 0) {
        debugPrint('waiting: $waitTimeSeconds, ID: ${feeds[oldest].id}');
        await Future.delayed(Duration(seconds: waitTimeSeconds));
      }
      await updateOrCreateFeed(feeds[oldest]);
      return true;
    } else {
      _log.finer('Nothing to update');
    }
    return false;
  }

  Future<void> removeFeed(int feedId) async {
    final index = feeds.indexWhere((element) => element.id == feedId);
    if (index >= 0) {
      _log.warning('removeFeed($feedId)-remove');
      isInitialized.value = false;
      await db.deleteFeed(feeds[index]);
      var foundArticleIndexToRemove = -1;
      while ((foundArticleIndexToRemove = articles.indexWhere((element) => element.parent.id == feedId)) >= 0) {
        _removeArticleFromList(articles[foundArticleIndexToRemove], foundArticleIndexToRemove);
      }
      final oldFeed = feeds.removeAt(index);
      _listFeedKey.currentState?.removeItem(index, (context, animation) => FeedListItem(feed: oldFeed));
      _updateAmountOfShownArticles();
      isInitialized.value = true;
    } else {
      _log.warning('removeFeed($feedId)-invalid id');
    }
  }

  Future<int> markAllRead(int feedId) {
    final futureRet = db.markAllRead(feedId);
    int foundIndex;
    while ((foundIndex = articles.indexWhere((element) => element.parent.id == feedId)) >= 0) {
      changeArticleStatusByIndex(index: foundIndex);
    }
    return futureRet;
  }

  Future<FeedFullDecode?> fetchFeedEncode(String url, {FeedEncode? parentFeed}) async {
    final channel = await network.readChannel(url, log: _log);
    if (channel != null) return FeedFullDecode.fromChannel(channel, url, parentFeed: parentFeed);
    return null;
  }

  bool unreadLastItem() {
    if (_lastRemovedId != null) {
      _log.info('unreadLastItem: $_lastRemovedId');
      final updateId = _lastRemovedId!;
      _lastRemovedId = null;
      hasUndoItem.value = false;
      db.updateArticleStatus(articleId: updateId, status: ArticleTableStatus.UNREAD).then((value) async {
        final articleData = await db.fetchSingleArticle(articleId: updateId);
        if (articleData != null) {
          await _addNewArticleToList(ArticleEncode.fromDB(articleData, feeds));
          if (selectedArticleIndexNotifier.value > -1) selectedArticleIndexNotifier.value = -1;
        }
      });
      return true;
    } else {
      _log.warning('unreadLastItem - not valid');
    }
    return false;
  }

  Future<void> _addNewArticleToList(ArticleEncode article) async {
    var sortedIndex = articles.lastIndexWhere((element) => element.pubDate > article.pubDate);
    if (sortedIndex == -1) sortedIndex = articles.length;
    _log.info('_addNewArticleToList(${article.url})-${article.id},${article.active}');
    (article.parent as FeedEncode).activeArticles.add(ArticleActiveRead(id: article.id, url: article.url, lastFoundEpoch: DateTime.now().millisecondsSinceEpoch));
    articles.insert(sortedIndex, article);
    _listArticleKey.currentState?.insertItem(sortedIndex);
    _updateAmountOfShownArticles();
  }

  Future<void> _addNewArticle(ArticleEncode article) async {
    assert(article.parent.id != null, "article can't be inserted with invalid parent.id");
    try {
      await db.insertArticle(article.toInsertCompanion).then((value) {
        article.id = value;
        _log.info('_addNewArticle(${article.url})-$value,${article.active}');
        _addNewArticleToList(article);
        (article.parent as FeedEncode).activeArticles.add(ArticleActiveRead(id: article.id, url: article.url, lastFoundEpoch: DateTime.now().millisecondsSinceEpoch));
      }).onError((error, stackTrace) async {
        final found = await (db.select(db.article)..where((tbl) => tbl.parent.equals(article.parent.id) & tbl.url.equals(article.url))).getSingleOrNull();
        if (found != null) {
          _log.warning('_addNewArticle()-Duplicate error: $error, found: ${found.id}');
          await (db.update(db.article)..where((tbl) => tbl.id.equals(found.id))).write(const ArticleCompanion(active: Value(true)));
          // debugPrint('statement: ret: $ret, ${await (db.select(db.article)..where((tbl) => tbl.id.equals(found.id))).getSingleOrNull()}');
          // (db.update(db.article)..where((tbl) => tbl.id.equals(found.id))).write(ArticleCompanion(active: Value(true)));
          (article.parent as FeedEncode).activeArticles.add(ArticleActiveRead(id: found.id, url: found.url, lastFoundEpoch: DateTime.now().millisecondsSinceEpoch));
        } else {
          _log.severe('_addNewArticle()-Different error?: $error');
        }
      });
    } catch (err) {
      _log.warning('_addNewArticle()-Article exist! $article, $err');
    }
  }

  Future<void> updateOrCreateFeed(FeedEncode? feed, {String? imgUrl, String? url}) async {
    assert(feed != null || url != null, 'feed or url must be valid');
    bool hasFeeds = false;
    try {
      feed?.lastError = null;
      final feedFullEncode = await fetchFeedEncode(feed?.url ?? url!, parentFeed: feed);
      if (feedFullEncode != null) {
        final updatedFeed = feed?.id != null ? feed! : feedFullEncode.feed;
        // int newId;
        if (feed?.id == null) {
          // feed = feedFullEncode.feed;
          final fut = db.insertNewFeed(updatedFeed.toInsertCompanion);
          var index = feeds.indexWhere((element) => element.title.compareTo(updatedFeed.title) > 0);
          if (index == -1) {
            index = feeds.length - 1;
          } else {
            hasFeeds = true;
          }
          feeds.insert(index, updatedFeed);
          _listFeedKey.currentState?.insertItem(index);
          updatedFeed.id = await fut;
          _log.info('updateOrCreateFeed()-new feed(${updatedFeed.id})');
        } else {
          updatedFeed.lastCheck = feedFullEncode.feed.lastCheck;
          _log.info('updateOrCreateFeed()-update lastCheck on feed(${updatedFeed.id}): ${await db.updateFeed(updatedFeed.id!, FeedCompanion(lastCheck: Value(updatedFeed.lastCheck)))}');
        }
        _log.finer('update/add-Feed: ${updatedFeed.id}');
        final lastEpoch = DateTime.now().millisecondsSinceEpoch;
        var newArticles = 0;
        for (var i = 0; i < feedFullEncode.articles.length; i++) {
          final article = feedFullEncode.articles[i];
          if (article.url.isNotEmpty) {
            final foundArticle = updatedFeed.activeArticles.indexWhere((element) => element.url.compareTo(article.url) == 0);
            if (foundArticle < 0) {
              _log.fine('Adding new item: ${article.title}(${article.url})');
              newArticles++;
              await _addNewArticle(article);
            } else {
              updatedFeed.activeArticles[foundArticle].lastFoundEpoch = lastEpoch;
            }
          } else {
            _log.warning('Ignoring empty item: ${article.guid}');
          }
        }
        var indexToRemove = -1;
        final batchIds = <int>[];
        while ((indexToRemove = updatedFeed.activeArticles.indexWhere((element) => element.lastFoundEpoch < lastEpoch)) >= 0) {
          batchIds.add(updatedFeed.activeArticles[indexToRemove].id);
          updatedFeed.activeArticles.removeAt(indexToRemove);
        }
        await db.removeActiveStatus(batchIds);
        if (!hasFeeds && newArticles > 0) playSound(soundFile: SOUND_FILE.SOUND_NEWITEM, log: _log);
        _log.info('Still active: ${updatedFeed.activeArticles.map((e) => e.id).join(",")}, new: $newArticles');
      }
    } on SocketException catch (err) {
      _log.warning('Error calling url: $err');
      if (feed?.id != null) {
        feed!.lastError = 'Error: $err';
        feed.lastCheck = DateTime.now().millisecondsSinceEpoch;
        await db.updateFeed(feed.id!, FeedCompanion(lastCheck: Value(feed.lastCheck)));
      }
    } catch (err) {
      _log.warning('updateOrCreateFeed($feed): $err');
      throw Exception('updateOrCreateFeed-Error');
    }
  }

  Value<T> _valueOrAbsent<T>(T? newValue, dynamic previous) => (newValue == null || newValue == previous) ? const Value.absent() : Value(newValue);
  Future<bool> updateFeedInfo(FeedEncode feed, {String? feedFav, String? title, String? url, int? ttl}) async {
    _log.info('updateFeedInfo($feed, $feedFav, $title, $url, $ttl)-${feed.id}');
    if (feed.id != null) {
      unawaited((db.update(db.feed)..where((tbl) => tbl.id.equals(feed.id))).write(FeedCompanion(feedFav: _valueOrAbsent(feedFav, feed.feedFav), title: _valueOrAbsent(title, feed.title), url: _valueOrAbsent(url, feed.url), ttl: _valueOrAbsent(ttl, feed.ttl))).then((value) {
        if (value != 1) _log.warning('updateFeedInfo-!Changed: ${feed.id}, $value, ${FeedCompanion(feedFav: _valueOrAbsent(feedFav, feed.feedFav), title: _valueOrAbsent(title, feed.title), url: _valueOrAbsent(url, feed.url), ttl: _valueOrAbsent(ttl, feed.ttl))}');
      }));
      feed.feedFav = feedFav ?? feed.feedFav;
      feed.ttl = ttl ?? feed.ttl;
      feed.title = title ?? feed.title;
      feed.url = url ?? feed.url;
      return true;
    }
    return false;
  }

  void _removeArticleFromList(ArticleEncode article, int index) {
    _listArticleKey.currentState!.removeItem(index, (context, animation) => SizeTransition(sizeFactor: animation, child: ArticleListItem.articleContainer(context, article)), duration: const Duration(milliseconds: 500));
    articles.removeAt(index);
  }

  void changeArticleStatusByIndex({required int index, int newStatus = ArticleTableStatus.READ}) {
    assert(index >= 0, 'changeArticleStatusByIndex($index, $newStatus)-Invalid index');
    try {
      changeSelectedArticle = -1;
      _log.info('changeArticleStatus-remove(${articles[index].id}, $index, $newStatus)');
      db.updateArticleStatus(articleId: articles[index].id, status: newStatus);
      if (newStatus == ArticleTableStatus.READ) {
        _lastRemovedId = articles[index].id;
        hasUndoItem.value = true;
        _removeArticleFromList(articles[index], index);
      }
      if (index < articles.length) changeSelectedArticle = index;
      _updateAmountOfShownArticles();
    } catch (err) {
      _log.severe('changeArticleStatus exception', err);
    }
  }

  void changeArticleStatusById({required int id, int newStatus = ArticleTableStatus.READ}) {
    assert(id > 0, 'changeArticleStatusById($id, $newStatus)');
    _log.info('changeArticleStatusById($id, $newStatus)');
    final foundIndex = articles.indexWhere((element) => element.id == id);
    if (foundIndex >= 0) changeArticleStatusByIndex(index: foundIndex);
  }

  GlobalKey<AnimatedListState> get articleKey => _listArticleKey;
  GlobalKey<AnimatedListState> get feedKey => _listFeedKey;
}
