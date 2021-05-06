import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:rss_feed_reader/providers/feed_list.dart';

const DEFAULT_PORT = kDebugMode ? 3343 : 3344;

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
  Socket? _clientSocket;
  ValueNotifier<bool> isConnected = ValueNotifier(false);
  SocketServerHandler(this.read, {this.port = DEFAULT_PORT}) {
    _startListener();
  }
  _startListener() async {
    if (_serverSocket == null) {
      _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, port);
      _serverSocket?.listen(_newConnection, onDone: _serverDone, onError: _serverError);
      _log.fine('_startListener');
    } else
      _log.info('_startListener()-already active');
  }

  dispose() {
    _closeServerListener();
    _closeClient();
  }

  _serverDone() {
    debugPrint('_serverDone');
  }

  _serverError(err) {
    debugPrint('_serverError($err)');
  }

  _closeServerListener() {
    _log.info('_closeServerListener($_serverSocket)');
    _serverSocket?.close();
    _serverSocket = null;
  }

  _newConnection(Socket socket) {
    if (_clientSocket == null) {
      _closeServerListener();
      _clientSocket = socket;
      _log.info('_newConnection(${_clientSocket?.remoteAddress}:${_clientSocket?.remotePort})');
      _clientSocket?.listen(_clientDataReceived, onDone: _clientDisconnected, onError: _clientError);
      _clientSocket?.write('CONNECTED:1');
      isConnected.value = _clientSocket != null;
    } else {
      _log.warning('_newConnection(${socket.remoteAddress}:${socket.remotePort}) - Someone is already connected so ignoring');
      _clientSendData({'code': -1, 'data': 'already connected'}, socket: socket);
      socket.destroy();
    }
  }

  _clientDisconnected() {
    _log.info('_clientDisconnected(${_clientSocket?.remoteAddress}:${_clientSocket?.remotePort})');
    _closeClient();
    _startListener();
  }

  _closeClient() {
    _log.info('_closeClient($_clientSocket)');
    _clientSocket?.close();
    _clientSocket?.destroy();
    _clientSocket = null;
    isConnected.value = _clientSocket != null;
  }

  _clientError(err) {
    _log.warning('_clientError($err)');
  }

  _clientSendData(Map<String, dynamic> json, {Socket? socket}) {
    socket ??= _clientSocket;
    assert(socket != null, 'Trying to send when no connected clients');
    final strSend = jsonEncode(json);
    _log.fine('_clientSendData: $strSend');
    socket?.write(json);
  }

  _clientDataReceived(Uint8List data) {
    String strData = utf8.decode(data);
    _log.info('_clientDataReceived($data)');
    Map<String, dynamic> json = jsonDecode(strData);
    switch (json['command']) {
      case 'feed':
        _log.info('_clientDataReceived - unread feeds');
        final feedProvider = read(providerFeedHeader);
        if (feedProvider.selectedArticle == null) feedProvider.changeSelectedArticle = 0;
        if (feedProvider.selectedArticle != null) {
          _clientSendData({'code': 1, 'data': feedProvider.selectedArticle!.toJson()});
        } else {
          _log.info('_clientDataReceived - no unread feeds');
          _clientSendData({'code': 0, 'data': 'No feeds'});
        }
        break;
      default:
        _log.warning('_clientDataReceived - invalid command: (${json['command']})');
    }
  }
}
