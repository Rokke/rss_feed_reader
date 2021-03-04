class RSSFeed {
  static const String TABLE_NAME = 'feed';
  static const String TABLE_CREATE = 'CREATE TABLE $TABLE_NAME(id INTEGER PRIMARY KEY, title TEXT NOT NULL, url TEXT NOT NULL, description TEXT, link TEXT, language TEXT, update_period TEXT, last_build_date INT, status INTEGER DEFAULT 0);';
  int? id;
  final String title, url;
  final String? description, link, language, updatePeriod;
  final int? lastBuildDate;
  int status;

  RSSFeed({this.id, required this.title, required this.url, this.link, this.lastBuildDate, this.description, this.language, this.updatePeriod, this.status = 0});
  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'url': url,
        'description': description,
        'language': language,
        'update_period': updatePeriod,
        'last_build_date': lastBuildDate,
        'status': status,
      };
}
