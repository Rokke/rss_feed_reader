import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rss_feed_reader/screens/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, ScopedReader watch) {
    debugPrint('build MyApp');
    return MaterialApp(
      theme: ThemeData(primarySwatch: Colors.deepPurple, brightness: Brightness.dark, appBarTheme: AppBarTheme(backgroundColor: Colors.deepPurple[900]), cardColor: Colors.blue[900]),
      themeMode: ThemeMode.dark,
      home: HomeScreen(),
    );
  }
}
