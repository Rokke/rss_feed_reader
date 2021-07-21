import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:news_common/tweet_encode.dart';
import 'package:rss_feed_reader/providers/feed_list.dart';
import 'package:rss_feed_reader/providers/tweet_list.dart';

// const static YOUTUBE_RSS_URL='https://www.youtube.com/feeds/videos.xml?channel_id=';
class AddFeedPopup extends StatelessWidget {
  const AddFeedPopup({Key? key}) : super(key: key);
  static const HERO_TAG = 'popupHeroAddFeed';

  @override
  Widget build(BuildContext context) {
    final txtUrl = TextEditingController(), txtTwitterUserId = TextEditingController(), txtTwitterUsername = TextEditingController();
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
                        constraints: const BoxConstraints.tightFor(width: 500, height: 400),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextField(controller: txtUrl, decoration: const InputDecoration(labelText: 'RSS url')),
                              if (constraints.maxWidth > 400)
                                Row(
                                  children: [
                                    Flexible(child: TextField(controller: txtTwitterUserId, decoration: const InputDecoration(labelText: 'Twitter userid'))),
                                    const SizedBox(width: 10),
                                    Flexible(child: TextField(controller: txtTwitterUsername, decoration: const InputDecoration(labelText: 'Twitter username'))),
                                  ],
                                ),
                              Flexible(
                                child: Container(),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  ElevatedButton(onPressed: () => Navigator.pop(context, null), child: const Text('Tilbake')),
                                  if (constraints.maxWidth > 400)
                                    ElevatedButton(
                                        onPressed: () async {
                                          if (txtUrl.text.length > 10) {
                                            final feedProvider = context.read(providerFeedHeader);
                                            await feedProvider.updateOrCreateFeed(null, url: txtUrl.text);
                                          } else {
                                            TweetUserEncode? foundUser;
                                            final tweetHead = context.read(providerTweetHeader);
                                            if (txtTwitterUserId.text.isNotEmpty && int.tryParse(txtTwitterUserId.text) != null) {
                                              foundUser = await tweetHead.fetchTweetUsername(id: int.parse(txtTwitterUserId.text));
                                            } else if (txtTwitterUsername.text.length > 3) foundUser = await tweetHead.fetchTweetUsername(username: txtTwitterUsername.text);
                                            if (foundUser != null) {
                                              tweetHead.addNewUser(foundUser);
                                            } else {
                                              return;
                                            }
                                          }
                                          Navigator.pop(
                                              context,
                                              txtUrl.text.length > 10
                                                  ? txtUrl.text
                                                  : txtTwitterUserId.text.isNotEmpty
                                                      ? txtTwitterUserId.text
                                                      : txtTwitterUsername.text);
                                        },
                                        child: const Text('Legg til RSS/Tweet userid')),
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
