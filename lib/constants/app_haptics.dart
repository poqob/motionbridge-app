import 'package:flutter/services.dart';

class AppHaptics {
  /// Hafif dokunuşlar (Dimmer kaydırmasındaki ufak kademe değişimleri)
  static void lightImpact() {
    HapticFeedback.lightImpact();
  }

  /// Tıklama hissiyatı (Trackpad click, Joystick çıkışı)
  static void mediumImpact() {
    HapticFeedback.mediumImpact();
  }

  /// Ağır vurma hissiyatı (Dimmer sınır noktaları: %0, %50, %100)
  static void heavyImpact() {
    HapticFeedback.heavyImpact();
  }

  /// Uyarı, geçersiz işlem veya kopma durumu
  static void error() {
    HapticFeedback.vibrate();
  }
}
