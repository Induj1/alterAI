import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../app/app_state.dart';
import '../../../core/theme/alter_palette.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/ambient_scaffold.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../../core/widgets/gradient_text.dart';
import '../../../core/widgets/metric_tile.dart';
import '../../../core/widgets/premium_controls.dart';
import '../../profile/application/profile_provider.dart';
import '../../shared/application/alter_data_providers.dart';
import '../application/native_wake_service_controller.dart';
import '../application/voice_runtime_controller.dart';
import '../data/voice_runtime_api_client.dart';
import '../domain/wake_word.dart';

class VoiceAssistantScreen extends ConsumerStatefulWidget {
  const VoiceAssistantScreen({super.key});

  @override
  ConsumerState<VoiceAssistantScreen> createState() =>
      _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends ConsumerState<VoiceAssistantScreen> {
  late final TextEditingController _transcriptController;
  bool _assistantMode = false;
  bool _wakeProcessing = false;
  bool _sttReady = false;
  String _partialTranscript = '';
  String _assistantStatus = 'Assistant mode is off.';
  String _sttError = '';

  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _transcriptController = TextEditingController(
      text:
          'Hey Alter, should I build ALTER into a startup and what should I do today?',
    );
  }

  @override
  void dispose() {
    _transcriptController.dispose();
    _assistantMode = false;
    _speech.cancel();
    _tts.stop();
    super.dispose();
  }

  Future<bool> _ensureSpeechReady() async {
    if (_sttReady) return true;
    _sttReady = await _speech.initialize(
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _sttError = error.errorMsg;
        });
        ref.read(alterAppControllerProvider.notifier).setVoiceListening(false);
        if (_assistantMode && !error.permanent) {
          _rearmWakeLoop();
        }
      },
      onStatus: (status) => _onSpeechStatus(status),
    );
    return _sttReady;
  }

  Future<void> _speak(String text, {required String locale}) async {
    if (text.trim().isEmpty) return;
    try {
      await _tts.stop();
      await _tts.setLanguage(locale);
      await _tts.setSpeechRate(0.52);
      await _tts.speak(text);
    } catch (_) {}
  }

  void _setVoiceActive(bool value) {
    if (!mounted) return;
    ref.read(alterAppControllerProvider.notifier).setVoiceListening(value);
  }

  Future<void> _runVoiceRuntime({
    required String transcript,
    required String locale,
  }) async {
    final cleaned = transcript.trim();
    if (cleaned.isEmpty) return;
    _transcriptController.text = cleaned;
    ref.read(alterAppControllerProvider.notifier).setVoiceListening(true);
    await ref
        .read(voiceRuntimeControllerProvider.notifier)
        .run(transcript: cleaned, locale: locale);
    if (!mounted) return;
    ref
        .read(alterAppControllerProvider.notifier)
        .setVoiceListening(_assistantMode);
  }

  Future<void> _startOneShotListening(String locale) async {
    if (!await _ensureSpeechReady()) {
      setState(
        () => _sttError =
            'Speech recognition is unavailable. Type your command instead.',
      );
      return;
    }
    _assistantMode = false;
    _wakeProcessing = false;
    _setVoiceActive(true);
    setState(() {
      _assistantStatus = 'Listening for a command.';
      _partialTranscript = '';
      _sttError = '';
    });
    await _speech.listen(
      listenOptions: SpeechListenOptions(
        localeId: locale,
        listenFor: const Duration(seconds: 18),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        listenMode: ListenMode.search,
        cancelOnError: false,
      ),
      onResult: (result) {
        if (!mounted) return;
        setState(() => _partialTranscript = result.recognizedWords);
        if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
          _speech.stop();
          unawaited(
            _runVoiceRuntime(
              transcript: result.recognizedWords,
              locale: locale,
            ),
          );
        }
      },
    );
  }

  Future<void> _toggleAssistantMode(String locale) async {
    if (_assistantMode) {
      setState(() {
        _assistantMode = false;
        _assistantStatus = 'Assistant mode is off.';
        _partialTranscript = '';
      });
      _setVoiceActive(false);
      await _speech.stop();
      return;
    }

    if (!await _ensureSpeechReady()) {
      setState(
        () => _sttError =
            'Speech recognition is unavailable. Type your command instead.',
      );
      return;
    }
    setState(() {
      _assistantMode = true;
      _assistantStatus = 'Assistant mode armed. Say "Hey Alter".';
      _partialTranscript = '';
      _sttError = '';
    });
    unawaited(_speak('Hey Alter is ready.', locale: locale));
    unawaited(_startWakeLoop(locale));
  }

  Future<void> _startWakeLoop(String locale) async {
    if (!_assistantMode || _wakeProcessing || !mounted) return;
    if (_speech.isListening) {
      await _speech.stop();
    }
    _setVoiceActive(true);
    setState(() {
      _assistantStatus = 'Listening for "Hey Alter".';
      _partialTranscript = '';
    });
    await _speech.listen(
      listenOptions: SpeechListenOptions(
        localeId: locale,
        listenFor: const Duration(seconds: 25),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        listenMode: ListenMode.search,
        cancelOnError: false,
      ),
      onResult: (result) => _onWakeResult(result, locale),
    );
  }

  void _onWakeResult(SpeechRecognitionResult result, String locale) {
    if (!mounted || !_assistantMode || _wakeProcessing) return;
    final heard = result.recognizedWords.trim();
    setState(() => _partialTranscript = heard);
    final wake = WakeWord.parse(heard);
    if (!wake.detected) return;
    _wakeProcessing = true;
    unawaited(_speech.stop());
    unawaited(_processWakeMatch(wake, locale));
  }

  Future<void> _processWakeMatch(WakeWordMatch wake, String locale) async {
    if (!mounted) return;
    setState(() {
      _assistantStatus = wake.hasCommand
          ? 'Wake word heard. Thinking.'
          : 'Wake word heard.';
      _partialTranscript = wake.original;
    });

    if (!wake.hasCommand) {
      await _speak('I am listening.', locale: locale);
      _wakeProcessing = false;
      _rearmWakeLoop();
      return;
    }

    await _runVoiceRuntime(transcript: wake.runtimeTranscript, locale: locale);
    _wakeProcessing = false;
    _rearmWakeLoop();
  }

  void _onSpeechStatus(String status) {
    if (!mounted) return;
    if (status == 'done' || status == 'notListening') {
      ref
          .read(alterAppControllerProvider.notifier)
          .setVoiceListening(_assistantMode);
      if (_assistantMode && !_wakeProcessing) {
        _rearmWakeLoop();
      }
    }
  }

  void _rearmWakeLoop() {
    if (!_assistantMode || !mounted) return;
    Future<void>.delayed(const Duration(milliseconds: 450), () {
      if (!mounted || !_assistantMode || _wakeProcessing) return;
      final locale = _localeForLanguage(
        ref.read(alterAppControllerProvider).selectedLanguage,
      );
      unawaited(_startWakeLoop(locale));
    });
  }

  Future<void> _handleNativeWakeEvent({
    required String phrase,
    required bool onDevice,
    required String locale,
  }) async {
    if (!mounted) return;
    final heard = phrase.trim().isEmpty ? 'Hey Alter' : phrase.trim();
    final wake = WakeWord.parse(heard);

    _assistantMode = false;
    _wakeProcessing = false;
    await _speech.cancel();
    _setVoiceActive(true);

    if (wake.detected && wake.hasCommand) {
      _wakeProcessing = true;
      await _processWakeMatch(wake, locale);
      return;
    }

    if (!mounted) return;
    setState(() {
      _assistantStatus = onDevice
          ? 'Native on-device wake heard. Listening for a command.'
          : 'Native wake heard. Listening for a command.';
      _partialTranscript = heard;
      _sttError = '';
    });

    await _speak('I am listening.', locale: locale);
    if (!mounted) return;
    await _startOneShotListening(locale);
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(alterAppControllerProvider);
    final brief = ref.watch(assistantBriefProvider);
    final runtime = ref.watch(voiceRuntimeControllerProvider);
    final nativeWake = ref.watch(nativeWakeServiceControllerProvider);
    final hasOpenAI = ref.watch(openAIServiceProvider) != null;
    final theme = Theme.of(context);
    final locale = _localeForLanguage(appState.selectedLanguage);

    // Auto-TTS spoken response after AI finishes.
    ref.listen(voiceRuntimeControllerProvider, (prev, next) {
      if (prev?.isRunning == true && !next.isRunning) {
        final spoken = next.result?.spokenResponse ?? '';
        if (spoken.isNotEmpty) {
          unawaited(_speak(spoken, locale: locale));
        }
      }
    });

    ref.listen(nativeWakeServiceControllerProvider, (prev, next) {
      if ((prev?.wakeCount ?? 0) >= next.wakeCount) return;
      final event = next.lastEvent;
      if (event == null) return;
      unawaited(
        _handleNativeWakeEvent(
          phrase: event.phrase,
          onDevice: event.onDevice,
          locale: locale,
        ),
      );
    });

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
                          ? 'Say Hey Alter.'
                          : 'Assistant layer is ready.',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.02,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton.filled(
                    tooltip: _assistantMode
                        ? 'Turn off Hey Alter'
                        : 'Turn on Hey Alter',
                    style: IconButton.styleFrom(
                      backgroundColor: _assistantMode
                          ? AlterPalette.aura
                          : appState.voiceListening || runtime.isRunning
                          ? AlterPalette.iris
                          : theme.colorScheme.surface.withValues(alpha: 0.7),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: runtime.isRunning
                        ? null
                        : () => _toggleAssistantMode(locale),
                    icon: Icon(
                      _assistantMode ? LucideIcons.mic_off : LucideIcons.mic,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final language in _assistantLanguages.keys)
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
          if (_sttError.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              _sttError,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AlterPalette.amber,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (!hasOpenAI) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => context.go('/settings'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AlterPalette.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AlterPalette.amber.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.triangle_alert,
                      color: AlterPalette.amber,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Connect the backend with SARVAM_API_KEY, or add an OpenAI key in Settings for fallback AI.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AlterPalette.amber,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Icon(
                      LucideIcons.arrow_right,
                      color: AlterPalette.amber,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 22),
          _VoiceCore(
            isListening:
                _assistantMode || appState.voiceListening || runtime.isRunning,
            assistantMode: _assistantMode,
            status: _assistantStatus,
            partialTranscript: _partialTranscript,
            onTap: runtime.isRunning
                ? null
                : () => _toggleAssistantMode(locale),
          ),
          const SizedBox(height: 18),
          _NativeWakeServicePanel(
            state: nativeWake,
            onToggle: () =>
                ref.read(nativeWakeServiceControllerProvider.notifier).toggle(),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: PremiumButton(
                  label: _assistantMode ? 'Hey Alter on' : 'Arm Hey Alter',
                  icon: _assistantMode ? LucideIcons.radio : LucideIcons.power,
                  onPressed: runtime.isRunning
                      ? null
                      : () => _toggleAssistantMode(locale),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                icon: const Icon(LucideIcons.mic, size: 16),
                label: const Text('Talk once'),
                onPressed: runtime.isRunning || _assistantMode
                    ? null
                    : () => _startOneShotListening(locale),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _VoiceRuntimePanel(
            controller: _transcriptController,
            locale: locale,
            isRunning: runtime.isRunning,
            errorMessage: runtime.errorMessage,
            result: runtime.result,
            onRun: () => _runVoiceRuntime(
              transcript: _transcriptController.text,
              locale: locale,
            ),
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

class _NativeWakeServicePanel extends StatelessWidget {
  const _NativeWakeServicePanel({required this.state, required this.onToggle});

  final NativeWakeServiceState state;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lastWake = state.lastEvent;
    final subtitle = state.running
        ? 'Foreground mic service is armed.'
        : state.supported
        ? 'Android wake service is ready.'
        : 'Android native wake is unavailable here.';

    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Native Hey Alter',
            subtitle: subtitle,
            trailing: PremiumButton(
              label: state.running ? 'Stop' : 'Start',
              compact: true,
              icon: state.running ? LucideIcons.mic_off : LucideIcons.radio,
              onPressed: state.supported || !state.running ? onToggle : null,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              PremiumChip(
                label: state.running ? 'Foreground' : 'Idle',
                selected: state.running,
                icon: state.running ? LucideIcons.radio : LucideIcons.power,
              ),
              PremiumChip(
                label: state.onDeviceWakeAvailable
                    ? 'On-device'
                    : 'Offline preferred',
                selected: state.onDeviceWakeAvailable,
                icon: LucideIcons.cpu,
              ),
              PremiumChip(
                label: '${state.wakeCount} wakes',
                selected: state.wakeCount > 0,
                icon: LucideIcons.audio_waveform,
              ),
            ],
          ),
          if (lastWake != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AlterPalette.cyan.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AlterPalette.cyan.withValues(alpha: 0.18),
                ),
              ),
              child: Text(
                lastWake.phrase,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AlterPalette.cyan,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
            ),
          ],
          if (state.error.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              state.error,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AlterPalette.amber,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VoiceCore extends StatelessWidget {
  const _VoiceCore({
    required this.isListening,
    required this.assistantMode,
    required this.status,
    required this.partialTranscript,
    required this.onTap,
  });

  final bool isListening;
  final bool assistantMode;
  final String status;
  final String partialTranscript;
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
                          width: isListening
                              ? 116.0 + index * 52
                              : 100.0 + index * 38,
                          height: isListening
                              ? 116.0 + index * 52
                              : 100.0 + index * 38,
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
              assistantMode
                  ? 'Wake phrase armed'
                  : isListening
                  ? 'Thinking with context'
                  : 'Say Hey Alter',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              status,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
                height: 1.3,
              ),
            ),
            if (partialTranscript.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AlterPalette.iris.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AlterPalette.iris.withValues(alpha: 0.18),
                  ),
                ),
                child: Text(
                  partialTranscript,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AlterPalette.iris,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
              ),
            ],
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
            title: 'Hey Alter Runtime',
            subtitle:
                'Wake word, intent, memory, reasoning, action, follow-up.',
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
              label: result.wakeWordDetected
                  ? 'Wake word heard'
                  : 'No wake word',
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
            PremiumChip(
              label: result.aiProvider == 'sarvam'
                  ? 'Sarvam AI'
                  : result.aiProvider,
              selected: result.aiProvider == 'sarvam',
              icon: LucideIcons.sparkles,
            ),
            PremiumChip(
              label:
                  '${result.languageDisplayName} ${result.responseLanguageCode}',
              selected: true,
              icon: LucideIcons.languages,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AlterPalette.iris.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AlterPalette.iris.withValues(alpha: 0.18),
            ),
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
  return _assistantLanguages[language] ?? 'en-IN';
}

const _assistantLanguages = <String, String>{
  'English': 'en-IN',
  'Hindi': 'hi-IN',
  'Bengali': 'bn-IN',
  'Tamil': 'ta-IN',
  'Telugu': 'te-IN',
  'Marathi': 'mr-IN',
  'Gujarati': 'gu-IN',
  'Kannada': 'kn-IN',
  'Malayalam': 'ml-IN',
  'Punjabi': 'pa-IN',
  'Odia': 'od-IN',
  'Assamese': 'as-IN',
  'Bodo': 'brx-IN',
  'Dogri': 'doi-IN',
  'Konkani': 'kok-IN',
  'Kashmiri': 'ks-IN',
  'Maithili': 'mai-IN',
  'Manipuri': 'mni-IN',
  'Nepali': 'ne-IN',
  'Sanskrit': 'sa-IN',
  'Santali': 'sat-IN',
  'Sindhi': 'sd-IN',
  'Urdu': 'ur-IN',
  'Spanish': 'es-ES',
  'French': 'fr-FR',
  'German': 'de-DE',
  'Portuguese': 'pt-BR',
  'Arabic': 'ar-SA',
  'Japanese': 'ja-JP',
  'Korean': 'ko-KR',
  'Chinese': 'zh-CN',
  'Russian': 'ru-RU',
};

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
