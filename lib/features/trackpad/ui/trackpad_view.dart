import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logic/trackpad_provider.dart';
import '../../dimmer/ui/dimmer_view.dart'; // import dimmerProvider

class TrackpadView extends ConsumerWidget {
  const TrackpadView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(trackpadProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Read brightness for dark mode dots
    final dimmerState = ref.watch(dimmerProvider);

    return Container(
      color: theme.colorScheme.surface,
      child: Stack(
        children: [
          // Background Pattern (Grid or Dots)
          Positioned.fill(
            child: CustomPaint(
              painter: _BackgroundPainter(
                lineColor: theme.colorScheme.shadow,
                isDark: isDark,
                brightness: dimmerState.value,
              ),
            ),
          ),

          // Full Screen Gesture Area
          Positioned.fill(
            child: Listener(
              onPointerDown: notifier.onPointerDown,
              onPointerMove: notifier.onPointerMove,
              onPointerUp: notifier.onPointerUp,
              onPointerCancel: notifier.onPointerCancel,
              child: GestureDetector(
                onScaleStart: notifier.onScaleStart,
                onScaleUpdate: notifier.onScaleUpdate,
                onScaleEnd: notifier.onScaleEnd,
                behavior: HitTestBehavior.opaque,
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  final Color lineColor;
  final bool isDark;
  final double brightness;

  _BackgroundPainter({
    required this.lineColor,
    required this.isDark,
    required this.brightness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isDark) {
      // Light Mode: Grid
      final paint = Paint()
        ..color = lineColor
        ..strokeWidth = 1.0;

      const double spacing = 40.0;

      for (double i = 0; i < size.width; i += spacing) {
        canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
      }
      for (double i = 0; i < size.height; i += spacing) {
        canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
      }
    } else {
      // Dark Mode: Isometric Dots synced with brightness
      // brightness is between 0.0 and 1.0
      // Map brightness to opacity (0 to 1 -> 0.05 to 0.8)
      final double dotOpacity = 0.02 + (brightness * 0.5);
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: dotOpacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;

      const double spacingX = 40.0;
      const double spacingY = 34.64; // spacingX * sin(60)

      bool shift = false;
      for (double y = 0; y < size.height + spacingY; y += spacingY) {
        double startX = shift ? (spacingX / 2) : 0;
        for (double x = startX; x < size.width; x += spacingX) {
          canvas.drawCircle(Offset(x, y), 1.5, paint);
        }
        shift = !shift;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor ||
        oldDelegate.isDark != isDark ||
        oldDelegate.brightness != brightness;
  }
}
