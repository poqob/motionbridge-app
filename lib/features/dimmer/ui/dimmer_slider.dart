import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_bridge/constants/app_styles.dart';
import 'dimmer_view.dart';

class DimmerSlider extends ConsumerWidget {
  final double width;
  final double height;

  const DimmerSlider({
    super.key,
    this.width = 120,
    required this.height,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dimmerProvider);
    final notifier = ref.read(dimmerProvider.notifier);
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
            child: RotatedBox(
              quarterTurns: 3,
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: width,
                  activeTrackColor: theme.colorScheme.secondary.withValues(alpha: 0.5),
                  inactiveTrackColor: Colors.transparent,
                  thumbColor: theme.colorScheme.primary,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 0),
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
    final double trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}
