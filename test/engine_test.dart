import 'package:flutter_test/flutter_test.dart';
import 'package:roadai/models/emotion.dart';
import 'package:roadai/models/intervention.dart';
import 'package:roadai/models/session.dart';
import 'package:roadai/services/simulation_engine.dart';

void main() {
  group('Sakin Surus Puani', () {
    test('tamamen sakin surus -> yuksek puan', () {
      final score = DriveSession.computeCalmScore({
        EmotionType.neutral: 600,
        EmotionType.happy: 100,
      });
      expect(score, greaterThanOrEqualTo(90));
    });

    test('ofkeli surus -> dusuk puan', () {
      final score = DriveSession.computeCalmScore({
        EmotionType.angry: 500,
        EmotionType.stressed: 200,
        EmotionType.neutral: 50,
      });
      expect(score, lessThan(25));
    });

    test('bos veri -> 100 (ceza yok)', () {
      expect(DriveSession.computeCalmScore({}), 100);
    });

    test('puan her zaman 0..100 araliginda', () {
      for (final data in [
        {EmotionType.angry: 10000.0},
        {EmotionType.neutral: 10000.0},
        {EmotionType.tired: 5.0, EmotionType.happy: 5.0},
      ]) {
        final s = DriveSession.computeCalmScore(data);
        expect(s, inInclusiveRange(0, 100));
      }
    });
  });

  group('EmotionSample', () {
    test('primary en yuksek skoru secer', () {
      final s = EmotionSample(time: DateTime.now(), scores: {
        EmotionType.angry: 0.9,
        EmotionType.neutral: 0.3,
      });
      expect(s.primary, EmotionType.angry);
      expect(s.confidence, 0.9);
    });

    test('toMap/fromMap kayipsiz donusum', () {
      final orig = EmotionSample(
        time: DateTime.fromMillisecondsSinceEpoch(1720000000000),
        scores: {for (final t in EmotionType.values) t: 0.5},
        speedKmh: 88.4,
      );
      final restored = EmotionSample.fromMap(orig.toMap());
      expect(restored.time, orig.time);
      expect(restored.speedKmh, closeTo(88.4, 0.01));
      expect(restored.score(EmotionType.angry), closeTo(0.5, 0.01));
    });
  });

  group('DriveSession serilestirme', () {
    test('toMap/fromMap tum alanlari korur', () {
      final orig = DriveSession(
        id: 'sess_1',
        start: DateTime.fromMillisecondsSinceEpoch(1720000000000),
        end: DateTime.fromMillisecondsSinceEpoch(1720003600000),
        distanceKm: 42.5,
        maxSpeedKmh: 120,
        emotionSeconds: {EmotionType.angry: 100, EmotionType.neutral: 900},
        interventions: [
          InterventionEvent(
            type: InterventionType.calmMusic,
            time: DateTime.fromMillisecondsSinceEpoch(1720001000000),
            reason: 'test',
            message: 'mesaj',
            accepted: true,
          ),
        ],
        timeline: [],
        calmScore: 75,
        mode: 'camera',
      );
      final restored = DriveSession.fromMap(orig.toMap());
      expect(restored.id, 'sess_1');
      expect(restored.calmScore, 75);
      expect(restored.interventions.length, 1);
      expect(restored.interventions.first.accepted, true);
      expect(restored.emotionSeconds[EmotionType.angry], 100);
      expect(restored.duration, const Duration(hours: 1));
    });
  });

  group('Simulasyon motoru', () {
    test('ofke senaryosu ofke fazina ulasir', () {
      final sim = SimulationEngine(DriveScenario.trafficRage);
      var maxAnger = 0.0;
      for (var i = 0; i < 120; i++) {
        final s = sim.next();
        if (s.score(EmotionType.angry) > maxAnger) {
          maxAnger = s.score(EmotionType.angry);
        }
      }
      expect(maxAnger, greaterThan(0.6));
    });

    test('skorlar 0..1 araliginda kalir', () {
      final sim = SimulationEngine(DriveScenario.freeDrive);
      for (var i = 0; i < 200; i++) {
        final s = sim.next();
        for (final t in EmotionType.values) {
          expect(s.score(t), inInclusiveRange(0.0, 1.0));
        }
        expect(s.speedKmh, inInclusiveRange(0, 160));
      }
    });
  });
}
