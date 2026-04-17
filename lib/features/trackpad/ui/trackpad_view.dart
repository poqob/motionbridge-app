import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logic/trackpad_provider.dart';
import '../logic/dictation_provider.dart';
import '../../dimmer/ui/dimmer_view.dart';
import '../../settings/logic/settings_provider.dart';
import '../../air_mouse/logic/air_mouse_provider.dart';

import 'trackpad_painter.dart';

class TrackpadView extends ConsumerStatefulWidget {
  const TrackpadView({super.key});

  @override
  ConsumerState<TrackpadView> createState() => _TrackpadViewState();
}

class _TrackpadViewState extends ConsumerState<TrackpadView> {
  final ValueNotifier<Map<int, Offset>> _cursorsNotifier =
      ValueNotifier<Map<int, Offset>>({});
  final ValueNotifier<Map<int, List<Offset>>> _pathsNotifier =
      ValueNotifier<Map<int, List<Offset>>>({});

  double? _micDragX;
  bool _isMicOnRight = false;

  @override
  void dispose() {
    _cursorsNotifier.dispose();
    _pathsNotifier.dispose();
    // Ensure Air Mouse stops when leaving trackpad view if it was left ON
    final airMouseNotifier = ref.read(airMouseProvider.notifier);
    if (ref.read(airMouseProvider).isClutchEngaged) {
      airMouseNotifier.releaseClutch();
      airMouseNotifier.sendModeDisabled();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(trackpadProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Read brightness for dark mode dots
    final dimmerState = ref.watch(dimmerProvider);
    final settingsState = ref.watch(settingsProvider);
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
                return ValueListenableBuilder<Map<int, List<Offset>>>(
                  valueListenable: _pathsNotifier,
                  builder: (context, cursorPaths, child) {
                    return CustomPaint(
                      painter: TrackpadPainter(
                        lineColor: theme.colorScheme.shadow,
                        isDark: isDark,
                        brightness: dimmerState.value,
                        cursorPositions: cursorPositions,
                        cursorPaths: cursorPaths,
                        backgroundStyle: settingsState.trackpadBackground,
                      ),
                    );
                  },
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

                final newPathsMap = Map<int, List<Offset>>.from(
                  _pathsNotifier.value,
                );
                newPathsMap[event.pointer] = [event.localPosition];
                _pathsNotifier.value = newPathsMap;

                notifier.onPointerDown(event);
              },
              onPointerMove: (event) {
                final newMap = Map<int, Offset>.from(_cursorsNotifier.value);
                newMap[event.pointer] = event.localPosition;
                _cursorsNotifier.value = newMap;

                final newPathsMap = Map<int, List<Offset>>.from(
                  _pathsNotifier.value,
                );
                // Keep only last 10 points for a trail, or just all points. A shorter trail is better for a spline.
                if (newPathsMap.containsKey(event.pointer)) {
                  final list = List<Offset>.from(newPathsMap[event.pointer]!);
                  list.add(event.localPosition);
                  if (list.length > 25) {
                    // Trail length limit
                    list.removeAt(0);
                  }
                  newPathsMap[event.pointer] = list;
                }
                _pathsNotifier.value = newPathsMap;

                notifier.onPointerMove(event);
              },
              onPointerUp: (event) {
                final newMap = Map<int, Offset>.from(_cursorsNotifier.value);
                newMap.remove(event.pointer);
                _cursorsNotifier.value = newMap;

                final newPathsMap = Map<int, List<Offset>>.from(
                  _pathsNotifier.value,
                );
                newPathsMap.remove(event.pointer);
                _pathsNotifier.value = newPathsMap;

                notifier.onPointerUp(event);
              },
              onPointerCancel: (event) {
                final newMap = Map<int, Offset>.from(_cursorsNotifier.value);
                newMap.remove(event.pointer);
                _cursorsNotifier.value = newMap;

                final newPathsMap = Map<int, List<Offset>>.from(
                  _pathsNotifier.value,
                );
                newPathsMap.remove(event.pointer);
                _pathsNotifier.value = newPathsMap;

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

          // Smart Directive Button (Copy/Paste)
          const SmartDirectiveWidget(),
        ],
      ),
    );
  }
}

class SmartDirectiveWidget extends ConsumerStatefulWidget {
  const SmartDirectiveWidget({super.key});

  @override
  ConsumerState<SmartDirectiveWidget> createState() =>
      _SmartDirectiveWidgetState();
}

class _SmartDirectiveWidgetState extends ConsumerState<SmartDirectiveWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  bool _wasShowing = false;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    // Zıplama efekti için: 0 -> 15 (sağa kayacak) -> 0 (geri dönecek)
    _bounceAnimation = TweenSequence([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 15.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 15.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_bounceController);
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trackpadState = ref.watch(trackpadProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isCopy = trackpadState.smartDirective == SmartDirective.copy;
    final isPaste = trackpadState.smartDirective == SmartDirective.paste;
    final showButton = isCopy || isPaste;

    if (showButton && !_wasShowing) {
      // Düğme görünür olduğunda ve animasyon bitince zıplamayı başlat (Giriş animasyonu yaklaşık 300ms)
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) {
          _bounceController.forward(from: 0);
        }
      });
    }
    _wasShowing = showButton;

    // Premium renkler
    final bgColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF);
    final iconColor = isDark
        ? const Color(0xFFE0E0E0)
        : const Color(0xFF1E1E1E);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      bottom: 24, // Sağ altta ortaya çıkmalı
      right: showButton ? 24 : -100, // Çerçeveden dışarı
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: showButton ? 1.0 : 0.0,
        child: AnimatedBuilder(
          animation: _bounceAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_bounceAnimation.value, 0),
              child: child,
            );
          },
          child: GestureDetector(
            onHorizontalDragUpdate: (details) {
              if (details.primaryDelta! > 5) {
                // Sağa doğru çekerse kaybolsun
                ref.read(trackpadProvider.notifier).dismissSmartDirective();
              }
            },
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(16),
              color: bgColor,
              child: InkWell(
                onTap: () {
                  ref.read(trackpadProvider.notifier).onSmartDirectiveTapped();
                },
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 56,
                  height: 56, // Rounded edge square form
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(scale: animation, child: child);
                      },
                      child: Icon(
                        isCopy ? Icons.copy : Icons.paste,
                        key: ValueKey(isCopy),
                        color: iconColor,
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
