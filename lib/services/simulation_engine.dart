import 'dart:math';

import '../models/emotion.dart';

/// Demo modu: dokumandaki gercek zamanli senaryolari (Bolum 9) canlandirir.
/// Kamera/mikrofon olmadan da urunun tam deneyimini gosterir.
class DriveScenario {
  final String id;
  final String title;
  final String subtitle;
  final String emoji;

  /// (saniye araligi, hedef duygu yogunluklari, hedef hiz)
  final List<ScenarioPhase> phases;

  const DriveScenario({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.phases,
  });

  static const trafficRage = DriveScenario(
    id: 'traffic_rage',
    title: 'Yoğun Trafikte Öfke',
    subtitle: 'Sıkışık trafik, korna, ani frenler — öfke patlaması senaryosu',
    emoji: '🚗💢',
    phases: [
      ScenarioPhase(30, {EmotionType.neutral: .8}, 45),
      ScenarioPhase(25, {EmotionType.stressed: .55, EmotionType.neutral: .4}, 20),
      ScenarioPhase(35, {EmotionType.angry: .88, EmotionType.stressed: .6}, 15),
      ScenarioPhase(25, {EmotionType.angry: .6, EmotionType.stressed: .5}, 40),
      ScenarioPhase(40, {EmotionType.neutral: .7, EmotionType.happy: .3}, 60),
    ],
  );

  static const longTripFatigue = DriveScenario(
    id: 'fatigue',
    title: 'Uzun Yolda Yorgunluk',
    subtitle: 'Saatler süren otoyol sürüşü — göz kapanması ve dalgınlık',
    emoji: '🛣️🥱',
    phases: [
      ScenarioPhase(30, {EmotionType.neutral: .8}, 110),
      ScenarioPhase(30, {EmotionType.tired: .45, EmotionType.neutral: .5}, 105),
      ScenarioPhase(35, {EmotionType.tired: .78, EmotionType.neutral: .3}, 95),
      ScenarioPhase(30, {EmotionType.tired: .55}, 90),
      ScenarioPhase(30, {EmotionType.neutral: .7, EmotionType.happy: .35}, 100),
    ],
  );

  static const stressfulMeeting = DriveScenario(
    id: 'stress',
    title: 'Stresli Toplantı Sonrası',
    subtitle: 'İş stresi ile direksiyona geçiş — gergin başlayan yolculuk',
    emoji: '💼😖',
    phases: [
      ScenarioPhase(25, {EmotionType.stressed: .82, EmotionType.sad: .3}, 30),
      ScenarioPhase(30, {EmotionType.stressed: .65, EmotionType.neutral: .35}, 50),
      ScenarioPhase(30, {EmotionType.stressed: .45, EmotionType.neutral: .55}, 70),
      ScenarioPhase(35, {EmotionType.neutral: .75, EmotionType.happy: .4}, 80),
    ],
  );

  static const freeDrive = DriveScenario(
    id: 'free',
    title: 'Serbest Demo Sürüşü',
    subtitle: 'Rastgele duygu dalgalanmalı keşif modu',
    emoji: '🎲🚙',
    phases: [],
  );

  static const all = [trafficRage, longTripFatigue, stressfulMeeting, freeDrive];
}

class ScenarioPhase {
  final int seconds;
  final Map<EmotionType, double> targets;
  final double speedKmh;
  const ScenarioPhase(this.seconds, this.targets, this.speedKmh);
}

/// Senaryoyu saniye saniye yumusak gecisli duygu orneklerine cevirir.
class SimulationEngine {
  final DriveScenario scenario;
  final _rnd = Random();
  int _tick = 0;
  Map<EmotionType, double> _current = {
    for (final t in EmotionType.values) t: t == EmotionType.neutral ? 0.7 : 0.05,
  };
  double _speed = 40;

  SimulationEngine(this.scenario);

  ScenarioPhase? _phaseAt(int tick) {
    if (scenario.phases.isEmpty) return null;
    var acc = 0;
    for (final p in scenario.phases) {
      acc += p.seconds;
      if (tick < acc) return p;
    }
    // Senaryo bitti: son faz etrafinda sakin devam
    return scenario.phases.last;
  }

  EmotionSample next() {
    _tick++;
    final phase = _phaseAt(_tick);

    final targets = <EmotionType, double>{
      for (final t in EmotionType.values) t: 0.04,
    };
    double targetSpeed;

    if (phase != null) {
      phase.targets.forEach((k, v) => targets[k] = v);
      targetSpeed = phase.speedKmh;
    } else {
      // Serbest mod: yavas rastgele dalgalanma
      targets.addAll(_current);
      if (_tick % 15 == 0) {
        final t = EmotionType.values[_rnd.nextInt(EmotionType.values.length)];
        targets[t] = 0.3 + _rnd.nextDouble() * 0.6;
      }
      targets[EmotionType.neutral] =
          (targets[EmotionType.neutral] ?? 0.4).clamp(0.25, 0.9);
      targetSpeed = 30 + _rnd.nextDouble() * 80;
    }

    // Yumusak gecis (EMA) + kucuk gurultu
    final nextScores = <EmotionType, double>{};
    targets.forEach((t, target) {
      final cur = _current[t] ?? 0;
      final noise = (_rnd.nextDouble() - 0.5) * 0.06;
      nextScores[t] = (cur + (target - cur) * 0.12 + noise).clamp(0.0, 1.0);
    });
    _current = nextScores;
    _speed += (targetSpeed - _speed) * 0.15 + (_rnd.nextDouble() - 0.5) * 3;
    _speed = _speed.clamp(0, 160);

    return EmotionSample(
      time: DateTime.now(),
      scores: Map.of(_current),
      speedKmh: _speed,
      voiceLevel:
          ((_current[EmotionType.angry] ?? 0) * 0.7 + _rnd.nextDouble() * 0.2)
              .clamp(0.0, 1.0),
      simulated: true,
    );
  }
}
