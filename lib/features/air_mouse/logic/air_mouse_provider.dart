import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../../utils/network_manager.dart';
import '../../settings/logic/settings_provider.dart';

enum DeviceOrientation { portrait, landscapeLeft, landscapeRight, portraitUp }

class AirMouseState {
  final bool isClutchEngaged;
  final bool isGyroscopeAvailable;
  final DeviceOrientation orientation;

  AirMouseState({
    this.isClutchEngaged = false,
    this.isGyroscopeAvailable = false,
    this.orientation = DeviceOrientation.portrait,
  });

  AirMouseState copyWith({
    bool? isClutchEngaged,
    bool? isGyroscopeAvailable,
    DeviceOrientation? orientation,
  }) {
    return AirMouseState(
      isClutchEngaged: isClutchEngaged ?? this.isClutchEngaged,
      isGyroscopeAvailable: isGyroscopeAvailable ?? this.isGyroscopeAvailable,
      orientation: orientation ?? this.orientation,
    );
  }
}

class AirMouseNotifier extends Notifier<AirMouseState> {
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  DateTime _lastSendTime = DateTime.now();

  static const double _gyroThreshold = 0.05;

  @override
  AirMouseState build() {
    ref.onDispose(() {
      _stopSensors();
    });
    return AirMouseState();
  }

  void updateOrientation(DeviceOrientation orientation) {
    if (state.orientation != orientation) {
      state = state.copyWith(orientation: orientation);
      if (kDebugMode) {
        print('[AirMouse] Orientation: $orientation');
      }
    }
  }

  void _send(String type, Map<String, dynamic> data) {
    final Map<String, dynamic> payload = {"t": type};
    data.forEach((key, value) {
      if (value is double) {
        payload[key] = double.parse(value.toStringAsFixed(2));
      } else {
        payload[key] = value;
      }
    });
    if (kDebugMode) {
      print('[AirMouse] ${type == 'AM_M' ? 'UDP' : 'WS'}: $payload');
    }
    NetworkManager().sendPacket(payload);
  }

  void _startSensors() {
    if (kDebugMode) {
      print('[AirMouse] Starting gyroscope...');
    }

    _gyroscopeSubscription?.cancel();

    _gyroscopeSubscription =
        gyroscopeEventStream(
          samplingPeriod: const Duration(milliseconds: 16),
        ).listen(
          (GyroscopeEvent event) {
            if (!state.isClutchEngaged) return;

            final maxFps = ref.read(settingsProvider).maxFps;
            final intervalMs = 1000 ~/ maxFps;

            final now = DateTime.now();
            if (now.difference(_lastSendTime).inMilliseconds < intervalMs) {
              return;
            }
            _lastSendTime = now;

            final sensitivity = ref.read(settingsProvider).airMouseSensitivity;
            final orientation = state.orientation;

            double gyroX = event.x;
            double gyroY = event.y;

            if (orientation == DeviceOrientation.landscapeLeft ||
                orientation == DeviceOrientation.landscapeRight) {
              final temp = gyroX;
              gyroX = gyroY;
              gyroY = temp;
            }

            double mouseX = gyroY * sensitivity;
            double mouseY = gyroX * sensitivity * -1;

            if (orientation == DeviceOrientation.landscapeLeft ||
                orientation == DeviceOrientation.landscapeRight) {
              mouseY = mouseY * -1;
            }

            if (mouseX.abs() < _gyroThreshold &&
                mouseY.abs() < _gyroThreshold) {
              return;
            }

            mouseX = mouseX.clamp(-1.0, 1.0);
            mouseY = mouseY.clamp(-1.0, 1.0);

            if (kDebugMode) {
              print(
                '[AirMouse] gyro(y:${event.y.toStringAsFixed(3)} x:${event.x.toStringAsFixed(3)}) → mouse(x:${mouseX.toStringAsFixed(2)} y:${mouseY.toStringAsFixed(2)})',
              );
            }

            _send("AM_M", {"x": mouseX, "y": mouseY});
          },
          onError: (error) {
            if (kDebugMode) {
              print('[AirMouse] Gyroscope error: $error');
            }
            state = state.copyWith(isGyroscopeAvailable: false);
          },
        );

    state = state.copyWith(isGyroscopeAvailable: true);
    if (kDebugMode) {
      print('[AirMouse] Gyroscope started');
    }
  }

  void _stopSensors() {
    if (kDebugMode) {
      print('[AirMouse] Stopping sensors...');
    }
    _gyroscopeSubscription?.cancel();
    _gyroscopeSubscription = null;
    state = state.copyWith(isGyroscopeAvailable: false);
  }

  void engageClutch() {
    if (state.isClutchEngaged) return;

    if (kDebugMode) {
      print('[AirMouse] Clutch ENGAGED');
    }

    state = state.copyWith(isClutchEngaged: true);
    _startSensors();
  }

  void releaseClutch() {
    if (!state.isClutchEngaged) return;

    if (kDebugMode) {
      print('[AirMouse] Clutch RELEASED');
    }

    state = state.copyWith(isClutchEngaged: false);
    _stopSensors();
  }

  void sendModeEnabled() {
    if (kDebugMode) {
      print('[AirMouse] AM_MODE enabled=true');
    }
    NetworkManager().sendAirMouseMode(true);
  }

  void sendModeDisabled() {
    if (kDebugMode) {
      print('[AirMouse] AM_MODE enabled=false');
    }
    NetworkManager().sendAirMouseMode(false);
  }

  void sendSensitivity(double value) {
    if (kDebugMode) {
      print('[AirMouse] AM_SENS value=$value');
    }
    NetworkManager().sendAirMouseSensitivity(value);
  }
}

final airMouseProvider = NotifierProvider<AirMouseNotifier, AirMouseState>(() {
  return AirMouseNotifier();
});
