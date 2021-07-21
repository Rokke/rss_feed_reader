import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:moor/moor.dart';
import 'package:news_common/tweet_encode.dart';
import 'package:rss_feed_reader/database/database.dart';

class TweetEncode extends TweetEncodeBase {
  // final int id; //, tweetUserId;
  // final String text;
  // final DateTime createdAt;
  // TweetEncode? retweet;
  // // final List<TweetReferencedTweet> referenced_tweets;
  // TweetUserEncode parentUser;

  TweetEncode({required int id, required TweetUserEncode parentUser, required String text, required DateTime createdAt, TweetEncodeBase? retweet}) : super(id: id, parentUser: parentUser, text: text, createdAt: createdAt, retweet: retweet);
  factory TweetEncode.fromJSON(TweetUserEncode parentUser, Map<String, dynamic> data, List<TweetEncode>? linkedTweets) {
    try {
      // if (parentUser == null) ;
      final refTweet = data['referenced_tweets'];
      final ret = TweetEncode(
        id: int.parse(data['id'].toString()),
        parentUser: parentUser,
        text: HtmlUnescape().convert(data['text'].toString()),
        createdAt: DateTime.parse(data['created_at'].toString()),
      );
      if (refTweet is List<Map<String, dynamic>>) {
        final referencedTweet = refTweet.map<TweetReferencedTweet>((ref) => TweetReferencedTweet.fromJSON(ref)).firstOrNull;
        debugPrint('refTweet: $refTweet => $referencedTweet => ${referencedTweet?.id != null ? (linkedTweets?.firstWhereOrNull((l) => l.id == referencedTweet?.id)) ?? linkedTweets : 'N/A'}');
        if (referencedTweet != null) ret.retweet = linkedTweets?.firstWhereOrNull((l) => l.id == referencedTweet.id);
      }
      return ret;
    } catch (err) {
      debugPrint('TweetEncode.fromJSON exception: $data');
      rethrow;
    }
  }
  // Map<String, dynamic> toJson() => {
  //       'id': id,
  //       'text': text,
  //       'createdAt': createdAt.millisecondsSinceEpoch,
  //       'user': {
  //         'id': parentUser.id,
  //         'name': parentUser.name,
  //         'profile_image_url': parentUser.profileImageUrl,
  //         'tweetUserId': parentUser.tweetUserId,
  //         'username': parentUser.username,
  //       }
  //     };
  factory TweetEncode.retweetFromDB(RetweetData data) => TweetEncode(id: data.tweetId, parentUser: TweetUserEncode(tweetUserId: data.tweetUserId, username: data.username, name: data.name), text: data.title, createdAt: DateTime.fromMillisecondsSinceEpoch(data.createdAt));
  factory TweetEncode.fromDB(TweetData data, List<TweetUserEncode> users, RetweetData? retweet) {
    try {
      return TweetEncode(
        id: data.tweetId,
        parentUser: users.firstWhere((element) => element.id == data.parent, orElse: () => TweetUserEncode(name: 'UNKNOWN', username: 'anonymous', tweetUserId: 0)),
        text: data.title,
        createdAt: DateTime.fromMillisecondsSinceEpoch(data.createdAt),
        retweet: retweet != null ? TweetEncode.retweetFromDB(retweet) : null,
      );
    } catch (err) {
      debugPrint('TweetEncode.fromDB exception: $data, ${users.length}, $retweet');
      rethrow;
    }
  }
  // String get tweetWebUrl => 'https://twitter.com/i/web/status/$id';
  TweetData toTweetDataIsItInUse() => TweetData(tweetId: id, parent: parentUser.id!, title: text, createdAt: createdAt.millisecondsSinceEpoch);
  // bool get isReply => referenced_tweets.any((element) => element.type == 'replied_to');
  // bool get isRetweet => retweet != null;
  // int get firstRetweetId => referenced_tweets.indexWhere((element) => element.type == 'retweeted');
  @override
  String toString() {
    return 'TweetEncode($id,${parentUser.tweetUserId},$text,$createdAt,${retweet?.id})';
  }
}

class TweetRetweet {}

class TweetReferencedTweet {
  final int id;
  final String type;

  TweetReferencedTweet({required this.id, required this.type});
  factory TweetReferencedTweet.fromJSON(Map<String, dynamic> json) => TweetReferencedTweet(id: int.parse(json['id'].toString()), type: json['type'] as String);
  bool get isRetweet => type == 'retweeted';
  @override
  String toString() {
    return 'TweetReferencedTweet($id,$type)';
  }
}

extension TweetUserDataFunctions on TweetUserData {
  TweetUserEncode toTweetUserEncode() => TweetUserEncode(id: id, tweetUserId: tweetUserId, username: username, name: name, profileImageUrl: profileUrl ?? '', sinceId: sinceId);
}

extension TweetUserEncodeFunctions on TweetUserEncode {
  TweetUserCompanion toTweetUserCompanionInsert() => TweetUserCompanion.insert(tweetUserId: tweetUserId, username: username, name: name, profileUrl: Value(profileImageUrl), sinceId: sinceId);
}
// class TweetUserEncode extends TweetUserEncodeBase {
// //   int? id;
// //   final int tweetUserId;
// //   final String username, name, profileImageUrl;
// //   int sinceId;
// //   int lastCheck = 0;

//   TweetUserEncode({int? id, required int tweetUserId, required String username, required String name, String profileImageUrl = '', int sinceId = 0}) : super(id: id, tweetUserId: tweetUserId, username: username, name: name, profileImageUrl: profileImageUrl, sinceId: sinceId);
//    factory TweetUserEncode.fromJSON(Map<String, dynamic> json) => TweetUserEncode(
//   //       tweetUserId: int.parse(json['id'].toString()),
//   //       username: json['username'] as String,
//   //       name: json['name'] as String,
//   //       profileImageUrl: json['profile_image_url'] as String,
//   //       sinceId: json['since_id'] as int? ?? 0,
//   //     );
//   factory TweetUserEncode.fromDB(TweetUserData userData) => TweetUserEncode(id: userData.id, tweetUserId: userData.tweetUserId, username: userData.username, name: userData.name, profileImageUrl: userData.profileUrl ?? '', sinceId: userData.sinceId);
// //   // bool get isFirstTime => sinceId ?? 0 == 0;
//   TweetUserCompanion toTweetUserCompanionInsert() => TweetUserCompanion.insert(tweetUserId: tweetUserId, username: username, name: name, profileUrl: Value(profileImageUrl), sinceId: sinceId);
// //   @override
// //   String toString() {
// //     return 'TweetUserEncode($id,$tweetUserId,$username,$name,$sinceId)';
// //   }
// }

class TweetFullDecode {
  List<TweetUserEncode>? includeUsers;
  late List<TweetEncode> tweets;
  List<TweetEncode>? includeTweets;
  TweetFullDecode(Map<String, dynamic> json, TweetUserEncode parentUser) : assert(json['data'] != null, "json don't have a data type") {
    if (json['includes'] != null) {
      if (json['includes']['users'] is List) {
        includeUsers = (json['includes']['users'] as List).map<TweetUserEncode>((user) => TweetUserEncode.fromJSON(user as Map<String, dynamic>)).toList();
      }
      try {
        if (includeUsers != null && json['includes']['tweets'] is List<Map<String, dynamic>>) {
          includeTweets = (json['includes']['tweets'] as List<Map<String, dynamic>>).map<TweetEncode>((tweet) => TweetEncode.fromJSON(includeUsers!.firstWhere((iuser) => iuser.tweetUserId == int.tryParse(tweet['author_id'].toString())), tweet, null)).toList();
        }
      } catch (err) {
        debugPrint('ERR include(${includeUsers?.length}): $includeUsers');
        debugPrint('tweets: ${json['includes']['tweets']}');
        debugPrint('jsonusers: ${json['includes']['users']}');
        rethrow;
      }
    } else {
      debugPrint('No includes');
    }
    if (json['data'] is List) {
      tweets = (json['data'] as List).map<TweetEncode>((data) {
        final newTweet = TweetEncode.fromJSON(parentUser, data as Map<String, dynamic>, includeTweets);
        return newTweet;
      }).toList();
    } else {
      tweets = [TweetEncode.fromJSON(parentUser, json['data'] as Map<String, dynamic>, includeTweets)];
    }
  }
}

abstract class TweetTableStatus {
  static const READ = -1;
  static const UNREAD = 0;
  static const RETWEET = 1;
}
