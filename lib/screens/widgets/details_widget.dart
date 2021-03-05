import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rss_feed_reader/database/database.dart';
import 'package:url_launcher/url_launcher.dart';

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

  _launchURL(url) async {
    if (await canLaunch(url)) {
      print("Launching url");
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context, ScopedReader watch) {
    // final article = watch(selectedDetailProvider.state);
    final article = watch(detailProvider).state;
    debugPrint('Details build');
    return Card(
        child: Hero(
            tag: HERO_TAG,
            child: Container(
                decoration:
                    BoxDecoration(borderRadius: BorderRadius.circular(10)),
                child: (article != null)
                    ? Column(
                        children: [
                          Container(
                            margin: EdgeInsets.only(
                                top: 5, right: 5, left: 5, bottom: 15),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${article.title}',
                                  style: TextStyle(fontSize: 28),
                                ),
                                Container(
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.open_in_browser),
                                        onPressed: () =>
                                            _launchURL(article.url),
                                      ),
                                      IconButton(
                                          icon: Icon(Icons.delete),
                                          onPressed: () => context
                                              .read(rssDatabase)
                                              .changeArticleStatus(
                                                  -1, article.id)),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                          Text('${article.description}'),
                        ],
                      )
                    : Container())));
  }
}
