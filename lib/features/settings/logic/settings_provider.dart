import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final int maxFps;
  final ThemeMode themeMode;
  final String languageCode;
  final String deviceName;
  final String deviceId; // '' for system

  SettingsState({
    required this.maxFps,
    required this.themeMode,
    required this.languageCode,
    required this.deviceName,
    required this.deviceId,
  });

  SettingsState copyWith({
    int? maxFps,
    ThemeMode? themeMode,
    String? languageCode,
    String? deviceName,
    String? deviceId,
  }) {
    return SettingsState(
      maxFps: maxFps ?? this.maxFps,
      themeMode: themeMode ?? this.themeMode,
      languageCode: languageCode ?? this.languageCode,
      deviceName: deviceName ?? this.deviceName,
      deviceId: deviceId ?? this.deviceId,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  SharedPreferences? _prefs;

  @override
  SettingsState build() {
    _initPrefs();
    return SettingsState(
      maxFps: 60,
      themeMode: ThemeMode.system,
      languageCode: '',
      deviceName: 'MotionBridge',
      deviceId: '',
    );
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    final fps = _prefs?.getInt('maxFps') ?? 60;
    final themeIndex = _prefs?.getInt('themeMode') ?? ThemeMode.system.index;
    final lang = _prefs?.getString('languageCode') ?? '';
    final storedDeviceId = _prefs?.getString('deviceId');
    final deviceId =
        storedDeviceId ??
        DateTime.now().millisecondsSinceEpoch.toRadixString(16);
    if (storedDeviceId == null) {
      _prefs?.setString('deviceId', deviceId);
    }

    String deviceName = _prefs?.getString('deviceName') ?? '';
    if (deviceName.isEmpty) {
      // Trying to guess default name via IP
      deviceName = "MotionBridge";
      try {
        final interfaces = await NetworkInterface.list(
          type: InternetAddressType.IPv4,
          includeLinkLocal: false,
        );
        for (var interface in interfaces) {
          for (var addr in interface.addresses) {
            if (!addr.isLoopback) {
              final parts = addr.address.split('.');
              if (parts.length == 4) {
                deviceName = "Controller_${parts.last}";
              }
              break;
            }
          }
        }
      } catch (_) {}
      _prefs?.setString('deviceName', deviceName);
    }

    // ThemeMode.values fallback
    final mode = ThemeMode.values.firstWhere(
      (e) => e.index == themeIndex,
      orElse: () => ThemeMode.system,
    );
    state = state.copyWith(
      maxFps: fps,
      themeMode: mode,
      languageCode: lang,
      deviceName: deviceName,
      deviceId: deviceId,
    );
  }

  void setFps(int fps) {
    state = state.copyWith(maxFps: fps);
    _prefs?.setInt('maxFps', fps);
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _prefs?.setInt('themeMode', mode.index);
  }

  void setDeviceName(String name) {
    state = state.copyWith(deviceName: name);
    _prefs?.setString('deviceName', name);
  }

  void setLanguageCode(String code) {
    state = state.copyWith(languageCode: code);
    _prefs?.setString('languageCode', code);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(() {
  return SettingsNotifier();
});
