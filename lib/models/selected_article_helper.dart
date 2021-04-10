import 'package:rss_feed_reader/database/database.dart';

class SelectedArticleHelper {
  final Function(int status) onStatusChanged;
  final ArticleData? articleData;

  SelectedArticleHelper(this.articleData, this.onStatusChanged);
}
