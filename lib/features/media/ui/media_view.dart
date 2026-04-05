import 'package:flutter/material.dart';
import 'package:motion_bridge/l10n/app_localizations.dart';
import '../logic/media_provider.dart';

class MediaView extends StatelessWidget {
  const MediaView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.play_circle_outline_rounded,
              size: 120,
              color: colorScheme.primary.withAlpha(128),
            ),
            const SizedBox(height: 32),
            Text(
              l10n.media,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 48),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _MediaButton(
                      icon: Icons.play_arrow_rounded,
                      size: 72,
                      onPressed: () => mediaController.play(),
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 32),
                    _MediaButton(
                      icon: Icons.pause_rounded,
                      size: 72,
                      onPressed: () => mediaController.pause(),
                      color: colorScheme.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _MediaButton(
                      icon: Icons.skip_previous_rounded,
                      size: 48,
                      onPressed: () => mediaController.previous(),
                      color: colorScheme.secondary,
                    ),
                    const SizedBox(width: 40),
                    _MediaButton(
                      icon: Icons.skip_next_rounded,
                      size: 48,
                      onPressed: () => mediaController.next(),
                      color: colorScheme.secondary,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onPressed;
  final Color color;

  const _MediaButton({
    required this.icon,
    required this.size,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withAlpha(25),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Icon(icon, size: size, color: color),
        ),
      ),
    );
  }
}
