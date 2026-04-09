import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logic/settings_provider.dart';

class TrackpadBackgroundSelector extends ConsumerWidget {
  const TrackpadBackgroundSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    String getLabel(String val) {
      switch (val) {
        case 'none':
          return "Arkaplan Yok";
        case 'isometric':
          return "İzometrik-Manyetik";
        case 'touch_indicators':
          return "Dokunsal-Gösterge";
        case 'spline':
          return "Spline";
        default:
          return "İzometrik-Manyetik";
      }
    }

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        "Trackpad Arkaplanı",
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        getLabel(state.trackpadBackground),
        style: theme.textTheme.bodyMedium,
      ),
      trailing: const Icon(Icons.wallpaper),
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
                    title: const Text("Arkaplan Yok"),
                    onTap: () {
                      ref
                          .read(settingsProvider.notifier)
                          .setTrackpadBackground('none');
                      Navigator.pop(ctx);
                    },
                  ),
                  ListTile(
                    title: const Text("İzometrik-Manyetik"),
                    onTap: () {
                      ref
                          .read(settingsProvider.notifier)
                          .setTrackpadBackground('isometric');
                      Navigator.pop(ctx);
                    },
                  ),
                  ListTile(
                    title: const Text("Dokunsal-Gösterge"),
                    onTap: () {
                      ref
                          .read(settingsProvider.notifier)
                          .setTrackpadBackground('touch_indicators');
                      Navigator.pop(ctx);
                    },
                  ),
                  ListTile(
                    title: const Text("Spline"),
                    onTap: () {
                      ref
                          .read(settingsProvider.notifier)
                          .setTrackpadBackground('spline');
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
