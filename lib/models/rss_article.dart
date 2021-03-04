import 'package:xml/xml.dart';

class RSSArticle {
  static const String TABLE_NAME = 'article';
  static const String TABLE_CREATE = 'CREATE TABLE $TABLE_NAME(id INTEGER PRIMARY KEY, parent INTEGER NOT NULL, title TEXT NOT NULL, url TEXT, description TEXT, creator TEXT, pub_date INT, status INTEGER DEFAULT 0);';
  static const String sort = 'pub_date';
  int? id;
  final int parent;
  final String title, url;
  final String? description, creator;
  final int pubDate;
  int status;

  RSSArticle({this.id, required this.parent, required this.title, required this.url, this.description, this.creator, int? pubDate, this.status = 0}) : pubDate = pubDate ?? DateTime.now().millisecondsSinceEpoch;
  Map<String, dynamic> toMap() => {
        'id': id,
        'parent': parent,
        'title': title,
        'url': url,
        'description': description,
        'creator': creator,
        'pubDate': pubDate,
        'status': status,
      };
  factory RSSArticle.fromMap(Map map) => RSSArticle(
        id: map['id'],
        parent: map['parent'],
        title: map['title'],
        url: map['url'],
        description: map['description'],
        status: map['status'],
        creator: map['creator'],
        pubDate: map['pub_date'],
      );
  factory RSSArticle.fromXML(int parent, XmlElement xmlElement) {
    return RSSArticle(
      parent: parent,
      title: xmlElement.getElement('title')?.innerText ?? '',
      url: xmlElement.getElement('title')?.innerText ?? '?',
      description: xmlElement.getElement('description')?.innerText,
      creator: xmlElement.getElement('creator')?.innerText,
      pubDate: DateTime.tryParse(xmlElement.getElement('title')?.innerText ?? '')?.millisecondsSinceEpoch,
    );
  }
}
