import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../ui/theme.dart';
import '../../../ui/widgets.dart';
import '../application/agent_controller.dart';

class AgentScreen extends ConsumerStatefulWidget {
  const AgentScreen({super.key});

  @override
  ConsumerState<AgentScreen> createState() => _AgentScreenState();
}

class _AgentScreenState extends ConsumerState<AgentScreen>
    with TickerProviderStateMixin {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  late final AnimationController _eqWave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _eqWave.dispose();
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

  VoiceEqualizerMode _eqMode(AgentState state) {
    if (state.isListening) return VoiceEqualizerMode.listening;
    if (state.isThinking) return VoiceEqualizerMode.speaking;
    return VoiceEqualizerMode.idle;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(agentControllerProvider);
    final notifier = ref.read(agentControllerProvider.notifier);
    _scrollToEnd();

    return DeepScaffold(
      title: 'ALTER',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: notifier.stopSpeaking,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.white(0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.white(0.12)),
                ),
                child: Icon(LucideIcons.volume_x,
                    size: 18, color: AppColors.white(0.85)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: RainbowEqualizer(
              mode: _eqMode(state),
              animation: _eqWave,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Text(
              state.isListening
                  ? 'Listening…'
                  : state.isThinking
                      ? 'Alter is thinking'
                      : 'Talk or type to ALTER',
              textAlign: TextAlign.center,
              style: AppText.body(15, weight: FontWeight.w600),
            ),
          ),
          if (state.partial.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 6, 22, 0),
              child: Text(
                state.partial,
                style: AppText.body(14, color: AppColors.cyan).copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          if (state.error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 6, 22, 0),
              child: Text(
                state.error,
                style: AppText.body(12, color: AppColors.orange),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 12),
              itemCount:
                  state.messages.length + (state.isThinking ? 1 : 0),
              itemBuilder: (context, i) {
                if (i >= state.messages.length) {
                  return const _ThinkingBubble();
                }
                return _Bubble(message: state.messages[i]);
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              18,
              8,
              18,
              8 + MediaQuery.paddingOf(context).bottom,
            ),
            child: _Composer(
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
          ),
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
    if (message.role == AgentRole.tool) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.cyan.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.pending)
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.cyan,
                    ),
                  )
                else
                  Icon(LucideIcons.zap, size: 12, color: AppColors.cyan),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    message.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(12,
                        weight: FontWeight.w700, color: AppColors.cyan),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? AppColors.white(0.10) : null,
          gradient: isUser
              ? null
              : LinearGradient(
                  colors: [
                    AppColors.lime.withValues(alpha: 0.16),
                    AppColors.purple.withValues(alpha: 0.14),
                  ],
                ),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 6),
            bottomRight: Radius.circular(isUser ? 6 : 20),
          ),
          border: Border.all(
            color: isUser
                ? AppColors.white(0.14)
                : AppColors.lime.withValues(alpha: 0.25),
          ),
        ),
        child: Text(
          message.text,
          style: AppText.body(14, height: 1.45),
        ),
      ),
    );
  }
}

class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.white(0.10)),
        ),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.lime,
          ),
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
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white(0.07),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: AppColors.white(0.16)),
            ),
            padding: const EdgeInsets.only(left: 18, right: 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSend(),
                    style: AppText.body(14),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: listening ? 'Listening…' : 'Talk or type…',
                      hintStyle: AppText.body(14, color: AppColors.white(0.4)),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onSend,
                  child: Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.lime.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: AppColors.lime.withValues(alpha: 0.5)),
                    ),
                    child: const Icon(Icons.arrow_upward,
                        size: 18, color: AppColors.lime),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: onMic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: listening
                  ? LinearGradient(
                      colors: [AppColors.orange, AppColors.danger],
                    )
                  : const LinearGradient(
                      colors: [AppColors.lime, AppColors.limeDeep],
                    ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (listening ? AppColors.orange : AppColors.lime)
                      .withValues(alpha: 0.45),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              listening ? LucideIcons.square : LucideIcons.mic,
              color: AppColors.bg,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }
}
