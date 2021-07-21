import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:rss_feed_reader/database/database.dart';
import 'package:rss_feed_reader/models/feed_encode.dart';
import 'package:rss_feed_reader/providers/feed_list.dart';
import 'package:rss_feed_reader/screens/widgets/twitter_widget.dart';
import 'package:rss_feed_reader/utils/misc_functions.dart';

final providerErrorReported = StateProvider<String?>((ref) => null);

class DetailWidget extends StatelessWidget {
  final _log = Logger('DetailWidget');
  DetailWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    debugPrint('Details build');
    final feedProvider = context.read(providerFeedHeader);
    return Card(
        child: Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
            child: ValueListenableBuilder(
                valueListenable: feedProvider.selectedArticleIndexNotifier,
                builder: (context, int selectedIndex, child) => selectedIndex >= 0
                    ? RawKeyboardListener(
                        focusNode: FocusNode(),
                        autofocus: true,
                        onKey: (RawKeyEvent event) {
                          if (event.logicalKey == LogicalKeyboardKey.delete && event.runtimeType.toString() == 'RawKeyDownEvent') feedProvider.changeArticleStatusByIndex(index: selectedIndex);
                        },
                        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          Container(
                            color: Colors.blue[800],
                            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(color: Colors.purple[900], padding: const EdgeInsets.all(4), child: Text('${feedProvider.selectedArticle!.id}')),
                                Flexible(
                                  child: Text(
                                    feedProvider.selectedArticle!.title,
                                    style: Theme.of(context).textTheme.headline6,
                                  ),
                                ),
                                Row(
                                  children: [
                                    ValueListenableBuilder(
                                      valueListenable: feedProvider.hasUndoItem,
                                      builder: (_, bool hasUndo, __) => IconButton(
                                        icon: const Icon(Icons.undo),
                                        onPressed: hasUndo ? () => feedProvider.unreadLastItem() : null,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.open_in_browser),
                                      onPressed: () => launchURL(feedProvider.selectedArticle!.url),
                                    ),
                                    IconButton(
                                        icon: Icon(
                                          Icons.favorite,
                                          color: feedProvider.status == ArticleTableStatus.FAVORITE ? Colors.red : null,
                                        ),
                                        onPressed: () {
                                          feedProvider.changeArticleStatusByIndex(index: selectedIndex, newStatus: feedProvider.status != ArticleTableStatus.FAVORITE ? ArticleTableStatus.FAVORITE : ArticleTableStatus.UNREAD);
                                        }),
                                    IconButton(
                                        icon: Icon(
                                          feedProvider.status == ArticleTableStatus.READ ? Icons.visibility_off : Icons.visibility,
                                          color: feedProvider.status == ArticleTableStatus.READ ? Colors.green : null,
                                        ),
                                        onPressed: () {
                                          feedProvider.changeArticleStatusByIndex(index: selectedIndex, newStatus: feedProvider.status != ArticleTableStatus.READ ? ArticleTableStatus.READ : ArticleTableStatus.UNREAD);
                                        }),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                              child: Container(
                                  padding: const EdgeInsets.only(left: 5, right: TwitterWidget.TWITTER_LIST_WIDTH - 30, top: 5, bottom: 5),
                                  child: FutureBuilder(
                                    future: feedProvider.selectedArticle!.articleDescription(context.read(rssDatabase)),
                                    initialData: null,
                                    builder: (BuildContext context, AsyncSnapshot snapshot) {
                                      try {
                                        return !snapshot.hasData
                                            ? const CircularProgressIndicator()
                                            : snapshot.data is String
                                                ? SingleChildScrollView(
                                                    // child: Text(snapshot.data)
                                                    child: Html(
                                                      data: snapshot.data as String,
                                                      onImageError: (err, obj) {
                                                        context.read(providerErrorReported).state = 'onImageError(): $err';
                                                        _log.warning('onImageError(${feedProvider.selectedArticle!.id})=>$obj', err);
                                                      },
                                                      onMathError: (str1, str2, str3) {
                                                        context.read(providerErrorReported).state = 'onMathError()';
                                                        _log.warning('onMathError(${feedProvider.selectedArticle!.id})=>$str1,$str2,$str3');
                                                        return Container(constraints: const BoxConstraints.tightFor(width: 20, height: 20), color: Colors.red);
                                                      },
                                                    ),
                                                  )
                                                : Center(
                                                    child: Text(
                                                    'Ingen beskrivelse',
                                                    style: Theme.of(context).textTheme.headline3,
                                                  ));
                                      } catch (err) {
                                        _log.severe('Error rendering text');
                                        return SingleChildScrollView(child: Text('No data: ${snapshot.data}'));
                                      }
                                    },
                                  ))),
                          Container(
                            color: Colors.purple[900],
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                if (feedProvider.selectedArticle!.creator != null) Text(feedProvider.selectedArticle!.creator!, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)) else const Text('N/A', style: TextStyle(fontSize: 12)),
                                Flexible(child: (feedProvider.selectedArticle!.category != null) ? Text(feedProvider.selectedArticle!.category!, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)) : const Text('N/A', style: TextStyle(fontSize: 12))),
                                Text(dateTimeFormat(DateTime.fromMillisecondsSinceEpoch(feedProvider.selectedArticle!.pubDate)), overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        ]),
                      )
                    : Center(
                        child: Text(
                        'Ingen artikkel valgt',
                        style: Theme.of(context).textTheme.headline3,
                      )))));
  }
}
