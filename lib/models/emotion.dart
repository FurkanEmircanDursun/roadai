import 'package:flutter/material.dart';

/// Dokumandaki 7 duygu sinifi + stres (ses/multimodal fuzyondan turetilir).
enum EmotionType { angry, stressed, tired, sad, fearful, surprised, happy, neutral }

extension EmotionTypeX on EmotionType {
  String get labelTr => switch (this) {
        EmotionType.angry => 'Öfkeli',
        EmotionType.stressed => 'Stresli',
        EmotionType.tired => 'Yorgun',
        EmotionType.sad => 'Üzgün',
        EmotionType.fearful => 'Korku',
        EmotionType.surprised => 'Şaşkın',
        EmotionType.happy => 'Mutlu',
        EmotionType.neutral => 'Sakin',
      };

  String get emoji => switch (this) {
        EmotionType.angry => '😠',
        EmotionType.stressed => '😖',
        EmotionType.tired => '🥱',
        EmotionType.sad => '😢',
        EmotionType.fearful => '😨',
        EmotionType.surprised => '😮',
        EmotionType.happy => '😊',
        EmotionType.neutral => '😌',
      };

  Color get color => switch (this) {
        EmotionType.angry => const Color(0xFFFF4D5E),
        EmotionType.stressed => const Color(0xFFFF9F43),
        EmotionType.tired => const Color(0xFF8A7CFF),
        EmotionType.sad => const Color(0xFF4D8DFF),
        EmotionType.fearful => const Color(0xFFB45CFF),
        EmotionType.surprised => const Color(0xFFFFD166),
        EmotionType.happy => const Color(0xFF3DDC84),
        EmotionType.neutral => const Color(0xFF38E0C8),
      };

  /// Sakin surus puani hesabinda saniye basina katki (negatif = puan dusurur).
  double get scoreWeight => switch (this) {
        EmotionType.angry => -1.0,
        EmotionType.stressed => -0.7,
        EmotionType.tired => -0.5,
        EmotionType.sad => -0.2,
        EmotionType.fearful => -0.4,
        EmotionType.surprised => -0.1,
        EmotionType.happy => 0.9,
        EmotionType.neutral => 1.0,
      };
}

/// Tek bir analiz ani: multimodal fuzyon ciktisi + arac verisi.
class EmotionSample {
  final DateTime time;
  final Map<EmotionType, double> scores;
  final double speedKmh;
  final double voiceLevel; // 0..1 normalize mikrofon enerjisi
  final bool faceVisible;
  final bool simulated;

  EmotionSample({
    required this.time,
    required this.scores,
    this.speedKmh = 0,
    this.voiceLevel = 0,
    this.faceVisible = true,
    this.simulated = false,
  });

  EmotionType get primary {
    var best = EmotionType.neutral;
    var bestV = -1.0;
    for (final e in scores.entries) {
      if (e.value > bestV) {
        bestV = e.value;
        best = e.key;
      }
    }
    return best;
  }

  double get confidence => (scores[primary] ?? 0).clamp(0.0, 1.0);

  double score(EmotionType t) => scores[t] ?? 0;

  Map<String, dynamic> toMap() => {
        't': time.millisecondsSinceEpoch,
        's': scores.map((k, v) => MapEntry(k.name, double.parse(v.toStringAsFixed(3)))),
        'v': double.parse(speedKmh.toStringAsFixed(1)),
        'f': faceVisible,
      };

  static EmotionSample fromMap(Map<dynamic, dynamic> m) {
    final raw = Map<dynamic, dynamic>.from(m['s'] as Map);
    final scores = <EmotionType, double>{};
    for (final t in EmotionType.values) {
      scores[t] = (raw[t.name] as num?)?.toDouble() ?? 0;
    }
    return EmotionSample(
      time: DateTime.fromMillisecondsSinceEpoch(m['t'] as int),
      scores: scores,
      speedKmh: (m['v'] as num?)?.toDouble() ?? 0,
      faceVisible: m['f'] as bool? ?? true,
    );
  }
}
