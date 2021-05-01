import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:rss_feed_reader/database/database.dart';
import 'package:rss_feed_reader/providers/network.dart';
import 'package:rss_feed_reader/providers/tweet_list.dart';

final monitoringRunning = StateProvider<bool>((ref) => false);
const TTL_MS = 60000;

class RSSTree {
  // final List<RSSArticle> _articles = [1, 2, 3, 4, 5, 6, 7].map((e) => RSSArticle('url $e')).toList();
}

class RSSHead extends StateNotifier<RSSTree> {
  final _log = Logger('RSSHead');
  Timer? _timer;
  final Reader read;
  bool busy = false;
  RSSHead(this.read) : super(RSSTree());
  startMonitoring({Duration? postponeStart}) async {
    _log.info('startMonitoring($postponeStart)');
    read(monitoringRunning).state = true;
    if (postponeStart != null) await Future.delayed(postponeStart);
    _timer = Timer.periodic(Duration(seconds: 10), (_) async {
      if (!busy) {
        busy = true;
        try {
          if (!await findFeedToUpdate()) await read(providerTweetHeader).checkAndUpdateTweet(isAuto: true);
        } catch (err) {
          _log.severe('Monitor error', err);
        } finally {
          busy = false;
        }
      }
    });
  }

  bool get started => _timer != null;

  Future<bool> findFeedToUpdate() async {
    final rssDb = read(rssDatabase);
    final msEpoch = DateTime.now().millisecondsSinceEpoch;
    final found = await rssDb.fetchOldestFeed(msEpoch).getSingleOrNull();
    if (found != null) {
      final feed = await rssDb.fetchFeed(found.id!);
      if (feed != null) {
        final addedFeeds = await RSSNetwork.updateFeed(rssDb, feed);
        // read(unreadArticles).state.changeValue(addedFeeds);
        _log.info('Added $addedFeeds');
        return true;
      } else
        _log.severe('illegal feed: ${found.id}');
    } else
      _log.finer('Nothing to update');
    return false;
  }

  // Future<bool> findTweetToUpdate() async {
  // }

  stopMonitoring() {
    debugPrint('stopMonitoring');
    _timer?.cancel();
    _timer = null;
    read(monitoringRunning).state = false;
  }

  @override
  void dispose() {
    stopMonitoring();
    super.dispose();
  }
}

final rssProvider = Provider<RSSHead>((ref) {
  final rssHead = RSSHead(ref.read);
  ref.onDispose(() {
    print('disprss');
    rssHead.stopMonitoring();
  });
  return rssHead;
});
