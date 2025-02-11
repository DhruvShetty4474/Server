import 'package:flutter/material.dart';

import 'Server/websocket.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Server_UI(),
    );
  }
}

class Server_UI extends StatefulWidget {
  const Server_UI({super.key});

  @override
  State<Server_UI> createState() => _Server_UIState();
}

class _Server_UIState extends State<Server_UI> {
  WebsocketServer server = WebsocketServer();
  @override
  Widget build(BuildContext context) {
    return SafeArea(child: Scaffold(
      body: Center(
        child: Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                  onPressed: (){
                    server.start();
                  },
                  child: Text('Start Server')),

              SizedBox(height: 10,),

              ElevatedButton(
                  onPressed: (){
                    server.stop();
                  },
                  child: Text('Stop Server'))
            ],
          ),
        ),
      ),
    ));
  }
}

