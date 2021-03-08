import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rss_feed_reader/database/database.dart';
import 'package:rss_feed_reader/screens/widgets/lists/article_list_item.dart';
import 'package:rss_feed_reader/screens/widgets/feed_widget.dart';

final articleProvider = StreamProvider<List<ArticleData>>((ref) {
  final db = ref.watch(rssDatabase);
  final selectedFeed = ref.watch(selectedFeedId);
  return db.articles(selectedFeed.state).watch();
});
// final selectedArticleIdProvider = Provider<int>((ref) => -1);

class ArticleView extends ConsumerWidget {
  const ArticleView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, ScopedReader watch) {
    final articleRef = watch(articleProvider);
    return Card(
        child: Container(
            child: articleRef.when(
                data: (articles) {
                  // final selectedId=watch(selectedArticleIdProvider);
                  return ListView.builder(
                    itemCount: articles.length,
                    itemBuilder: (BuildContext context, int index) {
                      return (articles[index].status ?? 0) >= 0
                          ? ArticleListItem(
                              article: articles[index],
                            )
                          : Container();
                    },
                  );
                },
                loading: () => CircularProgressIndicator(),
                error: (err, _) => Text('Error: $err'))));
  }
}
