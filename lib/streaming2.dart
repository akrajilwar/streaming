import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:streaming/websocket.dart';

class Streaming2Page extends StatefulWidget {
  const Streaming2Page({Key? key}) : super(key: key);

  @override
  State<Streaming2Page> createState() => _Streaming2PageState();
}

class _Streaming2PageState extends State<Streaming2Page> {
  final String _url = "wss://aucprobid.azurewebsites.net/webcastauction";

  final _ctrlMessage = TextEditingController();

  SimpleWebSocket? _socket;
  List<String> _messagesList = [];

  connect() async {
    _socket = SimpleWebSocket(_url);

    _socket?.onMessage = (message) {
      print('Websocket: Received data: $message');
      setState(() {
        _messagesList.add(message);
      });
    };

    await _socket?.connect();
  }

  @override
  void initState() {
    super.initState();
    connect();
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
                child: ListView(
              shrinkWrap: true,
                  children: _messagesList.map((e) => Text(e)).toList(),
            )),
            TextFormField(
              controller: _ctrlMessage,
              decoration: const InputDecoration(
                  hintText: 'Type message', isDense: true),
            ),
            ElevatedButton(onPressed: () => _sendMessage(), child: const Text('Send'))
          ],
        ),
      ),
    );
  }

  _sendMessage() {
    _socket?.send(_ctrlMessage.text);
    _ctrlMessage.clear();
  }

  _send() {

  }
}
