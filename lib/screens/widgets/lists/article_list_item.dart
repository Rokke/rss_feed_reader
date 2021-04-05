import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rss_feed_reader/database/database.dart';
import 'package:rss_feed_reader/screens/widgets/category_widget.dart';
import 'package:rss_feed_reader/screens/widgets/details_widget.dart';
import 'package:rss_feed_reader/utils/misc_functions.dart';

class ArticleListItem extends ConsumerWidget {
  final ArticleData article;
  final Function() onRemoveArticle;
  const ArticleListItem({required this.article, required this.onRemoveArticle});

  @override
  Widget build(BuildContext context, ScopedReader watch) {
    final selectedArticle = watch(selectedArticleId);
    final isSelected = selectedArticle.state != article.id;
    try {
      return Dismissible(
        key: Key(article.id.toString()),
        onDismissed: (direction) => onRemoveArticle(), //_removeArticle(context, selectedArticle, isSelected),
        child: Container(
          decoration: BoxDecoration(color: selectedArticle.state == article.id ? Colors.blue[900] : Colors.blue, borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.all(2),
          child: Card(
            color: isSelected ? Colors.blue[900] : Colors.blue,
            elevation: selectedArticle.state == article.id ? 0 : 10,
            child: Stack(
              children: [
                ListTile(
                    leading: IconButton(icon: Icon(Icons.visibility), onPressed: () => selectedArticle.state = article.id!),
                    dense: true,
                    title: Text(article.title),
                    subtitle: Text(article.url ?? 'Ingen link'),
                    trailing: IconButton(
                      icon: article.status == ArticleTableStatus.FAVORITE ? Icon(Icons.favorite, color: Colors.red) : Icon(Icons.delete),
                      onPressed: () => article.status == ArticleTableStatus.FAVORITE ? context.read(rssDatabase).changeArticleStatus(ArticleTableStatus.UNREAD, article.id) : onRemoveArticle(),
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
