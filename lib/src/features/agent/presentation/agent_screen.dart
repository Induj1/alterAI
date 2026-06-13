import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/alter_palette.dart';
import '../../../core/widgets/ambient_scaffold.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../../core/widgets/gradient_text.dart';
import '../application/agent_controller.dart';
import '../application/agent_execution_runtime.dart';
import '../application/persistent_intelligence_store.dart';

class AgentScreen extends ConsumerStatefulWidget {
  const AgentScreen({super.key});

  @override
  ConsumerState<AgentScreen> createState() => _AgentScreenState();
}

class _AgentScreenState extends ConsumerState<AgentScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(agentControllerProvider);
    final runtime = ref.watch(agentExecutionRuntimeProvider);
    final store = ref.watch(persistentIntelligenceStoreProvider);
    final notifier = ref.read(agentControllerProvider.notifier);
    final theme = Theme.of(context);
    _scrollToEnd();

    return AmbientScaffold(
      scrollable: false,
      bottomPadding: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GradientText(
                'ALTER',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'voice agent',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Stop talking',
                icon: const Icon(LucideIcons.volume_x),
                onPressed: notifier.stopSpeaking,
              ),
              IconButton.filledTonal(
                tooltip: state.isSarvamRecording
                    ? 'Stop Sarvam voice'
                    : 'Start Sarvam voice',
                icon: Icon(
                  state.isSarvamRecording
                      ? LucideIcons.square
                      : LucideIcons.audio_lines,
                  size: 18,
                ),
                onPressed: notifier.toggleSarvamLiveVoice,
              ),
            ],
          ),
          const SizedBox(height: 8),
          _LiveControlCenter(
            runtime: runtime,
            store: store.asData?.value,
            liveVoiceStatus: state.liveVoiceStatus,
            onRunGoal: () {
              final goal = _input.text.trim();
              if (goal.isEmpty) return;
              ref.read(agentExecutionRuntimeProvider.notifier).runGoal(goal);
            },
            onStop: () =>
                ref.read(agentExecutionRuntimeProvider.notifier).stop(),
            onExport: () async {
              final json = await ref
                  .read(persistentIntelligenceStoreProvider.notifier)
                  .exportData();
              await Clipboard.setData(ClipboardData(text: json));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Local twin export copied.')),
                );
              }
            },
            onDelete: () {
              ref
                  .read(persistentIntelligenceStoreProvider.notifier)
                  .deleteScopes(const ['audit', 'memories']);
            },
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 12),
              itemCount: state.messages.length + (state.isThinking ? 1 : 0),
              itemBuilder: (context, i) {
                if (i >= state.messages.length) {
                  return const _ThinkingBubble();
                }
                return _Bubble(message: state.messages[i]);
              },
            ),
          ),
          if (state.partial.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                state.partial,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AlterPalette.iris,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          if (state.error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                state.error,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AlterPalette.amber,
                ),
              ),
            ),
          _Composer(
            controller: _input,
            listening: state.isListening,
            onMic: () {
              HapticFeedback.mediumImpact();
              notifier.toggleListening();
            },
            onSend: () {
              final t = _input.text.trim();
              if (t.isEmpty) return;
              _input.clear();
              notifier.send(t);
            },
          ),
          SizedBox(height: MediaQuery.paddingOf(context).bottom + 8),
        ],
      ),
    );
  }
}

class _LiveControlCenter extends StatelessWidget {
  const _LiveControlCenter({
    required this.runtime,
    required this.store,
    required this.liveVoiceStatus,
    required this.onRunGoal,
    required this.onStop,
    required this.onExport,
    required this.onDelete,
  });

  final AgentExecutionState runtime;
  final IntelligenceStoreState? store;
  final String liveVoiceStatus;
  final VoidCallback onRunGoal;
  final VoidCallback onStop;
  final VoidCallback onExport;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = runtime.running || runtime.plan.isNotEmpty;
    return GlassPanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                runtime.running ? LucideIcons.activity : LucideIcons.workflow,
                color: runtime.running ? AlterPalette.mint : AlterPalette.cyan,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  runtime.currentGoal.isEmpty
                      ? 'Live control center'
                      : runtime.currentGoal,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                tooltip: runtime.running ? 'Stop loop' : 'Run phone loop',
                icon: Icon(
                  runtime.running ? LucideIcons.square : LucideIcons.play,
                  size: 17,
                ),
                onPressed: runtime.running ? onStop : onRunGoal,
              ),
              IconButton(
                tooltip: 'Export local twin',
                icon: const Icon(LucideIcons.download, size: 17),
                onPressed: store == null ? null : onExport,
              ),
              IconButton(
                tooltip: 'Delete local audit and memories',
                icon: const Icon(LucideIcons.trash_2, size: 17),
                onPressed: store == null ? null : onDelete,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniChip(
                label: runtime.currentAgent.label,
                icon: LucideIcons.bot,
                selected: runtime.running,
              ),
              _MiniChip(
                label: '${runtime.completedSteps}/${runtime.plan.length} steps',
                icon: LucideIcons.list_checks,
                selected: runtime.completedSteps > 0,
              ),
              _MiniChip(
                label: '${store?.memories.length ?? 0} memories',
                icon: LucideIcons.database,
                selected: (store?.memories.length ?? 0) > 0,
              ),
              _MiniChip(
                label: '${store?.audit.length ?? 0} audit',
                icon: LucideIcons.clipboard_check,
                selected: (store?.audit.length ?? 0) > 0,
              ),
            ],
          ),
          if (liveVoiceStatus.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              liveVoiceStatus,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AlterPalette.cyan,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (active) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 84,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: runtime.plan.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final step = runtime.plan[index];
                  return _StepPill(step: step, index: index + 1);
                },
              ),
            ),
          ],
          if (runtime.audit.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              runtime.audit.first.summary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: runtime.audit.first.ok
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.62)
                    : AlterPalette.amber,
              ),
            ),
          ],
          if (runtime.failures.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              runtime.failures.first,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AlterPalette.amber,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({
    required this.label,
    required this.icon,
    required this.selected,
  });

  final String label;
  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: (selected ? AlterPalette.cyan : AlterPalette.slate).withValues(
          alpha: 0.12,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (selected ? AlterPalette.cyan : AlterPalette.slate).withValues(
            alpha: 0.22,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: selected ? AlterPalette.cyan : null),
            const SizedBox(width: 5),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _StepPill extends StatelessWidget {
  const _StepPill({required this.step, required this.index});

  final AgentRuntimeStep step;
  final int index;

  @override
  Widget build(BuildContext context) {
    final color = switch (step.status) {
      AgentStepStatus.done => AlterPalette.mint,
      AgentStepStatus.failed || AgentStepStatus.blocked => AlterPalette.amber,
      AgentStepStatus.running => AlterPalette.cyan,
      AgentStepStatus.planned => AlterPalette.iris,
    };
    return SizedBox(
      width: 190,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.11),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$index. ${step.agent.label}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                step.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final AgentMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (message.role == AgentRole.tool) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AlterPalette.cyan.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                color: AlterPalette.cyan.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.pending)
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AlterPalette.cyan,
                    ),
                  )
                else
                  Icon(LucideIcons.zap, size: 12, color: AlterPalette.cyan),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    message.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AlterPalette.cyan,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isUser = message.role == AgentRole.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          gradient: isUser ? AlterPalette.premiumGradient : null,
          color: isUser
              ? null
              : theme.colorScheme.surface.withValues(alpha: 0.55),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isUser ? 14 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 14),
          ),
          border: isUser
              ? null
              : Border.all(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                ),
        ),
        child: Text(
          message.text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isUser ? Colors.white : theme.colorScheme.onSurface,
            height: 1.35,
            fontWeight: isUser ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.listening,
    required this.onMic,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool listening;
  final VoidCallback onMic;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            minLines: 1,
            maxLines: 4,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => onSend(),
            decoration: InputDecoration(
              hintText: listening ? 'Listening…' : 'Talk or type to ALTER…',
              filled: true,
              fillColor: theme.colorScheme.surface.withValues(alpha: 0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: const Icon(LucideIcons.send_horizontal, size: 18),
                onPressed: onSend,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: onMic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: listening
                  ? const LinearGradient(
                      colors: [AlterPalette.aura, AlterPalette.danger],
                    )
                  : AlterPalette.premiumGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (listening ? AlterPalette.aura : AlterPalette.iris)
                      .withValues(alpha: 0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              listening ? LucideIcons.square : LucideIcons.mic,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }
}
