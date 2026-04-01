import 'utils/network_manager.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_bridge/l10n/app_localizations.dart';
import 'constants/app_theme.dart';
import 'features/trackpad/ui/trackpad_view.dart';
import 'features/dimmer/ui/dimmer_view.dart';
import 'features/settings/logic/settings_provider.dart';
import 'features/settings/ui/settings_view.dart';
import 'features/dimmer/ui/dimmer_slider.dart';

enum InputMode { trackpad, dimmer }

final inputModeProvider = NotifierProvider<InputModeNotifier, InputMode>(() {
  return InputModeNotifier();
});

class InputModeNotifier extends Notifier<InputMode> {
  @override
  InputMode build() => InputMode.trackpad;

  void setMode(InputMode newMode) {
    state = newMode;
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const ProviderScope(child: MotionBridgeApp()));
}

class MotionBridgeApp extends ConsumerWidget {
  const MotionBridgeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsProvider);

    return MaterialApp(
      title: 'MotionBridge',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settingsState.themeMode,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: settingsState.languageCode.isEmpty
          ? null
          : Locale(settingsState.languageCode),
      home: const MotionScreen(),
    );
  }
}

class MotionScreen extends ConsumerStatefulWidget {
  const MotionScreen({super.key});

  @override
  ConsumerState<MotionScreen> createState() => _MotionScreenState();
}

class _MotionScreenState extends ConsumerState<MotionScreen> {
  bool _showLandscapeDimmer = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
  }

  void _showDeviceDiscovery(BuildContext context) {
    if (MediaQuery.orientationOf(context) == Orientation.landscape) {
      _scaffoldKey.currentState?.openDrawer();
    } else {
      final theme = Theme.of(context);
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          return Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withAlpha(240),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: const _DeviceDiscoveryContent(),
          );
        },
      );
    }
  }

  void _showControllersMenu(BuildContext context) {
    final currentMode = ref.read(inputModeProvider);
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                loc.controllers,
                style: theme.textTheme.displayMedium?.copyWith(fontSize: 14),
              ),
              const SizedBox(height: 24),
              _MenuTile(
                title: loc.trackpad,
                icon: Icons.touch_app_rounded,
                isSelected: currentMode == InputMode.trackpad,
                onTap: () {
                  ref
                      .read(inputModeProvider.notifier)
                      .setMode(InputMode.trackpad);
                  Navigator.pop(context);
                },
              ),
              _MenuTile(
                title: loc.dimmer,
                icon: Icons.blur_on_rounded,
                isSelected: currentMode == InputMode.dimmer,
                onTap: () {
                  ref
                      .read(inputModeProvider.notifier)
                      .setMode(InputMode.dimmer);
                  Navigator.pop(context);
                },
              ),
              const Divider(height: 32),
              _MenuTile(
                title: loc.settings,
                icon: Icons.settings_rounded,
                isSelected: false,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsView()),
                  );
                },
              ),
              const SizedBox(height: 48),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(dimmerProvider, (p, n) {});

    ref.listen(settingsProvider, (prev, next) {
      if (next.deviceName.isNotEmpty && next.deviceId.isNotEmpty) {
        NetworkManager().startDiscovery(
          name: next.deviceName,
          id: next.deviceId,
        );
      }
    });

    final mode = ref.watch(inputModeProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bool isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    Widget activeView = switch (mode) {
      InputMode.trackpad => const TrackpadView(key: ValueKey('trackpad')),
      InputMode.dimmer => const DimmerView(key: ValueKey('dimmer')),
    };

    return Scaffold(
      key: _scaffoldKey,
      drawer: isLandscape
          ? const Drawer(child: SafeArea(child: _DeviceDiscoveryContent()))
          : null,
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            switchInCurve: Curves.easeOutExpo,
            switchOutCurve: Curves.easeInCirc,
            child: activeView,
          ),

          // Floating Dimmer Overlay for Landscape
          if (isLandscape && mode == InputMode.trackpad && _showLandscapeDimmer)
            Positioned(
              right: 80, // slightly left of the menu button
              top: 40,
              bottom: 40,
              child: Center(
                child: DimmerSlider(
                  width: 100,
                  height: MediaQuery.of(context).size.height * 0.7,
                ),
              ),
            ),

          // Top Left Device Discovery Button
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
                        color: theme.colorScheme.surface,
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
                        onPressed: () => _showDeviceDiscovery(context),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Top Right Menu Button
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
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
                    icon: Icon(
                      isLandscape && _showLandscapeDimmer
                          ? Icons.close_rounded
                          : Icons.menu_rounded,
                    ),
                    color: theme.colorScheme.onSurface,
                    onPressed: () {
                      if (isLandscape && mode == InputMode.trackpad) {
                        setState(() {
                          _showLandscapeDimmer = !_showLandscapeDimmer;
                        });
                      } else {
                        _showControllersMenu(context);
                      }
                    },
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

class _MenuTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _MenuTile({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isSelected
        ? theme.colorScheme.onSurface
        : theme.textTheme.labelMedium?.color ?? Colors.grey;

    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      tileColor: isSelected
          ? theme.colorScheme.secondary.withValues(alpha: 0.3)
          : Colors.transparent,
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _DeviceDiscoveryContent extends StatefulWidget {
  const _DeviceDiscoveryContent();

  @override
  State<_DeviceDiscoveryContent> createState() =>
      _DeviceDiscoveryContentState();
}

class _DeviceDiscoveryContentState extends State<_DeviceDiscoveryContent> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = NetworkManager().currentState;
    final activeHost = NetworkManager().activeHost;

    if (status == NetworkConnectionState.connected && activeHost != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.wifi_tethering_rounded,
                color: Color(0xFF4CAF50),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                "Bağlı: ${activeHost.hostName}",
                style: theme.textTheme.displayMedium?.copyWith(
                  fontSize: 16,
                  color: const Color(0xFF4CAF50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            activeHost.ip,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  NetworkManager().disconnect();
                  setState(() {});
                  if (Scaffold.maybeOf(context)?.isDrawerOpen == true) {
                    Navigator.of(context).pop();
                  } else if (ModalRoute.of(context)?.isCurrent != true) {
                    // close bottom sheet
                    Navigator.of(context).pop();
                  }
                },
                icon: const Icon(Icons.link_off),
                label: const Text("Bağlantıyı Kes"),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  NetworkManager().unpairHost();
                  setState(() {});
                  if (Scaffold.maybeOf(context)?.isDrawerOpen == true) {
                    Navigator.of(context).pop();
                  } else if (ModalRoute.of(context)?.isCurrent != true) {
                    // check if it's in a modal route?
                    Navigator.of(context).pop();
                  }
                },
                icon: const Icon(Icons.delete_forever),
                label: const Text("Ağı Unut"),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        StreamBuilder<NetworkConnectionState>(
          stream: NetworkManager().connectionStateStream,
          initialData: NetworkConnectionState.disconnected,
          builder: (context, snapshot) {
            final snapStatus = snapshot.data;
            String msg = "Ağ Aranıyor...";
            Color color = Colors.orange;

            if (snapStatus == NetworkConnectionState.waitingApproval) {
              msg = "Masaüstünde Onay Bekleniyor...";
              color = Colors.blueAccent;
            } else if (snapStatus == NetworkConnectionState.disconnected) {
              msg = "Bağlı Değil";
              color = Colors.red;
            }

            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_find_rounded, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  msg,
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontSize: 16,
                    color: color,
                  ),
                ),
              ],
            );
          },
        ),
        const Divider(height: 32),
        Expanded(
          child: StreamBuilder<List<DiscoveredHost>>(
            stream: NetworkManager().discoveredHostsStream,
            initialData: const [],
            builder: (context, snapshot) {
              final hosts = snapshot.data ?? [];
              if (hosts.isEmpty) {
                return Center(
                  child: Text(
                    "Ağda cihaz bulunamadı.\nMasaüstü uygulamanızın açık olduğuna emin olun.",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                );
              }

              return ListView.builder(
                itemCount: hosts.length,
                itemBuilder: (context, index) {
                  final host = hosts[index];
                  return ListTile(
                    leading: const Icon(Icons.computer_rounded, size: 32),
                    title: Text(
                      host.hostName,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(host.ip),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.cable_rounded),
                      onPressed: () {
                        NetworkManager().connectToHost(host);
                        Navigator.pop(context);
                      },
                    ),
                    onTap: () {
                      NetworkManager().connectToHost(host);
                      Navigator.pop(context);
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
