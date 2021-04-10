import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart' as http;
import 'package:logging/logging.dart';
import 'package:moor/moor.dart' as moor;
import 'package:rss_feed_reader/database/database.dart';
import 'package:rss_feed_reader/models/xml_mapper/channel_mapper.dart';
import 'package:rss_feed_reader/models/xml_mapper/item_mapper.dart';
import 'package:rss_feed_reader/utils/misc_functions.dart';
import 'package:xml/xml.dart';

final networkProvider = Provider<RSSNetwork>((ref) {
  return RSSNetwork(ref.watch(rssDatabase));
});

class RSSNetwork {
  static final _log = Logger('RSSNetwork');
  final AppDb db;

  RSSNetwork(this.db);
  static Future<int> updateFeed(AppDb db, FeedData feed, {String? imgUrl}) async {
    final xEl = await readFeed(feed.url);
    final currentEpochMs = DateTime.now().millisecondsSinceEpoch;
    int numberOfArticlesAdded = 0;
    if (xEl != null) {
      final channel = ChannelMapper.fromXML(xEl);
      int newId;
      if (feed.id == null && channel.title != null) {
        newId = await db.insertFeed(feed.url, channel, currentEpochMs, imgUrl ?? channel.image ?? (fetchHostUrl(channel.link ?? channel.atomlink ?? feed.url) + '/favicon.ico'));
        //.addFeed(channel.title!, feed.url, channel.description, channel.link ?? channel.atomlink, channel.language, channel.category, channel.ttl, channel.lastBuildDate ?? currentEpochMs, channel.pubDate, null, currentEpochMs);
        // _checkAndAddFavIcon(db, newId, channel.image ?? (fetchHostUrl(channel.link ?? channel.atomlink ?? feed.url) + '/favicon.ico'));
      } else {
        newId = feed.id!;
        // if (channel.equals(feed))
        _log.info('update lastCheck on feed($newId): ${await db.updateFeed(newId, FeedCompanion(lastCheck: moor.Value(currentEpochMs)))}');
        // else
        //   _log.severe('channel feed has changed: $channel, $feed');
        // await db.updateFeed(feed.title.isEmpty ? channel.title : null, null, channel.description, channel.link ?? channel.atomlink, channel.language, channel.category, channel.ttl, channel.lastBuildDate ?? currentEpochMs, channel.pubDate, null, currentEpochMs, feed.id);
      }
      debugPrint('update/add-Feed: $newId');
      List<int> stillActiveArticles = [];
      for (ItemMapper item in channel.items) {
        final foundArticle = await (db.select(db.article)..where((tbl) => tbl.url.equals(item.link ?? item.guid))).getSingleOrNull();
        if (foundArticle == null) {
          _log.fine('Adding new item: ${item.title}');
          if (await db.insertArticle(item.toArticleCompanion(newId)) > 0) numberOfArticlesAdded++; //.addArticle(newId, item.title!, item.link, item.guid ?? item.link!, item.description, item.author, item.pubDate, item.category, item.encoded, null);
        } else
          stillActiveArticles.add(foundArticle.id!);
      }
      if (feed.id != null) db.updateActiveStatus(feed.id!, stillActiveArticles);
    }
    return numberOfArticlesAdded;
  }

  // static Future<void> _checkAndAddFavIcon(AppDb db, int feed_id, String url) async {
  //   await db.into(db.feedFav).insert(FeedFavCompanion.insert(feedId: feed_id, url: url));
  // }

  static Future<XmlElement?> readFeed(String url) async {
    _log.info('readFeed($url)');
    final response = await http.Dio().get(url);
    if (response.statusCode == 200) {
      final root = XmlDocument.parse(response.data);
      if (root.findAllElements('channel').isEmpty)
        return root.findAllElements('feed').first;
      else
        return root.findAllElements('channel').first;
    } else
      return null;
  }
}
