import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rss_feed_reader/providers/feed_list.dart';
import 'package:rss_feed_reader/screens/widgets/drawer_feed_list.dart';
import 'package:rss_feed_reader/screens/widgets/popups/add_feed.dart';
import 'package:rss_feed_reader/utils/popup_card.dart';

// final providerFeeds = Provider<List<FeedData>>((ref) {
//   final db = ref.watch(rssDatabase);
//   return db.feeds().first;
// });
// final selectedFeedId = StateProvider<int?>((ref) => null);
// final filterShowArticleStatus = StateProvider<int>((ref) => 0);
// final filterShowTitleText = StateProvider<String>((ref) => '');
// final selectedFeedStatusArticlesCount = StreamProvider<int>((ref) {
//   final db = ref.watch(rssDatabase);
//   final filter = ref.watch(filterShowArticleStatus);
//   return db.numberOfArticlesStatus(ref.watch(selectedFeedId).state, filter.state).watchSingle();
// });

class FeedView extends ConsumerWidget {
  const FeedView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, ScopedReader watch) {
    final feedRef = watch(providerFeedHeader);
    debugPrint('dato: ${DateTime.tryParse("2021-04-06T15:50:23+0100")}');
    return Container(
      color: Theme.of(context).appBarTheme.backgroundColor,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Container(
          constraints: BoxConstraints(maxHeight: 120),
          child: DrawerHeader(
            child: Container(
              padding: EdgeInsets.all(4),
              child: Stack(
                children: [
                  Container(constraints: BoxConstraints.expand(height: 30), child: Text('RSS Feeder', style: Theme.of(context).textTheme.headline6)),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Hero(
                      tag: AddFeedPopup.HERO_TAG,
                      child: Material(
                          child: SingleChildScrollView(
                        child: Container(
                          child: ElevatedButton.icon(
                              onPressed: () async {
                                final ret = await Navigator.of(context).push(HeroDialogRoute(builder: (context) {
                                  return AddFeedPopup();
                                }));
                                if (ret is String && ret.length > 1)
                                  Navigator.of(context).pop();
                                else
                                  debugPrint('Ugyldig valg');
                              },
                              icon: Icon(Icons.add_circle),
                              label: Text('Ny RSS/Twitter')),
                        ),
                      )),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    child: Container(
                      child: ElevatedButton.icon(
                          onPressed: () {
                            feedRef.findFeedToUpdate();
                            Navigator.pop(context);
                          },
                          icon: Icon(Icons.add_circle),
                          label: Text('Oppdater RSS')),
                    ),
                  ),
                  // Positioned(
                  //   right: 0,
                  //   child: Row(mainAxisSize: MainAxisSize.min, children: [
                  //     ElevatedButton.icon(
                  //         onPressed: () {
                  //           () async {
                  //             final amountImported = context.read(rssDatabase).importJSON('D://downloads//extract.json');
                  //             ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
                  //               content: Text('Importerte $amountImported RSS feeds'),
                  //               shape: RoundedRectangleBorder(
                  //                 borderRadius: BorderRadius.circular(10.0),
                  //               ),
                  //             ));
                  //           }();
                  //           Navigator.pop(context);
                  //         },
                  //         icon: Icon(Icons.import_contacts),
                  //         label: Text('Import RSS')),
                  //     SizedBox(width: 4),
                  //     ElevatedButton.icon(
                  //         onPressed: () {
                  //           context.read(rssDatabase).extractJSON('D://downloads//extract.json');
                  //           Navigator.pop(context);
                  //         },
                  //         icon: Icon(Icons.upload_file),
                  //         label: Text('Extract RSS')),
                  //   ]),
                  // ),
                ],
              ),
            ),
          ),
        ),
        Flexible(
            child: ValueListenableBuilder(
          valueListenable: feedRef.isInitialized,
          builder: (context, bool initialized, child) {
            return initialized ? DrawerListItems(feedRef.feeds) : CircularProgressIndicator();
          },
        )),
      ]),
    );
  }
}
