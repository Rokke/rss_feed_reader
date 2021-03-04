import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rss_feed_reader/database/database.dart';
import 'package:rss_feed_reader/screens/widgets/lists/article_list_item.dart';

final articleProvider = StreamProvider<List<ArticleData>>((ref) {
  final db = ref.watch(rssDatabase);
  return db.articles().watch();
});

class ArticleView extends ConsumerWidget {
  const ArticleView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, ScopedReader watch) {
    final articleRef = watch(articleProvider);
    return Card(
        child: Container(
            child: articleRef.when(
                data: (articles) => ListView.builder(
                      itemCount: articles.length,
                      itemBuilder: (BuildContext context, int index) {
                        return (articles[index].status ?? 0) >= 0 ? ArticleListItem(articleId: articles[index].id!) : Container();
                      },
                    ),
                loading: () => CircularProgressIndicator(),
                error: (err, _) => Text('Error: $err'))));
  }
}
