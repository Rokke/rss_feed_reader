import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:moor/moor.dart' as moor;
// import 'package:moor/moor.dart';
import 'package:rss_feed_reader/database/database.dart';
import 'package:rss_feed_reader/screens/widgets/lists/article_list_item.dart';

class UpdateFeedPopup extends ConsumerWidget {
  static final _log = Logger('UpdateFeedPopup');
  final FeedData feed;
  const UpdateFeedPopup(this.feed, {Key? key}) : super(key: key);
  static const HERO_TAG = 'popupHeroUpdateFeed';

  @override
  Widget build(BuildContext context, ScopedReader watch) {
    FeedFavData? feedFav;
    ValueNotifier<String?> valueUrl = ValueNotifier(null);
    TextEditingController txtUrl = TextEditingController(text: feed.url);
    TextEditingController txtTitle = TextEditingController(text: feed.title);
    TextEditingController txtFavIcon = TextEditingController();
    TextEditingController txtTtl = TextEditingController(text: feed.ttl != null ? feed.ttl.toString() : '');
    context.read(feedFavIdProvider(feed.id!)).whenData((data) {
      feedFav = data;
      if (data != null) valueUrl.value = txtFavIcon.text = data.url;
    });
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Hero(
            tag: HERO_TAG + feed.id.toString(),
            child: Material(
                color: Colors.purple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: SingleChildScrollView(
                  child: Container(
                      constraints: BoxConstraints.tightFor(width: 600, height: 500),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(controller: txtUrl, decoration: InputDecoration(labelText: 'RSS url')),
                            TextField(controller: txtTitle, decoration: InputDecoration(labelText: 'Tittel')),
                            Row(
                              children: [
                                Expanded(child: TextField(controller: txtFavIcon, decoration: InputDecoration(labelText: 'FavIcon'))),
                                ValueListenableBuilder(
                                    valueListenable: valueUrl,
                                    builder: (context, String? valUrl, _) {
                                      // print('refesh: $valUrl');
                                      return ElevatedButton.icon(
                                          label: Container(height: 40),
                                          style: ButtonStyle(backgroundColor: MaterialStateColor.resolveWith((states) => Colors.purple.shade700)),
                                          // color: Colors.blue,
                                          icon: valUrl != null
                                              ? (valUrl.isEmpty
                                                  ? Icon(Icons.rss_feed, color: Colors.red)
                                                  : Image.network(
                                                      valUrl,
                                                      width: 30,
                                                      fit: BoxFit.fitWidth,
                                                      errorBuilder: (err, __, ___) {
                                                        _log.warning('invalid imageurl: $valUrl', err);
                                                        return Icon(Icons.error);
                                                      },
                                                    ))
                                              : Icon(Icons.download_sharp),
                                          onPressed: () {
                                            print('new: ${txtFavIcon.text}');
                                            valueUrl.value = txtFavIcon.text;
                                          });
                                    }),
                              ],
                            ),
                            TextField(controller: txtTtl, decoration: InputDecoration(labelText: 'TTL')),
                            Expanded(child: Container()),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ElevatedButton(onPressed: () => Navigator.pop(context, null), child: Text('Avbryt')),
                                ElevatedButton(
                                    onPressed: () {
                                      if (valueUrl.value != null && feed.id != null) {
                                        () async {
                                          // print('save: ${valueUrl.value} <> ${feedFav?.url}');
                                          final db = context.read(rssDatabase);
                                          if (feedFav?.id == null)
                                            await db.into(db.feedFav).insert(FeedFavCompanion.insert(feedId: feed.id!, url: valueUrl.value!));
                                          else if (valueUrl.value != feedFav?.url) await db.updateFeedFav(feedFav!.id!, FeedFavCompanion(url: moor.Value(valueUrl.value!)));
                                          Navigator.pop(
                                              context,
                                              FeedCompanion(
                                                title: txtTitle.text != feed.title ? moor.Value(txtTitle.text) : moor.Value.absent(),
                                                url: txtUrl.text != feed.url ? moor.Value(txtUrl.text) : moor.Value.absent(),
                                                ttl: int.tryParse(txtTtl.text) != null ? moor.Value(int.tryParse(txtTtl.text)) : moor.Value.absent(),
                                                id: moor.Value(feed.id!),
                                              ));
                                          // print('ok');
                                        }();
                                      }
                                    },
                                    child: Text('Lagre')),
                              ],
                            ),
                          ],
                        ),
                      )),
                ))),
      ),
    );
  }
}
