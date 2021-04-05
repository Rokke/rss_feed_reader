import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rss_feed_reader/database/database.dart';
import 'package:rss_feed_reader/screens/widgets/article_widget.dart';
import 'package:rss_feed_reader/screens/widgets/details_widget.dart';
import 'package:rss_feed_reader/screens/widgets/feed_widget.dart';
import 'package:rss_feed_reader/screens/widgets/monitor_button.dart';

class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, ScopedReader watch) {
    return Scaffold(
      drawer: Container(width: MediaQuery.of(context).size.width / 1.25, child: Drawer(child: FeedView())),
      appBar: AppBar(
        title: Text('RSS Oversikt'),
        actions: [MonitorButton(), IconButton(icon: Icon(Icons.hot_tub), onPressed: () => watch(rssDatabase).createTestData())],
      ),
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
