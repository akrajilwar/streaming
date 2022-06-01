import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:uuid/uuid.dart';

import './signal.dart';

class Streaming4Page extends StatefulWidget {
  final bool isPub;
  const Streaming4Page(this.isPub, {Key? key}) : super(key: key);

  @override
  State<Streaming4Page> createState() => _Streaming4PageState();
}

class _Streaming4PageState extends State<Streaming4Page> {
  Signal? _signal;

  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  connect() async {
    _signal = Signal(widget.isPub)..connect();

    _signal?.onLocalStream = (stream) {
      setState(() {
        _localRenderer.srcObject = stream;
      });
    };

    _signal?.onAddRemoteStream = (stream) {
      setState(() {
        _remoteRenderer.srcObject = stream;
      });
    };
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
            widget.isPub
                ? ElevatedButton(
                    onPressed: () => _sendMessage(), child: const Text('Start'))
                : const SizedBox()
          ],
        ),
      ),
    );
  }

  _sendMessage() async {
    _signal?.sendStream();
  }

}
