import 'dart:convert';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:streaming/stream3/signaling.dart';
import 'package:uuid/uuid.dart';

import '../websocket.dart';

class Signal {
  Signal(this.isPub);

  // final String _url = "wss://aucprobid.azurewebsites.net/webcastauction";
  final String _url = "ws://192.168.29.122:8080";

  final String sessionId = 'test session';
  final String _uuid = const Uuid().v4();

  SimpleWebSocket? _socket;
  bool isPub;

  MediaStream? _localStream;
  Function(dynamic event)? onPeersUpdate;
  Function(MediaStream stream)? onLocalStream;
  Function(MediaStream stream)? onAddRemoteStream;

  final JsonEncoder _encoder = const JsonEncoder();
  final JsonDecoder _decoder = const JsonDecoder();

  String get sdpSemantics =>
      WebRTC.platformIsWindows ? 'plan-b' : 'unified-plan';

  final Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'url': 'stun:stun.l.google.com:19302'},
      {
        "urls": ["turn:13.250.13.83:3478?transport=udp"],
        "username": "YzYNCouZM1mhqhmseWk6",
        "credential": "YzYNCouZM1mhqhmseWk6"
      }
    ]
  };

  final Map<String, dynamic> _config = {
    'mandatory': {},
    'optional': [
      {'DtlsSrtpKeyAgreement': true},
    ]
  };

  connect() async {
    _socket = SimpleWebSocket(_url);

    _socket?.onOpen = () {
      print('Websocket: onOpen');
      _send('new', {
        'sessionId': sessionId,
        'userId': _uuid,
        'isHost': isPub,
      });
    };

    _socket?.onMessage = (message) {
      print('Websocket: Received data: $message');
      // onMessage(_decoder.convert(message));
    };

    await _socket?.connect();
  }

  _send(event, data) {
    var request = {};
    request["type"] = event;
    request["data"] = data;
    _socket?.send(_encoder.convert(request));
  }

  sendStream() async {
    _localStream = await createStream('video', false);
    // _send('stream', _localStream?.getVideoTracks()[0]);
  }

  Future<MediaStream> createStream(String media, bool userScreen) async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': userScreen ? false : true,
      'video': userScreen
          ? true
          : {
              'mandatory': {
                'minWidth': '640',
                'minHeight': '480',
                'minFrameRate': '30',
              },
              'facingMode': 'user',
              'optional': [],
            }
    };
    MediaStream stream = userScreen
        ? await navigator.mediaDevices.getDisplayMedia(mediaConstraints)
        : await navigator.mediaDevices.getUserMedia(mediaConstraints);

    onLocalStream?.call(stream);

    return stream;
  }
}
