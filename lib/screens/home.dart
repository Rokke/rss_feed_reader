import 'package:flutter/material.dart';
import 'package:rss_feed_reader/database/database.dart';
import 'package:rss_feed_reader/models/rss_tree.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rss_feed_reader/screens/widgets/article_widget.dart';
import 'package:rss_feed_reader/screens/widgets/details_widget.dart';
import 'package:rss_feed_reader/screens/widgets/feed_widget.dart';

class HomeScreen extends ConsumerWidget {
  _toggleStartStop(BuildContext context) {
    debugPrint('_toggleStartStop()');
    context.read(rssProvider);
  }

  @override
  Widget build(BuildContext context, ScopedReader watch) {
    return Scaffold(
      drawer: Drawer(child: FeedView()),
      appBar: AppBar(
        title: Text('RSS Oversikt'),
        actions: [IconButton(icon: Icon(Icons.play_arrow), onPressed: () => _toggleStartStop(context)), IconButton(icon: Icon(Icons.hot_tub), onPressed: () => watch(rssDatabase).createTestData())],
      ),
      body: LayoutBuilder(
          builder: (context, constraints) => constraints.maxWidth > 1000
              ? Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  // SizedBox(width: 250, child: FeedView()),
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [Expanded(child: ArticleView()), SizedBox(height: 400, child: DetailWidget())],
                  )),
                ])
              : ArticleView()),
    );
  }
}
