import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../utils/dictation_channel.dart';
import '../logic/settings_provider.dart';

class SpeechEngineSelector extends ConsumerWidget {
  const SpeechEngineSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!Platform.isAndroid) return const SizedBox.shrink();

    final state = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        "Speech Engine",
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        state.speechEnginePackage.isEmpty
            ? "System Default"
            : state.speechEnginePackage,
        style: theme.textTheme.bodyMedium,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.record_voice_over),
      onTap: () async {
        final engines = await DictationChannel.getEngines();
        if (!context.mounted) return;

        showModalBottomSheet(
          context: context,
          backgroundColor: theme.colorScheme.surface,
          builder: (ctx) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text("System Default"),
                    onTap: () {
                      ref
                          .read(settingsProvider.notifier)
                          .setSpeechEnginePackage('');
                      Navigator.pop(ctx);
                    },
                  ),
                  ...engines
                      .map(
                        (e) => ListTile(
                          title: Text(e['name'] ?? ""),
                          subtitle: Text(e['packageName'] ?? ""),
                          onTap: () {
                            ref
                                .read(settingsProvider.notifier)
                                .setSpeechEnginePackage(e['packageName']!);
                            Navigator.pop(ctx);
                          },
                        ),
                      )
                      .toList(),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
