import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rss_feed_reader/database/database.dart';

final selectedArticleProvider = StreamProvider.autoDispose.family<ArticleData, int>((ref, _id) {
  final db = ref.watch(rssDatabase);
  return (db.select(db.article)..where((tbl) => tbl.id.equals(_id))).getSingle().asStream();
});

class ArticleListItem extends ConsumerWidget {
  final int articleId;
  const ArticleListItem({required this.articleId});

  @override
  Widget build(BuildContext context, ScopedReader watch) {
    final articleRef = watch(selectedArticleProvider(articleId));
    return articleRef.when(
        data: (article) => ListTile(
              dense: true,
              title: Text(article.title),
              subtitle: Text(article.url ?? 'Ingen link'),
            ),
        loading: () => ListTile(leading: const CircularProgressIndicator(), title: const Text('Laster inn...')),
        error: (error, _) => ListTile(title: Text('Feil: $error')));
  }
}
