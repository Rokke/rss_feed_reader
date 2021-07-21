import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rss_feed_reader/providers/feed_list.dart';
import 'package:rss_feed_reader/screens/widgets/lists/article_list_item.dart';

// final articlesProvider = StreamProvider<List<ArticleData>>((ref) {
//   final db = ref.watch(rssDatabase);
//   final selectedFeed = ref.watch(selectedFeedId);
//   return db.articles(feedId: selectedFeed.state, status: ref.watch(filterShowArticleStatus).state);
// });
// final selectedArticleHelperProvider = StateProvider<SelectedArticleHelper?>((ref) => null);

class ArticleView extends ConsumerWidget {
  const ArticleView({Key? key}) : super(key: key);

  // static _changeArticleStatus(BuildContext context, List<ArticleEncode> articles, int index, StateController<SelectedArticleHelper?> selected, int status) async {
  //   debugPrint('_changeArticleStatus - selected: ${articles.length - 1 > index ? index + 1 : index - 1}, index: $index, newindex: ${articles.length - 1 > index ? index + 1 : index - 1}, length: ${articles.length}: change: ${articles[index].id}-${articles[index].title}');
  //   context.read(rssDatabase).updateArticleStatus(articleId: articles[index].id!, status: status);
  //   selected.state = articles.length - 1 <= index ? null : SelectedArticleHelper(articles[index + 1], (status) => _changeArticleStatus(context, articles, index + 1, selected, status));
  // }

  @override
  Widget build(BuildContext context, ScopedReader watch) {
    final feedProvider = context.read(providerFeedHeader);
    return Card(
        child: ValueListenableBuilder(
      valueListenable: feedProvider.isInitialized,
      builder: (context, bool initialized, child) => initialized
          ? AnimatedList(
              key: feedProvider.articleKey,
              initialItemCount: feedProvider.articles.length,
              itemBuilder: (BuildContext context, int index, animation) {
                return SizeTransition(
                    sizeFactor: animation,
                    child: ArticleListItem(
                      article: feedProvider.articles[index],
                      onRemoveArticle: () => feedProvider.changeArticleStatusByIndex(index: index),
                      onSelectedArticle: () {
                        debugPrint('onSelectedArticle: $index => ${feedProvider.articles[index].id}');
                        feedProvider.changeSelectedArticle = index;
                        // selected.state = SelectedArticleHelper(articles[index], (int status) => _changeArticleStatus(context, articles, index, selected, status));
                      },
                    ));
              },
            )
          : Center(
              child: Text(
              'Ingen uleste RSS feed',
              style: Theme.of(context).textTheme.headline3,
            )),
    ));
  }
}
