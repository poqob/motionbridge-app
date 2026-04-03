import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_bridge/l10n/app_localizations.dart';
import '../logic/volume_provider.dart';
import 'volume_slider.dart';

class VolumeView extends ConsumerWidget {
  const VolumeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(volumeProvider);
    final notifier = ref.read(volumeProvider.notifier);
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
                    loc.volume.toUpperCase(),
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
                        'Mute',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      Switch(
                        value: state.isMuted,
                        activeTrackColor: theme.colorScheme.secondary
                            .withValues(alpha: 0.5),
                        activeThumbColor: theme.colorScheme.secondary,
                        onChanged: (val) => notifier.toggleMute(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                Expanded(
                  child: Center(
                    child: VolumeSlider(
                      width: 120,
                      height: MediaQuery.of(context).size.height * 0.5,
                    ),
                  ),
                ),

                const SizedBox(height: 32),
                Text(
                  state.isMuted ? 'MUTED' : '${state.value.toInt()}%',
                  style: TextStyle(
                    color: state.isMuted
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
