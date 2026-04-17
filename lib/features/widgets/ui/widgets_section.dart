import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../utils/network_manager.dart';
import '../../../l10n/app_localizations.dart';
import '../../air_mouse/logic/air_mouse_provider.dart';

DeviceOrientation _getOrientation(BuildContext context) {
  final orientation = MediaQuery.orientationOf(context);
  if (orientation == Orientation.landscape) {
    final isLandscapeLeft =
        MediaQuery.of(context).size.width >
            MediaQuery.of(context).size.height &&
        MediaQuery.of(context).viewPadding.left >
            MediaQuery.of(context).viewPadding.right;
    return isLandscapeLeft
        ? DeviceOrientation.landscapeLeft
        : DeviceOrientation.landscapeRight;
  }
  return DeviceOrientation.portrait;
}

class WidgetsSection extends ConsumerWidget {
  const WidgetsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final airMouseState = ref.watch(airMouseProvider);
    final isAirMouseOn = airMouseState.isClutchEngaged;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: Container(
        width: 120, // Fixed width for widgets section
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Header
            Text(
              l10n.widgets, // Added "widgets" in arb file
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Air Mouse Toggle Button
                    Material(
                      color: isAirMouseOn
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(16),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          final notifier = ref.read(airMouseProvider.notifier);
                          if (isAirMouseOn) {
                            notifier.releaseClutch();
                            notifier.sendModeDisabled();
                          } else {
                            notifier.updateOrientation(
                              _getOrientation(context),
                            );
                            notifier.sendModeEnabled();
                            notifier.engageClutch();
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.air_rounded,
                                size: 32,
                                color: isAirMouseOn
                                    ? theme.colorScheme.onPrimaryContainer
                                    : theme.colorScheme.onSecondaryContainer,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.airMouse,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: isAirMouseOn
                                      ? theme.colorScheme.onPrimaryContainer
                                      : theme.colorScheme.onSecondaryContainer,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Lock Button
                    Material(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(16),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          NetworkManager().sendLockScreen();
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.lock_rounded,
                                size: 32,
                                color: theme.colorScheme.onSecondaryContainer,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.lockScreen,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSecondaryContainer,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Power Off Button
                    Material(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(16),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          NetworkManager().sendPowerOff();
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.power_settings_new_rounded,
                                size: 32,
                                color: theme.colorScheme.onErrorContainer,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.powerOff,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onErrorContainer,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Reboot Button
                    Material(
                      color: theme.colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(16),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          NetworkManager().sendReboot();
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.restart_alt_rounded,
                                size: 32,
                                color: theme.colorScheme.onTertiaryContainer,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.reboot,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onTertiaryContainer,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
