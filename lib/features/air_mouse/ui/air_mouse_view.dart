import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_bridge/l10n/app_localizations.dart';
import 'package:motion_bridge/utils/network_manager.dart';
import '../logic/air_mouse_provider.dart';
import '../../settings/logic/settings_provider.dart';

class AirMouseView extends ConsumerStatefulWidget {
  const AirMouseView({super.key});

  @override
  ConsumerState<AirMouseView> createState() => _AirMouseViewState();
}

class _AirMouseViewState extends ConsumerState<AirMouseView> {
  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      print('[AirMouseView] initState called');
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (kDebugMode) {
        print('[AirMouseView] Sending AM_MODE enabled=true');
      }
      ref.read(airMouseProvider.notifier).sendModeEnabled();
    });
  }

  @override
  void dispose() {
    if (kDebugMode) {
      print('[AirMouseView] dispose - Sending AM_MODE enabled=false');
    }
    ref.read(airMouseProvider.notifier).sendModeDisabled();
    super.dispose();
  }

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

  @override
  Widget build(BuildContext context) {
    final airMouseState = ref.watch(airMouseProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final loc = AppLocalizations.of(context)!;
    final currentOrientation = _getOrientation(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(airMouseProvider.notifier).updateOrientation(currentOrientation);
    });

    if (kDebugMode) {
      print(
        '[AirMouseView] Build - clutch: ${airMouseState.isClutchEngaged}, orientation: $currentOrientation',
      );
    }

    final bgColor = isDark ? Colors.black : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          Listener(
            onPointerDown: (event) {
              if (kDebugMode) {
                print('[AirMouseView] onPointerDown');
              }
              ref.read(airMouseProvider.notifier).engageClutch();
            },
            onPointerUp: (event) {
              if (kDebugMode) {
                print('[AirMouseView] onPointerUp');
              }
              ref.read(airMouseProvider.notifier).releaseClutch();
            },
            onPointerCancel: (event) {
              if (kDebugMode) {
                print('[AirMouseView] onPointerCancel');
              }
              ref.read(airMouseProvider.notifier).releaseClutch();
            },
            child: Container(
              color: Colors.transparent,
              width: double.infinity,
              height: double.infinity,
            ),
          ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  airMouseState.isClutchEngaged
                      ? Icons.pan_tool_rounded
                      : Icons.air_rounded,
                  size: 80,
                  color: airMouseState.isClutchEngaged
                      ? theme.colorScheme.primary
                      : (isDark ? Colors.white24 : Colors.black26),
                ),
                const SizedBox(height: 24),
                Text(
                  airMouseState.isClutchEngaged
                      ? 'Air Mouse Active'
                      : 'Touch to activate',
                  style: TextStyle(
                    color: airMouseState.isClutchEngaged
                        ? theme.colorScheme.primary
                        : (isDark ? Colors.white38 : Colors.black38),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Mode: ${currentOrientation.name}',
                  style: TextStyle(
                    color: isDark ? Colors.white24 : Colors.black26,
                    fontSize: 12,
                  ),
                ),
                if (!airMouseState.isGyroscopeAvailable) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Gyroscope not available',
                      style: TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),

          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: StreamBuilder<NetworkConnectionState>(
                  stream: NetworkManager().connectionStateStream,
                  initialData: NetworkConnectionState.disconnected,
                  builder: (context, snapshot) {
                    final status = snapshot.data;
                    Color color = Colors.redAccent;
                    IconData picon = Icons.wifi_off_rounded;

                    if (status == NetworkConnectionState.connected) {
                      color = const Color(0xFF4CAF50);
                      picon = Icons.wifi_tethering_rounded;
                    } else if (status ==
                        NetworkConnectionState.waitingApproval) {
                      color = Colors.blueAccent;
                      picon = Icons.wifi_protected_setup_rounded;
                    } else if (status == NetworkConnectionState.discovering) {
                      color = Colors.orange;
                      picon = Icons.wifi_find_rounded;
                    }

                    return Container(
                      decoration: BoxDecoration(
                        color: bgColor.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? const Color(0x33000000)
                                : const Color(0x08000000),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(picon, color: color),
                        onPressed: () {},
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: bgColor.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? const Color(0x33000000)
                            : const Color(0x08000000),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: isDark ? Colors.white : Colors.black,
                    onPressed: () => Navigator.pop(context),
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
