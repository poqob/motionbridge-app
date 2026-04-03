import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:motion_bridge/l10n/app_localizations.dart';
import '../logic/settings_provider.dart';
import 'about_view.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        title: Text(
          loc.settings,
          style: theme.textTheme.displayMedium?.copyWith(fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          final version = snapshot.hasData ? snapshot.data!.version : '1.0.0';
          return ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              // Device Name Section
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  loc.deviceName,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  state.deviceName,
                  style: theme.textTheme.bodyMedium,
                ),
                trailing: const Icon(Icons.edit_rounded),
                onTap: () async {
                  final controller = TextEditingController(
                    text: state.deviceName,
                  );
                  final newName = await showDialog<String>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: theme.colorScheme.surface,
                      title: Text(loc.deviceName),
                      content: TextField(
                        controller: controller,
                        autofocus: true,
                        decoration: InputDecoration(hintText: loc.deviceName),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                            MaterialLocalizations.of(context).cancelButtonLabel,
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(ctx, controller.text.trim()),
                          child: Text(
                            MaterialLocalizations.of(context).saveButtonLabel,
                          ),
                        ),
                      ],
                    ),
                  );
                  if (newName != null && newName.isNotEmpty) {
                    notifier.setDeviceName(newName);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Packet Rate Section
              Text(
                loc.maxPacketRate,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 30, label: Text('30')),
                  ButtonSegment(value: 45, label: Text('45')),
                  ButtonSegment(value: 60, label: Text('60')),
                  ButtonSegment(value: 120, label: Text('120')),
                ],
                selected: {state.maxFps},
                onSelectionChanged: (Set<int> newSelection) {
                  notifier.setFps(newSelection.first);
                },
              ),
              const SizedBox(height: 32),

              // Theme Section
              Text(
                loc.theme,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              SegmentedButton<ThemeMode>(
                segments: [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text(loc.themeSystem),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text(loc.themeLight),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text(loc.themeDark),
                  ),
                ],
                selected: {state.themeMode},
                onSelectionChanged: (Set<ThemeMode> newSelection) {
                  notifier.setThemeMode(newSelection.first);
                },
              ),
              const SizedBox(height: 32),

              // Language Section
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  loc.language,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  state.languageCode == 'en'
                      ? loc.languageEnglish
                      : state.languageCode == 'tr'
                      ? loc.languageTurkish
                      : state.languageCode == 'ru'
                      ? loc.languageRussian
                      : loc.languageSystem,
                  style: theme.textTheme.bodyMedium,
                ),
                trailing: const Icon(Icons.language_rounded),
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: theme.colorScheme.surface,
                    builder: (ctx) {
                      return SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              title: Text(loc.languageSystem),
                              onTap: () {
                                notifier.setLanguageCode('');
                                Navigator.pop(ctx);
                              },
                            ),
                            ListTile(
                              title: Text(loc.languageEnglish),
                              onTap: () {
                                notifier.setLanguageCode('en');
                                Navigator.pop(ctx);
                              },
                            ),
                            ListTile(
                              title: Text(loc.languageTurkish),
                              onTap: () {
                                notifier.setLanguageCode('tr');
                                Navigator.pop(ctx);
                              },
                            ),
                            ListTile(
                              title: Text(loc.languageRussian),
                              onTap: () {
                                notifier.setLanguageCode('ru');
                                Navigator.pop(ctx);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  loc.reverseScroll,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                value: state.reverseScroll,
                onChanged: (val) {
                  notifier.setReverseScroll(val);
                },
              ),

              const SizedBox(height: 48),
              const Divider(),

              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  loc.aboutApp,
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
                trailing: const Icon(Icons.info_outline),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AboutView()),
                  );
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  loc.licenses,
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
                trailing: const Icon(Icons.policy_outlined),
                onTap: () {
                  showLicensePage(
                    context: context,
                    applicationName: 'MotionBridge',
                    applicationVersion: version,
                  );
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  loc.privacyPolicy,
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
                trailing: const Icon(Icons.privacy_tip_outlined),
                onTap: () {
                  // Şimdilik yönlendirme yok
                },
              ),

              const SizedBox(height: 48),
              Center(
                child: Text(
                  loc.version(version),
                  style: theme.textTheme.labelMedium,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
