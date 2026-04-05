import 'package:flutter/material.dart';
import '../logic/media_provider.dart';

class MediaCard extends StatelessWidget {
  const MediaCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(24),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                iconSize: 32,
                icon: const Icon(Icons.skip_previous_rounded),
                onPressed: () => mediaController.previous(),
              ),
              const SizedBox(height: 8),
              IconButton(
                iconSize: 48,
                icon: const Icon(Icons.play_arrow_rounded),
                onPressed: () => mediaController.play(),
              ),
              const SizedBox(height: 8),
              IconButton(
                iconSize: 48,
                icon: const Icon(Icons.pause_rounded),
                onPressed: () => mediaController.pause(),
              ),
              const SizedBox(height: 8),
              IconButton(
                iconSize: 32,
                icon: const Icon(Icons.skip_next_rounded),
                onPressed: () => mediaController.next(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
