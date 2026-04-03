import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_bridge/constants/app_styles.dart';
import '../logic/volume_provider.dart';

class VolumeSlider extends ConsumerWidget {
  final double width;
  final double height;

  const VolumeSlider({super.key, this.width = 120, required this.height});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(volumeProvider);
    final notifier = ref.read(volumeProvider.notifier);
    final theme = Theme.of(context);

    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: AppStyles.backdropFilter,
          child: Container(
            decoration: AppStyles.glassDecoration(context),
            child: Stack(
              children: [
                RotatedBox(
                  quarterTurns: 3,
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: width,
                      activeTrackColor: theme.colorScheme.secondary.withValues(
                        alpha: 0.5,
                      ),
                      inactiveTrackColor: Colors.transparent,
                      thumbColor: state.isMuted
                          ? theme.colorScheme.error
                          : theme.colorScheme.primary,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 0,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 0,
                      ),
                      trackShape: _CustomTrackShape(),
                    ),
                    child: Slider(
                      min: 0,
                      max: 100,
                      value: state.value,
                      onChanged: state.isMuted ? null : notifier.updateVolume,
                      onChangeEnd: state.isMuted
                          ? null
                          : (_) => notifier.flushVolume(),
                    ),
                  ),
                ),
                // Ortada sayıyı gösteren metin ve ikon
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          state.isMuted
                              ? Icons.volume_off_rounded
                              : Icons.volume_up_rounded,
                          color: state.isMuted
                              ? theme.colorScheme.error
                              : Colors.white,
                          size: width * 0.4,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.isMuted ? 'MUTE' : '${state.value.toInt()}',
                          style: TextStyle(
                            color: state.isMuted
                                ? theme.colorScheme.error
                                : Colors.white,
                            fontSize: width * 0.3,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
