import 'package:html_unescape/html_unescape.dart';
import 'package:logging/logging.dart';
import 'package:rss_feed_reader/models/xml_mapper/base_mapper.dart';
import 'package:xml/xml.dart';

class ItemMapper extends XMLBaseMapper {
  static final _log = Logger('ItemMapper');
  String? title, link, description, author, comments, guid, source, encoded, category;
  int? pubDate;

  ItemMapper();
  factory ItemMapper.fromXML(XmlElement xEl) {
    ItemMapper item = ItemMapper();
    xEl.children.forEach((xNode) {
      if (xNode is XmlElement) {
        switch (xNode.name.toString()) {
          case 'title':
            item.title = xNode.innerText;
            break;
          case 'media:group':
            if (item.description == null && xNode.getElement('media:description') != null) {
              item.description = xNode.getElement('media:description')!.innerXml;
            }
            break;
          case 'description':
          case 'content':
            item.description = HtmlUnescape().convert(xNode.innerXml);
            break;
          case 'link':
            item.link = xNode.innerText.isEmpty ? xNode.getAttribute('href') : xNode.innerText;
            break;
          case 'atom:link':
          case 'id': // Backup if guid is replaced with atom:link from the provider
            if (item.guid == null) item.guid = xNode.innerXml;
            break;
          case 'author':
          case 'dc:creator':
            item.author = xNode.innerText;
            break;
          case 'content:encoded':
            item.encoded = xNode.innerText;
            break;
          case 'guid':
            item.guid = xNode.innerXml;
            break;
          case 'category':
            final cat = xNode.innerText.split(',').where((element) => element.isNotEmpty).toList();
            if (cat.length > 0) {
              item.category = ((item.category == null) ? '' : '${item.category},') + cat.join(',');
            }
            break;
          case 'comments':
            item.comments = xNode.innerText;
            break;
          case 'source':
            item.source = xNode.innerText;
            break;
          case 'pubDate':
          case 'updated':
          case 'published':
          case 'atom:updated':
            if (item.pubDate == null) {
              final dt = item.parseRSSString(xNode.innerText);
              if (dt != null)
                item.pubDate = dt.millisecondsSinceEpoch;
              else
                _log.warning('Error pubDate format: ${xNode.innerXml}');
            }
            break;
          case 'media:content':
          case 'enclosure':
          case 'image':
          case 'cloud':
          case 'docs':
          case 'copyright':
          case 'managingEditor':
          case 'webMaster':
          case 'skipHours':
          case 'skipDays':
          case 'item':
          case 'og':
          case 'site':
          case 'slash:comments':
          case 'post-id':
          case 'wfw:commentRss':
          case 'discourse:topicArchived':
          case 'discourse:topicClosed':
          case 'discourse:topicPinned':
          case 'media:credit':
          case 'feedburner:origLink':
          case 'trackback:ping':
          case 'pingback:server':
          case 'pingback:target':
          case 's:doctype':
          case 'wfw:comment':
          case 'item:media':
          case 'thr:total':
          case 'itunes:summary':
          case 'itunes:image':
          case 'itunes:explicit':
          case 'itunes:duration':
          case 'media:thumbnail':
          case 'itunes:keywords':
          case 'imgRegular':
          case 'yt:videoId':
          case 'yt:channelId':
          case 'dc:date':
            break;
          default:
            if (!xNode.name.toString().startsWith('vg:')) _log.info('Ukjent feed element: ${xNode.name}=>${xNode.text.length > 100 ? xNode.text.substring(0, 100) + "..." : xNode.text}');
        }
      } else if (xNode.nodeType != XmlNodeType.COMMENT && xNode.outerXml.trim().isNotEmpty) _log.info('Ukjent nodetype: ${xNode.nodeType}=>${xNode.outerXml}');
    });
    return item;
  }
  // ArticleCompanion toArticleCompanion(int parent) => ArticleCompanion(
  //       parent: moor.Value(parent),
  //       title: moor.Value(title!),
  //       url: moor.Value(link),
  //       guid: moor.Value(guid ?? link!),
  //       description: moor.Value(description),
  //       creator: moor.Value(author),
  //       pubDate: moor.Value(pubDate),
  //       category: moor.Value(category),
  //       encoded: moor.Value(encoded),
  //     );
  // addArticle(newId, item.title!, item.link, item.guid ?? item.link!, item.description, item.author, item.pubDate, item.category, item.encoded, null);
}
