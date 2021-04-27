import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rss_feed_reader/database/database.dart';
import 'package:rss_feed_reader/screens/widgets/article_widget.dart';
import 'package:rss_feed_reader/utils/misc_functions.dart';

class DetailWidget extends ConsumerWidget {
  const DetailWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, ScopedReader watch) {
    final selectedArticleData = watch(selectedArticleHelperProvider);
    debugPrint('Details build');
    return Card(
        child: Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
            child: (selectedArticleData.state?.articleData != null)
                ? RawKeyboardListener(
                    focusNode: FocusNode(),
                    autofocus: true,
                    onKey: (RawKeyEvent event) {
                      if (event.logicalKey == LogicalKeyboardKey.delete && event.runtimeType.toString() == 'RawKeyDownEvent' && selectedArticleData.state!.articleData!.status == ArticleTableStatus.UNREAD) selectedArticleData.state!.onStatusChanged(ArticleTableStatus.READ);
                    },
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Container(
                        color: Colors.blue[800],
                        padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(color: Colors.purple[900], padding: EdgeInsets.all(4), child: Text('${selectedArticleData.state!.articleData!.id}')),
                            Flexible(
                              child: Text(
                                '${selectedArticleData.state!.articleData!.title}',
                                style: Theme.of(context).textTheme.headline6,
                              ),
                            ),
                            Container(
                              child: Row(
                                children: [
                                  if (selectedArticleData.state!.articleData!.url != null)
                                    IconButton(
                                      icon: Icon(Icons.open_in_browser),
                                      onPressed: () => launchURL(selectedArticleData.state!.articleData!.url!),
                                    ),
                                  IconButton(
                                      icon: Icon(
                                        Icons.favorite,
                                        color: selectedArticleData.state!.articleData!.status == ArticleTableStatus.FAVORITE ? Colors.red : null,
                                      ),
                                      onPressed: () {
                                        selectedArticleData.state!.onStatusChanged(selectedArticleData.state!.articleData!.status != ArticleTableStatus.FAVORITE ? ArticleTableStatus.FAVORITE : ArticleTableStatus.UNREAD);
                                      }),
                                  IconButton(
                                      icon: Icon(
                                        selectedArticleData.state!.articleData!.status == ArticleTableStatus.READ ? Icons.visibility_off : Icons.visibility,
                                        color: selectedArticleData.state!.articleData!.status == ArticleTableStatus.READ ? Colors.green : null,
                                      ),
                                      onPressed: () {
                                        selectedArticleData.state!.onStatusChanged(selectedArticleData.state!.articleData!.status != ArticleTableStatus.READ ? ArticleTableStatus.READ : ArticleTableStatus.UNREAD);
                                      }),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                      Expanded(
                          child: Container(
                        padding: EdgeInsets.all(5),
                        child: selectedArticleData.state!.articleData!.description != null
                            ? SingleChildScrollView(child: Html(data: selectedArticleData.state!.articleData!.description!))
                            : Center(
                                child: Text(
                                'Ingen beskrivelse',
                                style: Theme.of(context).textTheme.headline3,
                              )),
                      )),
                      Container(
                        color: Colors.purple[900],
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            (selectedArticleData.state!.articleData!.creator != null) ? Text("${selectedArticleData.state!.articleData!.creator}", overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12)) : Text("N/A", style: TextStyle(fontSize: 12)),
                            Flexible(child: (selectedArticleData.state!.articleData!.category != null) ? Text("${selectedArticleData.state!.articleData!.category}", overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12)) : Text("N/A", style: TextStyle(fontSize: 12))),
                            (selectedArticleData.state!.articleData!.pubDate != null)
                                ? Text(dateTimeFormat(DateTime.fromMillisecondsSinceEpoch(selectedArticleData.state!.articleData!.pubDate!)), overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12))
                                : Text("N/A", style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ]),
                  )
                : Center(
                    child: Text(
                    'Ingen artikkel valgt',
                    style: Theme.of(context).textTheme.headline3,
                  ))));
  }
}
