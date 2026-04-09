import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class DictationChannel {
  static const MethodChannel _channel = MethodChannel(
    'com.motionbridge.app/dictation',
  );
  static const EventChannel _eventChannel = EventChannel(
    'com.motionbridge.app/dictation_events',
  );

  static Future<List<Map<String, String>>> getEngines() async {
    if (!Platform.isAndroid) return [];
    try {
      final List<dynamic>? result = await _channel.invokeListMethod<dynamic>(
        'getEngines',
      );
      if (result == null) return [];
      return result
          .map(
            (e) => {
              'packageName': e['packageName'] as String,
              'name': e['name'] as String,
            },
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<bool> startDictation(
    String enginePackage,
    String locale,
  ) async {
    if (!Platform.isAndroid) return false;
    try {
      final bool result = await _channel.invokeMethod('startDictation', {
        'enginePackage': enginePackage,
        'locale': locale,
      });
      return result;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> stopDictation() async {
    if (!Platform.isAndroid) return false;
    try {
      final bool result = await _channel.invokeMethod('stopDictation');
      return result;
    } catch (_) {
      return false;
    }
  }

  static Stream<Map<String, dynamic>> listenEvents() {
    if (!Platform.isAndroid) return const Stream.empty();
    return _eventChannel.receiveBroadcastStream().map((event) {
      return Map<String, dynamic>.from(event);
    });
  }
}
