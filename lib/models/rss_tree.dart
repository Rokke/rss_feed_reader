import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rss_feed_reader/database/database.dart';
import 'package:rss_feed_reader/providers/network.dart';

final monitoringRunning = StateProvider<bool>((ref) => false);
const TTL_MS = 60000;

class RSSTree {
  // final List<RSSArticle> _articles = [1, 2, 3, 4, 5, 6, 7].map((e) => RSSArticle('url $e')).toList();
}

class RSSHead extends StateNotifier<RSSTree> {
  Timer? _timer;
  final Reader read;
  bool busy = false;
  RSSHead(this.read) : super(RSSTree());
  startMonitoring() {
    debugPrint('startMonitoring');
    read(monitoringRunning).state = true;
    _timer = Timer.periodic(Duration(seconds: 10), (_) {
      print('timer...');
      if (!busy) {
        busy = true;
        try {
          findFeedToUpdate();
        } catch (err) {
          log('Monitor error', error: err);
        } finally {
          busy = false;
        }
      }
    });
  }

  findFeedToUpdate() async {
    final rssDb = read(rssDatabase);
    final msEpoch = DateTime.now().millisecondsSinceEpoch;
    final found = await rssDb.fetchOldestFeed(msEpoch).getSingleOrNull();
    if (found != null) {
      final feed = await rssDb.fetchFeed(found.id!).getSingleOrNull();
      if (feed != null) {
        await RSSNetwork.updateFeed(rssDb, feed);
      } else
        debugPrint('illegal feed: ${found.id}');
    } else
      debugPrint('Nothing to update');
  }

  stopMonitoring() {
    debugPrint('stopMonitoring');
    _timer?.cancel();
    _timer = null;
    read(monitoringRunning).state = false;
  }

  @override
  void dispose() {
    print('dispcls');
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
