import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart';

// Top-level JS globals (browser window scope)
@JS('SpeechRecognition')
external JSFunction? get _speechRecognitionCtor;

@JS('webkitSpeechRecognition')
external JSFunction? get _webkitSpeechRecognitionCtor;

@JS('speechSynthesis')
external JSObject? get _speechSynthesis;

@JS('SpeechSynthesisUtterance')
external JSFunction? get _speechSynthesisUtteranceCtor;

class SpeechService {
  factory SpeechService() => _instance;
  SpeechService._();
  static final _instance = SpeechService._();

  JSObject? _recognition;

  bool get isSupported =>
      kIsWeb &&
      (_speechRecognitionCtor != null || _webkitSpeechRecognitionCtor != null);

  JSObject _newRecognition() {
    final ctor = _speechRecognitionCtor ?? _webkitSpeechRecognitionCtor;
    if (ctor == null) throw Exception('Web Speech API not supported.');
    return ctor.callAsConstructor<JSObject>();
  }

  Future<String> listen({String locale = 'en-US'}) async {
    if (!isSupported) {
      throw Exception(
        'Speech recognition requires Chrome. Please use Chrome or type your command instead.',
      );
    }
    stop();

    final completer = Completer<String>();
    final rec = _newRecognition();
    _recognition = rec;

    rec.setProperty('continuous'.toJS, false.toJS);
    rec.setProperty('interimResults'.toJS, false.toJS);
    rec.setProperty('lang'.toJS, locale.toJS);
    rec.setProperty('maxAlternatives'.toJS, 1.toJS);

    void Function(JSAny?) onResult = (JSAny? event) {
      if (completer.isCompleted) return;
      final e = event as JSObject?;
      if (e == null) return;
      final results = e.getProperty('results'.toJS) as JSObject?;
      if (results == null) return;
      final first = results.getProperty(0.toJS) as JSObject?;
      if (first == null) return;
      final isFinal =
          (first.getProperty('isFinal'.toJS) as JSBoolean?)?.toDart ?? false;
      if (!isFinal) return;
      final alt = first.getProperty(0.toJS) as JSObject?;
      if (alt == null) return;
      final transcript =
          (alt.getProperty('transcript'.toJS) as JSString?)?.toDart.trim() ??
          '';
      completer.complete(transcript);
    };

    void Function(JSAny?) onError = (JSAny? event) {
      if (completer.isCompleted) return;
      final e = event as JSObject?;
      final error =
          (e?.getProperty('error'.toJS) as JSString?)?.toDart ?? 'unknown';
      if (error == 'aborted' || error == 'no-speech') {
        completer.complete('');
      } else {
        completer.completeError(Exception('Speech recognition error: $error'));
      }
    };

    void Function(JSAny?) onEnd = (_) {
      if (!completer.isCompleted) completer.complete('');
    };

    rec.setProperty('onresult'.toJS, onResult.toJS);
    rec.setProperty('onerror'.toJS, onError.toJS);
    rec.setProperty('onend'.toJS, onEnd.toJS);

    rec.callMethod('start'.toJS);

    return completer.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        stop();
        return '';
      },
    );
  }

  void stop() {
    try {
      _recognition?.callMethod('stop'.toJS);
    } catch (_) {}
    _recognition = null;
  }

  void speak(String text, {String locale = 'en-US', double rate = 1.0}) {
    if (!kIsWeb) return;
    final syn = _speechSynthesis;
    if (syn == null) return;
    syn.callMethod('cancel'.toJS);
    final utteranceCtor = _speechSynthesisUtteranceCtor;
    if (utteranceCtor == null) return;
    final utterance = utteranceCtor.callAsConstructor<JSObject>(text.toJS);
    utterance.setProperty('lang'.toJS, locale.toJS);
    utterance.setProperty('rate'.toJS, rate.toJS);
    utterance.setProperty('pitch'.toJS, 1.0.toJS);
    utterance.setProperty('volume'.toJS, 1.0.toJS);
    syn.callMethod('speak'.toJS, utterance);
  }

  void stopSpeaking() {
    if (!kIsWeb) return;
    _speechSynthesis?.callMethod('cancel'.toJS);
  }
}
