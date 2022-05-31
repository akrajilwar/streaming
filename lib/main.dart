import 'package:flutter/material.dart';
import 'package:streaming/stream4/streaming4.dart';
import 'package:streaming/streaming.dart';
import 'package:streaming/streaming2.dart';
import 'package:streaming/stream3/streaming3.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final ctrl = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Streaming Demo"),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextFormField(controller: ctrl, keyboardType: TextInputType.number,),
              ElevatedButton(
                  onPressed: () => openPage(false),
                  child: const Text('Client')),
              ElevatedButton(
                  onPressed: () => openPage(true), child: const Text('Host')),
            ],
          ),
        ));
  }

  openPage(bool isPub) {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => Streaming3Page(isPub, ctrl.text)));
  }
}
