import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';

class NetworkManager {
  static final NetworkManager _instance = NetworkManager._internal();
  factory NetworkManager() => _instance;
  NetworkManager._internal();

  RawDatagramSocket? _discoverySocket;
  Timer? _discoveryTimer;
  bool _isDiscovering = false;

  // Bilgileri saklamak için (SettingsProvider'dan eklenecek)
  String deviceName = "MotionBridge";
  String deviceId = "unknown";

  // Data komutları için soket eklenebilir. Şu an mock:
  void sendPacket(Map<String, dynamic> data) {
    try {
      final jsonString = jsonEncode(data);
      // Orijinal mock davranışı (Desktop bulunduğunda TCP veya bağlı UDP'den gidebilir)
      // debugPrint("📦 [MBP] Packet Sent: $jsonString");
    } catch (e) {
      debugPrint("❌ [MBP] Serialization err: $e");
    }
  }

  /// Keşif yayınını (UDP Broadcast) başlatır
  Future<void> startDiscovery({
    required String name,
    required String id,
  }) async {
    // Güncel bilgileri her durumda kaydet (isim değişmiş olabilir)
    deviceName = name;
    deviceId = id;
    
    if (_isDiscovering) return;
    _isDiscovering = true;

    try {
      // Herhangi bir ip'den UDP soketi aç (port rastgele veya 0 olabilir, çünkü biz göndericiyiz)
      _discoverySocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0,
      );
      _discoverySocket?.broadcastEnabled = true;

      debugPrint("🚀 [NetworkManager] Discovery started...");

      // Cihazın yerel IP'sini bulalım
      String localIp = "127.0.0.1";
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (!addr.isLoopback) {
            localIp = addr.address;
            break;
          }
        }
      }

      // Her 2 saniyede bir broadcast yayını at
      _discoveryTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        if (!_isDiscovering) {
          timer.cancel();
          return;
        }

        final payload = {
          "id": deviceId,
          "name": deviceName,
          "role": "controller",
          "os": Platform.operatingSystem,
          "ip": localIp,
          "port": 5000, // Controller'ın varsa dinleme portu
          "version": 1,
        };

        final data = utf8.encode(jsonEncode(payload));
        // Hedef port 44444 (Bunu desktop tarafında dinleyeceğiz)
        _discoverySocket?.send(data, InternetAddress("255.255.255.255"), 44444);
        debugPrint(
          "📡 [Discovery] Broadcast sent -> 255.255.255.255:44444 payload: $payload",
        );
      });

      // Cevapları dinleme kısmı
      _discoverySocket?.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = _discoverySocket?.receive();
          if (datagram != null) {
            final msg = utf8.decode(datagram.data);
            debugPrint(
              "🚨 [Discovery] Answer received from ${datagram.address.address}: $msg",
            );
            // Eğer masaüstü bizi bulduysa ve anlaştıysak broadcast'i durdurabiliriz.
            // stopDiscovery();
          }
        }
      });
    } catch (e) {
      debugPrint("❌ [NetworkManager] Discovery error: $e");
      stopDiscovery();
    }
  }

  void stopDiscovery() {
    _isDiscovering = false;
    _discoveryTimer?.cancel();
    _discoveryTimer = null;
    _discoverySocket?.close();
    _discoverySocket = null;
    debugPrint("🛑 [NetworkManager] Discovery stopped.");
  }
}
