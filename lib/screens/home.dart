import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:rss_feed_reader/models/rss_tree.dart';
import 'package:rss_feed_reader/screens/widgets/appbar_widget.dart';
import 'package:rss_feed_reader/screens/widgets/article_widget.dart';
import 'package:rss_feed_reader/screens/widgets/details_widget.dart';
import 'package:rss_feed_reader/screens/widgets/feed_widget.dart';
import 'package:rss_feed_reader/screens/widgets/twitter_widget.dart';

final applicationVersionProvider = FutureProvider<PackageInfo>((ref) {
  final rss = ref.watch(rssProvider);
  final pi = PackageInfo.fromPlatform();
  if (kReleaseMode && !rss.started) rss.startMonitoring(postponeStart: const Duration(seconds: 20));
  return pi;
});

// class AppInfo {
//   PackageInfo? _pInfo;
//   final _log = Logger('AppInfoNotifier');
//   AppInfoNotifier(RSSHead rss) {
//     _init(rss);
//   }

//   _init(RSSHead rss) async {
//     _pInfo = await PackageInfo.fromPlatform();
//     _log.info('App starting $this');
//     if (kReleaseMode) rss.startMonitoring(postponeStart: Duration(seconds: 20));
//   }

//   bool get initialized => _pInfo != null;
//   String? get appName => _pInfo?.appName;
//   String? get packageName => _pInfo?.packageName;
//   String? get buildNumber => _pInfo?.buildNumber;
//   String? get version => _pInfo?.version;
//   @override
//   String toString() {
//     return '$appName - $version.$buildNumber. $packageName';
//   }
// }

class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, ScopedReader watch) {
    PackageInfo.fromPlatform().then((appVersion) => debugPrint('Future: ${appVersion.appName}-${appVersion.buildNumber}-${appVersion.packageName}-${appVersion.version}'));
    final appVersionFuture = watch(applicationVersionProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      drawer: SizedBox(width: screenWidth < 500 ? screenWidth / 1.15 : 500, child: const Drawer(child: FeedView())),
      appBar: appVersionFuture.when(
          data: (appVersion) => PreferredSize(
                preferredSize: const Size.fromHeight(50),
                child: CustomAppBarWidget(appVersion),
              ),
          loading: () => AppBar(
                title: const Text('Starter...'),
                actions: const [CircularProgressIndicator()],
              ),
          error: (_, __) => AppBar(title: const Text('RSS Oversikt'))),
      body: LayoutBuilder(
          builder: (context, constraints) => constraints.maxHeight > 700
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: constraints.maxHeight / 3, child: const ArticleView()),
                    Expanded(
                        child: Stack(
                      children: [
                        DetailWidget(),
                        Positioned(right: 0, bottom: 15, child: Container(constraints: BoxConstraints.tightFor(width: TwitterWidget.TWITTER_LIST_WIDTH, height: constraints.maxHeight - constraints.maxHeight / 3 - 60), child: const TwitterWidget())),
                      ],
                    ))
                  ],
                )
              : const ArticleView()),
    );
  }
}
