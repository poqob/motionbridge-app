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
import 'features/volume/ui/volume_view.dart';
import 'features/volume/ui/volume_slider.dart';
import 'features/media/ui/media_view.dart';
import 'features/media/ui/media_card.dart';
import 'features/widgets/ui/widgets_section.dart';
import 'features/air_mouse/ui/air_mouse_view.dart';

enum InputMode { trackpad, dimmer, volume, media }

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
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isLandscape =
            MediaQuery.orientationOf(context) == Orientation.landscape;

        final menuContent = Column(
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
                ref.read(inputModeProvider.notifier).setMode(InputMode.dimmer);
                Navigator.pop(context);
              },
            ),
            _MenuTile(
              title: loc.volume,
              icon: Icons.volume_up_rounded,
              isSelected: currentMode == InputMode.volume,
              onTap: () {
                ref.read(inputModeProvider.notifier).setMode(InputMode.volume);
                Navigator.pop(context);
              },
            ),
            _MenuTile(
              title: loc.media,
              icon: Icons.play_circle_outline_rounded,
              isSelected: currentMode == InputMode.media,
              onTap: () {
                ref.read(inputModeProvider.notifier).setMode(InputMode.media);
                Navigator.pop(context);
              },
            ),
            _MenuTile(
              title: loc.airMouse,
              icon: Icons.air_rounded,
              isSelected: false,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AirMouseView()),
                );
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
        );

        return Container(
          height: isLandscape ? MediaQuery.sizeOf(ctx).height * 0.9 : null,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: isLandscape
              ? SafeArea(
                  maintainBottomViewPadding: true,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Expanded(flex: 3, child: _ClipboardViewer()),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 2,
                        child: SingleChildScrollView(child: menuContent),
                      ),
                    ],
                  ),
                )
              : menuContent,
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
      InputMode.volume => const VolumeView(key: ValueKey('volume')),
      InputMode.media => const MediaView(key: ValueKey('media')),
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
          if (isLandscape && mode == InputMode.trackpad)
            Positioned(
              right: 80, // slightly left of the menu button
              top: 40,
              bottom: 40,
              child: IgnorePointer(
                ignoring: !_showLandscapeDimmer,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  opacity: _showLandscapeDimmer ? 1.0 : 0.0,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 250, // Clipboard Container Width
                        child: const _ClipboardViewer(),
                      ),
                      const SizedBox(width: 24),
                      const WidgetsSection(),
                      const SizedBox(width: 24),
                      const MediaCard(),
                      const SizedBox(width: 24),
                      DimmerSlider(
                        width: 100,
                        height: MediaQuery.of(context).size.height * 0.7,
                      ),
                      const SizedBox(width: 24),
                      VolumeSlider(
                        width: 60,
                        height: MediaQuery.of(context).size.height * 0.7,
                      ),
                    ],
                  ),
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

    return StreamBuilder<NetworkConnectionState>(
      stream: NetworkManager().connectionStateStream,
      initialData: NetworkManager().currentState,
      builder: (context, snapshot) {
        final status = snapshot.data ?? NetworkConnectionState.disconnected;
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
                      // The StreamBuilder will automatically rebuild the UI
                      if (Scaffold.maybeOf(context)?.isDrawerOpen == true) {
                        Navigator.of(context).pop();
                      } else if (ModalRoute.of(context)?.isCurrent != true) {
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
                      if (Scaffold.maybeOf(context)?.isDrawerOpen == true) {
                        Navigator.of(context).pop();
                      } else if (ModalRoute.of(context)?.isCurrent != true) {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.wifi_find_rounded,
                  color: status == NetworkConnectionState.waitingApproval
                      ? Colors.blueAccent
                      : (status == NetworkConnectionState.disconnected
                            ? Colors.red
                            : Colors.orange),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  status == NetworkConnectionState.waitingApproval
                      ? "Masaüstünde Onay Bekleniyor..."
                      : (status == NetworkConnectionState.disconnected
                            ? "Bağlı Değil"
                            : "Ağ Aranıyor..."),
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontSize: 16,
                    color: status == NetworkConnectionState.waitingApproval
                        ? Colors.blueAccent
                        : (status == NetworkConnectionState.disconnected
                              ? Colors.red
                              : Colors.orange),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            Expanded(
              child: status == NetworkConnectionState.waitingApproval
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 24),
                          Text(
                            "Masaüstü Kullanıcısından\nBağlantı Onayı Bekleniyor...",
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            onPressed: () {
                              NetworkManager().disconnect();
                            },
                            icon: const Icon(Icons.close),
                            label: const Text("İptal Et"),
                          ),
                        ],
                      ),
                    )
                  : StreamBuilder<List<DiscoveredHost>>(
                      stream: NetworkManager().discoveredHostsStream,
                      initialData: NetworkManager().discoveredHosts,
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
                              leading: const Icon(
                                Icons.computer_rounded,
                                size: 32,
                              ),
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
                              trailing: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.link, size: 18),
                                label: const Text("Bağlan"),
                                onPressed: () {
                                  NetworkManager().connectToHost(host);
                                },
                              ),
                              onTap: () {
                                NetworkManager().connectToHost(host);
                              },
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _ClipboardViewer extends StatefulWidget {
  const _ClipboardViewer();

  @override
  State<_ClipboardViewer> createState() => _ClipboardViewerState();
}

class _ClipboardViewerState extends State<_ClipboardViewer>
    with WidgetsBindingObserver {
  final List<String> _history = [];
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkClipboard();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkClipboard();
    }
  }

  Future<void> _checkClipboard() async {
    if (_isChecking) return;
    _isChecking = true;
    try {
      final clipData = await Clipboard.getData(Clipboard.kTextPlain);
      final text = clipData?.text?.trim();
      if (text != null && text.isNotEmpty) {
        setState(() {
          if (_history.isEmpty || _history.first != text) {
            _history.removeWhere((item) => item == text);
            _history.insert(0, text);
          }
        });
      }
    } catch (_) {
      // Ignored
    } finally {
      _isChecking = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.secondary.withValues(alpha: 0.3),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.content_paste_rounded,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  loc.clipboardHistory,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.secondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.refresh_rounded,
                  size: 20,
                  color: theme.colorScheme.secondary,
                ),
                onPressed: _checkClipboard,
                tooltip: "Yenile",
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _history.isEmpty
                ? Center(
                    child: Text(
                      loc.clipboardEmpty,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: _history.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final itemText = _history[index];
                      return Material(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            NetworkManager().sendPacket({
                              't': 'CLIP',
                              'text': itemText,
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(loc.copiedToDesktop),
                                duration: const Duration(seconds: 1),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              itemText,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
