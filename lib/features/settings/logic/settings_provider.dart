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
  final bool reverseScroll;
  final String speechEnginePackage;
  final String trackpadBackground;
  final double airMouseSensitivity;

  SettingsState({
    required this.maxFps,
    required this.themeMode,
    required this.languageCode,
    required this.deviceName,
    required this.deviceId,
    required this.reverseScroll,
    required this.speechEnginePackage,
    required this.trackpadBackground,
    required this.airMouseSensitivity,
  });

  SettingsState copyWith({
    int? maxFps,
    ThemeMode? themeMode,
    String? languageCode,
    String? deviceName,
    String? deviceId,
    bool? reverseScroll,
    String? speechEnginePackage,
    String? trackpadBackground,
    double? airMouseSensitivity,
  }) {
    return SettingsState(
      maxFps: maxFps ?? this.maxFps,
      themeMode: themeMode ?? this.themeMode,
      languageCode: languageCode ?? this.languageCode,
      deviceName: deviceName ?? this.deviceName,
      deviceId: deviceId ?? this.deviceId,
      reverseScroll: reverseScroll ?? this.reverseScroll,
      speechEnginePackage: speechEnginePackage ?? this.speechEnginePackage,
      trackpadBackground: trackpadBackground ?? this.trackpadBackground,
      airMouseSensitivity: airMouseSensitivity ?? this.airMouseSensitivity,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  SharedPreferences? _prefs;

  @override
  SettingsState build() {
    _initPrefs();
    return SettingsState(
      maxFps: 30,
      themeMode: ThemeMode.system,
      languageCode: '',
      deviceName: 'MotionBridge',
      deviceId: '',
      reverseScroll: false,
      speechEnginePackage: "",
      trackpadBackground: "isometric",
      airMouseSensitivity: 1.0,
    );
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    final fps = _prefs?.getInt('maxFps') ?? 30;
    final themeIndex = _prefs?.getInt('themeMode') ?? ThemeMode.system.index;
    final lang = _prefs?.getString('languageCode') ?? '';
    final storedDeviceId = _prefs?.getString('deviceId');
    final deviceId =
        storedDeviceId ??
        DateTime.now().millisecondsSinceEpoch.toRadixString(16);
    final revScroll = _prefs?.getBool('reverseScroll') ?? false;
    final speechPkg = _prefs?.getString('speechEnginePackage') ?? '';
    final trackBack = _prefs?.getString('trackpadBackground') ?? 'isometric';
    final airMouseSens = _prefs?.getDouble('airMouseSensitivity') ?? 1.0;
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
      reverseScroll: revScroll,
      speechEnginePackage: speechPkg,
      trackpadBackground: trackBack,
      airMouseSensitivity: airMouseSens,
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

  void setReverseScroll(bool value) {
    state = state.copyWith(reverseScroll: value);
    _prefs?.setBool('reverseScroll', value);
  }

  void setSpeechEnginePackage(String pkg) {
    state = state.copyWith(speechEnginePackage: pkg);
    _prefs?.setString('speechEnginePackage', pkg);
  }

  void setTrackpadBackground(String style) {
    state = state.copyWith(trackpadBackground: style);
    _prefs?.setString('trackpadBackground', style);
  }

  void setAirMouseSensitivity(double value) {
    state = state.copyWith(airMouseSensitivity: value.clamp(0.1, 3.0));
    _prefs?.setDouble('airMouseSensitivity', value.clamp(0.1, 3.0));
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(() {
  return SettingsNotifier();
});
