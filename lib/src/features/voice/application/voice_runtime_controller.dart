import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/voice_runtime_api_client.dart';

final voiceRuntimeApiClientProvider = Provider<VoiceRuntimeApiClient>((ref) {
  final client = VoiceRuntimeApiClient(
    baseUrl: const String.fromEnvironment(
      'ALTER_API_GATEWAY_URL',
      defaultValue: 'http://localhost:8060',
    ),
  );
  ref.onDispose(client.close);
  return client;
});

final voiceRuntimeControllerProvider =
    NotifierProvider<VoiceRuntimeController, VoiceRuntimeState>(
      VoiceRuntimeController.new,
    );

class VoiceRuntimeController extends Notifier<VoiceRuntimeState> {
  @override
  VoiceRuntimeState build() => const VoiceRuntimeState();

  Future<void> run({
    required String transcript,
    required String locale,
  }) async {
    final trimmed = transcript.trim();
    if (trimmed.length < 3) {
      state = state.copyWith(errorMessage: 'Say or type a command for ALTER.');
      return;
    }
    state = state.copyWith(isRunning: true, errorMessage: '');
    try {
      final result = await ref
          .read(voiceRuntimeApiClientProvider)
          .run(transcript: trimmed, locale: locale);
      state = state.copyWith(isRunning: false, result: result);
    } catch (error) {
      state = state.copyWith(isRunning: false, errorMessage: error.toString());
    }
  }
}

class VoiceRuntimeState {
  const VoiceRuntimeState({
    this.isRunning = false,
    this.result,
    this.errorMessage = '',
  });

  final bool isRunning;
  final VoiceRuntimeResult? result;
  final String errorMessage;

  VoiceRuntimeState copyWith({
    bool? isRunning,
    VoiceRuntimeResult? result,
    String? errorMessage,
  }) {
    return VoiceRuntimeState(
      isRunning: isRunning ?? this.isRunning,
      result: result ?? this.result,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
