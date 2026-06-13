import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/gemma_edge_engine.dart';
import '../data/local_gemma_engine.dart';

/// Lifecycle of the on-device Gemma model.
enum GemmaStatus {
  checking,
  notInstalled,
  downloading,
  loading,
  ready,
  unsupported, // web / platform without on-device inference
  error,
}

class GemmaModelState {
  const GemmaModelState({
    this.status = GemmaStatus.checking,
    this.progress = 0,
    this.message = '',
  });

  final GemmaStatus status;
  final double progress; // 0..1 while downloading
  final String message;

  bool get isReady => status == GemmaStatus.ready;

  GemmaModelState copyWith({
    GemmaStatus? status,
    double? progress,
    String? message,
  }) => GemmaModelState(
    status: status ?? this.status,
    progress: progress ?? this.progress,
    message: message ?? this.message,
  );
}

/// A small, phone-friendly default. Editable in the install screen — point it
/// at Gemma 3n E4B (the brief's target) or any LiteRT `.task` model.
const kDefaultGemmaUrl =
    'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/Gemma3-1B-IT_multi-prefill-seq_q8_ekv1280.task';

final gemmaModelProvider = NotifierProvider<GemmaModelManager, GemmaModelState>(
  GemmaModelManager.new,
);

class GemmaModelManager extends Notifier<GemmaModelState> {
  InferenceModel? _model;
  InferenceModel? get model => _model;

  @override
  GemmaModelState build() {
    if (kIsWeb) {
      return const GemmaModelState(
        status: GemmaStatus.unsupported,
        message: 'On-device Gemma runs on the phone build, not web.',
      );
    }
    // Kick off an install check without blocking provider creation.
    Future.microtask(checkInstalled);
    return const GemmaModelState(status: GemmaStatus.checking);
  }

  Future<void> checkInstalled() async {
    if (kIsWeb) return;
    try {
      final installed = await FlutterGemma.listInstalledModels();
      if (installed.isEmpty) {
        state = const GemmaModelState(status: GemmaStatus.notInstalled);
        return;
      }
      await _load();
    } catch (e) {
      state = GemmaModelState(
        status: GemmaStatus.notInstalled,
        message: e.toString(),
      );
    }
  }

  Future<void> download({String? url, String? hfToken}) async {
    if (kIsWeb) return;
    state = const GemmaModelState(status: GemmaStatus.downloading, progress: 0);
    try {
      await FlutterGemma.installModel(
            modelType: ModelType.gemmaIt,
            fileType: ModelFileType.task,
          )
          .fromNetwork(
            url ?? kDefaultGemmaUrl,
            token: (hfToken ?? '').isEmpty ? null : hfToken,
          )
          .withProgress((p) {
            final frac = (p is num ? p.toDouble() : 0) / 100.0;
            state = state.copyWith(
              status: GemmaStatus.downloading,
              progress: frac.clamp(0, 1),
            );
          })
          .install();
      await _load();
    } catch (e) {
      state = GemmaModelState(
        status: GemmaStatus.error,
        message: 'Download failed: ${e.toString()}',
      );
    }
  }

  Future<void> _load() async {
    state = const GemmaModelState(status: GemmaStatus.loading);
    try {
      _model = await FlutterGemma.getActiveModel(maxTokens: 1024);
      state = const GemmaModelState(
        status: GemmaStatus.ready,
        message: 'Gemma is running on-device.',
      );
      ref.invalidate(localGemmaEngineProvider);
    } catch (e) {
      _model = null;
      state = GemmaModelState(
        status: GemmaStatus.error,
        message: 'Load failed: ${e.toString()}',
      );
    }
  }

  Future<void> remove() async {
    try {
      await _model?.close();
      final installed = await FlutterGemma.listInstalledModels();
      for (final id in installed) {
        await FlutterGemma.uninstallModel(id);
      }
    } catch (_) {}
    _model = null;
    state = const GemmaModelState(status: GemmaStatus.notInstalled);
    ref.invalidate(localGemmaEngineProvider);
  }
}

/// The edge engine the whole pipeline uses: real Gemma when the model is loaded,
/// deterministic heuristics otherwise. Swapping is invisible to callers.
final localGemmaEngineProvider = Provider<LocalGemmaEngine>((ref) {
  final gemma = ref.watch(gemmaModelProvider);
  final manager = ref.read(gemmaModelProvider.notifier);
  if (gemma.isReady && manager.model != null) {
    return GemmaEdgeEngine(manager.model!);
  }
  return const HeuristicGemmaEngine();
});

/// True when the real on-device model is driving the edge pass (for honest UI).
final edgeIsRealGemmaProvider = Provider<bool>(
  (ref) => ref.watch(gemmaModelProvider).isReady,
);
