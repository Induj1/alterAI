import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'package:alter/src/features/voice/application/native_wake_service_controller.dart';
import 'package:alter/src/features/voice/application/voice_runtime_controller.dart';
import 'package:alter/src/features/voice/domain/wake_word.dart';
import 'package:alter/src/ui/routes.dart';
import 'package:alter/src/ui/theme.dart';
import 'package:alter/src/ui/widgets.dart';
import 'package:alter/src/ui/screens/main_shell.dart';

enum VoiceMode { idle, listening, speaking }

class VoiceScreen extends ConsumerStatefulWidget {
  const VoiceScreen({super.key});

  @override
  ConsumerState<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends ConsumerState<VoiceScreen>
    with TickerProviderStateMixin {
  VoiceMode _mode = VoiceMode.idle;
  String _userText = '';
  String _assistantText = '';
  String _status = 'Tap to speak, or say "Hey Alter"';
  bool _assistantMode = false;
  bool _wakeProcessing = false;
  bool _sttReady = false;

  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  late final AnimationController _breathe = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  )..repeat(reverse: true);
  late final AnimationController _ring = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  static const _locale = 'en-US';

  @override
  void dispose() {
    _breathe.dispose();
    _ring.dispose();
    _wave.dispose();
    _speech.cancel();
    _tts.stop();
    super.dispose();
  }

  Future<bool> _ensureSpeechReady() async {
    if (_sttReady) return true;
    _sttReady = await _speech.initialize(
      onError: (_) {
        if (_assistantMode && mounted) _rearmWakeLoop();
      },
      onStatus: _onSpeechStatus,
    );
    return _sttReady;
  }

  Future<void> _speak(String text) async {
    if (text.trim().isEmpty) return;
    setState(() => _mode = VoiceMode.speaking);
    try {
      await _tts.stop();
      await _tts.setLanguage(_locale);
      await _tts.setSpeechRate(0.52);
      await _tts.speak(text);
    } catch (_) {}
    if (mounted && !_assistantMode) {
      setState(() => _mode = VoiceMode.idle);
    }
  }

  Future<void> _runVoiceRuntime(String transcript) async {
    final cleaned = transcript.trim();
    if (cleaned.isEmpty) return;
    setState(() {
      _userText = cleaned;
      _mode = VoiceMode.speaking;
      _status = 'Alter is responding';
    });
    await ref
        .read(voiceRuntimeControllerProvider.notifier)
        .run(transcript: cleaned, locale: _locale);
  }

  Future<void> _startOneShotListening() async {
    if (!await _ensureSpeechReady()) {
      setState(() => _status = 'Speech unavailable — type in Agent instead.');
      return;
    }
    _assistantMode = false;
    _wakeProcessing = false;
    await _speech.stop();
    setState(() {
      _mode = VoiceMode.listening;
      _status = 'Listening…';
    });
    await _speech.listen(
      listenOptions: SpeechListenOptions(
        localeId: _locale,
        listenFor: const Duration(seconds: 18),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        listenMode: ListenMode.search,
        cancelOnError: false,
      ),
      onResult: (result) {
        if (!mounted) return;
        if (result.recognizedWords.isNotEmpty) {
          setState(() => _userText = result.recognizedWords);
        }
        if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
          _speech.stop();
          unawaited(_runVoiceRuntime(result.recognizedWords));
        }
      },
    );
  }

  Future<void> _toggleAssistantMode() async {
    if (_assistantMode) {
      _assistantMode = false;
      await _speech.stop();
      setState(() {
        _mode = VoiceMode.idle;
        _status = 'Tap to speak, or say "Hey Alter"';
      });
      return;
    }
    if (!await _ensureSpeechReady()) return;
    _assistantMode = true;
    setState(() {
      _status = 'Listening for "Hey Alter"';
      _mode = VoiceMode.listening;
    });
    unawaited(_speak('Hey Alter is ready.'));
    unawaited(_startWakeLoop());
  }

  Future<void> _startWakeLoop() async {
    if (!_assistantMode || _wakeProcessing || !mounted) return;
    if (_speech.isListening) await _speech.stop();
    setState(() {
      _mode = VoiceMode.listening;
      _status = 'Listening for "Hey Alter"';
    });
    await _speech.listen(
      listenOptions: SpeechListenOptions(
        localeId: _locale,
        listenFor: const Duration(seconds: 25),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        listenMode: ListenMode.search,
        cancelOnError: false,
      ),
      onResult: _onWakeResult,
    );
  }

  void _onWakeResult(SpeechRecognitionResult result) {
    if (!mounted || !_assistantMode || _wakeProcessing) return;
    final wake = WakeWord.parse(result.recognizedWords);
    if (!wake.detected) return;
    _wakeProcessing = true;
    unawaited(_speech.stop());
    unawaited(_processWakeMatch(wake));
  }

  Future<void> _processWakeMatch(WakeWordMatch wake) async {
    if (!mounted) return;
    if (!wake.hasCommand) {
      await _speak('I am listening.');
      _wakeProcessing = false;
      _rearmWakeLoop();
      return;
    }
    await _runVoiceRuntime(wake.runtimeTranscript);
    _wakeProcessing = false;
    _rearmWakeLoop();
  }

  void _onSpeechStatus(String status) {
    if (!mounted) return;
    if ((status == 'done' || status == 'notListening') &&
        _assistantMode &&
        !_wakeProcessing) {
      _rearmWakeLoop();
    }
  }

  void _rearmWakeLoop() {
    if (!_assistantMode || !mounted) return;
    Future<void>.delayed(const Duration(milliseconds: 450), () {
      if (mounted && _assistantMode && !_wakeProcessing) {
        unawaited(_startWakeLoop());
      }
    });
  }

  Future<void> _handleNativeWakeEvent(
    String phrase, {
    required bool onDevice,
  }) async {
    if (!mounted) return;
    final heard = phrase.trim().isEmpty ? 'Hey Alter' : phrase.trim();
    final wake = WakeWord.parse(heard);
    _assistantMode = false;
    _wakeProcessing = false;
    await _speech.cancel();

    if (wake.detected && wake.hasCommand) {
      _wakeProcessing = true;
      await _processWakeMatch(wake);
      return;
    }

    setState(() {
      _status = onDevice
          ? 'Native wake heard. Listening…'
          : 'Wake heard. Listening…';
      _userText = heard;
    });
    await _speak('I am listening.');
    if (mounted) await _startOneShotListening();
  }

  void _onOrbTap() {
    final runtime = ref.read(voiceRuntimeControllerProvider);
    if (runtime.isRunning) return;
    if (_assistantMode) {
      unawaited(_toggleAssistantMode());
      return;
    }
    unawaited(_startOneShotListening());
  }

  @override
  Widget build(BuildContext context) {
    final shell = MainShell.of(context);
    final runtime = ref.watch(voiceRuntimeControllerProvider);
    final nativeWake = ref.watch(nativeWakeServiceControllerProvider);

    ref.listen(voiceRuntimeControllerProvider, (prev, next) {
      if (prev?.isRunning == true && !next.isRunning) {
        final spoken = next.result?.spokenResponse ?? '';
        final display = next.result?.displayResponse ?? spoken;
        if (mounted) {
          setState(() {
            _assistantText = display.isNotEmpty
                ? display
                : (next.errorMessage.isNotEmpty ? next.errorMessage : 'Done.');
            _mode = VoiceMode.speaking;
          });
        }
        if (spoken.isNotEmpty)
          unawaited(_speak(spoken));
        else if (mounted)
          setState(() => _mode = VoiceMode.idle);
      }
    });

    ref.listen(nativeWakeServiceControllerProvider, (prev, next) {
      if ((prev?.wakeCount ?? 0) >= next.wakeCount) return;
      final event = next.lastEvent;
      if (event == null) return;
      unawaited(_handleNativeWakeEvent(event.phrase, onDevice: event.onDevice));
    });

    final mode = runtime.isRunning
        ? VoiceMode.speaking
        : (_mode == VoiceMode.listening || nativeWake.running
              ? VoiceMode.listening
              : _mode);

    final label = runtime.isRunning
        ? 'Alter is responding'
        : nativeWake.running
        ? 'Hey Alter wake service active'
        : _status;

    final voiceBg = AlterUiTheme.light
        ? const [Color(0xFFECE8F6), Color(0xFFF4F1FB), Color(0xFFEEF0F8)]
        : const [Color(0xFF1A1430), Color(0xFF0D0A16), Color(0xFF060409)];

    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0.0, -0.2),
          radius: 1.3,
          colors: voiceBg,
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GearButton(onTap: shell.openSettings),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const StarMark(size: 15),
                      const SizedBox(width: 7),
                      Text(
                        'ALTER',
                        style: AppText.display(
                          12,
                          weight: FontWeight.w600,
                          letterSpacing: 2.5,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => context.push(AlterRoutes.lens),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.lime.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.lime.withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Icon(
                        Icons.camera_alt_outlined,
                        size: 20,
                        color: AppColors.lime,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: const Alignment(0, -0.25),
              child: SizedBox(
                width: 240,
                height: 240,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (mode == VoiceMode.listening) ..._rings(),
                    _orb(mode),
                  ],
                ),
              ),
            ),
            Align(
              alignment: const Alignment(0, 0.18),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: AppText.display(
                  19,
                  weight: FontWeight.w500,
                  color: AppColors.white(0.85),
                ),
              ),
            ),
            Align(
              alignment: const Alignment(0, 0.62),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_userText.isNotEmpty) _bubble(_userText, true, null),
                    if (_userText.isNotEmpty && _assistantText.isNotEmpty)
                      const SizedBox(height: 12),
                    if (_assistantText.isNotEmpty)
                      _bubble(
                        _assistantText,
                        false,
                        LinearGradient(
                          colors: [
                            AppColors.lime.withValues(alpha: 0.16),
                            AppColors.purple.withValues(alpha: 0.14),
                          ],
                        ),
                      ),
                    if (_userText.isEmpty && _assistantText.isEmpty)
                      _bubble(
                        'Hey Alter, should I learn AI or Cybersecurity?',
                        true,
                        null,
                      ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: const Alignment(0, 0.96),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 96),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => context.push(AlterRoutes.deepAnalysis),
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        decoration: BoxDecoration(
                          color: AppColors.white(0.06),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: AppColors.white(0.16)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Deep analysis',
                              style: AppText.body(14, weight: FontWeight.w600),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward,
                              size: 16,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onLongPress: () => unawaited(_toggleAssistantMode()),
                      onTap: nativeWake.supported
                          ? () => ref
                                .read(
                                  nativeWakeServiceControllerProvider.notifier,
                                )
                                .toggle()
                          : null,
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: nativeWake.running
                              ? AppColors.lime.withValues(alpha: 0.2)
                              : AppColors.white(0.06),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: nativeWake.running
                                ? AppColors.lime
                                : AppColors.white(0.16),
                          ),
                        ),
                        child: Icon(
                          nativeWake.running
                              ? Icons.hearing
                              : Icons.hearing_disabled,
                          size: 20,
                          color: nativeWake.running
                              ? AppColors.lime
                              : AppColors.white(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _rings() {
    return List.generate(3, (i) {
      return AnimatedBuilder(
        animation: _ring,
        builder: (_, __) {
          final t = ((_ring.value + i / 3) % 1.0);
          return Container(
            width: 170 + t * 150,
            height: 170 + t * 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.lime.withValues(alpha: (1 - t) * 0.5),
                width: 2,
              ),
            ),
          );
        },
      );
    });
  }

  Widget _orb(VoiceMode mode) {
    return GestureDetector(
      onTap: _onOrbTap,
      onLongPress: () => unawaited(_toggleAssistantMode()),
      child: AnimatedBuilder(
        animation: _breathe,
        builder: (_, child) {
          final s = 1 + _breathe.value * 0.06;
          return Transform.scale(scale: s, child: child);
        },
        child: Container(
          width: 170,
          height: 170,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              center: Alignment(-0.25, -0.3),
              colors: [AppColors.lime, AppColors.purple, AppColors.purpleDeep],
              stops: [0.0, 0.55, 0.8],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.purple.withValues(alpha: 0.6),
                blurRadius: 70,
                spreadRadius: 4,
              ),
            ],
          ),
          child: _orbContent(mode),
        ),
      ),
    );
  }

  Widget _orbContent(VoiceMode mode) {
    switch (mode) {
      case VoiceMode.speaking:
        return SizedBox(
          height: 60,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(14, (i) {
              return AnimatedBuilder(
                animation: _wave,
                builder: (_, __) {
                  final phase = (i % 4) / 4;
                  final v =
                      (0.3 +
                      0.7 *
                          (0.5 +
                              0.5 *
                                  (1 -
                                      2 *
                                          ((_wave.value + phase) % 1.0 - 0.5)
                                              .abs())));
                  return Container(
                    width: 5,
                    height: 38 * v,
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    decoration: BoxDecoration(
                      color: AppColors.lime,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                },
              );
            }),
          ),
        );
      case VoiceMode.listening:
        return const Icon(Icons.mic, size: 40, color: AppColors.bg);
      case VoiceMode.idle:
        return const StarMark(size: 42, color: AppColors.bg);
    }
  }

  Widget _bubble(String text, bool me, Gradient? grad) {
    return Align(
      alignment: me ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * (me ? 0.78 : 0.82),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: me ? AppColors.white(0.1) : null,
          gradient: grad,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(me ? 20 : 6),
            bottomRight: Radius.circular(me ? 6 : 20),
          ),
          border: Border.all(
            color: me
                ? AppColors.white(0.14)
                : AppColors.lime.withValues(alpha: 0.25),
          ),
        ),
        child: Text(text, style: AppText.body(14, height: 1.5)),
      ),
    );
  }
}
