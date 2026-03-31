import 'dart:ui';
import 'package:flutter/material.dart';

class AppStyles {
  // GlassCard bileşeni için temel Blur efekti (BackdropFilter)
  static final backdropFilter = ImageFilter.blur(sigmaX: 15, sigmaY: 15);

  // Tema-bağımlı Glassmorphism BoxDecoration
  static BoxDecoration glassDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? const Color(0x331A1816) : const Color(0x66F5F0E6),
      borderRadius: BorderRadius.circular(32),
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.2),
        width: 0.5,
      ),
    );
  }
}
