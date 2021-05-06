import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:moor/moor.dart';
import 'package:rss_feed_reader/database/database.dart';
import 'package:rss_feed_reader/models/xml_mapper/channel_mapper.dart';
import 'package:rss_feed_reader/models/xml_mapper/item_mapper.dart';

class FeedEncode {
  static const TTL_DEFAULT = 30;
  int? id;
  final int lastBuildDate, pubDate;
  String title, url;
  final String? category, link, language;
  String? feedFav, description;
  List<ArticleActiveRead> activeArticles = [];
  int ttl, lastCheck;
  FeedEncode({required this.title, required this.url, required this.ttl, required this.lastCheck, required this.lastBuildDate, required this.pubDate, this.description, this.link, this.id, this.category, this.feedFav, this.language});
  int get earliestMillisecondsSinceEpoch => lastCheck + ttl * 60000;
  factory FeedEncode.fromChannel(ChannelMapper channel, String url) =>
      FeedEncode(title: channel.title!, url: url, ttl: channel.ttl ?? TTL_DEFAULT, lastCheck: DateTime.now().millisecondsSinceEpoch, lastBuildDate: channel.lastBuildDate ?? 0, pubDate: channel.pubDate ?? 0, category: channel.category, link: channel.link ?? channel.atomlink, feedFav: channel.image);
  factory FeedEncode.fromDB(FeedData data) {
    try {
      return FeedEncode(
        title: data.title,
        url: data.url,
        ttl: data.ttl ?? 30,
        lastCheck: data.lastCheck ?? 0,
        lastBuildDate: data.lastBuildDate ?? DateTime.now().millisecondsSinceEpoch,
        pubDate: data.pubDate ?? 0,
        description: data.description,
        link: data.link,
        id: data.id,
        category: data.category,
        language: data.language,
        feedFav: data.feedFav,
      );
    } catch (err) {
      debugPrint('FeedEncode.fromDB exception: $data');
      throw err;
    }
  }
  Map<String, dynamic> toJson() => {
        'title': title,
        'url': url,
        'ttl': ttl,
        'lastCheck': lastCheck,
        'lastBuildDate': lastBuildDate,
        'pubDate': pubDate,
        'description': description,
        'link': link,
        'id': id,
        'category': category,
        'language': language,
        'feedFav': feedFav,
      };
  FeedCompanion get toInsertCompanion => FeedCompanion(
        title: Value(title),
        description: Value(description),
        category: Value(category),
        ttl: Value(ttl),
        pubDate: Value(pubDate),
        link: Value(link),
        lastBuildDate: Value(lastBuildDate),
        language: Value(language),
      );

  Widget? get fetchFeedFavImage => feedFav == null
      ? null
      : CachedNetworkImage(
          imageUrl: feedFav!,
          fit: BoxFit.fitWidth,
          alignment: Alignment.center,
          width: 30,
          errorWidget: (_, __, ___) => Container(),
        );
  @override
  String toString() {
    return 'FeedEncode($id,$title,$url,$link,$lastBuildDate)';
  }
}

class ArticleActiveRead {
  final int id;
  final String url;
  int lastFoundEpoch;

  ArticleActiveRead({required this.id, required this.url, this.lastFoundEpoch = 0});
}

class ArticleEncode {
  int? id;
  final String title, guid, url;
  final String? creator, encoded, category;
  String? description;
  final FeedEncode parent;
  final int pubDate;
  bool active;

  ArticleEncode({this.id, required this.parent, required this.title, required this.pubDate, required this.url, this.creator, this.description, this.encoded, this.category, required this.guid, this.active = true});
  Future<String?> articleDescription(AppDb db) async => description ??= (await (db.select(db.article)..where((tbl) => tbl.id.equals(id))).getSingleOrNull())?.description;
  factory ArticleEncode.fromChannelItem(ItemMapper item, FeedEncode feed) {
    try {
      return ArticleEncode(
        parent: feed,
        title: item.title!,
        guid: item.guid ?? item.link!,
        url: item.link!,
        description: item.description,
        creator: item.author,
        encoded: item.encoded,
        category: item.category,
        pubDate: item.pubDate ?? feed.lastCheck,
      );
    } catch (err) {
      debugPrint('ArticleEncode.fromChannelItem exception: $item');
      throw err;
    }
  }
  factory ArticleEncode.fromDB(ArticleData data, List<FeedEncode> feeds) {
    try {
      return ArticleEncode(
        id: data.id,
        parent: feeds.firstWhere((element) => element.id == data.parent),
        title: data.title,
        guid: data.guid,
        url: data.url,
        creator: data.creator,
        encoded: data.encoded,
        category: data.category,
        pubDate: data.pubDate ?? 0,
        active: data.active,
      );
    } catch (err) {
      debugPrint('ArticleEncode.fromDB exception: $data');
      throw err;
    }
  }
  Map<String, dynamic> toJson() => {
        'parent': parent.toJson(),
        'title': title,
        'guid': guid,
        'url': url,
        'description': description,
        'creator': creator,
        'encoded': encoded,
        'category': category,
        'pubDate': pubDate,
      };
  ArticleCompanion get toInsertCompanion => ArticleCompanion(
        parent: Value(parent.id!),
        title: Value(title),
        url: Value(url),
        guid: Value(guid),
        description: Value(description),
        creator: Value(creator),
        pubDate: Value(pubDate),
        category: Value(category),
        encoded: Value(encoded),
      );
  @override
  String toString() {
    return 'ArticleEncode($id,$title,$guid,${parent.id},$creator)';
  }
}

class FeedFullDecode {
  final FeedEncode feed;
  final List<ArticleEncode> articles;
  final String url;

  FeedFullDecode({required this.feed, required this.articles, required this.url});
  factory FeedFullDecode.fromChannel(ChannelMapper channel, url, {FeedEncode? parentFeed}) {
    final newFeed = FeedEncode.fromChannel(channel, url);
    return FeedFullDecode(feed: newFeed, articles: channel.items.map((item) => ArticleEncode.fromChannelItem(item, parentFeed ?? newFeed)).toList(), url: url);
  }
}

abstract class ArticleTableStatus {
  static const READ = -1;
  static const UNREAD = 0;
  static const FAVORITE = 1;
}
