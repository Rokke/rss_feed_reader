import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rss_feed_reader/database/database.dart';
import 'package:rss_feed_reader/models/selected_article_helper.dart';
import 'package:rss_feed_reader/screens/widgets/feed_widget.dart';
import 'package:rss_feed_reader/screens/widgets/lists/article_list_item.dart';

final articlesProvider = StreamProvider<List<ArticleData>>((ref) {
  final db = ref.watch(rssDatabase);
  final selectedFeed = ref.watch(selectedFeedId);
  return db.articles(feedId: selectedFeed.state, status: ref.watch(filterShowArticleStatus).state);
});
final selectedArticleHelperProvider = StateProvider<SelectedArticleHelper?>((ref) => null);

class ArticleView extends ConsumerWidget {
  const ArticleView({Key? key}) : super(key: key);

  static _changeArticleStatus(BuildContext context, List<ArticleData> articles, int index, StateController<SelectedArticleHelper?> selected, int status) async {
    final newIndex = articles.length - 1 > index ? index + 1 : index - 1;
    selected.state = articles.length <= 1 ? null : SelectedArticleHelper(articles[newIndex], (status) => _changeArticleStatus(context, articles, newIndex, selected, status));
    context.read(rssDatabase).updateArticleStatus(articleId: articles[index].id!, status: status);
  }

  @override
  Widget build(BuildContext context, ScopedReader watch) {
    final articleRef = watch(articlesProvider);
    return Card(
        child: Container(
            child: articleRef.when(
                data: (articles) {
                  return (articles.length > 0) // && articles.indexWhere((element) => (element.status ?? 0) >= 0) >= 0)
                      ? ListView.builder(
                          itemCount: articles.length,
                          itemBuilder: (BuildContext context, int index) {
                            return Consumer(
                              builder: (context, itemwatch, _) {
                                final selected = itemwatch(selectedArticleHelperProvider);
                                return ArticleListItem(
                                  article: articles[index],
                                  isSelected: articles[index].id == selected.state?.articleData?.id,
                                  onRemoveArticle: () => _changeArticleStatus(context, articles, index, selected, ArticleTableStatus.READ),
                                  onSelectedArticle: () {
                                    debugPrint('onSelectedArticle: $index');
                                    selected.state = SelectedArticleHelper(articles[index], (int status) => _changeArticleStatus(context, articles, index, selected, status));
                                  },
                                );
                              },
                            );
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
