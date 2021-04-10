import 'dart:io';

import 'package:desktop_window/desktop_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:rss_feed_reader/screens/home.dart';

void _startLogger() async {
  Logger.root.level = kDebugMode ? Level.FINEST : Level.INFO;
  Logger.root.onRecord.listen((event) async {
    debugPrint('[${event.loggerName}] ${event.level} ${event.time.hour.toString().padLeft(2, '0')}:${event.time.minute.toString().padLeft(2, '0')}:${event.time.second.toString().padLeft(2, '0')},${event.time.millisecond} ${event.message}' + (event.error == null ? '' : ', ERR: ${event.error}'));
    if (Platform.isWindows) {
      try {
        final fs = File(kDebugMode ? 'D:\\Temp\\rss_monitor_debug.log' : 'D:\\Temp\\rss_monitor.log');
        fs.writeAsStringSync(
            '[${event.loggerName}] ${event.level} ${event.time.hour.toString().padLeft(2, '0')}:${event.time.minute.toString().padLeft(2, '0')}:${event.time.second.toString().padLeft(2, '0')},${event.time.millisecond} ${event.message}\n${event.error != null ? " ${event.error}\n" : ""}',
            mode: FileMode.append);
      } catch (err) {
        print('log error: $err');
      }
    }
  });
}

void main() async {
  _startLogger();
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows) DesktopWindow.setWindowSize(Size(1200, 1100));
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primarySwatch: Colors.deepPurple, brightness: Brightness.dark, appBarTheme: AppBarTheme(backgroundColor: Colors.deepPurple[900]), cardColor: Colors.blue[900]),
      themeMode: ThemeMode.dark,
      home: HomeScreen(),
    );
  }
}
