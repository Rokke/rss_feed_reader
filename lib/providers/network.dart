import 'dart:io';

import 'package:dio/dio.dart' as http;
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:rss_feed_reader/models/xml_mapper/channel_mapper.dart';
import 'package:xml/xml.dart';

// final networkProvider = Provider<RSSNetwork>((ref) {
//   return RSSNetwork(ref.watch(rssDatabase));
// });

// static final _log = Logger('RSSNetwork');
// final AppDb db;

// RSSNetwork(this.db);
Future<ChannelMapper?> readChannel(String url, {Logger? log}) async {
  final xEl = await readFeed(url, log: log);
  // final currentEpochMs = DateTime.now().millisecondsSinceEpoch;
  // int numberOfArticlesAdded = 0;
  if (xEl != null) return ChannelMapper.fromXML(xEl);
  return null;
  //   int newId;
  //   if (feed.id == null && channel.title != null) {
  //     newId = await feedListHeader.insertFeed(FeedEncode.fromChannel(channel)(data) feed.url, channel, currentEpochMs, imgUrl ?? channel.image ?? (fetchHostUrl(channel.link ?? channel.atomlink ?? feed.url) + '/favicon.ico'));
  //   } else {
  //     newId = feed.id!;
  //     _log.info('update lastCheck on feed($newId): ${await db.updateFeed(newId, FeedCompanion(lastCheck: moor.Value(currentEpochMs)))}');
  //   }
  //   debugPrint('update/add-Feed: $newId');
  //   List<int> stillActiveArticles = [];
  //   for (ItemMapper item in channel.items) {
  //     if (item.link != null && item.link!.isNotEmpty) {
  //       final foundArticle = await (db.select(db.article)..where((tbl) => tbl.url.equals(item.link ?? item.guid))).getSingleOrNull();
  //       if (foundArticle == null) {
  //         _log.fine('Adding new item: ${item.title}');
  //         if (await db.insertArticle(item.toArticleCompanion(newId)) > 0) numberOfArticlesAdded++; //.addArticle(newId, item.title!, item.link, item.guid ?? item.link!, item.description, item.author, item.pubDate, item.category, item.encoded, null);
  //       } else
  //         stillActiveArticles.add(foundArticle.id!);
  //     } else
  //       _log.warning('Ignoring empty item: ${item.guid}');
  //   }
  //   if (feed.id != null) db.updateActiveStatus(feed.id!, stillActiveArticles);
  // }
  // return numberOfArticlesAdded;
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

Future<Map<String, dynamic>?> getResponse(String url, {Map<String, dynamic>? headers, Logger? log}) async {
  final response = await http.Dio().get(url,
      options: headers != null
          ? http.Options(
              headers: headers,
            )
          : null);
  if (response.statusCode == 200) {
    if (response.data['data'] != null) {
      return response.data as Map<String, dynamic>;
    } else {
      log?.info('getResponse()-No changed: ${response.data}');
    }
    return {};
  } else {
    log?.warning('getResponse()-Err response: ${response.data}');
  }
  return null;
}

Future<XmlElement?> readFeed(String url, {Logger? log}) async {
  log?.info('readFeed($url)');
  http.Options? opt;
  debugPrint('readFeed-1($url)');
  final matches = RegExp('https://([^/:?]*).*').allMatches(url);
  Map<String, dynamic>? headers;
  if (matches.isNotEmpty) {
    headers = {"Host": matches.first.group(1)};
    opt = http.Options(headers: headers);
  }
  debugPrint('readFeed-d($url): $headers');
  try {
    final response = await http.Dio().get(url, options: opt);
    if (response.statusCode == 200) {
      final root = XmlDocument.parse(response.data as String);
      debugPrint('root: $root');
      debugPrint('find: ${root.findAllElements('feed')}');
      if (root.findAllElements('channel').isEmpty) {
        return root.findAllElements('feed').first;
      } else {
        return root.findAllElements('channel').first;
      }
    } else {
      log?.warning('Error downloading feed: ${response.statusCode}, $url');
    }
  } on http.DioError catch (serr) {
    debugPrint('socket error: $serr');
    log?.warning('readFeed dio error ($url): ${serr.type}, ${serr.message}, ${serr.runtimeType}');
    if (serr.type == http.DioErrorType.response) throw SocketException('DIO error: $serr');
    log?.warning('readFeed error ${serr.error["errno"]}');
    rethrow;
  } catch (err) {
    debugPrint('error: $err');
    log?.warning('readFeed exception ($url, $headers): $err');
    rethrow;
  }
  return null;
}
