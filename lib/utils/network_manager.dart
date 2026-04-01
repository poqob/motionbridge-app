import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum NetworkConnectionState {
  disconnected,
  discovering,
  waitingApproval,
  connected,
}

class DiscoveredHost {
  final String ip;
  final String hostName;
  final int dataPort;
  final int wsPort;
  DateTime lastSeen;

  DiscoveredHost({
    required this.ip,
    required this.hostName,
    required this.dataPort,
    this.wsPort = 44445, // default
    required this.lastSeen,
  });
}

class NetworkManager {
  static final NetworkManager _instance = NetworkManager._internal();
  factory NetworkManager() => _instance;
  NetworkManager._internal() {
    _loadPairedHosts();
  }

  RawDatagramSocket?
  _socket; // localPort = 5000 (Listening for discovery_ack & Sending pairing_request/UDP data)
  RawDatagramSocket?
  _discoverySocket; // port = 44446 (Listening to host_announcement)
  WebSocket? _webSocket;
  Timer? _reconnectTimer;
  Timer? _staleHostTimer;

  final StreamController<NetworkConnectionState> _connectionStateController =
      StreamController<NetworkConnectionState>.broadcast();
  Stream<NetworkConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  final StreamController<List<DiscoveredHost>> _discoveredHostsController =
      StreamController<List<DiscoveredHost>>.broadcast();
  Stream<List<DiscoveredHost>> get discoveredHostsStream =>
      _discoveredHostsController.stream;

  NetworkConnectionState _currentState = NetworkConnectionState.disconnected;
  NetworkConnectionState get currentState => _currentState;

  final List<DiscoveredHost> _discoveredHosts = [];
  List<String> _pairedHostIps = [];
  String? _lastPairedHostIp;

  DiscoveredHost? _activeHost;
  DiscoveredHost? get activeHost => _activeHost;

  String deviceName = "MotionBridge";
  String deviceId = "unknown";
  final int localPort = 5000;
  final int hostBroadcastPort = 44446;

  Future<void> _loadPairedHosts() async {
    final prefs = await SharedPreferences.getInstance();
    _pairedHostIps = prefs.getStringList('paired_hosts') ?? [];
    _lastPairedHostIp = prefs.getString('last_paired_host');
  }

  Future<void> _savePairedHost(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_paired_host', ip);
    _lastPairedHostIp = ip;
    if (!_pairedHostIps.contains(ip)) {
      _pairedHostIps.add(ip);
      await prefs.setStringList('paired_hosts', _pairedHostIps);
    }
  }

  Future<void> unpairHost() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_paired_host');
    _lastPairedHostIp = null;
    disconnect();
  }

  void sendPacket(Map<String, dynamic> data) {
    if (_currentState != NetworkConnectionState.connected ||
        _activeHost == null ||
        _socket == null) {
      return;
    }

    try {
      final jsonString = jsonEncode(data);
      String type = data['t'] ?? '';
      if (type == 'C' || type == 'DRAG_START' || type == 'DRAG_END' || type == 'SWIPE_3') {
        if (_webSocket != null && _webSocket!.readyState == WebSocket.open) {
          _webSocket!.add(jsonString);
          if (kDebugMode) print("Sent via WebSocket: $jsonString");
        }
      } else {
        if (kDebugMode) print("Sent via UDP: $jsonString");
        final bytes = utf8.encode(jsonString);
        _socket?.send(
          bytes,
          InternetAddress(_activeHost!.ip),
          _activeHost!.dataPort,
        );
      }
    } catch (e) {
      if (kDebugMode) print("Packet send error: $e");
    }
  }

  void _setState(NetworkConnectionState state) {
    _currentState = state;
    _connectionStateController.add(state);
  }

  Future<void> startDiscovery({
    required String name,
    required String id,
  }) async {
    deviceName = name;
    deviceId = id;

    if (_currentState != NetworkConnectionState.disconnected) return;
    _setState(NetworkConnectionState.discovering);
    _discoveredHosts.clear();
    _discoveredHostsController.add(List.from(_discoveredHosts));

    try {
      // Primary socket for sending UDP data and receiving 'discovery_ack'
      _socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        localPort,
      );
      _socket?.broadcastEnabled = true;
      _socket?.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = _socket?.receive();
          if (datagram != null) {
            final msg = utf8.decode(datagram.data);
            _handleIncomingAck(msg, datagram.address);
          }
        }
      });

      // Socket to listen to Host Broadcasts
      _discoverySocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        hostBroadcastPort,
      );
      _discoverySocket?.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = _discoverySocket?.receive();
          if (datagram != null) {
            final msg = utf8.decode(datagram.data);
            _handleIncomingBroadcast(msg, datagram.address);
          }
        }
      });

      // Timer to clean up stale hosts that stopped broadcasting
      _staleHostTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        final now = DateTime.now();
        bool changed = false;
        _discoveredHosts.removeWhere((host) {
          final stale = now.difference(host.lastSeen).inSeconds > 10;
          if (stale) changed = true;
          return stale;
        });
        if (changed)
          _discoveredHostsController.add(List.from(_discoveredHosts));
      });
    } catch (e) {
      if (kDebugMode) print("Start discovery failed: $e");
      stopDiscovery();
    }
  }

  void _handleIncomingBroadcast(String msg, InternetAddress senderIp) {
    try {
      final json = jsonDecode(msg);
      if (json['type'] == 'host_announcement') {
        final hostName = json['name'] ?? "Unknown Host";
        final dataPort = json['port'] ?? 44444;

        final existingIdx = _discoveredHosts.indexWhere(
          (h) => h.ip == senderIp.address,
        );
        if (existingIdx >= 0) {
          _discoveredHosts[existingIdx].lastSeen = DateTime.now();
        } else {
          final newHost = DiscoveredHost(
            ip: senderIp.address,
            hostName: hostName,
            dataPort: dataPort,
            lastSeen: DateTime.now(),
          );
          _discoveredHosts.add(newHost);
          _discoveredHostsController.add(List.from(_discoveredHosts));

          // Auto-connect if it's the last paired host
          if (_currentState == NetworkConnectionState.discovering &&
              senderIp.address == _lastPairedHostIp) {
            connectToHost(newHost);
          }
        }
      }
    } catch (e) {
      // Ignore parse errors from unknown packets
    }
  }

  void _handleIncomingAck(String msg, InternetAddress senderIp) {
    try {
      final json = jsonDecode(msg);

      if (json['type'] == 'discovery_ack') {
        final wsPort = json['ws_port'] ?? 44445;

        // If we are waiting for approval from this specific host, try to connect via WS!
        if (_currentState == NetworkConnectionState.waitingApproval &&
            _activeHost?.ip == senderIp.address) {
          _connectWebSocket(_activeHost!.ip, wsPort);
        }
      } else if (json['type'] == 'disconnect') {
        disconnect();
      }
    } catch (e) {
      if (kDebugMode) print("Incoming ack error: $e");
    }
  }

  void connectToHost(DiscoveredHost host) {
    _activeHost = host;

    _webSocket?.close();
    _webSocket = null;
    _reconnectTimer?.cancel();

    _setState(NetworkConnectionState.waitingApproval);

    // Send pairing_request to host's data port
    if (_socket != null) {
      final payload = {
        "type": "pairing_request",
        "id": deviceId,
        "name": deviceName,
        "port": localPort,
      };
      _socket!.send(
        utf8.encode(jsonEncode(payload)),
        InternetAddress(host.ip),
        host.dataPort,
      );
    }
  }

  Future<void> _connectWebSocket(String ip, int port) async {
    try {
      final wsUrl = 'ws://$ip:$port';
      _webSocket = await WebSocket.connect(
        wsUrl,
      ).timeout(const Duration(seconds: 5));

      _webSocket!.listen(
        (message) {
          try {
            final json = jsonDecode(message);
            if (json['type'] == 'disconnect') {
              disconnect();
            } else if (json['type'] == 'connected_ack') {
              _savePairedHost(ip);
              _setState(NetworkConnectionState.connected);
            }
          } catch (e) {}
        },
        onDone: () => _handleWsDisconnect(),
        onError: (e) => _handleWsDisconnect(),
      );

      await _savePairedHost(ip);
      _setState(NetworkConnectionState.connected);
      _reconnectTimer?.cancel();
    } catch (e) {
      if (kDebugMode) print("WebSocket connection failed: $e");
      _handleWsDisconnect();
    }
  }

  void _handleWsDisconnect() {
    _webSocket?.close();
    _webSocket = null;

    if (_activeHost != null &&
        _currentState != NetworkConnectionState.disconnected &&
        _currentState != NetworkConnectionState.discovering) {
      _setState(NetworkConnectionState.waitingApproval);

      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(const Duration(seconds: 3), () {
        if (_activeHost != null) {
          connectToHost(_activeHost!); // Re-send pairing request
        }
      });
    }
  }

  void disconnect() {
    _activeHost = null;
    _webSocket?.close();
    _webSocket = null;
    _reconnectTimer?.cancel();

    _setState(
      NetworkConnectionState.discovering,
    ); // Fallback to discovery when manually disconnected
  }

  void stopDiscovery() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _staleHostTimer?.cancel();
    _staleHostTimer = null;

    _socket?.close();
    _socket = null;
    _discoverySocket?.close();
    _discoverySocket = null;

    if (_currentState != NetworkConnectionState.disconnected) {
      _setState(NetworkConnectionState.disconnected);
    }
  }
}
