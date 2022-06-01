import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:streaming/stream3/signaling.dart';

class Streaming3Page extends StatefulWidget {
  final bool isPub;
  final String userId;
  const Streaming3Page(this.isPub, this.userId, {Key? key}) : super(key: key);

  @override
  State<Streaming3Page> createState() => _Streaming3PageState();
}

class _Streaming3PageState extends State<Streaming3Page> {
  Signaling? _signaling;

  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  @override
  void initState() {
    super.initState();
    initRenderer();
    _connect();
  }

  initRenderer() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  _connect() async {
    _signaling = Signaling(widget.userId)..connect();

    _signaling?.onPeersUpdate = ((event) {
      if (widget.isPub) {
        _signaling?.invite('video', false);
      }
    });

    _signaling?.onLocalStream = ((stream) {
      setState(() {
        _localRenderer.srcObject = stream;
        print(
            "Websocket: {mode: local, uuid: ${widget.userId}, stream: ${stream.id}, "
            "video: ${stream.getVideoTracks()[0].id}, "
            "audio: ${stream.getAudioTracks()[0].id}}");
      });
    });

    _signaling?.onAddRemoteStream = ((_, stream) {
      setState(() {
        _remoteRenderer.srcObject = stream;
        print(
            "Websocket: {mode: remote, uuid: ${widget.userId}, stream: ${stream.id}, "
            "video: ${stream.getVideoTracks()[0].id}, "
            "audio: ${stream.getAudioTracks()[0].id}}");
      });
    });

    _signaling?.onRemoveRemoteStream = ((_, stream) {
      setState(() {
        _remoteRenderer.srcObject = null;
      });
    });
  }

  @override
  deactivate() {
    super.deactivate();
    _signaling?.close();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
  }

  @override
  dispose() {
    super.dispose();
    _signaling?.close();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Streaming Demo (${widget.userId})"),
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
                onPressed: () => _publishVideo(), child: const Text('Start'))
          ],
        ),
      ),
    );
  }

  _publishVideo() {
    if (widget.isPub) {
      _signaling?.start('video', false);
    }
  }
}
