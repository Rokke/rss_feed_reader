import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rss_feed_reader/database/database.dart';
import 'package:rss_feed_reader/utils/misc_functions.dart';
import 'package:url_launcher/url_launcher.dart';

final selectedArticleId = StateProvider<int>((ref) => 0);
final detailProvider = StreamProvider<ArticleData?>((ref) {
  final selectedId = ref.watch(selectedArticleId);
  if (selectedId.state > 0) {
    return ref.read(rssDatabase).fetchArticle(selectedId.state).watchSingleOrNull();
  }
  return Stream.value(null); // as Future<ArticleData>;
});
// final selectedDetailProvider = StateNotifierProvider((ref) => SelectedDetail());

/* class SelectedDetail extends StateNotifier<ArticleData> {
  SelectedDetail() : super(ArticleData(parent: 0, title: '', guid: ''));
  changeSelected(ArticleData articleData) {
    debugPrint('change article');
    state = articleData.copyWith();
  }
}
 */
class DetailWidget extends ConsumerWidget {
  // static const String HERO_TAG = 'detailSelectedHero';
  // final int articleId;
  const DetailWidget({Key? key}) : super(key: key);

  _launchURL(url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context, ScopedReader watch) {
    // final article = watch(selectedDetailProvider.state);
    final articleProvider = watch(detailProvider);
    // final found = watch(rssDatabase).articles(article.id).watchSingle();
    debugPrint('Details build');
    return articleProvider.when(
      data: (article) {
        return Card(
            child: Container(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
                child: (article != null)
                    ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Container(
                          color: Colors.blue[800],
                          padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
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
                                      onPressed: () => _launchURL(article.url),
                                    ),
                                    IconButton(
                                        icon: Icon(
                                          Icons.favorite,
                                          color: article.status == ArticleTableStatus.FAVORITE ? Colors.red : null,
                                        ),
                                        onPressed: () {
                                          context.read(rssDatabase).changeArticleStatus(article.status != ArticleTableStatus.FAVORITE ? ArticleTableStatus.FAVORITE : ArticleTableStatus.UNREAD, article.id);
                                          // context.read(detailProvider).state = context.read(detailProvider).state;
                                        }),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                        Expanded(
                            child: Container(
                          // constraints: BoxConstraints.expand(),
                          padding: EdgeInsets.all(5),
                          child: SingleChildScrollView(child: Html(data: article.description!)),
                        )),
                        Container(
                          color: Colors.purple[900],
                          // constraints: BoxConstraints.expand(height: 200),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              (article.creator != null) ? Text("${article.creator}", style: TextStyle(fontSize: 12)) : Text("Atricle creator N/A", style: TextStyle(fontSize: 12)),
                              (article.category != null) ? Text("${article.category}", style: TextStyle(fontSize: 12)) : Text("Article category N/A", style: TextStyle(fontSize: 12)),
                              (article.pubDate != null) ? Text(dateTimeFormat(DateTime.fromMillisecondsSinceEpoch(article.pubDate!)), style: TextStyle(fontSize: 12)) : Text("Pusblish date N/A", style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      ])
                    : Center(
                        child: Text(
                        'Ingen artikkel valgt',
                        style: Theme.of(context).textTheme.headline3,
                      ))));
      },
      loading: () => Container(child: Text('loading')),
      error: (err, stack) => Container(child: Text('error: $err, $stack')),
    );
  }
}
