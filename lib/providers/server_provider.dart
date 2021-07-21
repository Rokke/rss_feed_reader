import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:rss_feed_reader/database/database.dart';
import 'package:rss_feed_reader/models/rss_tree.dart';
import 'package:rss_feed_reader/providers/feed_list.dart';
import 'package:rss_feed_reader/providers/tweet_list.dart';

const DEFAULT_PORT = kDebugMode ? 3343 : 3344;
const _SOCKET_HEADHELLO = 'CONNECTED:';
const _SOCKET_VERSION = '1.0';
const CODE_ALREADY_CONNECTED = -99;
const blockedIP = ['45.'];

final providerSocketServer = Provider<SocketServerHandler>((ref) {
  final ret = SocketServerHandler(ref.read);
  ref.onDispose(() => ret.dispose());
  return ret;
});

class SocketServerHandler {
  final _log = Logger('SocketServerHandler');
  final int port;
  final Reader read;
  ServerSocket? _serverSocket;
  String clientVersion = '';
  int currentTweetIndex = 0;
  Socket? _clientSocket;
  ValueNotifier<bool?> isConnected = ValueNotifier(false);
  String get clientIP => _clientSocket?.remoteAddress.address ?? '?';
  SocketServerHandler(this.read, {this.port = DEFAULT_PORT}) {
    _startListener();
  }
  Future<void> _startListener() async {
    if (_serverSocket == null) {
      _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, port);
      _serverSocket?.listen(_newConnection, onDone: _serverDone, onError: _serverError);
      _log.fine('_startListener');
    } else {
      _log.info('_startListener()-already active');
    }
  }

  void dispose() {
    _closeServerListener();
    _closeClient();
  }

  void _serverDone() {
    debugPrint('_serverDone');
  }

  void _serverError(err) {
    debugPrint('_serverError($err)');
  }

  void _closeServerListener() {
    _log.info('_closeServerListener($_serverSocket)');
    _serverSocket?.close();
    _serverSocket = null;
  }

  void _newConnection(Socket socket) {
    if (_clientSocket == null) {
      _closeServerListener();
      if (blockedIP.any((element) => _clientSocket?.remoteAddress.address.startsWith(element) != false)) {
        _log.warning('_newConnection(${socket.remoteAddress}:${socket.remotePort}) - Blocked IP trying to connect');
        socket.destroy();
      }
      _clientSocket = socket;
      _log.info('_newConnection(${_clientSocket?.remoteAddress}:${_clientSocket?.remotePort})');
      _clientSocket?.listen(_clientDataReceived, onDone: _clientDisconnected, onError: _clientError);
      _clientSocket?.write('$_SOCKET_HEADHELLO$_SOCKET_VERSION');
      isConnected.value = _clientSocket != null;
      _clientSocket?.flush();
      Future.delayed(const Duration(milliseconds: 100), () => _selectAndSendFeed());
    } else {
      _log.warning('_newConnection(${socket.remoteAddress}:${socket.remotePort}) - Someone is already connected so ignoring');
      _clientSendData({'code': CODE_ALREADY_CONNECTED, 'data': 'already connected'}, socket: socket);
      socket.destroy();
    }
  }

  void _clientDisconnected() {
    _log.info('_clientDisconnected(${_clientSocket?.remoteAddress}:${_clientSocket?.remotePort})');
    _closeClient();
    _startListener();
  }

  void _closeClient() {
    _log.info('_closeClient($_clientSocket)');
    _clientSocket?.close();
    _clientSocket?.destroy();
    _clientSocket = null;
    clientVersion = '';
    isConnected.value = false;
  }

  void _clientError(err) {
    _log.warning('_clientError($err)');
  }

  void _clientSendData(Map<String, dynamic> json, {Socket? socket}) {
    socket ??= _clientSocket;
    assert(socket != null, 'Trying to send when no connected clients');
    final strSend = jsonEncode(json);
    _log.fine('_clientSendData: $strSend');
    socket?.write(strSend);
  }

  void _selectAndSendTweet({int tweetIndex = 0}) {
    assert(tweetIndex >= -1 && tweetIndex <= 1, 'Invalid tweetIndex: $tweetIndex');
    _log.info('_selectAndSendTweet($tweetIndex)');
    final tweetProvider = read(providerTweetHeader);
    if (tweetProvider.tweets.isEmpty) {
      _log.info('_selectAndSendTweet - no unread tweets');
      _clientSendData(_createJSON(code: -2, data: 'No tweets'));
    }
    if (tweetIndex == -1) {
      if (--currentTweetIndex < 0) currentTweetIndex = tweetProvider.tweets.length - 1;
    } else if (tweetIndex == 1) {
      if (++currentTweetIndex >= tweetProvider.tweets.length) currentTweetIndex = 0;
    }
    _clientSendData(_createJSON(code: 2, data: tweetProvider.tweets[currentTweetIndex].toJson()));
  }

  Future<void> _selectAndSendFeed({int changeIndex = 0}) async {
    _log.info('_selectAndSendFeed($changeIndex)');
    assert(changeIndex >= -1 || changeIndex <= 1, 'Invalid changeIndex: $changeIndex');
    final feedProvider = read(providerFeedHeader);
    if (feedProvider.selectedArticle == null) {
      feedProvider.changeSelectedArticle = 0;
    } else if (changeIndex == -1) {
      feedProvider.selectPreviousArticle();
    } else if (changeIndex == 1) feedProvider.selectNextArticle();
    if (feedProvider.selectedArticle != null) {
      await feedProvider.selectedArticle!.articleDescription(read(rssDatabase));
      _clientSendData(_createJSON(code: 1, data: feedProvider.selectedArticle!.toJson()));
    } else {
      _log.info('_selectAndSendFeed - no unread feeds');
      _clientSendData(_createJSON(code: -1, data: 'No feeds'));
    }
  }

  Map<String, dynamic> _createJSON({required int code, required dynamic data}) {
    final feedProvider = read(providerFeedHeader);
    final tweetProvider = read(providerTweetHeader);
    return {
      'code': code,
      'data': data,
      'articleCount': feedProvider.articles.length,
      'articleIndex': feedProvider.selectedArticleIndexNotifier.value,
      'tweetCount': tweetProvider.tweets.length,
      'tweetIndex': currentTweetIndex,
      'running': read(monitoringRunning).state,
    };
  }

  void _clientDataReceived(Uint8List data) {
    final utfString = utf8.decode(data);
    _log.info('_clientDataReceived($utfString)');
    if (isConnected.value == false || clientVersion.isEmpty) {
      if (utfString.startsWith(_SOCKET_HEADHELLO)) {
        clientVersion = utfString.split('$_SOCKET_HEADHELLO:').last;
        isConnected.value = _clientSocket != null;
        debugPrint('Connected: $clientVersion, ${isConnected.value}');
      } else {
        debugPrint('Invalid client request: "$utfString" != "$_SOCKET_HEADHELLO"');
        _closeClient();
      }
    } else {
      debugPrint('decode');
      final json = jsonDecode(utfString) as Map<String, dynamic>;
      debugPrint('decoded: $json');
      switch (json['command']) {
        case 'start_monitor':
          read(rssProvider).startMonitoring();
          break;
        case 'previous_feed':
          _selectAndSendFeed(changeIndex: -1);
          break;
        case 'next_feed':
          _selectAndSendFeed(changeIndex: 1);
          break;
        case 'feed':
          _selectAndSendFeed();
          break;
        case 'previous_tweet':
          _selectAndSendTweet(tweetIndex: -1);
          break;
        case 'next_tweet':
          _selectAndSendTweet(tweetIndex: 1);
          break;
        case 'tweet':
          _selectAndSendTweet();
          break;
        case 'tweet_read':
          final tweetProvider = read(providerTweetHeader);
          final id = json['id'] as int;
          if (id >= 0) {
            tweetProvider.removeTweet(id);
            _selectAndSendTweet();
          }
          break;
        case 'article_read':
          final feedProvider = read(providerFeedHeader);
          final id = json['id'] as int;
          if (id >= 0) {
            feedProvider.changeArticleStatusById(id: id);
            _selectAndSendFeed();
          }
          break;
        default:
          _log.warning('_clientDataReceived - invalid command: (${json['command']})');
      }
    }
  }
}
