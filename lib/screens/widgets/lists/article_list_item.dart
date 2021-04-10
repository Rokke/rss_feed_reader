import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rss_feed_reader/database/database.dart';
import 'package:rss_feed_reader/models/selected_article_helper.dart';
import 'package:rss_feed_reader/screens/widgets/article_widget.dart';
import 'package:rss_feed_reader/screens/widgets/category_widget.dart';
import 'package:rss_feed_reader/screens/widgets/details_widget.dart';
import 'package:rss_feed_reader/utils/misc_functions.dart';

// final rssLinkImageCache = StreamProvider<List<FeedFavData>>((ref) {
//   final db = ref.watch(rssDatabase);
//   return db.fetchFeedFavorites().watch();
// });
// final rssLinkStateProvider = StateProvider<List<FeedFavData>?>((ref) {
//   ref.watch(rssLinkImageCache).when(data: (data) => data, loading: () => null, error: (_, __) => null);
// });
final feedFavIdProvider = StreamProviderFamily<FeedFavData?, int>((ref, feedId) {
  return ref.watch(rssDatabase).fetchFavForFeed(feedId);
});

class ArticleListItem extends ConsumerWidget {
  final ArticleData article;
  final Function() onRemoveArticle;
  final Function() onSelectedArticle;
  final bool isSelected;
  const ArticleListItem({required this.article, required this.isSelected, required this.onRemoveArticle, required this.onSelectedArticle});

  @override
  Widget build(BuildContext context, ScopedReader watch) {
    // final selectedArticleData = watch(selectedArticleIndexProvider);
    // final isSelected = context.read(selectedArticleDataProvider).state?.id == article.id;
    final favImage = watch(feedFavIdProvider(article.parent));
    try {
      return Dismissible(
        key: Key(article.id.toString()),
        onDismissed: (direction) => onRemoveArticle(), //_removeArticle(context, selectedArticle, isSelected),
        child: Container(
          decoration: BoxDecoration(color: isSelected ? Colors.blue[900] : Colors.blue, borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.all(2),
          child: Card(
            color: isSelected ? Colors.blue[800] : Colors.blue,
            elevation: isSelected ? 0 : 10,
            child: Stack(
              children: [
                ListTile(
                    leading: IconButton(
                      icon: favImage.when(
                          data: (fav) => fav != null
                              ? CachedNetworkImage(
                                  imageUrl: fav.url,
                                  fit: BoxFit.fitWidth,
                                  alignment: Alignment.center,
                                  width: 30,
                                  errorWidget: (_, __, ___) => Container(),
                                )
                              : Icon(Icons.visibility),
                          loading: () => Icon(Icons.cloud_download_outlined),
                          error: (error, _) {
                            return Icon(Icons.error);
                          }),
                      onPressed: isSelected ? null : () => onSelectedArticle(),
                    ), // selectedArticleIndex.state = isSelected ? -1 : index),
                    dense: true,
                    title: Text(article.title),
                    subtitle: Text(article.url ?? 'Ingen link'),
                    trailing: IconButton(
                      icon: article.status == ArticleTableStatus.FAVORITE ? Icon(Icons.favorite, color: Colors.red) : Icon(article.status == ArticleTableStatus.READ ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => article.status != ArticleTableStatus.UNREAD ? context.read(rssDatabase).updateArticleStatus(articleId: article.id!, status: ArticleTableStatus.UNREAD) : onRemoveArticle(),
                    )),
                if (article.category != null) Positioned(right: 50, top: 0, child: Wrap(children: article.category!.split(',').map((e) => CategoryWidget(article.id!, e)).toList())),
                if (article.pubDate != null)
                  Positioned(
                    right: 50,
                    bottom: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      margin: EdgeInsets.all(2),
                      decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(3)),
                      child: Text(dateTimeFormat(DateTime.fromMillisecondsSinceEpoch(article.pubDate!))),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    } catch (error) {
      debugPrint('Error: $article');
      return Container(child: Text('error: $error'));
    }
  }
}
