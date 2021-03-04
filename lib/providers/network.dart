import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart' as http;
import 'package:rss_feed_reader/database/database.dart';
import 'package:rss_feed_reader/models/xml_mapper/channel_mapper.dart';
import 'package:rss_feed_reader/models/xml_mapper/item_mapper.dart';
import 'package:xml/xml.dart';

final networkProvider = Provider<RSSNetwork>((ref) {
  return RSSNetwork(ref.watch(rssDatabase));
});

class RSSNetwork {
  final AppDb db;

  RSSNetwork(this.db);
  static updateFeed(AppDb db, FeedData feed) async {
    final xEl = await readFeed(feed.url);
    if (xEl != null) {
      final channel = ChannelMapper.fromXML(xEl);
      final newId = feed.id == null
          ? await db.addFeed(channel.title!, feed.url, channel.description, channel.link ?? channel.atomlink, channel.language, channel.category, channel.ttl, channel.lastBuildDate ?? DateTime.now().millisecondsSinceEpoch, channel.pubDate, null)
          : channel.equals(feed)
              ? feed.id!
              : await db.updateFeed(null, null, channel.description, channel.link ?? channel.atomlink, channel.language, channel.category, channel.ttl, channel.lastBuildDate ?? DateTime.now().millisecondsSinceEpoch, channel.pubDate, null, feed.id);
      debugPrint('update/add-Feed: $newId');
      for (ItemMapper item in channel.items) {
        if ((await (db.select(db.article)..where((tbl) => tbl.url.equals(item.link ?? item.guid))).getSingleOrNull()) == null) {
          debugPrint('Adding new item: ${item.title}');
          await db.addArticle(newId, item.title!, item.link, item.guid ?? item.link!, item.description, item.author, item.pubDate, item.category, item.encoded, null);
        } else
          debugPrint('Existing item: ${item.title}');
      }
    }
  }

  static Future<XmlElement?> readFeed(String url) async {
    debugPrint('readFeed($url)');
    final response = await http.Dio().get(url);
    if (response.statusCode == 200)
      return XmlDocument.parse(response.data).findAllElements('channel').first;
    else
      return null;
  }
}
