import 'package:logging/logging.dart';
import 'package:moor/moor.dart' as moor;
import 'package:rss_feed_reader/database/database.dart';
import 'package:rss_feed_reader/models/xml_mapper/base_mapper.dart';
import 'package:rss_feed_reader/models/xml_mapper/item_mapper.dart';
import 'package:xml/xml.dart';

class ChannelMapper extends XMLBaseMapper {
  static final _log = Logger('ChannelMapper');
  String? description, title, link, language, updatePeriod, atomlink, textInput, generator, category, image;
  int? lastBuildDate, ttl, updateFrequency, pubDate;
  List<ItemMapper> items = [];

  ChannelMapper();
  factory ChannelMapper.fromXML(XmlElement xEl) {
    ChannelMapper channel = ChannelMapper();
    xEl.children.forEach((xNode) {
      if (xNode is XmlElement) {
        switch (xNode.name.toString()) {
          case 'title':
            channel.title = xNode.innerText;
            break;
          case 'description':
            channel.description = xNode.innerXml;
            break;
          case 'link':
            channel.link = xNode.innerText.isEmpty ? xNode.getAttribute('href') : xNode.innerText;
            break;
          case 'atom:link':
          case 'id':
            if (channel.atomlink != null) channel.atomlink = xNode.innerText.isEmpty ? xNode.getAttribute('href') : xNode.innerText;
            break;
          case 'language':
            channel.language = xNode.innerText;
            break;
          case 'updatePeriod':
          case 'sy:updatePeriod':
            channel.updatePeriod = xNode.innerText;
            break;
          case 'sy:updateFrequency':
          case 'updateFrequency':
            if (xNode.innerText.isNotEmpty) {
              channel.updateFrequency = int.tryParse(xNode.innerText);
              if (channel.updateFrequency == null) _log.info('Invalid updateFrequency: ${xNode.innerXml}');
            }
            break;
          case 'textInput':
            channel.textInput = xNode.innerXml;
            break;
          case 'category':
          case 'itunes:category':
            final String text = xNode.innerText.isEmpty ? (xNode.getAttribute('text') ?? '') : xNode.innerText;
            channel.category = ((channel.category?.isEmpty ?? true) ? '' : ',') + text;
            break;
          case 'generator':
            channel.generator = xNode.innerXml;
            break;
          case 'ttl':
            if (xNode.innerText.isNotEmpty) {
              channel.ttl = int.tryParse(xNode.innerText);
              if (channel.ttl == null) _log.warning('Invalid updateFrequency: ${xNode.innerXml}');
            }
            break;
          case 'lastBuildDate':
            final dt = channel.parseRSSString(xNode.innerText);
            if (dt != null)
              channel.lastBuildDate = dt.millisecondsSinceEpoch;
            else
              _log.warning('Error lastBuildDate format: ${xNode.innerXml}');
            break;
          case 'pubDate':
          case 'updated':
            final dt = channel.parseRSSString(xNode.innerText);
            if (dt != null)
              channel.pubDate = dt.millisecondsSinceEpoch;
            else
              _log.warning('Error pubDate format: ${xNode.innerText}');
            break;
          case 'image':
          case 'itunes:image':
            if (channel.image == null) {
              if (xNode.getElement("url")?.innerText.isNotEmpty ?? false)
                channel.image = xNode.getElement("url")!.innerText;
              else if (xNode.getElement("href")?.innerText.isNotEmpty ?? false)
                channel.image = xNode.getElement("href")!.innerText;
              else
                channel.image = xNode.innerText.isEmpty ? xNode.getAttribute('href') : xNode.innerText;
            }
            break;
          case 'cloud':
          case 'author':
          case 'docs':
          case 'copyright':
          case 'managingEditor':
          case 'webMaster':
          case 'skipHours':
          case 'skipDays':
          case 'feedburner:info':
          case 'atom10:link':
          case 'feedburner:browserFriendly':
          case 'webfeeds:logo':
          case 'webfeeds:analytics':
          case 'meta':
          case 'itunes:author':
          case 'itunes:summary':
          case 'itunes:subtitle':
          case 'itunes:owner':
          case 'itunes:keywords':
          case 's:counts':
          case 'itunes:explicit':
          case 'openSearch:startIndex':
          case 'openSearch:totalResults':
          case 'openSearch:itemsPerPage':
          case 'yt:channelId':
          case 'published':
          case 'site':
            break;
          case 'item':
          case 'entry':
            channel.items.add(ItemMapper.fromXML(xNode));
            break;
          default:
            _log.info('Ukjent channel element: ${xNode.name}=>${xNode.innerXml}');
        }
      } else if (xNode.nodeType != XmlNodeType.TEXT || xNode.text.trim().isNotEmpty) _log.info('Ukjent nodetype: ${xNode.nodeType}=>${xNode.outerXml}');
    });
    return channel;
  }
  // bool equals(FeedData feed) => feed.pubDate == pubDate && feed.link == (atomlink ?? link);
  FeedCompanion toFeedCompanion({String? url}) => FeedCompanion(
        title: moor.Value(title!),
        description: moor.Value(description),
        category: moor.Value(category),
        ttl: moor.Value(ttl),
        pubDate: moor.Value(pubDate),
        link: moor.Value(link ?? atomlink),
        lastBuildDate: moor.Value(lastBuildDate),
        language: moor.Value(language),
      );
  @override
  String toString() {
    return 'Channel($description, $title, $link, $language, $updatePeriod, $atomlink, $textInput, $generator, $category, $lastBuildDate, $ttl, $updateFrequency, $pubDate, [${items.length}])';
  }
}
