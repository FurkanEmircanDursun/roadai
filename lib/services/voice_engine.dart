import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:record/record.dart';

/// Ses tabanli duygu analizi girdisi: mikrofon enerjisi (RMS) 0..1.
/// Yuksek ve dalgali ses seviyesi = ofke/stres gostergesi (dokuman 5.2).
class VoiceEngine {
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _sub;
  double _level = 0; // 0..1 normalize
  double _peak = 1200; // adaptif tepe (16-bit PCM genligi)
  bool _running = false;

  double get level => _level;
  bool get running => _running;

  Future<bool> start() async {
    try {
      if (!await _recorder.hasPermission()) return false;
      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
      );
      _sub = stream.listen(_onChunk);
      _running = true;
      return true;
    } catch (_) {
      _running = false;
      return false;
    }
  }

  void _onChunk(Uint8List chunk) {
    if (chunk.length < 4) return;
    final data = ByteData.sublistView(chunk);
    var sum = 0.0;
    final samples = chunk.length ~/ 2;
    for (var i = 0; i < samples; i++) {
      final v = data.getInt16(i * 2, Endian.little).toDouble();
      sum += v * v;
    }
    final rms = sqrt(sum / samples);
    _peak = max(_peak * 0.999, rms); // adaptif normalizasyon
    final norm = (rms / _peak).clamp(0.0, 1.0);
    // Yumusatma
    _level = _level * 0.7 + norm * 0.3;
  }

  Future<void> stop() async {
    _running = false;
    await _sub?.cancel();
    _sub = null;
    try {
      await _recorder.stop();
    } catch (_) {}
    _level = 0;
  }

  void dispose() {
    stop();
    _recorder.dispose();
  }
}
