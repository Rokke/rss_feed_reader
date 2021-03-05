import 'dart:developer';
import 'package:rss_feed_reader/models/xml_mapper/base_mapper.dart';
import 'package:xml/xml.dart';

class ItemMapper extends XMLBaseMapper {
  String? title, link, description, author, comments, enclosure, guid, source, category, encoded;
  int? pubDate;

  ItemMapper();
  factory ItemMapper.fromXML(XmlElement xEl) {
    ItemMapper item = ItemMapper();
    xEl.children.forEach((xNode) {
      if (xNode is XmlElement) {
        switch (xNode.name.toString()) {
          case 'title': //TODO: Endre til innerXml når flutter_html støtter nullsafety
            item.title = xNode.innerText;
            break;
          case 'description':
            item.description = xNode.innerText;
            break;
          case 'link':
            item.link = xNode.innerXml;
            break;
          // case 'atom:link':
          //   item.atomlink = xNode.innerXml;
          //   break;
          case 'author':
          case 'dc:creator':
            item.author = xNode.innerText;
            break;
          case 'content:encoded':
            // case 'encoded':
            item.encoded = xNode.innerText;
            break;
          case 'guid':
            item.guid = xNode.innerXml;
            break;
          case 'category':
            item.category = (item.category == null ? '' : ',') + xNode.innerText;
            break;
          case 'comments':
            item.comments = xNode.innerXml;
            break;
          // case 'enclosure':
          //   item.enclosure = xNode.outerXml;
          //   break;
          case 'source':
            item.source = xNode.innerText;
            break;
          case 'pubDate':
            final dt = item.parseRSSString(xNode.innerText);
            if (dt != null)
              item.pubDate = dt.millisecondsSinceEpoch;
            else
              log('Error pubDate format: ${xNode.innerXml}');
            break;
          // case 'image':
          // case 'cloud':
          // case 'docs':
          // case 'copyright':
          // case 'managingEditor':
          // case 'webMaster':
          // case 'skipHours':
          // case 'skipDays':
          // case 'item':
          //   break;
          default:
            log('Ukjent element: ${xNode.name}=>${xNode.text}');
        }
      } else
        log('Ukjent nodetype: ${xNode.nodeType}=>${xNode.outerXml}');
    });
    return item;
  }
}
