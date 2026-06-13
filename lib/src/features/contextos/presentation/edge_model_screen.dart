import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/alter_palette.dart';
import '../../../core/widgets/ambient_scaffold.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../../core/widgets/gradient_text.dart';
import '../../../core/widgets/premium_controls.dart';
import '../application/gemma_model_manager.dart';

class EdgeModelScreen extends ConsumerStatefulWidget {
  const EdgeModelScreen({super.key});

  @override
  ConsumerState<EdgeModelScreen> createState() => _EdgeModelScreenState();
}

class _EdgeModelScreenState extends ConsumerState<EdgeModelScreen> {
  final _url = TextEditingController(text: kDefaultGemmaUrl);
  final _token = TextEditingController();

  @override
  void dispose() {
    _url.dispose();
    _token.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemma = ref.watch(gemmaModelProvider);
    final notifier = ref.read(gemmaModelProvider.notifier);

    return AmbientScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientText(
            'Edge Model',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1.02,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'ALTER is not a cloud wrapper. Run Gemma on the iQOO itself — the '
            'first pass (redaction, triage, risk) happens on-device, before any '
            'cloud call.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          _StatusCard(state: gemma),
          const SizedBox(height: 14),
          if (gemma.status == GemmaStatus.downloading)
            GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Downloading model…',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: gemma.progress == 0 ? null : gemma.progress,
                      minHeight: 8,
                      backgroundColor: AlterPalette.cyan.withValues(
                        alpha: 0.12,
                      ),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AlterPalette.cyan,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(gemma.progress * 100).round()}% — large model, keep the app open.',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.55,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (gemma.status == GemmaStatus.ready)
            GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        LucideIcons.circle_check,
                        color: AlterPalette.mint,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Gemma is running on-device. Edge analysis now uses the '
                          'real model.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    icon: const Icon(LucideIcons.trash_2, size: 16),
                    label: const Text('Remove model'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AlterPalette.danger,
                    ),
                    onPressed: notifier.remove,
                  ),
                ],
              ),
            )
          else if (gemma.status == GemmaStatus.unsupported)
            GlassPanel(
              child: Text(
                'On-device Gemma runs on the Android/iQOO build. On web, ALTER '
                'uses the deterministic edge heuristics and cloud reasoning.',
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
              ),
            )
          else
            GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Install a LiteRT model',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Default is a small Gemma 3 model. Point it at Gemma 3n E4B '
                    '(.task) for the full multimodal edge.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _url,
                    maxLines: 2,
                    minLines: 1,
                    decoration: const InputDecoration(
                      labelText: 'Model .task URL',
                      prefixIcon: Icon(LucideIcons.link),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _token,
                    decoration: const InputDecoration(
                      labelText: 'HuggingFace token (for gated models)',
                      hintText: 'hf_…  (optional)',
                      prefixIcon: Icon(LucideIcons.key_round),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: PremiumButton(
                      label: 'Download & run on-device',
                      icon: LucideIcons.download,
                      onPressed: () => notifier.download(
                        url: _url.text.trim(),
                        hfToken: _token.text.trim(),
                      ),
                    ),
                  ),
                  if (gemma.status == GemmaStatus.error &&
                      gemma.message.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      gemma.message,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AlterPalette.danger,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 14),
          GlassPanel(
            child: Row(
              children: [
                Icon(LucideIcons.shield, size: 18, color: AlterPalette.iris),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Whatever the model state, sensitive data (OTP, card, UPI) is '
                    'redacted on-device before anything leaves the phone.',
                    style: theme.textTheme.labelSmall?.copyWith(height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.state});

  final GemmaModelState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, color, icon) = switch (state.status) {
      GemmaStatus.ready => (
        'On-device · active',
        AlterPalette.mint,
        LucideIcons.cpu,
      ),
      GemmaStatus.downloading => (
        'Downloading',
        AlterPalette.cyan,
        LucideIcons.download,
      ),
      GemmaStatus.loading => ('Loading', AlterPalette.cyan, LucideIcons.loader),
      GemmaStatus.checking => (
        'Checking',
        AlterPalette.slate,
        LucideIcons.loader,
      ),
      GemmaStatus.unsupported => (
        'Heuristics (web)',
        AlterPalette.amber,
        LucideIcons.globe,
      ),
      GemmaStatus.error => (
        'Error',
        AlterPalette.danger,
        LucideIcons.triangle_alert,
      ),
      GemmaStatus.notInstalled => (
        'Not installed · heuristics',
        AlterPalette.amber,
        LucideIcons.cpu,
      ),
    };
    return GlassPanel(
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(icon, color: color, size: 24),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edge status',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
