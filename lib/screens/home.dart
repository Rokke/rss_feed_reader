import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:rss_feed_reader/models/rss_tree.dart';
import 'package:rss_feed_reader/screens/widgets/appbar_widget.dart';
import 'package:rss_feed_reader/screens/widgets/article_widget.dart';
import 'package:rss_feed_reader/screens/widgets/details_widget.dart';
import 'package:rss_feed_reader/screens/widgets/feed_widget.dart';

final applicationVersionProvider = FutureProvider<PackageInfo>((ref) {
  final rss = ref.watch(rssProvider);
  final pi = PackageInfo.fromPlatform();
  if (kReleaseMode && !rss.started) rss.startMonitoring(postponeStart: Duration(seconds: 20));
  return pi;
});

class AppInfo {
  PackageInfo? _pInfo;
  final _log = Logger('AppInfoNotifier');
  AppInfoNotifier(RSSHead rss) {
    _init(rss);
  }

  _init(RSSHead rss) async {
    _pInfo = await PackageInfo.fromPlatform();
    _log.info('App starting $this');
    if (kReleaseMode) rss.startMonitoring(postponeStart: Duration(seconds: 20));
  }

  bool get initialized => _pInfo != null;
  String? get appName => _pInfo?.appName;
  String? get packageName => _pInfo?.packageName;
  String? get buildNumber => _pInfo?.buildNumber;
  String? get version => _pInfo?.version;
  @override
  String toString() {
    return '$appName - $version.$buildNumber. $packageName';
  }
}

class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, ScopedReader watch) {
    final appVersionFuture = watch(applicationVersionProvider);
    return Scaffold(
      drawer: Container(width: MediaQuery.of(context).size.width / 1.25, child: Drawer(child: FeedView())),
      appBar: appVersionFuture.when(
          data: (appVersion) => PreferredSize(
                preferredSize: Size.fromHeight(50),
                child: CustomAppBarWidget(appVersion),
              ),
          loading: () => AppBar(
                title: Text('Starter...'),
                actions: [CircularProgressIndicator()],
              ),
          error: (_, __) => AppBar(title: Text('RSS Oversikt'))),
      body: LayoutBuilder(
          builder: (context, constraints) => constraints.maxWidth > 1000
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [Expanded(child: ArticleView()), SizedBox(height: 600, child: DetailWidget())],
                )
              : ArticleView()),
    );
  }
}
