import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rss_feed_reader/database/database.dart';
import 'package:rss_feed_reader/screens/widgets/category_widget.dart';
import 'package:rss_feed_reader/screens/widgets/details_widget.dart';
import 'package:rss_feed_reader/utils/misc_functions.dart';

class ArticleListItem extends ConsumerWidget {
  final ArticleData article;
  const ArticleListItem({required this.article});

  @override
  Widget build(BuildContext context, ScopedReader watch) {
    final selectedArticle = watch(detailProvider);
    try {
      return Container(
        decoration: BoxDecoration(color: selectedArticle.state?.id == article.id ? Colors.blue[900] : Colors.blue, borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(2),
        child: Card(
          color: selectedArticle.state?.id != article.id ? Colors.blue[900] : Colors.blue,
          elevation: selectedArticle.state?.id == article.id ? 0 : 10,
          child: Stack(
            children: [
              ListTile(
                leading: IconButton(icon: Icon(Icons.visibility), onPressed: () => selectedArticle.state = article),
                dense: true,
                title: Text(article.title),
                subtitle: Text(article.url ?? 'Ingen link'),
                trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      context.read(rssDatabase).changeArticleStatus(-1, article.id);
                      selectedArticle.state = null;
                    }),
              ),
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
      );
    } catch (error) {
      debugPrint('Error: $article');
      return Container(child: Text('error: $error'));
    }
  }
}
