import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_state.dart';
import '../../../core/theme/alter_palette.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/ambient_scaffold.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../../core/widgets/gradient_text.dart';
import '../../../core/widgets/metric_tile.dart';
import '../../../core/widgets/premium_controls.dart';
import '../../shared/application/alter_data_providers.dart';
import '../application/voice_runtime_controller.dart';
import '../data/voice_runtime_api_client.dart';

class VoiceAssistantScreen extends ConsumerStatefulWidget {
  const VoiceAssistantScreen({super.key});

  @override
  ConsumerState<VoiceAssistantScreen> createState() =>
      _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends ConsumerState<VoiceAssistantScreen> {
  late final TextEditingController _transcriptController;

  @override
  void initState() {
    super.initState();
    _transcriptController = TextEditingController(
      text: 'Hey Alter, should I build ALTER into a startup and what should I do today?',
    );
  }

  @override
  void dispose() {
    _transcriptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(alterAppControllerProvider);
    final brief = ref.watch(assistantBriefProvider);
    final runtime = ref.watch(voiceRuntimeControllerProvider);
    final theme = Theme.of(context);
    final locale = _localeForLanguage(appState.selectedLanguage);
    void runVoiceRuntime() {
      ref.read(alterAppControllerProvider.notifier).setVoiceListening(true);
      ref
          .read(voiceRuntimeControllerProvider.notifier)
          .run(
            transcript: _transcriptController.text,
            locale: locale,
          )
          .whenComplete(() {
            if (mounted) {
              ref
                  .read(alterAppControllerProvider.notifier)
                  .setVoiceListening(false);
            }
          });
    }

    return AmbientScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hey Alter',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AlterPalette.iris,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GradientText(
                      appState.voiceListening
                          ? 'Listening across context.'
                          : 'Your future OS is ready.',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.02,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filled(
                tooltip: 'Run voice runtime',
                style: IconButton.styleFrom(
                  backgroundColor: appState.voiceListening || runtime.isRunning
                      ? AlterPalette.iris
                      : theme.colorScheme.surface.withValues(alpha: 0.7),
                  foregroundColor: appState.voiceListening || runtime.isRunning
                      ? Colors.white
                      : AlterPalette.iris,
                ),
                onPressed: runtime.isRunning ? null : runVoiceRuntime,
                icon: const Icon(LucideIcons.mic),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final language in const [
                'English',
                'Hindi',
                'Spanish',
                'Japanese',
              ])
                PremiumChip(
                  label: language,
                  selected: appState.selectedLanguage == language,
                  icon: LucideIcons.languages,
                  onTap: () {
                    ref
                        .read(alterAppControllerProvider.notifier)
                        .setLanguage(language);
                  },
                ),
            ],
          ),
          const SizedBox(height: 22),
          _VoiceCore(
            isListening: appState.voiceListening || runtime.isRunning,
            onTap: runtime.isRunning ? null : runVoiceRuntime,
          ),
          const SizedBox(height: 18),
          _VoiceRuntimePanel(
            controller: _transcriptController,
            locale: locale,
            isRunning: runtime.isRunning,
            errorMessage: runtime.errorMessage,
            result: runtime.result,
            onRun: runVoiceRuntime,
          ),
          const SizedBox(height: 18),
          brief.when(
            data: (data) => GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: data.greeting,
                    subtitle: data.focus,
                    trailing: PremiumChip(
                      label: data.nextAction,
                      selected: true,
                      icon: LucideIcons.sparkles,
                    ),
                  ),
                  const SizedBox(height: 18),
                  for (final signal in data.signals)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.check,
                            size: 17,
                            color: AlterPalette.mint,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              signal,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            loading: () => const _LoadingPanel(),
            error: (error, stackTrace) => Text('Unable to load brief: $error'),
          ),
          const SizedBox(height: 18),
          ResponsiveGrid(
            children: const [
              MetricTile(
                label: 'Wake word latency',
                value: '128 ms',
                icon: LucideIcons.audio_waveform,
                detail: 'On-device activation target',
                accent: AlterPalette.cyan,
              ),
              MetricTile(
                label: 'Memory confidence',
                value: '92%',
                icon: LucideIcons.brain_circuit,
                detail: 'Personal graph freshness',
                accent: AlterPalette.iris,
              ),
              MetricTile(
                label: 'Next best move',
                value: '1',
                icon: LucideIcons.radar,
                detail: 'Opportunity is time-sensitive',
                accent: AlterPalette.aura,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VoiceCore extends StatelessWidget {
  const _VoiceCore({required this.isListening, required this.onTap});

  final bool isListening;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: GlassPanel(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            SizedBox(
              height: 190,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  for (var index = 0; index < 3; index++)
                    AnimatedContainer(
                      duration: Duration(milliseconds: 520 + index * 90),
                      curve: Curves.easeOutCubic,
                      width:
                          isListening ? 116.0 + index * 52 : 100.0 + index * 38,
                      height:
                          isListening ? 116.0 + index * 52 : 100.0 + index * 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AlterPalette.iris.withValues(
                            alpha: isListening ? 0.26 - index * 0.05 : 0.12,
                          ),
                        ),
                      ),
                    )
                        .animate(
                          target: isListening ? 1 : 0,
                          onPlay: (controller) {
                            if (isListening) {
                              controller.repeat(reverse: true);
                            }
                          },
                        )
                        .scale(
                          begin: const Offset(0.97, 0.97),
                          end: const Offset(1.04, 1.04),
                          duration: 1500.ms,
                        ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AlterPalette.premiumGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AlterPalette.iris.withValues(alpha: 0.34),
                          blurRadius: 42,
                        ),
                      ],
                    ),
                    child: const SizedBox(
                      width: 96,
                      height: 96,
                      child: Icon(
                        LucideIcons.mic,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isListening ? 'Thinking with context' : 'Say Hey Alter',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var index = 0; index < 18; index++)
                  _WaveBar(index: index, active: isListening),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VoiceRuntimePanel extends StatelessWidget {
  const _VoiceRuntimePanel({
    required this.controller,
    required this.locale,
    required this.isRunning,
    required this.errorMessage,
    required this.result,
    required this.onRun,
  });

  final TextEditingController controller;
  final String locale;
  final bool isRunning;
  final String errorMessage;
  final VoiceRuntimeResult? result;
  final VoidCallback onRun;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Voice Action Runtime',
            subtitle: 'Intent, memory, reasoning, action, follow-up.',
            trailing: PremiumButton(
              label: isRunning ? 'Thinking' : 'Run Voice',
              compact: true,
              icon: isRunning ? LucideIcons.loader : LucideIcons.radio,
              onPressed: isRunning ? null : onRun,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Voice transcript',
              hintText: 'Hey Alter, what should I do today?',
              prefixIcon: const Icon(LucideIcons.audio_lines),
              suffixText: locale,
            ),
            onSubmitted: (_) {
              if (!isRunning) {
                onRun();
              }
            },
          ),
          if (isRunning) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: const LinearProgressIndicator(minHeight: 5),
            ),
          ],
          if (errorMessage.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              errorMessage,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (result != null) ...[
            const SizedBox(height: 16),
            _VoiceRuntimeResultPanel(result: result!),
          ],
        ],
      ),
    );
  }
}

class _VoiceRuntimeResultPanel extends StatelessWidget {
  const _VoiceRuntimeResultPanel({required this.result});

  final VoiceRuntimeResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            PremiumChip(
              label: result.wakeWordDetected ? 'Wake word heard' : 'No wake word',
              selected: result.wakeWordDetected,
              icon: result.wakeWordDetected
                  ? LucideIcons.badge_check
                  : LucideIcons.badge_alert,
            ),
            PremiumChip(
              label: result.inferredIntent.replaceAll('_', ' '),
              selected: true,
              icon: LucideIcons.workflow,
            ),
            PremiumChip(
              label: '${(result.intentConfidence * 100).round()}% intent',
              selected: result.intentConfidence >= 0.7,
              icon: LucideIcons.gauge,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AlterPalette.iris.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AlterPalette.iris.withValues(alpha: 0.18)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(LucideIcons.volume_2, color: AlterPalette.iris),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  result.spokenResponse,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.32,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (result.experimentPlan != null) ...[
          const SizedBox(height: 14),
          _VoiceExperimentPanel(plan: result.experimentPlan!),
        ],
        const SizedBox(height: 14),
        ResponsiveGrid(
          mediumColumns: 2,
          expandedColumns: 3,
          children: [
            _VoiceListPanel(
              title: 'Action Graph',
              icon: LucideIcons.workflow,
              items: result.actionGraph,
            ),
            _VoiceListPanel(
              title: 'Next Actions',
              icon: LucideIcons.check_check,
              items: result.nextActions,
            ),
            _VoiceListPanel(
              title: 'Follow Up',
              icon: LucideIcons.messages_square,
              items: result.followUpQuestions,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final signal in result.signals)
              PremiumChip(
                label: signal.latencyMs == null
                    ? signal.title
                    : '${signal.title} ${signal.latencyMs}ms',
                selected: signal.isHealthy,
                icon: signal.isHealthy
                    ? LucideIcons.circle_check
                    : LucideIcons.circle_alert,
              ),
          ],
        ),
      ],
    );
  }
}

class _VoiceExperimentPanel extends StatelessWidget {
  const _VoiceExperimentPanel({required this.plan});

  final VoiceExperimentPlan plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AlterPalette.mint.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AlterPalette.mint.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.flask_conical, color: AlterPalette.mint),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Experiment Plan',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              PremiumChip(
                label: plan.deadline,
                selected: true,
                icon: LucideIcons.calendar,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            plan.action,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            plan.whyItMatters,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            plan.successMetric,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AlterPalette.mint,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _VoiceListPanel extends StatelessWidget {
  const _VoiceListPanel({
    required this.title,
    required this.icon,
    required this.items,
  });

  final String title;
  final IconData icon;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: AlterPalette.iris),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final item in items.take(5))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                item,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.64),
                  height: 1.34,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WaveBar extends StatelessWidget {
  const _WaveBar({required this.index, required this.active});

  final int index;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final height = active ? 16.0 + ((index * 7) % 28) : 7.0;
    return AnimatedContainer(
      duration: Duration(milliseconds: 260 + index * 18),
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 5,
      height: height,
      decoration: BoxDecoration(
        color: AlterPalette.iris.withValues(alpha: active ? 0.72 : 0.22),
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}

String _localeForLanguage(String language) {
  return switch (language) {
    'Hindi' => 'hi-IN',
    'Spanish' => 'es-ES',
    'Japanese' => 'ja-JP',
    _ => 'en-US',
  };
}

class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel();

  @override
  Widget build(BuildContext context) {
    return const GlassPanel(
      child: SizedBox(
        height: 112,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
