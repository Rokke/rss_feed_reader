import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rss_feed_reader/database/database.dart';

final detailProvider = StateProvider<ArticleData?>((ref) => null);
// final selectedDetailProvider = StateNotifierProvider((ref) => SelectedDetail());

class SelectedDetail extends StateNotifier<ArticleData> {
  SelectedDetail() : super(ArticleData(parent: 0, title: '', guid: ''));
  changeSelected(ArticleData articleData) {
    debugPrint('change article');
    state = articleData.copyWith();
  }
}

class DetailWidget extends ConsumerWidget {
  static const String HERO_TAG = 'detailSelectedHero';
  // final int articleId;
  const DetailWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, ScopedReader watch) {
    // final article = watch(selectedDetailProvider.state);
    final article = watch(detailProvider).state;
    debugPrint('Details build');
    return Card(child: Hero(tag: HERO_TAG, child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)), child: (article != null) ? Text('${article.description}') : Container())));
  }
}
