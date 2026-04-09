import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

class TrackpadPainter extends CustomPainter {
  final Color lineColor;
  final bool isDark;
  final double brightness;
  final Map<int, Offset> cursorPositions;
  final Map<int, List<Offset>> cursorPaths;
  final String backgroundStyle;

  TrackpadPainter({
    required this.lineColor,
    required this.isDark,
    required this.brightness,
    required this.cursorPositions,
    required this.cursorPaths,
    required this.backgroundStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (backgroundStyle == 'none') return;

    if (backgroundStyle == 'touch_indicators') {
      _paintTouchIndicators(canvas, size);
    } else if (backgroundStyle == 'spline') {
      _paintSpline(canvas, size);
    } else {
      _paintIsometric(canvas, size);
    }
  }

  void _paintIsometric(Canvas canvas, Size size) {
    final double dotOpacity = !isDark ? 0.3 : (0.02 + (brightness * 0.5));
    final dotColor = !isDark ? lineColor : Colors.white;

    final paint = Paint()
      ..color = dotColor.withValues(alpha: dotOpacity.clamp(0.0, 1.0))
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    const double spacingX = 40.0;
    const double spacingY = 34.64;

    const double influenceRadius = 120.0;
    const double influenceRadiusSq = influenceRadius * influenceRadius;
    const double maxDisplacement = -15.0;

    final List<Offset> points = [];
    bool shift = false;
    for (double y = 0; y < size.height + spacingY; y += spacingY) {
      double startX = shift ? (spacingX / 2) : 0;
      for (double x = startX; x < size.width; x += spacingX) {
        double px = x;
        double py = y;

        for (final cursorPosition in cursorPositions.values) {
          final double dx = x - cursorPosition.dx;
          final double dy = y - cursorPosition.dy;
          final double distSq = dx * dx + dy * dy;

          if (distSq < influenceRadiusSq) {
            final double dist = math.sqrt(distSq);
            final double t = 1.0 - (dist / influenceRadius);
            final double tCurve = Curves.easeOut.transform(t);
            final double magnitude = maxDisplacement * tCurve;

            if (dist > 0) {
              final double dirX = dx / dist;
              final double dirY = dy / dist;
              px += dirX * magnitude;
              py += dirY * magnitude;
            }
          }
        }
        points.add(Offset(px, py));
      }
      shift = !shift;
    }
    canvas.drawPoints(PointMode.points, points, paint);
  }

  void _paintTouchIndicators(Canvas canvas, Size size) {
    final color = isDark ? Colors.white : Colors.black;
    for (final cursorPosition in cursorPositions.values) {
      final paint = Paint()
        ..color = color.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15.0);
      canvas.drawCircle(cursorPosition, 40.0, paint);

      final paintInner = Paint()
        ..color = color.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
      canvas.drawCircle(cursorPosition, 20.0, paintInner);
    }
  }

  void _paintSpline(Canvas canvas, Size size) {
    final color = isDark ? Colors.white : Colors.black;
    final paint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final path in cursorPaths.values) {
      if (path.length < 2) {
        if (path.isNotEmpty) {
          canvas.drawCircle(path.first, 3.0, paint..style = PaintingStyle.fill);
        }
        continue;
      }

      final p = Path();
      p.moveTo(path[0].dx, path[0].dy);
      for (int i = 1; i < path.length - 1; i++) {
        final xc = (path[i].dx + path[i + 1].dx) / 2;
        final yc = (path[i].dy + path[i + 1].dy) / 2;
        p.quadraticBezierTo(path[i].dx, path[i].dy, xc, yc);
      }
      p.lineTo(path.last.dx, path.last.dy);
      canvas.drawPath(p, paint);
    }

    // Draw current positions as leading big dots
    for (final pos in cursorPositions.values) {
      canvas.drawCircle(
        pos,
        8.0,
        Paint()..color = color.withValues(alpha: 0.8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant TrackpadPainter oldDelegate) {
    return true; // Simple approach to make animations/splines update reliably
  }
}
