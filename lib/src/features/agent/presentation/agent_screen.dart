import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/alter_palette.dart';
import '../../../core/widgets/ambient_scaffold.dart';
import '../../../core/widgets/gradient_text.dart';
import '../application/agent_controller.dart';

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
            ],
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
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: AlterPalette.amber),
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
              border: Border.all(color: AlterPalette.cyan.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.pending)
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AlterPalette.cyan),
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
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.08)),
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
                      colors: [AlterPalette.aura, AlterPalette.danger])
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
