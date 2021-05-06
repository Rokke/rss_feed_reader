import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:moor/moor.dart';
import 'package:rss_feed_reader/database/database.dart';
import 'package:rss_feed_reader/models/feed_encode.dart';
import 'package:rss_feed_reader/providers/network.dart';
import 'package:rss_feed_reader/screens/widgets/lists/article_list_item.dart';
import 'package:rss_feed_reader/screens/widgets/lists/feed_list_item.dart';

final providerFeedHeader = Provider<FeedListHeader>((ref) {
  return FeedListHeader(ref.watch(rssDatabase));
});

class FeedListHeader {
  static final _log = Logger('FeedListHeader');
  final _listFeedKey = GlobalKey<AnimatedListState>();
  GlobalKey<AnimatedListState> _listArticleKey = GlobalKey<AnimatedListState>();
  final AppDb db;
  // final List<int> readIds = [];
  List<ArticleEncode> articles = [];
  List<FeedEncode> feeds = [];
  int status = ArticleTableStatus.UNREAD;
  // int get numberOfArticles => articles.length;
  ValueNotifier<bool> isInitialized = ValueNotifier(false);
  ValueNotifier<int> selectedArticleIndexNotifier = ValueNotifier(-1);
  ValueNotifier<int> numberOfArticleNotifier = ValueNotifier(0);
  void _updateAmountOfShownArticles() => numberOfArticleNotifier.value = articles.length;
  ArticleEncode? get selectedArticle => selectedArticleIndexNotifier.value >= 0 ? articles[selectedArticleIndexNotifier.value] : null;
  set changeSelectedArticle(int index) {
    if (index < articles.length) selectedArticleIndexNotifier.value = index;
  }

  FeedListHeader(this.db) {
    reloadFeeds();
  }
  reloadFeeds() async {
    _log.info('reloadFeeds()');
    isInitialized.value = false;
    feeds = (await db.feeds()).map((e) => FeedEncode.fromDB(e)).toList();
    feeds.forEach((feed) {
      db.fetchActiveArticles(feed.id!).then((value) => feed.activeArticles = value.map<ArticleActiveRead>((f) => ArticleActiveRead(id: f.id!, url: f.url)).toList());
    });
    debugPrint('_init(), feeds from db: ${feeds.length}');
    articles = (await db.articles()).map((e) => ArticleEncode.fromDB(e, feeds)).toList();
    debugPrint('_init(), feeds from db: ${feeds.length}');
    _updateAmountOfShownArticles();
    isInitialized.value = true;
  }

  Future<bool> findFeedToUpdate() async {
    int oldest = -1;
    for (int i = 0; i < feeds.length; i++) {
      if (oldest == -1 || feeds[i].earliestMillisecondsSinceEpoch < feeds[oldest].earliestMillisecondsSinceEpoch) oldest = i;
      if (feeds[oldest].lastCheck == 0) break;
    }
    if (oldest >= 0 && feeds[oldest].earliestMillisecondsSinceEpoch < DateTime.now().millisecondsSinceEpoch) {
      updateOrCreateFeed(feeds[oldest]);
      return true;
    } else
      _log.finer('Nothing to update');
    return false;
  }

  removeFeed(int feedId) async {
    final index = feeds.indexWhere((element) => element.id == feedId);
    if (index >= 0) {
      _log.warning('removeFeed($feedId)-remove');
      isInitialized.value = false;
      await db.deleteFeed(feeds[index]);
      int foundArticleIndexToRemove = -1;
      while ((foundArticleIndexToRemove = articles.indexWhere((element) => element.parent.id == feedId)) >= 0) {
        _removeArticleFromList(articles[foundArticleIndexToRemove], foundArticleIndexToRemove);
      }
      final oldFeed = feeds.removeAt(index);
      _listFeedKey.currentState?.removeItem(index, (context, animation) => FeedListItem(feed: oldFeed));
      _updateAmountOfShownArticles();
      isInitialized.value = true;
    } else
      _log.warning('removeFeed($feedId)-invalid id');
  }

  Future<int> markAllRead(int feedId) {
    final futureRet = db.markAllRead(feedId);
    int foundIndex;
    while ((foundIndex = articles.indexWhere((element) => element.parent == feedId)) >= 0) {
      changeArticleStatus(index: foundIndex);
    }
    return futureRet;
  }

  Future<FeedFullDecode?> fetchFeedEncode(String url, {FeedEncode? parentFeed}) async {
    final channel = await RSSNetwork.readChannel(url);
    if (channel != null) return FeedFullDecode.fromChannel(channel, url, parentFeed: parentFeed);
    return null;
  }

  void _addNewArticle(ArticleEncode article) async {
    assert(article.parent.id != null, 'article can\'t be inserted with invalid parent.id');
    int sortedIndex = articles.lastIndexWhere((element) => element.pubDate > article.pubDate);
    if (sortedIndex == -1) sortedIndex = articles.length;
    db.insertArticle(article.toInsertCompanion).then((value) {
      _log.info('_addNewArticle(${article.title})-$value');
      article.parent.activeArticles.add(ArticleActiveRead(id: article.id = value, url: article.url));
      articles.insert(sortedIndex, article);
      _listArticleKey.currentState?.insertItem(sortedIndex);
      _updateAmountOfShownArticles();
    });
  }

  Future<void> updateOrCreateFeed(FeedEncode? feed, {String? imgUrl, String? url}) async {
    assert(feed != null || url != null, 'feed or url must be valid');
    final feedFullEncode = await fetchFeedEncode(feed?.url ?? url!, parentFeed: feed);
    if (feedFullEncode != null) {
      // int newId;
      if (feed?.id == null) {
        feed = feedFullEncode.feed;
        final fut = db.insertNewFeed(feed.toInsertCompanion);
        int index = feeds.indexWhere((element) => element.title.compareTo(feed!.title) > 0);
        if (index == -1) index = feeds.length - 1;
        feeds.insert(index, feed);
        _listFeedKey.currentState?.insertItem(index);
        feed.id = await fut;
        _log.info('updateOrCreateFeed()-new feed(${feed.id})');
      } else {
        feed!.lastCheck = feedFullEncode.feed.lastCheck;
        _log.info('updateOrCreateFeed()-update lastCheck on feed(${feed.id}): ${await db.updateFeed(feed.id!, FeedCompanion(lastCheck: Value(feed.lastCheck)))}');
      }
      debugPrint('update/add-Feed: ${feed.id}');
      final lastEpoch = DateTime.now().millisecondsSinceEpoch;
      for (ArticleEncode article in feedFullEncode.articles) {
        if (article.url.isNotEmpty) {
          final foundArticle = feed.activeArticles.indexWhere((element) => element.url.compareTo(article.url) == 0);
          if (foundArticle < 0) {
            _log.fine('Adding new item: ${article.title}');
            _addNewArticle(article);
          } else
            feed.activeArticles[foundArticle].lastFoundEpoch = lastEpoch;
        } else
          _log.warning('Ignoring empty item: ${article.guid}');
      }
      int indexToRemove = -1;
      final List<int> batchIds = [];
      while ((indexToRemove = feed.activeArticles.indexWhere((element) => element.lastFoundEpoch < lastEpoch)) >= 0) {
        batchIds.add(feed.activeArticles[indexToRemove].id);
        feed.activeArticles.removeAt(indexToRemove);
      }
      db.removeActiveStatus(batchIds);
      debugPrint('Still active: ${feed.activeArticles.map((e) => e.id).join(",")}');
    }
  }

  Value<T> _valueOrAbsent<T>(dynamic newValue, dynamic previous) => (newValue == null || newValue == previous) ? Value.absent() : Value(newValue);
  Future<bool> updateFeedInfo(FeedEncode feed, {String? feedFav, String? title, String? url, int? ttl}) async {
    if (feed.id != null) {
      feed.feedFav = feedFav ?? feed.feedFav;
      feed.ttl = ttl ?? feed.ttl;
      feed.title = title ?? feed.title;
      feed.url = url ?? feed.url;
      (db.update(db.feed)..where((tbl) => tbl.id.equals(feed.id))).write(FeedCompanion(feedFav: _valueOrAbsent(feedFav, feed.feedFav), title: _valueOrAbsent(title, feed.title), url: _valueOrAbsent(url, feed.url), ttl: _valueOrAbsent(ttl, feed.ttl)));
      return true;
    }
    return false;
  }

  _removeArticleFromList(ArticleEncode article, int index) {
    _listArticleKey.currentState!.removeItem(index, (context, animation) => SizeTransition(sizeFactor: animation, child: ArticleListItem.articleContainer(context, article)), duration: Duration(milliseconds: 500));
    articles.removeAt(index);
  }

  void changeArticleStatus({required int index, int newStatus = ArticleTableStatus.READ}) {
    if (index >= 0) {
      try {
        changeSelectedArticle = -1;
        _log.info('changeArticleStatus-remove(${articles[index].id}, $index, $newStatus)');
        db.updateArticleStatus(articleId: articles[index].id!, status: newStatus);
        _removeArticleFromList(articles[index], index);
        if (index < articles.length) changeSelectedArticle = index;
        _updateAmountOfShownArticles();
      } catch (err) {
        _log.severe('changeArticleStatus exception', err);
      }
    } else
      _log.warning('changeArticleStatus-remove($index, $newStatus)-Invalid index');
  }

  GlobalKey<AnimatedListState> get articleKey => _listArticleKey;
  GlobalKey<AnimatedListState> get feedKey => _listFeedKey;
}
