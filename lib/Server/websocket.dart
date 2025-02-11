import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:server_websocket/Server/server.dart';
import 'constant.dart';

class WebsocketServer {
  static final WebsocketServer _singleton = WebsocketServer._internal();
  factory WebsocketServer() => _singleton;

  final int port;
  String ipAddress = "Unknown";
  final List<WebSocket> clients = []; // List to store connected clients
  bool _isRunning = false;

  WebsocketServer._internal({this.port = PORT});

  Future<void> start() async {
    if (_isRunning) {
      print('WebSocket server is already running.');
      return;
    }
    _isRunning = true;

    try {
      await MongoDB_Server.connect();
      ipAddress = await _getLocalIPAddress();

      HttpServer server = await HttpServer.bind(ipAddress, port);
      print("WebSocket Server running on ws://$ipAddress:$port");

      server.transform(WebSocketTransformer()).listen((WebSocket socket) async {
        clients.add(socket);
        print("New WebSocket client connected");

        await sendExistingData(socket);

        socket.done.then((_) {
          print("WebSocket client disconnected");
          clients.remove(socket);
        });
      });

      watchDatabaseChanges();
    } catch (e) {
      print("Error starting WebSocket server: $e");
      _isRunning = false;
    }
  }

  Future<String> _getLocalIPAddress() async {
    final interfaces = await NetworkInterface.list();
    for (var interface in interfaces) {
      for (var addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4 && !addr.address.startsWith("127.")) {
          return addr.address;
        }
      }
    }
    return "0.0.0.0";
  }

  bool isRunning() => _isRunning;

  Future<void> stop() async {
    if (!_isRunning) return;
    print("Stopping WebSocket Server...");

    for (var client in clients) {
      await client.close();
    }
    clients.clear();
    _isRunning = false;
    print("WebSocket Server Stopped.");
  }

  Future<void> sendExistingData(WebSocket socket) async {
    try {
      var data = await MongoDB_Server.collection.find().toList();
      socket.add(jsonEncode(data));
    } catch (e) {
      print("Error fetching existing data: $e");
    }
  }

  void watchDatabaseChanges() {
    MongoDB_Server.watchChanges().listen((change) {
      print("Database change detected: $change");
      sendUpdateToClients(jsonEncode(change));
    }, onError: (error) {
      print("Error watching database changes: $error");
    });
  }

  void sendUpdateToClients(String message) {
    for (var client in clients) {
      client.add(message);
    }
    print("Sent update to \${clients.length} clients");
  }
}
