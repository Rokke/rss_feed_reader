import 'dart:io';

// import 'package:flutter/material.dart';
import 'package:moor/moor.dart';
// These imports are only needed to open the database
import 'package:moor/ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'database.g.dart';

final rssDatabase = Provider<AppDb>((ref) {
  print('rss');
  return AppDb();
});

@UseMoor(
  // relative import for the moor file. Moor also supports `package:`
  // imports
  include: {'tables.moor'},
)
class AppDb extends _$AppDb {
  AppDb() : super(_openConnection());

  @override
  int get schemaVersion => 1;
  createTestData() async {
    into(feed).insert(FeedData(title: 'Teslarati', url: 'http://www.teslarati.com/feed/'));
    into(feed).insert(FeedData(title: 'RBNett', url: 'https://www.rbnett.no/?widgetName=polarisFeeds&widgetId=6485383&getXmlFeed=true'));
  }
}

LazyDatabase _openConnection() {
  // the LazyDatabase util lets us find the right location for the file async.
  return LazyDatabase(() async {
    // put the database file, called db.sqlite here, into the documents folder
    // for your app.
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'rss_db.sqlite'));
    return VmDatabase(file);
  });
}
