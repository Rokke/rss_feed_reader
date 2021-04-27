import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rss_feed_reader/database/database.dart';
import 'package:rss_feed_reader/models/tweet_encoding.dart';
import 'package:rss_feed_reader/providers/network.dart';
import 'package:rss_feed_reader/providers/tweet_list.dart';

// const static YOUTUBE_RSS_URL='https://www.youtube.com/feeds/videos.xml?channel_id=';
class AddFeedPopup extends ConsumerWidget {
  const AddFeedPopup({Key? key}) : super(key: key);
  static const HERO_TAG = 'popupHeroAddFeed';

  @override
  Widget build(BuildContext context, ScopedReader watch) {
    TextEditingController txtUrl = TextEditingController();
    TextEditingController txtTwitterUserId = TextEditingController();
    TextEditingController txtTwitterUsername = TextEditingController();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Hero(
            tag: HERO_TAG,
            child: Material(
                color: Colors.purple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) => SingleChildScrollView(
                    child: Container(
                        constraints: BoxConstraints.tightFor(width: 500, height: 400),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextField(controller: txtUrl, decoration: InputDecoration(labelText: 'RSS url')),
                              if (constraints.maxWidth > 400)
                                Row(
                                  children: [
                                    Flexible(child: TextField(controller: txtTwitterUserId, decoration: InputDecoration(labelText: 'Twitter userid'))),
                                    SizedBox(width: 10),
                                    Flexible(child: TextField(controller: txtTwitterUsername, decoration: InputDecoration(labelText: 'Twitter username'))),
                                  ],
                                ),
                              Flexible(
                                child: Container(),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  ElevatedButton(child: Text('Tilbake'), onPressed: () => Navigator.pop(context, null)),
                                  if (constraints.maxWidth > 400)
                                    ElevatedButton(
                                        onPressed: () async {
                                          if (txtUrl.text.length > 10)
                                            RSSNetwork.updateFeed(context.read(rssDatabase), FeedData(title: '', url: txtUrl.text));
                                          else {
                                            TweetUserEncode? foundUser;
                                            if (txtTwitterUserId.text.length > 0 && int.tryParse(txtTwitterUserId.text) != null)
                                              foundUser = await RSSNetwork.fetchTweetUsername(id: int.parse(txtTwitterUserId.text));
                                            else if (txtTwitterUsername.text.length > 3) foundUser = await RSSNetwork.fetchTweetUsername(username: txtTwitterUsername.text);
                                            if (foundUser != null) {
                                              context.read(providerTweetHeader).addNewUser(foundUser);
                                            } else
                                              return;
                                          }
                                          Navigator.pop(
                                              context,
                                              txtUrl.text.length > 10
                                                  ? txtUrl.text
                                                  : txtTwitterUserId.text.length > 0
                                                      ? txtTwitterUserId.text
                                                      : txtTwitterUsername.text);
                                        },
                                        child: Text('Legg til RSS/Tweet userid')),
                                ],
                              ),
                            ],
                          ),
                        )),
                  ),
                ))),
      ),
    );
  }
}
