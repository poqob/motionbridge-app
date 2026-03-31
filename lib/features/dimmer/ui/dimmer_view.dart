import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_bridge/l10n/app_localizations.dart';
import 'package:motion_bridge/constants/app_styles.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:rxdart/rxdart.dart';
import '../../../utils/network_manager.dart';

class DimmerState {
  final double value;
  final bool isAuto;

  DimmerState({required this.value, required this.isAuto});

  DimmerState copyWith({double? value, bool? isAuto}) {
    return DimmerState(
      value: value ?? this.value,
      isAuto: isAuto ?? this.isAuto,
    );
  }
}

final dimmerProvider = NotifierProvider<DimmerNotifier, DimmerState>(() {
  return DimmerNotifier();
});

class DimmerNotifier extends Notifier<DimmerState> {
  StreamSubscription<double>? _brightnessSubscription;
  final _brightnessSubject = PublishSubject<double>();

  @override
  DimmerState build() {
    _brightnessSubject.debounceTime(const Duration(milliseconds: 300)).listen((
      brightness,
    ) {
      if (state.isAuto) {
        state = state.copyWith(value: brightness);
        _sendBrightness(brightness);
      }
    });

    ref.onDispose(() {
      _brightnessSubscription?.cancel();
      _brightnessSubject.close();
    });

    return DimmerState(value: 0.0, isAuto: false);
  }

  void _sendBrightness(double value) {
    if ((value * 100).toInt() % 10 == 0) {
      HapticFeedback.lightImpact();
    }
    final Map<String, dynamic> payload = {
      "t": "D",
      "v": double.parse(value.toStringAsFixed(2)),
    };
    NetworkManager().sendPacket(payload);
  }

  void updateDimmer(double value) {
    if (state.isAuto) {
      toggleAuto(false);
    }
    state = state.copyWith(value: value.clamp(0.0, 1.0));
    _sendBrightness(state.value);
  }

  Future<void> toggleAuto(bool isAuto) async {
    state = state.copyWith(isAuto: isAuto);

    if (isAuto) {
      try {
        final currentBrightness = await ScreenBrightness().application;
        state = state.copyWith(value: currentBrightness);
        _sendBrightness(currentBrightness);

        _brightnessSubscription = ScreenBrightness()
            .onApplicationScreenBrightnessChanged
            .listen((brightness) {
              _brightnessSubject.add(brightness);
            });
      } catch (e) {
        debugPrint('Karanlık okuma hatası: $e');
        state = state.copyWith(isAuto: false);
      }
    } else {
      _brightnessSubscription?.cancel();
      _brightnessSubscription = null;
    }
  }
}

class DimmerView extends ConsumerWidget {
  const DimmerView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dimmerProvider);
    final notifier = ref.read(dimmerProvider.notifier);
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return Container(
      color: theme.colorScheme.surface,
      child: Stack(
        children: [
          SafeArea(
            child: IgnorePointer(
              child: Padding(
                padding: const EdgeInsets.only(top: 24, left: 24),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    loc.dimmer.toUpperCase(),
                    style: theme.textTheme.displayLarge?.copyWith(fontSize: 28),
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 100),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        loc.autoDimSync,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      Switch(
                        value: state.isAuto,
                        activeTrackColor: theme.colorScheme.secondary
                            .withValues(alpha: 0.5),
                        activeThumbColor: theme.colorScheme.secondary,
                        onChanged: notifier.toggleAuto,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                Expanded(
                  child: Center(
                    child: SizedBox(
                      width: 120,
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: BackdropFilter(
                          filter: AppStyles.backdropFilter,
                          child: Container(
                            decoration: AppStyles.glassDecoration(context),
                            child: RotatedBox(
                              quarterTurns: 3,
                              child: SliderTheme(
                                data: SliderThemeData(
                                  trackHeight: 120, // Tüm alanı kapla
                                  activeTrackColor: theme.colorScheme.secondary
                                      .withValues(alpha: 0.5),
                                  inactiveTrackColor: Colors.transparent,
                                  thumbColor: theme.colorScheme.primary,
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 0,
                                  ),
                                  overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 0,
                                  ),
                                  trackShape: _CustomTrackShape(),
                                ),
                                child: Slider(
                                  value: state.value,
                                  onChanged: notifier.updateDimmer,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
                Text(
                  '${(state.value * 100).toInt()}%',
                  style: TextStyle(
                    color: theme.colorScheme.primary, // Primary
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 48), // Bottom padding
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomTrackShape extends RoundedRectSliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight ?? 0;
    final double trackLeft = offset.dx;
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}
