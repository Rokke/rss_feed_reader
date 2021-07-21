import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rss_feed_reader/database/database.dart';
import 'package:rss_feed_reader/providers/feed_list.dart';
import 'package:rss_feed_reader/screens/widgets/drawer_feed_list.dart';
import 'package:rss_feed_reader/screens/widgets/popups/add_feed.dart';
import 'package:rss_feed_reader/screens/widgets/popups/confirm_dialog.dart';
import 'package:rss_feed_reader/utils/misc_functions.dart';
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
  // final _log = Logger('FeedView');
  const FeedView({Key? key}) : super(key: key);

  // _test() async {
  //   final url = 'https://www.rbnett.no/?widgetName=polarisFeeds&widgetId=6485383&getXmlFeed=true';
  //   try {
  //     final dio = new http.Dio();
  //     (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate = (HttpClient client) {
  //       // debugPrint('client: ${client}');
  //       client.badCertificateCallback = (X509Certificate cert, String host, int port) {
  //         debugPrint('client?: ${cert.issuer},${cert.startValidity}-${cert.endValidity},${cert.subject}, $host, $port');
  //         return true;
  //       };
  //       return client;
  //     };
  //     final response = await dio.get(
  //       url,
  //       options: http.Options(
  //         followRedirects: true,
  //         headers: {
  //           'User-Agent': 'Thunder Client (https://www.thunderclient.io)',
  //           'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9',
  //           'Host': 'www.rbnett.no',
  //           'Accept-Encoding': 'gzip, deflate, br',
  //           'Connection': 'keep-alive',
  //           'Cookie':
  //               'cX_P=k6pfhdvwg94efx87; cX_G=cx:djfun4byzl2nqv4zkp9rdguk:2g57f6m8wubq2; __gads=ID=b86787e81d58e390:T=1581881698:S=ALNI_Ma9aeuPk0IMjvcXvFJhVxuPLTOUew; i00=00005900c432cd0d0000; _lp4_u=VvWiocdX0U; __utmc=130080656; cX_S=kauvw5sy8l1m6f63; SP_ID=eyJjbGllbnRfaWQiOiI1MzU3YWI4YTQzMWM3YWMwNTQwMDAwMDIiLCJhdXRoIjoicEhXZ2dSOHl5WnBYRHZUNE5qZU1LVXUyM2xkZGlXa2VRQ1FRS0NnMGtYSlY5RzVqUDdVYmR4TmdGYmIxenZ0QkdLdVlrYzY4WlpoWVZMb0lWYnVlUGdnZENFdkVqR2MxcC1ES2MzUEdyQjQifQ; _ga=GA1.2.562817127.1581881697; amplitude_idundefinedrbnett.no=eyJvcHRPdXQiOmZhbHNlLCJzZXNzaW9uSWQiOm51bGwsImxhc3RFdmVudFRpbWUiOm51bGwsImV2ZW50SWQiOjAsImlkZW50aWZ5SWQiOjAsInNlcXVlbmNlTnVtYmVyIjowfQ==; amplitude_id_613997809256176a49238d1216a03ce2rbnett.no=eyJkZXZpY2VJZCI6IjFjNzc5YjViLTVlMzQtNDM0My1iZWE2LTRlMmQwOGQ5YWVlMVIiLCJ1c2VySWQiOiJ1bmtub3duVXNlciIsIm9wdE91dCI6ZmFsc2UsInNlc3Npb25JZCI6MTU5NzE1MTMwMzA5NywibGFzdEV2ZW50VGltZSI6MTU5NzE1MTMwMzExNSwiZXZlbnRJZCI6MTgsImlkZW50aWZ5SWQiOjE4LCJzZXF1ZW5jZU51bWJlciI6MzZ9; __utmz=130080656.1619793157.103.3.utmcsr=t.co|utmccn=(referral)|utmcmd=referral|utmcct=/; id-jwt=eyJraWQiOiIzYWNkODdmNS0zYmQyLTQ5ZTMtYWFhOC0wYTI5ZjU2MzY1YTIiLCJhbGciOiJSUzI1NiJ9.eyJhdWQiOiJzZHJuOnNwaWQubm86Y2xpZW50OjUzNTdhYjhhNDMxYzdhYzA1NDAwMDAwMiIsInN1YiI6Ijg0ZWE2M2VlLTQyZTItNTk2OC05NjU0LTIxZmVlZjE3ODUzZCIsInVzZXJfaWQiOiIxNTAxMzYiLCJpc3MiOiJodHRwczpcL1wvc2Vzc2lvbi1zZXJ2aWNlLmxvZ2luLnNjaGlic3RlZC5jb20iLCJleHAiOjE2NTIxMjI5MzcsImlhdCI6MTYyMDU4NjkzNywianRpIjoiNjNjZjI3NjgtMzcyNi00ZTRmLTliYjAtMTA5MzYyMTNiODE3In0.N4Pe6893FPeBLhdyvOHOjCpgVax8tYiAyP94jEqG-xigqTR4BvGSHhsPg6LJqiR1t3fEuglHw7mAZ49DOXLExub8k89jwezJbPs8O2V8rMpy7n7x0NU2uo4J3v_wyaAazePK5SBrrzLEEwM1kFxHDzvpPpnaF1pANMEqjEf6OKpXHvnJp6TXsTepIqLjTFMLtVW6Tup1HxKGPasu6uDagQvj4mv8WKN15DjWVaMDlL45Kdq5sgfK2o-zEvd2vcotvBK1aNzs0LXAj8bidu5ClECfqWPLYUQV_cusVQ4-38wuvd8lI9d7LyqfSqH7eH6opd5k81rQnLTC42T8jrmo2yoRjoxzS9oTID_Vh-YSiRCMGdtSdUHMmVLiz8USkjyzRMc6H62_yWetVI23YmhGhS8RxkW-ZwQHCZcBZ7f2ch95G-KmdCwYSr9Vqj4jmIiFYXJDXYWAb2Ec6gFL81oaYfCAQmRHfOYuM0fj6fbfcyu0XVdQSGEtLHgcQvWpasAnxrIXkbXPU2tM1yopovdZzvD9qQhz53IFu2cDJHR7a4wnkUxl61GaQAnTvyM2TMjltPgMr9qUcjBS7eqF_fCgVKI-T-KB0EvUqWwXpzk-yIkhgDEqy_NfotQjyt_PdppuTvYPeo3bB-cQZcAZ5GbXuI1JinMCYOhMMDAe6u4V44Y; pjcTotal=3; pjcTotal=3; __utma=130080656.562817127.1581881697.1620985158.1621196034.115; VPW_State=ZGVuaWVkPSgpLHNpZz0weDI3NGFmNzBmYjcxY2U3ZDI5Y2JhYzRiOTIwZmQ1YTJiOWEzOTlhNTQyNjkzZWIzOGVjYjc2ZGJiMTUwMGJhMDU=; _MBL={"u":"uUhMIqg4F2","t":1621406577}; ajs_user_id="unknownUser"; ajs_anonymous_id="82efd93c-7f2e-4d54-a475-9623a077fb52"; _pulse2data=d8855795-5dc7-4f39-b9fc-e89daef0ddb7,v,,1621407478069,eyJpc3N1ZWRBdCI6IjIwMTktMDYtMDFUMTY6MjY6MzVaIiwiZW5jIjoiQTEyOENCQy1IUzI1NiIsImFsZyI6ImRpciIsImtpZCI6IjIifQ..iIEJ3yBf8JUxTDMH9FqsZw.Wc9iEx-yw1AotLSO_fGo0mkCu9I4SqlKs7Qo6YpvnOEb9kYXMolXCy9kAqbp5Yqj-zpqZwsWA94Ox21DTuYkHAmWc950ca-qWHQwgoYs5VIrnXAJsf49L9juqRa0b1tOVW0jkAy7hnfi7Mrntuz0WCD-X458x8o4BL37IN5vxieHAZjcmTfaTlcjxDTXW8kGV3Nw9ClkNlRNt1_O4HS7KQ.2dR3bUMC-eVxUMRPau7FIA,0,1621420978069,true,,eyJraWQiOiIyIiwiYWxnIjoiSFMyNTYifQ..quPpk1QqZI9kha1-QoOzOwZ9a5XIVEM4luyEONuyjnE; _cioid=unknownUser; _cio=4bf6ff03-dd53-6416-e229-8268bc6ad12c'
  //         },
  //         // validateStatus: (status) {
  //         //   debugPrint('status: $status');
  //         //   return true;
  //         // }
  //       ),
  //     );
  //     debugPrint('Error downloading feed: ${response.statusCode}, $url');
  //   } catch (err) {
  //     debugPrint('readFeed exception ($url): $err');
  //   }
  // }
  // _test(BuildContext context) async {
  //   final db = context.read(rssDatabase);
  //   final ret = await (db.update(db.article)..where((tbl) => tbl.id.equals(11785))).write(ArticleCompanion(active: moor.Value(true)));
  //   debugPrint("UPDATE: $ret");
  // }
  // _test2() async {
  //   final url = 'https://www.rbnett.no/?widgetName=polarisFeeds&widgetId=6485383&getXmlFeed=true';
  //   try {
  //     // final dio = new http.Dio();
  //     // (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate = (HttpClient client) {
  //     //   client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  //     //   return client;
  //     // };
  //     final response = await http2.get(Uri.parse(url), headers: {'User-Agent': 'Thunder Client (https://www.thunderclient.io)', 'Accept': '*/*', 'Authorization': 'notapplicable', 'Host': 'www.rbnett.no'});
  //     debugPrint('Error downloading feed: ${response.statusCode}, $url');
  //   } catch (err) {
  //     debugPrint('readFeed exception ($url): $err');
  //   }
  // }

  @override
  Widget build(BuildContext context, ScopedReader watch) {
    final feedRef = watch(providerFeedHeader);
    return Container(
      color: Theme.of(context).appBarTheme.backgroundColor,
      child: Column(children: [
        Container(
          constraints: const BoxConstraints(maxHeight: 120),
          child: DrawerHeader(
            child: Container(
              padding: const EdgeInsets.all(4),
              child: Stack(
                children: [
                  Container(constraints: const BoxConstraints.expand(height: 30), child: Text('RSS Feeder', style: Theme.of(context).textTheme.headline6)),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Hero(
                      tag: AddFeedPopup.HERO_TAG,
                      child: Material(
                          child: SingleChildScrollView(
                        child: ElevatedButton.icon(
                            onPressed: () async {
                              final ret = await Navigator.of(context).push(HeroDialogRoute(builder: (context) {
                                return const AddFeedPopup();
                              }));
                              if (ret is String && ret.length > 1) {
                                Navigator.of(context).pop();
                              } else {
                                debugPrint('Ugyldig valg');
                              }
                            },
                            icon: const Icon(Icons.add_circle),
                            label: const Text('Ny RSS/Twitter')),
                      )),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    child: ElevatedButton.icon(
                        onPressed: () {
                          debugPrint('findFeedToUpdate');
                          // _test(context);
                          // playSound(soundFile: Random().nextBool() ? SOUND_FILE.SOUND_NEWTWEET : SOUND_FILE.SOUND_NEWITEM, log: _log);
                          Navigator.pop(context);
                          feedRef.findFeedToUpdate(waitTimeSeconds: 15);
                        },
                        icon: const Icon(Icons.add_circle),
                        label: const Text('Oppdater RSS')),
                  ),
                  Positioned(
                    bottom: 50,
                    child: ElevatedButton.icon(
                        onPressed: () async {
                          if (await confirmChoice(context, 'Sletting', 'Er du sikker på at du ønsker å slette alle leste artikler og tweets?') == true) showSnackbar(context, 'Slettet ${await context.read(rssDatabase).cleanOldData()} rader');
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.add_circle),
                        label: const Text('Rensk database')),
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
            return initialized ? DrawerListItems(feedRef.feeds) : const CircularProgressIndicator();
          },
        )),
      ]),
    );
  }
}
