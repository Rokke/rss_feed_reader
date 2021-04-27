import 'dart:convert';

import 'package:dio/dio.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:moor/moor.dart' as moor;
import 'package:rss_feed_reader/database/database.dart';
import 'package:rss_feed_reader/models/tweet_encoding.dart';
import 'package:rss_feed_reader/models/xml_mapper/channel_mapper.dart';
import 'package:rss_feed_reader/models/xml_mapper/item_mapper.dart';
import 'package:rss_feed_reader/secret.dart';
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
        if (item.link != null && item.link!.isNotEmpty) {
          final foundArticle = await (db.select(db.article)..where((tbl) => tbl.url.equals(item.link ?? item.guid))).getSingleOrNull();
          if (foundArticle == null) {
            _log.fine('Adding new item: ${item.title}');
            if (await db.insertArticle(item.toArticleCompanion(newId)) > 0) numberOfArticlesAdded++; //.addArticle(newId, item.title!, item.link, item.guid ?? item.link!, item.description, item.author, item.pubDate, item.category, item.encoded, null);
          } else
            stillActiveArticles.add(foundArticle.id!);
        } else
          _log.warning('Ignoring empty item: ${item.guid}');
      }
      if (feed.id != null) db.updateActiveStatus(feed.id!, stillActiveArticles);
    }
    return numberOfArticlesAdded;
  }

  ///TODO - Slett gamle feeds som ikke blir sendt lengre. Skal jeg her sjekke +10 tweets når jeg starter opp APP eller lenge siden sjekk og slette da de som ikke kommer?
  static Future<List<TweetEncode>> fetchUserTweets(AppDb db, TweetUserEncode tweetUserData) async {
    assert(tweetUserData.id != null, 'Invalid tweetUser: $tweetUserData');
    _log.info('fetchUserTweets($tweetUserData)');
    final response = await http.Dio().get('https://api.twitter.com/2/users/${tweetUserData.tweetUserId}/tweets?tweet.fields=created_at,referenced_tweets', options: http.Options(headers: {'Authorization': 'Bearer $TWITTER_BEARER_TOKEN'}));
    if (response.statusCode == 200 && response.data['data'] is List) {
      try {
        return (response.data['data'] as List).map((tweet) => TweetEncode.fromJSON(tweetUserData.tweetUserId, tweet)).toList();
      } catch (err) {
        _log.warning('fetchUserTweets()-Error decode: ${response.data}, $err');
      }
    } else
      _log.warning('fetchUserTweets()-Err response: $json');
    return [];
  }
  // static Future<bool> updateTweets(AppDb db, TweetUserData tweetUserData) async {
  //   assert(tweetUserData.id != null, 'Invalid tweetUser: $tweetUserData');
  //   debugPrint('readTweets($tweetUserData)');
  //   final response = await http.Dio().get('https://api.twitter.com/2/users/${tweetUserData.tweetUserId}/tweets?tweet.fields=created_at,referenced_tweets', options: http.Options(headers: {'Authorization': 'Bearer $TWITTER_BEARER_TOKEN'}));
  //   if (response.statusCode == 200 && response.data['data'] is List) {
  //     try {
  //       return await db.createAndUpdateTweets(
  //         tweetUserData.id!,
  //         (response.data['data'] as List).map((tweet) => TweetCompanion.insert(tweetId: int.parse(tweet['id']), parent: tweetUserData.id!, title: tweet['text'], createdAt: DateTime.tryParse(tweet['created_at'])?.millisecondsSinceEpoch ?? 0)).toList(),
  //       );
  //     } catch (err) {
  //       debugPrint('Error decode: ${response.data}, $err');
  //     }
  //   } else
  //     debugPrint('Err response: $json');
  //   return false;
  // }

  static Future<TweetUserEncode?> fetchTweetUsername({int? id, String? username}) async {
    _log.fine('addTweetUsername($id, $username)');
    assert(id != null || username != null, 'addTweetUsername-id or username must be valid');
    final url = 'https://api.twitter.com/2/users/${id != null ? id : "by/username/$username"}?user.fields=profile_image_url';
    _log.finest('url: $url');
    final response = await http.Dio().get(url, options: http.Options(headers: {'Authorization': 'Bearer $TWITTER_BEARER_TOKEN'}));
    if (response.statusCode == 200 && response.data['data'] != null) {
      try {
        _log.info('fetchTweetUsername()-Adding user: ${response.data['data']}');
        return TweetUserEncode.fromJSON(response.data['data']);
        // await db.insertTweetUser(int.parse(response.data['data']['id']), response.data['data']['username'], response.data['data']['name'], profileUrl: response.data['data']['profile_image_url']);
        // return (response.data['data'] as List).map((tweet) => Tweet.fromJSON(tweet)).toList();
      } catch (err) {
        _log.warning('fetchTweetUsername()-Error decode: ${response.data}, $err');
      }
    } else
      _log.warning('fetchTweetUsername()-Err response: ${response.data}');
    return null;
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
