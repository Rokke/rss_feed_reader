import 'dart:developer';
import 'package:rss_feed_reader/database/database.dart';
import 'package:rss_feed_reader/models/xml_mapper/base_mapper.dart';
import 'package:rss_feed_reader/models/xml_mapper/item_mapper.dart';
import 'package:xml/xml.dart';

class ChannelMapper extends XMLBaseMapper {
  String? description, title, link, language, updatePeriod, atomlink, textInput, generator, category;
  int? lastBuildDate, ttl, updateFrequency, pubDate;
  List<ItemMapper> items = [];

  ChannelMapper();
  factory ChannelMapper.fromXML(XmlElement xEl) {
    ChannelMapper channel = ChannelMapper();
    xEl.children.forEach((xNode) {
      if (xNode is XmlElement) {
        switch (xNode.name.toString()) {
          case 'title':
            channel.title = xNode.innerXml;
            break;
          case 'description':
            channel.description = xNode.innerXml;
            break;
          case 'link':
            channel.link = xNode.innerXml;
            break;
          case 'atom:link':
            channel.atomlink = xNode.innerXml;
            break;
          case 'language':
            channel.language = xNode.innerXml;
            break;
          case 'updatePeriod':
          case 'sy:updatePeriod':
            channel.updatePeriod = xNode.innerXml;
            break;
          case 'sy:updateFrequency':
          case 'updateFrequency':
            channel.updateFrequency = int.tryParse(xNode.innerText);
            break;
          case 'textInput':
            channel.textInput = xNode.innerXml;
            break;
          case 'category':
            channel.category = (channel.category == null ? '' : ',') + xNode.innerText;
            break;
          case 'generator':
            channel.generator = xNode.innerXml;
            break;
          case 'ttl':
            channel.ttl = int.tryParse(xNode.innerXml);
            break;
          case 'lastBuildDate':
            final dt = channel.parseRSSString(xNode.innerText);
            if (dt != null)
              channel.lastBuildDate = dt.millisecondsSinceEpoch;
            else
              log('Error lastBuildDate format: ${xNode.innerXml}');
            break;
          case 'pubDate':
            final dt = channel.parseRSSString(xNode.innerText);
            if (dt != null)
              channel.pubDate = dt.millisecondsSinceEpoch;
            else
              log('Error pubDate format: ${xNode.innerXml}');
            break;
          case 'image':
          case 'cloud':
          case 'docs':
          case 'copyright':
          case 'managingEditor':
          case 'webMaster':
          case 'skipHours':
          case 'skipDays':
            break;
          case 'item':
            channel.items.add(ItemMapper.fromXML(xNode));
            break;
          default:
            log('Ukjent element: ${xNode.name}=>${xNode.text}');
        }
      } else if (xNode.nodeType != XmlNodeType.TEXT || xNode.text.trim().isNotEmpty) log('Ukjent nodetype: ${xNode.nodeType}=>${xNode.outerXml}');
    });
    return channel;
  }
  bool equals(FeedData feed) => feed.pubDate == pubDate && feed.link == (atomlink ?? link);
  @override
  String toString() {
    return 'Channel($description, $title, $link, $language, $updatePeriod, $atomlink, $textInput, $generator, $category, $lastBuildDate, $ttl, $updateFrequency, $pubDate, [${items.length}])';
  }
}
