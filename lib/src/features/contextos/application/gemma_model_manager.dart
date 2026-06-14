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

/// A downloadable on-device model option (LiteRT `.task`, MediaPipe).
class GemmaPreset {
  const GemmaPreset({
    required this.name,
    required this.url,
    required this.size,
    required this.note,
    this.gated = false,
  });

  final String name;
  final String url;
  final String size; // human-readable download size
  final String note;
  final bool gated; // needs a HuggingFace token + license acceptance
}

/// Curated on-device models, best-first. The default is **Gemma 3n E4B** — the
/// 4B-class on-device model (runs comfortably on a flagship like the iQOO).
/// The 1B option is ungated and tiny, useful to prove the pipeline end-to-end.
const kGemmaPresets = <GemmaPreset>[
  GemmaPreset(
    name: 'Gemma 3n E4B · 4B-class',
    url:
        'https://huggingface.co/google/gemma-3n-E4B-it-litert-preview/resolve/main/gemma-3n-E4B-it-int4.task',
    size: '~4.4 GB',
    note: 'Best on-device quality. Needs a HuggingFace token + license accept. '
        'Flagship-class RAM.',
    gated: true,
  ),
  GemmaPreset(
    name: 'Gemma 3n E2B · 2B-class',
    url:
        'https://huggingface.co/google/gemma-3n-E2B-it-litert-preview/resolve/main/gemma-3n-E2B-it-int4.task',
    size: '~3.1 GB',
    note: 'Balanced quality/size. Needs a HuggingFace token.',
    gated: true,
  ),
  GemmaPreset(
    name: 'Gemma 3 1B · fast',
    url:
        'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/Gemma3-1B-IT_multi-prefill-seq_q8_ekv1280.task',
    size: '~0.5 GB',
    note: 'Smallest, ungated. Good to verify on-device inference works.',
  ),
];

/// Default target: Gemma 3n E4B (4B-class). Editable in the install screen.
const kDefaultGemmaUrl =
    'https://huggingface.co/google/gemma-3n-E4B-it-litert-preview/resolve/main/gemma-3n-E4B-it-int4.task';

final gemmaModelProvider = NotifierProvider<GemmaModelManager, GemmaModelState>(
  GemmaModelManager.new,
);

class GemmaModelManager extends Notifier<GemmaModelState> {
  InferenceModel? _model;
  InferenceModel? get model => _model;

  // Serializes inference: flutter_gemma runs one session at a time per model,
  // so every generate() call queues behind the previous one.
  Future<void> _lock = Future<void>.value();

  /// Run a single prompt through the loaded on-device model and return the
  /// trimmed text. Returns null if the model isn't ready or inference fails —
  /// callers fall back to their deterministic path, so nothing ever blocks on
  /// the model. Calls are serialized.
  Future<String?> generate(
    String prompt, {
    double temperature = 0.4,
    int topK = 40,
  }) {
    final model = _model;
    if (!state.isReady || model == null) return Future.value(null);
    final run = _lock.then((_) async {
      try {
        final session = await model.createSession(
          temperature: temperature,
          topK: topK,
        );
        await session.addQueryChunk(Message.text(text: prompt, isUser: true));
        final out = await session.getResponse();
        await session.close();
        final trimmed = out.trim();
        return trimmed.isEmpty ? null : trimmed;
      } catch (_) {
        return null;
      }
    });
    // Keep the chain alive regardless of this call's success.
    _lock = run.then((_) {}, onError: (_) {});
    return run;
  }

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
            final frac = p.toDouble() / 100.0;
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
