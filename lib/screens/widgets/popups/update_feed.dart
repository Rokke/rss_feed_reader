import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:rss_feed_reader/models/feed_encode.dart';
import 'package:rss_feed_reader/providers/feed_list.dart';

class UpdateFeedPopup extends StatelessWidget {
  static final _log = Logger('UpdateFeedPopup');
  final FeedEncode feed;
  const UpdateFeedPopup(this.feed, {Key? key}) : super(key: key);
  static const HERO_TAG = 'popupHeroUpdateFeed';

  @override
  Widget build(BuildContext context) {
    // FeedFavData? feedFav;
    ValueNotifier<String?> favUrlChanged = ValueNotifier(null);
    TextEditingController txtUrl = TextEditingController(text: feed.url);
    TextEditingController txtTitle = TextEditingController(text: feed.title);
    TextEditingController txtFavIcon = TextEditingController(text: feed.feedFav);
    TextEditingController txtTtl = TextEditingController(text: feed.ttl.toString());
    // context.read(feedFavIdProvider(feed.id!)).whenData((data) {
    //   feedFav = data;
    //   if (data != null) valueUrl.value = txtFavIcon.text = data.url;
    // });
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
                                    valueListenable: favUrlChanged,
                                    builder: (context, String? changedUrlValue, _) {
                                      // print('refesh: $valUrl');
                                      return ElevatedButton.icon(
                                          label: Container(height: 40),
                                          style: ButtonStyle(backgroundColor: MaterialStateColor.resolveWith((states) => Colors.purple.shade700)),
                                          // color: Colors.blue,
                                          icon: changedUrlValue == null && feed.feedFav == null
                                              ? Icon(Icons.rss_feed, color: Colors.red)
                                              : Image.network(
                                                  changedUrlValue ?? feed.feedFav!,
                                                  width: 30,
                                                  fit: BoxFit.fitWidth,
                                                  errorBuilder: (err, __, ___) {
                                                    _log.warning('invalid imageurl: ${changedUrlValue ?? feed.feedFav}', err);
                                                    return Icon(Icons.error);
                                                  },
                                                ),
                                          onPressed: () {
                                            print('new: ${txtFavIcon.text}');
                                            favUrlChanged.value = txtFavIcon.text;
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
                                    onPressed: () async {
                                      if (feed.id != null && (favUrlChanged.value != null || (txtTitle.text.isNotEmpty && txtTitle.text != feed.title) || (txtTtl.text.isNotEmpty && int.tryParse(txtTtl.text) != feed.ttl))) {
                                        if (await context.read(providerFeedHeader).updateFeedInfo(feed, feedFav: favUrlChanged.value, title: txtTitle.text, url: txtUrl.text, ttl: int.tryParse(txtTtl.text))) Navigator.of(context).pop(true);
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
