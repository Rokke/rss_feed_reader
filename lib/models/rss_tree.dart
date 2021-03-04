import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class RSSTree {
  // final List<RSSArticle> _articles = [1, 2, 3, 4, 5, 6, 7].map((e) => RSSArticle('url $e')).toList();
}

class RSSHead extends StateNotifier<RSSTree> {
  Timer? _timer;
  RSSHead() : super(RSSTree());
  startMonitoring() {
    _timer = Timer.periodic(Duration(seconds: 1), (_) {});
  }

  stopMonitoring() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    stopMonitoring();
    super.dispose();
  }
}

final rssProvider = StateNotifierProvider<RSSHead>((ref) {
  return RSSHead();
});
