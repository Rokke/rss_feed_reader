import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rss_feed_reader/database/database.dart';
import 'package:rss_feed_reader/screens/widgets/details_widget.dart';
import 'package:rss_feed_reader/screens/widgets/feed_widget.dart';
import 'package:rss_feed_reader/screens/widgets/lists/article_list_item.dart';

final articleProvider = StreamProvider<List<ArticleData>>((ref) {
  final db = ref.watch(rssDatabase);
  final selectedFeed = ref.watch(selectedFeedId);
  return db.articles(selectedFeed.state).watch();
});
// final selectedArticleIdProvider = Provider<int>((ref) => -1);

class ArticleView extends ConsumerWidget {
  const ArticleView({Key? key}) : super(key: key);

  _removeArticle(BuildContext context, List<ArticleData> articles, int index) {
    final selectedIndex = context.read(selectedArticleId);
    // print('_remove: ${selectedIndex} == ${articles[index].id}');
    if (selectedIndex.state == articles[index].id) selectedIndex.state = articles.length > 1 ? articles[articles.length - 1 > index ? index + 1 : index - 1].id! : 0;
    context.read(rssDatabase).changeArticleStatus(ArticleTableStatus.READ, articles[index].id);
  }

  @override
  Widget build(BuildContext context, ScopedReader watch) {
    final articleRef = watch(articleProvider);
    return Card(
        child: Container(
            child: articleRef.when(
                data: (articles) {
                  // final selectedId=watch(selectedArticleIdProvider);
                  return (articles.length > 0) // && articles.indexWhere((element) => (element.status ?? 0) >= 0) >= 0)
                      ? ListView.builder(
                          itemCount: articles.length,
                          itemBuilder: (BuildContext context, int index) {
                            return (articles[index].status ?? 0) >= 0
                                ? ArticleListItem(
                                    article: articles[index],
                                    onRemoveArticle: () => _removeArticle(context, articles, index),
                                  )
                                : Container(child: Text('tomt'));
                          },
                        )
                      : Center(
                          child: Text(
                          'Ingen uleste RSS feed',
                          style: Theme.of(context).textTheme.headline3,
                        ));
                },
                loading: () => CircularProgressIndicator(),
                error: (err, _) => Text('Error: $err'))));
  }
}
