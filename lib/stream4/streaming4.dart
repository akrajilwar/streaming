import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:uuid/uuid.dart';

import '../websocket.dart';

class Streaming4Page extends StatefulWidget {
  final bool isPub;
  const Streaming4Page(this.isPub, {Key? key}) : super(key: key);

  @override
  State<Streaming4Page> createState() => _Streaming4PageState();
}

class _Streaming4PageState extends State<Streaming4Page> {
  final String _url = "wss://aucprobid.azurewebsites.net/webcastauction";
  final String sessionId = 'test session';

  final String _uuid = const Uuid().v4();

  SimpleWebSocket? _socket;

  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

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
    };

    _socket?.onMessage = (message) {
      print('Websocket: Received data: $message');
    };

    onLocalStream = (stream) {
      setState(() {
        _localRenderer.srcObject = stream;
      });
    };

    await _socket?.connect();
  }

  initRenderer() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  @override
  void initState() {
    super.initState();
    initRenderer();
    connect();
  }

  @override
  deactivate() {
    super.deactivate();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Streaming Demo"),
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: RTCVideoView(
                widget.isPub ? _localRenderer : _remoteRenderer,
              ),
            ),
            ElevatedButton(
                onPressed: () => _sendMessage(), child: const Text('Start'))
          ],
        ),
      ),
    );
  }

  _sendMessage() async {

  }
}
