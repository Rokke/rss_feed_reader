import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:rss_feed_reader/database/database.dart';
import 'package:rss_feed_reader/screens/widgets/feed_widget.dart';
import 'package:rss_feed_reader/screens/widgets/monitor_button.dart';

class CustomAppBarWidget extends ConsumerWidget {
  static final _log = Logger('CustomAppBarWidget');
  final PackageInfo appVersion;
  const CustomAppBarWidget(this.appVersion, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, ScopedReader watch) {
    final selectedFilter = watch(filterShowArticleStatus).state;
    final articleCountFuture = watch(selectedFeedStatusArticlesCount);
    return AppBar(
      title: Text('RSS Oversikt - ${appVersion.version}${(appVersion.buildNumber.isNotEmpty) ? ".${appVersion.buildNumber}" : ""}'),
      actions: [
        Center(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(border: Border.all(), borderRadius: BorderRadius.circular(10), color: Colors.purple[900]),
            child: articleCountFuture.when(
                data: (articleCount) => Row(
                      children: [
                        DropdownButton(
                          items: ['Nye', 'Lest', 'Favoriter']
                              .map((e) => DropdownMenuItem(
                                    child: Text(e),
                                    value: e,
                                  ))
                              .toList(),
                          value: selectedFilter == -1
                              ? 'Lest'
                              : selectedFilter == 1
                              ? 'Favoriter'
                              : 'Nye',
                          onChanged: (val) => context.read(filterShowArticleStatus).state = (val == 'Favoriter'
                              ? 1
                              : val == 'Lest'
                              ? -1
                              : 0),
                        ),
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                          decoration: BoxDecoration(border: Border.all(), borderRadius: BorderRadius.circular(6), color: articleCount > 0 ? Colors.blue : null),
                          child: articleCount < 0 ? Text('?') : Text('${articleCount}'),
                        ),
                        if (selectedFilter == ArticleTableStatus.READ) SizedBox(width: 4),
                        if (selectedFilter == ArticleTableStatus.READ && articleCount > 0)
                          ElevatedButton.icon(
                            onPressed: () async {
                              final ret = await showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                        title: Text('Advarsel'),
                                        actions: [
                                          ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: Text('Avbryt')),
                                          ElevatedButton(onPressed: () => Navigator.of(context).pop('OK'), child: Text('OK')),
                                        ],
                                      ));
                              if (ret == 'OK') {
                                final amountRemoved = await context.read(rssDatabase).deleteAllReadArticles(feedId: context.read(selectedFeedId).state);
                                _log.info('Removing $amountRemoved articles that was read');
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text(
                                      amountRemoved > 0 ? 'Det ble ryddet opp i $amountRemoved gamle artikler' : 'Ingen artikler å rydde opp',
                                      style: Theme.of(context).textTheme.headline6,
                                      textAlign: TextAlign.center,
                                    ),
                                    width: 600.0,
                                    elevation: 8,
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: Colors.green,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                    )));
                              } else
                                _log.fine('User cancelled deleting');
                            },
                            icon: Icon(Icons.delete_forever),
                            label: Text('Slett'),
                            style: ButtonStyle(backgroundColor: MaterialStateColor.resolveWith((states) => Colors.red)),
                          )
                      ],
                    ),
                loading: () => Text('?'),
                error: (_, __) => Text('E')),
          ),
        ),
        MonitorButton()
      ],
    );
  }
}
