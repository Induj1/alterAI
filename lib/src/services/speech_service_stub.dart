class SpeechService {
  factory SpeechService() => _instance;
  SpeechService._();
  static final _instance = SpeechService._();

  bool get isSupported => false;

  Future<String> listen({String locale = 'en-US'}) async {
    throw Exception('Speech recognition is not available on this platform.');
  }

  void stop() {}

  void speak(String text, {String locale = 'en-US', double rate = 1.0}) {}

  void stopSpeaking() {}
}
