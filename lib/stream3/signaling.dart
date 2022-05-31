import 'dart:convert';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:uuid/uuid.dart';

import '../websocket.dart';

class Session {
  Session({required this.sessionId});
  String sessionId;
  RTCPeerConnection? pc;
  RTCDataChannel? dc;
  List<RTCIceCandidate> remoteCandidates = [];
}

class Signaling {
  final String _url = "wss://aucprobid.azurewebsites.net/webcastauction";
  final String sessionId = 'test session';

  final String _uuid; // = const Uuid().v4();

  SimpleWebSocket? _socket;
  Session? session;

  Signaling(this._uuid);

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

  final Map<String, dynamic> _dcConstraints = {
    'mandatory': {
      'OfferToReceiveAudio': false,
      'OfferToReceiveVideo': false,
    },
    'optional': [],
  };

  final JsonEncoder _encoder = const JsonEncoder();
  final JsonDecoder _decoder = const JsonDecoder();

  MediaStream? _localStream;
  final List<MediaStream> _remoteStreams = <MediaStream>[];
  final Map<String, Session> _sessions = {};

  Function(dynamic event)? onPeersUpdate;
  Function(MediaStream stream)? onLocalStream;
  Function(Session session, MediaStream stream)? onAddRemoteStream;
  Function(Session session, MediaStream stream)? onRemoveRemoteStream;

  connect() async {
    _socket = SimpleWebSocket(_url);

    _socket?.onOpen = () {
      print('Websocket: onOpen');
      _send('new', {
        'sessionId': sessionId,
        'userId': _uuid,
      });
    };

    _socket?.onMessage = (message) {
      print('Websocket: Received data: $message');
      onMessage(_decoder.convert(message));
    };

    _socket?.onClose = (int? code, String? reason) {
      print('Websocket: Closed by server [$code => $reason]!');
    };

    await _socket?.connect();
  }

  _send(event, data) {
    var request = {};
    request["type"] = event;
    request["data"] = data;
    _socket?.send(_encoder.convert(request));
  }

  void start(String media, bool useScreen) async {
    Session session = await _createSession(null,
        sessionId: sessionId,
        media: media,
        screenSharing: useScreen,
        isPub: true);
    _sessions[sessionId] = session;
  }

  void invite(String media, bool useScreen) async {
    Session? s = _sessions[sessionId];
    if (s != null) {
      _offerStream(s, media);
    }
  }

  void accept(String sessionId) {
    var session = _sessions[sessionId];
    if (session == null) {
      return;
    }
    _joinStream(session, 'video');
  }

  void onMessage(message) async {
    Map<String, dynamic> mapData = message;
    var data = mapData['data'];

    switch (mapData['type']) {
      case 'new':
        {
          if (onPeersUpdate != null) {
            onPeersUpdate?.call(data);
          }
        }
        break;
      case 'candidate':
        {
          var sessionId = data['sessionId'];
          var candidateMap = data['candidate'];
          var session = _sessions[sessionId];

          RTCIceCandidate candidate = RTCIceCandidate(candidateMap['candidate'],
              candidateMap['sdpMid'], candidateMap['sdpMLineIndex']);

          if (session != null) {
            if (session.pc != null) {
              await session.pc?.addCandidate(candidate);
            } else {
              session.remoteCandidates.add(candidate);
            }
          } else {
            _sessions[sessionId] = Session(
              sessionId: sessionId,
            )..remoteCandidates.add(candidate);
          }
        }
        break;
      case 'offer':
        {
          var sessionId = data['sessionId'];
          var description = data['description'];
          var media = data['media'];

          var session = _sessions[sessionId];

          var newSession = await _createSession(session,
              sessionId: sessionId,
              media: media,
              screenSharing: false,
              isPub: false);

          _sessions[sessionId] = newSession;

          await newSession.pc?.setRemoteDescription(
              RTCSessionDescription(description['sdp'], description['type']));
          // await _joinStream(newSession, media);

          if (newSession.remoteCandidates.isNotEmpty) {
            for (var candidate in newSession.remoteCandidates) {
              await newSession.pc?.addCandidate(candidate);
            }
            newSession.remoteCandidates.clear();
          }
        }
        break;
      case 'join':
        {
          var description = data['description'];
          var sessionId = data['sessionId'];
          var session = _sessions[sessionId];

          session?.pc?.setRemoteDescription(
              RTCSessionDescription(description['sdp'], description['type']));
        }
        break;
      case 'keepAlive':
        {
          print('keepAlive response!');
        }
        break;
      default:
        break;
    }
  }

  Future<void> _offerStream(Session session, String media) async {
    try {
      RTCSessionDescription s =
          await session.pc!.createOffer(media == 'data' ? _dcConstraints : {});
      await session.pc!.setLocalDescription(s);

      _send('offer', {
        'sessionId': session.sessionId,
        'userId': _uuid,
        'description': {'sdp': s.sdp, 'type': s.type},
        'media': media,
      });
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> _joinStream(Session session, String media) async {
    print("Websocket: ${session.sessionId} & $media");
    try {
      RTCSessionDescription s =
          await session.pc!.createAnswer(media == 'data' ? _dcConstraints : {});
      await session.pc!.setLocalDescription(s);

      _send('join', {
        'sessionId': session.sessionId,
        'userId': _uuid,
        'description': {'sdp': s.sdp, 'type': s.type},
      });
    } catch (e) {
      print(e.toString());
    }
  }

  Future<Session> _createSession(Session? session,
      {required String sessionId,
      required String media,
      required bool screenSharing,
      required bool isPub}) async {
    var newSession = session ?? Session(sessionId: sessionId);

    if (isPub) {
      _localStream = await createStream(media, screenSharing);
    }

    RTCPeerConnection pc = await createPeerConnection({
      ..._iceServers,
      ...{'sdpSemantics': sdpSemantics}
    }, _config);

    switch (sdpSemantics) {
      case 'unified-plan':
        pc.onTrack = (event) {
          if (event.track.kind == 'video') {
            onAddRemoteStream?.call(newSession, event.streams[0]);
          }
        };
        if (isPub) {
          _localStream!.getTracks().forEach((track) {
            pc.addTrack(track, _localStream!);
          });
        }
        break;
    }

    pc.onIceCandidate = (candidate) async {
      if (candidate == null) {
        print('onIceCandidate: complete!');
        return;
      }

      await Future.delayed(
          const Duration(seconds: 1),
          () => _send('candidate', {
                'sessionId': sessionId,
                'userId': _uuid,
                'candidate': {
                  'sdpMLineIndex': candidate.sdpMlineIndex,
                  'sdpMid': candidate.sdpMid,
                  'candidate': candidate.candidate,
                },
              }));
    };

    pc.onIceConnectionState = (state) {};

    pc.onRemoveStream = (stream) {
      onRemoveRemoteStream?.call(newSession, stream);
      _remoteStreams.removeWhere((it) {
        return (it.id == stream.id);
      });
    };

    newSession.pc = pc;
    return newSession;
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

  close() async {
    await _cleanSessions();
    _socket?.close();
  }

  Future<void> _cleanSessions() async {
    if (_localStream != null) {
      _localStream!.getTracks().forEach((element) async {
        await element.stop();
      });
      await _localStream!.dispose();
      _localStream = null;
    }
    _sessions.forEach((key, sess) async {
      await sess.pc?.close();
      await sess.dc?.close();
    });
    _sessions.clear();
  }
}
