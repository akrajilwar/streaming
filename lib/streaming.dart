import 'package:flutter/material.dart';
// import 'package:flutter_ion/flutter_ion.dart' as ion;
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:uuid/uuid.dart';

class Participant {
  Participant(this.title, this.renderer, this.stream);
  MediaStream? stream;
  String title;
  RTCVideoRenderer renderer;
}

class StreamingPage extends StatefulWidget {
  final bool isPub;
  const StreamingPage(this.isPub, {Key? key}) : super(key: key);

  @override
  State<StreamingPage> createState() => _StreamingPageState();
}

class _StreamingPageState extends State<StreamingPage> {
  List<Participant> plist = <Participant>[];
  bool isPub = false;

  final RTCVideoRenderer _localRender = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRender = RTCVideoRenderer();

  @override
  void initState() {
    super.initState();
    isPub = widget.isPub;
    initRender();
    initSfu();
  }

  void initRender() async {
    await _localRender.initialize();
    await _remoteRender.initialize();
  }

  @override
  deactivate() {
    super.deactivate();
    _localRender.dispose();
    _remoteRender.dispose();
  }

  getUrl() {
    // String url = 'wss://aucprobid.azurewebsites.net/webcastauction';
    String url = 'http://192.168.29.122:8080';

    // return ion.JsonRPCSignal(url);
  }

  // ion.Client? _client;
  // ion.LocalStream? _localStream;
  final String _uuid = const Uuid().v4();

  static final defaultConfig = {
    'iceServers': [
      {'url': 'stun:stun.l.google.com:19302'},
    ],
    'sdpSemantics': 'unified-plan'
  };

  void initSfu() async {
    // ion.Signal signal = await getUrl();
    // _client = await ion.Client.create(
    //     sid: '9636896968', uid: _uuid, signal: signal, config: defaultConfig);
    // if (!isPub) {
    //   _client?.ontrack = (track, ion.RemoteStream remoteStream) {
    //     print(track.id);
    //     if (track.kind == 'video') {
    //       print("ontrack: remote stream => ${remoteStream.id}");
    //       setState(() {
    //         _remoteRender.srcObject = remoteStream.stream;
    //       });
    //     }
    //   };
    // }
  }

  void publish() async {
    // _localStream = await ion.LocalStream.getUserMedia(
    //     constraints: ion.Constraints.defaults..simulcast = false);
    //
    // setState(() {
    //   _localRender.srcObject = _localStream?.stream;
    // });
    //
    // await _client?.publish(_localStream!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Streaming Demo"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[getVideoView()],
        ),
      ),
      floatingActionButton:
          getFab(), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Widget getVideoView() {
    return Expanded(child: RTCVideoView(isPub ? _localRender : _remoteRender));
  }

  Widget getFab() {
    if (!isPub) {
      return Container();
    } else {
      return FloatingActionButton(
        onPressed: publish,
        child: const Icon(Icons.video_call),
      );
    }
  }
}
