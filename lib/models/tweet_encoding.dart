import 'package:moor/moor.dart';
import 'package:rss_feed_reader/database/database.dart';

class TweetEncode {
  final int id, tweetUserId;
  final String text;
  final DateTime created_at;
  final List<TweetReferencedTweet> referenced_tweets;

  TweetEncode({required this.id, required this.tweetUserId, required this.text, required this.created_at, this.referenced_tweets = const []});
  factory TweetEncode.fromJSON(int tweetUserId, Map<String, dynamic> json) => TweetEncode(
        id: int.parse(json['id']),
        tweetUserId: tweetUserId,
        text: json['text'],
        created_at: DateTime.parse(json['created_at']),
        referenced_tweets: json['referenced_tweets'] is List ? (json['referenced_tweets'] as List).map((e) => TweetReferencedTweet.fromJSON(e)).toList() : [],
      );
  bool get isReply => referenced_tweets.any((element) => element.type == 'replied_to');
  bool get isRetweeted => referenced_tweets.any((element) => element.type == 'retweeted');
  @override
  String toString() {
    return 'TweetEncode($id,$tweetUserId,$text,$created_at,$referenced_tweets)';
  }
}

class TweetReferencedTweet {
  final int id;
  final String type;

  TweetReferencedTweet({required this.id, required this.type});
  factory TweetReferencedTweet.fromJSON(Map<String, dynamic> json) => TweetReferencedTweet(id: int.parse(json['id']), type: json['type']);
  @override
  String toString() {
    return 'TweetReferencedTweet($id,$type)';
  }
}

class TweetUserEncode {
  int? id;
  final int tweetUserId;
  final String username, name, profile_image_url;
  int lastCheck = 0;

  TweetUserEncode({this.id, required this.tweetUserId, required this.username, required this.name, this.profile_image_url = ''});
  factory TweetUserEncode.fromJSON(Map<String, dynamic> json) => TweetUserEncode(tweetUserId: int.parse(json['id']), username: json['username'], name: json['name'], profile_image_url: json['profile_image_url']);
  factory TweetUserEncode.fromDB(TweetUserData userData) => TweetUserEncode(id: userData.id!, tweetUserId: userData.tweetUserId, username: userData.username, name: userData.name, profile_image_url: userData.profileUrl ?? '');
  TweetUserCompanion toTweetUserCompanionInsert() => TweetUserCompanion.insert(tweetUserId: tweetUserId, username: username, name: name, profileUrl: Value(profile_image_url));
  @override
  String toString() {
    return 'TweetUserEncode($id,$tweetUserId,$username,$name,$lastCheck)';
  }
}
