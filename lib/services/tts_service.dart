import 'package:flutter_tts/flutter_tts.dart';

/// Turkce sesli asistan (mudahale mesajlari + nefes rehberi).
class TtsService {
  static final TtsService _instance = TtsService._();
  factory TtsService() => _instance;
  TtsService._();

  final FlutterTts _tts = FlutterTts();
  bool _ready = false;
  bool enabled = true;

  Future<void> _ensureReady() async {
    if (_ready) return;
    try {
      await _tts.setLanguage('tr-TR');
      await _tts.setSpeechRate(0.5);
      await _tts.setPitch(1.0);
      _ready = true;
    } catch (_) {}
  }

  Future<void> speak(String text) async {
    if (!enabled) return;
    try {
      await _ensureReady();
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {
      // TTS motoru yoksa sessizce devam et
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
