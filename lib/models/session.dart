import 'emotion.dart';
import 'intervention.dart';

/// Tamamlanmis bir surus oturumu (Hive'da saklanir).
class DriveSession {
  final String id;
  final DateTime start;
  final DateTime end;
  final double distanceKm;
  final double maxSpeedKmh;
  final Map<EmotionType, double> emotionSeconds; // duygu basina gecen sure
  final List<InterventionEvent> interventions;
  final List<EmotionSample> timeline; // seyrek ornekler (grafik icin)
  final int calmScore; // 0..100
  final String mode; // 'camera' | senaryo adi

  DriveSession({
    required this.id,
    required this.start,
    required this.end,
    required this.distanceKm,
    required this.maxSpeedKmh,
    required this.emotionSeconds,
    required this.interventions,
    required this.timeline,
    required this.calmScore,
    required this.mode,
  });

  Duration get duration => end.difference(start);

  double get totalEmotionSeconds =>
      emotionSeconds.values.fold(0.0, (a, b) => a + b).clamp(1.0, double.infinity);

  double share(EmotionType t) => (emotionSeconds[t] ?? 0) / totalEmotionSeconds;

  int get acceptedInterventions =>
      interventions.where((i) => i.accepted == true).length;

  Map<String, dynamic> toMap() => {
        'id': id,
        'start': start.millisecondsSinceEpoch,
        'end': end.millisecondsSinceEpoch,
        'km': distanceKm,
        'maxSpeed': maxSpeedKmh,
        'emotions': emotionSeconds
            .map((k, v) => MapEntry(k.name, double.parse(v.toStringAsFixed(1)))),
        'interventions': interventions.map((i) => i.toMap()).toList(),
        'timeline': timeline.map((s) => s.toMap()).toList(),
        'score': calmScore,
        'mode': mode,
      };

  static DriveSession fromMap(Map<dynamic, dynamic> m) {
    final rawE = Map<dynamic, dynamic>.from(m['emotions'] as Map? ?? {});
    final emotions = <EmotionType, double>{};
    for (final t in EmotionType.values) {
      emotions[t] = (rawE[t.name] as num?)?.toDouble() ?? 0;
    }
    return DriveSession(
      id: m['id'] as String,
      start: DateTime.fromMillisecondsSinceEpoch(m['start'] as int),
      end: DateTime.fromMillisecondsSinceEpoch(m['end'] as int),
      distanceKm: (m['km'] as num?)?.toDouble() ?? 0,
      maxSpeedKmh: (m['maxSpeed'] as num?)?.toDouble() ?? 0,
      emotionSeconds: emotions,
      interventions: (m['interventions'] as List? ?? [])
          .map((e) => InterventionEvent.fromMap(Map<dynamic, dynamic>.from(e as Map)))
          .toList(),
      timeline: (m['timeline'] as List? ?? [])
          .map((e) => EmotionSample.fromMap(Map<dynamic, dynamic>.from(e as Map)))
          .toList(),
      calmScore: (m['score'] as num?)?.toInt() ?? 0,
      mode: m['mode'] as String? ?? 'demo',
    );
  }

  /// Sakin surus puani: duygu surelerinin agirlikli ortalamasi -> 0..100
  static int computeCalmScore(Map<EmotionType, double> emotionSeconds) {
    final total = emotionSeconds.values.fold(0.0, (a, b) => a + b);
    if (total <= 0) return 100;
    var weighted = 0.0;
    for (final e in emotionSeconds.entries) {
      weighted += e.value * e.key.scoreWeight;
    }
    // -1..1 arasi normalize edilir, 0..100'e tasinir
    final norm = (weighted / total + 1) / 2;
    return (norm * 100).round().clamp(0, 100);
  }
}
