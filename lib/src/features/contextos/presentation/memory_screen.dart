import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/widgets.dart';
import 'memory_settings_sheet.dart';
import 'memory_swipe_deck.dart';

class MemoryScreen extends ConsumerWidget {
  const MemoryScreen({super.key});

  void _openSettings(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: surface,
      builder: (_) => const MemorySettingsSheet(),
    );
  }

  void _openKept(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: surface,
      builder: (_) => const MemoryKeptSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DeepScaffold(
      title: 'MEMORY',
      subtitle:
          'Swipe right to keep what matters about you. Swipe left to forget — '
          'removed from your profile and vector index.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _openSettings(context),
              icon: const Icon(LucideIcons.sliders_horizontal, size: 16),
              label: const Text('Governance & trusted sources'),
            ),
          ),
          Expanded(
            child: MemorySwipeDeck(
              onBrowseKept: () => _openKept(context),
            ),
          ),
        ],
      ),
    );
  }
}
