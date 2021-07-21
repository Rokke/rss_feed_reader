import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rss_feed_reader/models/rss_tree.dart';

class MonitorButton extends ConsumerWidget {
  const MonitorButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, ScopedReader watch) {
    final running = watch(monitoringRunning).state;
    return IconButton(
        icon: Icon(running ? Icons.pause : Icons.play_arrow),
        onPressed: () {
          debugPrint('_toggleStartStop($running)');
          if (!running) {
            context.read(rssProvider).startMonitoring();
          } else {
            context.read(rssProvider).stopMonitoring();
          }
        });
  }
}
