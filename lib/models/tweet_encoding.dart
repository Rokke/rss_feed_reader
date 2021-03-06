import 'package:flutter/material.dart';
import 'package:moor/moor.dart';
import 'package:collection/collection.dart';
import 'package:rss_feed_reader/database/database.dart';

class TweetEncode {
  final int id; //, tweetUserId;
  final String text;
  final DateTime created_at;
  TweetEncode? retweet;
  // final List<TweetReferencedTweet> referenced_tweets;
  TweetUserEncode parentUser;

  TweetEncode({required this.id, required this.parentUser, required this.text, required this.created_at});
  factory TweetEncode.fromJSON(TweetUserEncode parentUser, Map<String, dynamic> data, List<TweetEncode>? linkedTweets) {
    try {
      // if (parentUser == null) ;
      final refTweet = data['referenced_tweets'];
      final ret = TweetEncode(
        id: int.parse(data['id']),
        parentUser: parentUser,
        text: data['text'],
        created_at: DateTime.parse(data['created_at']),
      );
      if (refTweet is List) {
        final referencedTweet = refTweet.map<TweetReferencedTweet>((ref) => TweetReferencedTweet.fromJSON(ref)).firstWhereOrNull((f) => f.isRetweet);
        debugPrint('refTweet: $refTweet => $referencedTweet => ${referencedTweet?.id != null ? (linkedTweets?.firstWhereOrNull((l) => l.id == referencedTweet?.id)) ?? linkedTweets : 'N/A'}');
        if (referencedTweet != null) ret.retweet = linkedTweets?.firstWhereOrNull((l) => l.id == referencedTweet.id);
      }
      return ret;
    } catch (err) {
      debugPrint('TweetEncode.fromJSON exception: $data');
      throw err;
    }
  }
  // bool get isReply => referenced_tweets.any((element) => element.type == 'replied_to');
  bool get isRetweet => retweet != null;
  // int get firstRetweetId => referenced_tweets.indexWhere((element) => element.type == 'retweeted');
  @override
  String toString() {
    return 'TweetEncode($id,${parentUser.tweetUserId},$text,$created_at,${retweet?.id})';
  }
}

class TweetRetweet {}

class TweetReferencedTweet {
  final int id;
  final String type;

  TweetReferencedTweet({required this.id, required this.type});
  factory TweetReferencedTweet.fromJSON(Map<String, dynamic> json) => TweetReferencedTweet(id: int.parse(json['id']), type: json['type']);
  bool get isRetweet => type == 'retweeted';
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
  factory TweetUserEncode.fromJSON(Map<String, dynamic> json) => TweetUserEncode(
        tweetUserId: int.parse(json['id']),
        username: json['username'],
        name: json['name'],
        profile_image_url: json['profile_image_url'],
      );
  factory TweetUserEncode.fromDB(TweetUserData userData) => TweetUserEncode(id: userData.id!, tweetUserId: userData.tweetUserId, username: userData.username, name: userData.name, profile_image_url: userData.profileUrl ?? '');
  bool get isFirstTime => lastCheck == 0;
  TweetUserCompanion toTweetUserCompanionInsert() => TweetUserCompanion.insert(tweetUserId: tweetUserId, username: username, name: name, profileUrl: Value(profile_image_url));
  @override
  String toString() {
    return 'TweetUserEncode($id,$tweetUserId,$username,$name,$lastCheck)';
  }
}

class TweetFullDecode {
  List<TweetUserEncode>? includeUsers;
  late List<TweetEncode> tweets;
  List<TweetEncode>? includeTweets;
  TweetFullDecode(Map<String, dynamic> json, TweetUserEncode parentUser) {
    assert(json['data'] != null, 'json don\'t have a data type');
    if (json['includes'] != null) {
      if (json['includes']['users'] is List) includeUsers = (json['includes']['users'] as List).map<TweetUserEncode>((user) => TweetUserEncode.fromJSON(user)).toList();
      try {
        if (includeUsers != null && json['includes']['tweets'] is List) includeTweets = json['includes']['tweets'].map<TweetEncode>((tweet) => TweetEncode.fromJSON(includeUsers!.firstWhere((iuser) => iuser.tweetUserId == int.tryParse(tweet['author_id'])), tweet, null)).toList();
      } catch (err) {
        debugPrint('ERR include(${includeUsers?.length}): $includeUsers');
        debugPrint('tweets: ${json['includes']['tweets']}');
        debugPrint('jsonusers: ${json['includes']['users']}');
        throw err;
      }
    } else
      debugPrint('No includes');
    if (json['data'] is List)
      tweets = json['data'].map<TweetEncode>((data) {
        final newTweet = TweetEncode.fromJSON(parentUser, data, includeTweets);
        return newTweet;
      }).toList();
    else
      tweets = [TweetEncode.fromJSON(parentUser, json['data'], includeTweets)];
  }
}
