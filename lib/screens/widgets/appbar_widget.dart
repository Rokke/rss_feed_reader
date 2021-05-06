import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:rss_feed_reader/providers/feed_list.dart';
import 'package:rss_feed_reader/providers/server_provider.dart';
import 'package:rss_feed_reader/providers/tweet_list.dart';
import 'package:rss_feed_reader/screens/widgets/details_widget.dart';
import 'package:rss_feed_reader/screens/widgets/monitor_button.dart';

class CustomAppBarWidget extends ConsumerWidget {
  // static final _log = Logger('CustomAppBarWidget');
  final PackageInfo appVersion;
  const CustomAppBarWidget(this.appVersion, {Key? key}) : super(key: key);
  _test(BuildContext context) async {
    debugPrint('_test()');
    try {
      // final ret = await Process.runSync('pwsh', ['-c', 'Invoke-Command', '-ScriptBlock', '{[System.Console]::Beep(2000,200); [System.Console]::Beep(3000,100)}']);
      // debugPrint('Run: ${ret.stdout}, ${ret.stderr}, ${ret.exitCode}'); //r'$player = New-Object -TypeName System.Media.SoundPlayer;$player.SoundLocation = "D:\\Downloads\\tweet.wav";$player.Load();$player.Play()'])).exitCode}');
      debugPrint('checkAndUpdateTweet: ${await context.read(providerTweetHeader).checkAndUpdateTweet()}');
    } catch (err) {
      debugPrint('Error: $err');
    }
  }

  @override
  Widget build(BuildContext context, ScopedReader watch) {
    debugPrint('test: ${appVersion.appName}-${appVersion.buildNumber}-${appVersion.packageName}-${appVersion.version}');
    final feedProvider = context.read(providerFeedHeader);
    final socketProvider = context.read(providerSocketServer);
    return AppBar(
      title: Text('RSS Oversikt - ${appVersion.version}${(appVersion.buildNumber.isNotEmpty) ? ".${appVersion.buildNumber}" : ""}'),
      actions: [
        Center(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(border: Border.all(), borderRadius: BorderRadius.circular(10), color: Colors.purple[900]),
            child: Row(
              children: [
                // Container(
                //   constraints: BoxConstraints.tightFor(width: 30),
                //   child: TextField(
                //     controller: txtSearchFilter,
                //   ),
                // ),
                // Container(
                //   margin: EdgeInsets.symmetric(horizontal: 8),
                //   child: DropdownButton(
                //     items: ['Nye', 'Lest', 'Favoriter']
                //         .map((e) => DropdownMenuItem(
                //               child: Text(e),
                //               value: e,
                //             ))
                //         .toList(),
                //     value: selectedFilter == -1
                //         ? 'Lest'
                //         : selectedFilter == 1
                //             ? 'Favoriter'
                //             : 'Nye',
                //     onChanged: (val) => context.read(filterShowArticleStatus).state = (val == 'Favoriter'
                //         ? 1
                //         : val == 'Lest'
                //             ? -1
                //             : 0),
                //   ),
                // ),
                ValueListenableBuilder(
                  valueListenable: feedProvider.numberOfArticleNotifier,
                  builder: (context, int amount, _) {
                    final errorReported = context.read(providerErrorReported);
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                      decoration: BoxDecoration(
                          border: Border.all(),
                          borderRadius: BorderRadius.circular(6),
                          color: errorReported.state != null
                              ? Colors.red
                              : amount > 0
                                  ? Colors.blue
                                  : null),
                      child: errorReported.state == null
                          ? Text('${amount}')
                          : GestureDetector(
                              child: Text(amount.toString()),
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorReported.state!)));
                                errorReported.state = null;
                              },
                            ),
                    );
                  },
                ),
                // if (selectedFilter == ArticleTableStatus.READ) SizedBox(width: 4),
                // if (selectedFilter == ArticleTableStatus.READ && articleCount > 0)
                //   ElevatedButton.icon(
                //     onPressed: () async {
                //       final ret = await showDialog(
                //           context: context,
                //           builder: (_) => AlertDialog(
                //                 title: Text('Advarsel'),
                //                 actions: [
                //                   ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: Text('Avbryt')),
                //                   ElevatedButton(onPressed: () => Navigator.of(context).pop('OK'), child: Text('OK')),
                //                 ],
                //               ));
                //       if (ret == 'OK') {
                //         final amountRemoved = await context.read(rssDatabase).deleteAllReadArticles(feedId: context.read(selectedFeedId).state);
                //         _log.info('Removing $amountRemoved articles that was read');
                //         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                //             content: Text(
                //               amountRemoved > 0 ? 'Det ble ryddet opp i $amountRemoved gamle artikler' : 'Ingen artikler å rydde opp',
                //               style: Theme.of(context).textTheme.headline6,
                //               textAlign: TextAlign.center,
                //             ),
                //             width: 600.0,
                //             elevation: 8,
                //             behavior: SnackBarBehavior.floating,
                //             backgroundColor: Colors.green,
                //             shape: RoundedRectangleBorder(
                //               borderRadius: BorderRadius.circular(10.0),
                //             )));
                //       } else
                //         _log.fine('User cancelled deleting');
                //     },
                //     icon: Icon(Icons.delete_forever),
                //     label: Text('Slett'),
                //     style: ButtonStyle(backgroundColor: MaterialStateColor.resolveWith((states) => Colors.red)),
                //   )
              ],
            ),
          ),
        ),
        MonitorButton(),
        ValueListenableBuilder(
          valueListenable: socketProvider.isConnected,
          builder: (BuildContext context, bool connected, Widget? child) {
            return connected
                ? Icon(Icons.connect_without_contact_rounded, color: Colors.green)
                : Icon(
                    Icons.no_cell,
                    color: Colors.red,
                    size: 15,
                  );
          },
        ),
        if (kDebugMode)
          IconButton(
            icon: Icon(Icons.hot_tub),
            onPressed: () => _test(context),
          )
      ],
    );
  }
}
