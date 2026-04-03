import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logic/trackpad_provider.dart';
import '../logic/dictation_provider.dart';
import '../../dimmer/ui/dimmer_view.dart'; // import dimmerProvider

class TrackpadView extends ConsumerStatefulWidget {
  const TrackpadView({super.key});

  @override
  ConsumerState<TrackpadView> createState() => _TrackpadViewState();
}

class _TrackpadViewState extends ConsumerState<TrackpadView> {
  final ValueNotifier<Map<int, Offset>> _cursorsNotifier =
      ValueNotifier<Map<int, Offset>>({});

  double? _micDragX;
  bool _isMicOnRight = false;

  @override
  void dispose() {
    _cursorsNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(trackpadProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Read brightness for dark mode dots
    final dimmerState = ref.watch(dimmerProvider);
    final dictationState = ref.watch(dictationProvider);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final micSize = 52.0;
    final defaultMargin = 24.0;
    final rightMicLimit = screenWidth - micSize - defaultMargin;

    return Container(
      color: theme.colorScheme.surface,
      child: Stack(
        children: [
          // Background Pattern (Grid or Dots)
          Positioned.fill(
            child: ValueListenableBuilder<Map<int, Offset>>(
              valueListenable: _cursorsNotifier,
              builder: (context, cursorPositions, child) {
                return CustomPaint(
                  painter: _BackgroundPainter(
                    lineColor: theme.colorScheme.shadow,
                    isDark: isDark,
                    brightness: dimmerState.value,
                    cursorPositions: cursorPositions,
                  ),
                );
              },
            ),
          ),

          // Full Screen Gesture Area
          Positioned.fill(
            child: Listener(
              onPointerDown: (event) {
                final newMap = Map<int, Offset>.from(_cursorsNotifier.value);
                newMap[event.pointer] = event.localPosition;
                _cursorsNotifier.value = newMap;
                notifier.onPointerDown(event);
              },
              onPointerMove: (event) {
                final newMap = Map<int, Offset>.from(_cursorsNotifier.value);
                newMap[event.pointer] = event.localPosition;
                _cursorsNotifier.value = newMap;
                notifier.onPointerMove(event);
              },
              onPointerUp: (event) {
                final newMap = Map<int, Offset>.from(_cursorsNotifier.value);
                newMap.remove(event.pointer);
                _cursorsNotifier.value = newMap;
                notifier.onPointerUp(event);
              },
              onPointerCancel: (event) {
                final newMap = Map<int, Offset>.from(_cursorsNotifier.value);
                newMap.remove(event.pointer);
                _cursorsNotifier.value = newMap;
                notifier.onPointerCancel(event);
              },
              child: GestureDetector(
                onScaleStart: notifier.onScaleStart,
                onScaleUpdate: notifier.onScaleUpdate,
                onScaleEnd: notifier.onScaleEnd,
                behavior: HitTestBehavior.opaque,
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          // Dictation Mic Button
          AnimatedPositioned(
            duration: _micDragX != null
                ? Duration.zero
                : const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            bottom: 24,
            left: _micDragX ?? (_isMicOnRight ? rightMicLimit : defaultMargin),
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _micDragX =
                      (_micDragX ??
                          (_isMicOnRight ? rightMicLimit : defaultMargin)) +
                      details.delta.dx;
                });
              },
              onHorizontalDragEnd: (details) {
                setState(() {
                  if (details.primaryVelocity! > 200) {
                    _isMicOnRight = true;
                  } else if (details.primaryVelocity! < -200) {
                    _isMicOnRight = false;
                  } else {
                    _isMicOnRight =
                        (_micDragX ?? defaultMargin) > screenWidth / 2;
                  }
                  _micDragX = null;
                });
              },
              child: Material(
                color: dictationState.isListening
                    ? Colors.red.withValues(alpha: 0.8)
                    : theme.colorScheme.secondaryContainer.withValues(
                        alpha: 0.8,
                      ),
                shape: const CircleBorder(),
                elevation: 4,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    ref.read(dictationProvider.notifier).toggleListening();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Icon(
                      dictationState.isListening ? Icons.mic : Icons.mic_none,
                      color: dictationState.isListening
                          ? Colors.white
                          : theme.colorScheme.onSecondaryContainer,
                      size: 28,
                    ),
                  ),
                ),
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
  final Map<int, Offset> cursorPositions;

  _BackgroundPainter({
    required this.lineColor,
    required this.isDark,
    required this.brightness,
    required this.cursorPositions,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Both Modes: Isometric Dots synced with brightness
    final double dotOpacity = !isDark ? 0.3 : (0.02 + (brightness * 0.5));
    final dotColor = !isDark ? lineColor : Colors.white;

    final paint = Paint()
      ..color = dotColor.withValues(alpha: dotOpacity.clamp(0.0, 1.0))
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round; // Draw points efficiently

    const double spacingX = 40.0;
    const double spacingY = 34.64; // spacingX * sin(60)

    const double influenceRadius = 120.0;
    const double influenceRadiusSq = influenceRadius * influenceRadius;
    const double maxDisplacement = -15.0; // Negatif = parmaktan kaçma (repel)

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
            // "Sıvı yüzeyi" veya "Ethereal" hissi için Curves.easeOut kullanıyoruz
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

    // Toplu çizim için drawRawPoints veya drawPoints
    canvas.drawPoints(PointMode.points, points, paint);
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor ||
        oldDelegate.isDark != isDark ||
        oldDelegate.brightness != brightness ||
        oldDelegate.cursorPositions != cursorPositions;
  }
}
