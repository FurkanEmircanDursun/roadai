import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/emotion.dart';
import '../models/intervention.dart';
import '../models/session.dart';
import '../services/decision_engine.dart';
import '../services/face_engine.dart';
import '../services/simulation_engine.dart';
import '../services/speed_service.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../services/voice_engine.dart';
import 'music_controller.dart';
import 'settings_controller.dart';

enum DriveState { idle, starting, running }

enum DriveMode { camera, scenario }

/// Surus oturumunun beyni: veri toplama -> multimodal fuzyon -> KDS -> mudahale.
class DriveController extends ChangeNotifier {
  final SettingsController settings;
  final MusicController music;

  DriveController(this.settings, this.music);

  final FaceEngine face = FaceEngine();
  final VoiceEngine _voice = VoiceEngine();
  final SpeedService _speed = SpeedService();
  final DecisionEngine _kds = DecisionEngine();
  final TtsService _tts = TtsService();

  DriveState state = DriveState.idle;
  DriveMode mode = DriveMode.scenario;
  DriveScenario scenario = DriveScenario.freeDrive;
  SimulationEngine? _sim;

  DateTime? _startTime;
  Timer? _ticker;

  EmotionSample? current;
  final List<EmotionSample> history = []; // canli grafik (son ~3 dk)
  final List<EmotionSample> _timeline = []; // seyreltilmis kayit
  final Map<EmotionType, double> _emotionSeconds = {
    for (final t in EmotionType.values) t: 0.0,
  };
  final List<InterventionEvent> _interventions = [];
  double _distanceKm = 0;
  double _maxSpeed = 0;
  int _tick = 0;

  // Gercek mod fuzyon durumu
  double _eyesOpenEma = 1.0;
  double _smileEma = 0.0;
  double _arousalEma = 0.0; // ses enerjisi
  final Map<EmotionType, double> _realScores = {
    for (final t in EmotionType.values) t: t == EmotionType.neutral ? 0.7 : 0.05,
  };

  InterventionEvent? activeIntervention;
  bool cameraActive = false;
  bool micActive = false;
  bool gpsActive = false;

  Duration get sessionDuration =>
      _startTime == null ? Duration.zero : DateTime.now().difference(_startTime!);

  double get liveCalmScore =>
      DriveSession.computeCalmScore(_emotionSeconds).toDouble();

  int get interventionCount => _interventions.length;

  DriveSession? lastSession;

  Future<void> start({required DriveMode driveMode, DriveScenario? scn}) async {
    if (state != DriveState.idle) return;
    state = DriveState.starting;
    mode = driveMode;
    scenario = scn ?? DriveScenario.freeDrive;
    notifyListeners();

    _resetSession();
    _kds
      ..resetSession()
      ..enabledTypes = settings.enabledInterventions
      ..sensitivity = settings.sensitivity;

    if (mode == DriveMode.camera) {
      cameraActive = await face.start();
      micActive = await _voice.start();
      gpsActive = await _speed.start();
      // Kamera yoksa demo motoruna dus — surus deneyimi hic bosa dusmesin
      if (!cameraActive) {
        _sim = SimulationEngine(DriveScenario.freeDrive);
      }
    } else {
      _sim = SimulationEngine(scenario);
    }

    try {
      await WakelockPlus.enable();
    } catch (_) {}

    _startTime = DateTime.now();
    state = DriveState.running;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
    notifyListeners();
  }

  void _resetSession() {
    history.clear();
    _timeline.clear();
    _interventions.clear();
    _emotionSeconds.updateAll((_, _) => 0);
    _distanceKm = 0;
    _maxSpeed = 0;
    _tick = 0;
    _eyesOpenEma = 1.0;
    _smileEma = 0.0;
    _arousalEma = 0.0;
    activeIntervention = null;
    current = null;
  }

  void _onTick() {
    _tick++;
    final sample = (mode == DriveMode.camera && cameraActive)
        ? _fuseRealSample()
        : _sim!.next();

    current = sample;
    history.add(sample);
    if (history.length > 180) history.removeAt(0);
    if (_tick % 5 == 0) {
      _timeline.add(sample);
      if (_timeline.length > 720) _timeline.removeAt(0);
    }

    _emotionSeconds[sample.primary] =
        (_emotionSeconds[sample.primary] ?? 0) + 1;
    _distanceKm += sample.speedKmh / 3600.0;
    _maxSpeed = max(_maxSpeed, sample.speedKmh);

    // Son 30 saniyenin ortalama ofkesi (acil durum kurali icin)
    final recent = history.length <= 30
        ? history
        : history.sublist(history.length - 30);
    final sustainedAnger = recent.isEmpty
        ? 0.0
        : recent.map((s) => s.score(EmotionType.angry)).reduce((a, b) => a + b) /
            recent.length;

    final decision = _kds.decide(
      sample: sample,
      sessionDuration: sessionDuration,
      sustainedAnger: sustainedAnger,
    );
    if (decision != null) _fire(decision);

    notifyListeners();
  }

  /// Multimodal fuzyon (gercek mod): yuz metrikleri + ses enerjisi + hiz.
  EmotionSample _fuseRealSample() {
    final r = face.reading.value;
    final faceVisible = r?.faceVisible ?? false;

    if (r != null && faceVisible) {
      _eyesOpenEma = _eyesOpenEma * 0.85 + r.eyesOpen * 0.15;
      _smileEma = _smileEma * 0.7 + r.smile * 0.3;
    }
    _arousalEma = _arousalEma * 0.8 + _voice.level * 0.2;

    // Goruntu kanali
    final tired = ((0.55 - _eyesOpenEma) / 0.55).clamp(0.0, 1.0);
    final happy = _smileEma.clamp(0.0, 1.0);

    // Ses kanali: surekli yuksek enerji -> ofke/stres
    final angry = (_arousalEma * 1.15 - 0.15).clamp(0.0, 1.0);
    final stressed = (_arousalEma * 0.9 + tired * 0.2).clamp(0.0, 1.0);

    final neutral =
        (1.0 - max(max(angry, stressed), max(tired, happy))).clamp(0.05, 1.0);

    final target = <EmotionType, double>{
      EmotionType.angry: angry,
      EmotionType.stressed: stressed,
      EmotionType.tired: tired,
      EmotionType.happy: happy,
      EmotionType.sad: 0.05,
      EmotionType.fearful: 0.05,
      EmotionType.surprised: 0.05,
      EmotionType.neutral: neutral,
    };
    // EMA yumusatma — tek karelik sicramalari engeller
    target.forEach((t, v) {
      _realScores[t] = ((_realScores[t] ?? 0) * 0.7 + v * 0.3).clamp(0.0, 1.0);
    });

    return EmotionSample(
      time: DateTime.now(),
      scores: Map.of(_realScores),
      speedKmh: gpsActive ? _speed.speedKmh : 0,
      voiceLevel: _voice.level,
      faceVisible: faceVisible,
    );
  }

  void _fire(InterventionEvent event) {
    _interventions.add(event);
    activeIntervention = event;

    if (settings.hapticAlerts) {
      HapticFeedback.heavyImpact();
    }
    if (settings.voiceAlerts) {
      _tts.speak(event.message);
    }
    if (settings.autoMusic) {
      if (event.type == InterventionType.calmMusic) {
        music.playMood(TrackMood.calm);
      } else if (event.type == InterventionType.energize) {
        music.playMood(TrackMood.energetic);
      }
    }
  }

  /// Kullanici geri bildirimi -> KDS ogrenme motoru.
  Future<void> feedback(bool accepted) async {
    final e = activeIntervention;
    if (e == null) return;
    e.accepted = accepted;
    await _kds.learn(e.type, accepted);
    activeIntervention = null;
    notifyListeners();
  }

  void dismissIntervention() {
    activeIntervention = null;
    notifyListeners();
  }

  Future<DriveSession?> stop() async {
    if (state == DriveState.idle) return null;
    _ticker?.cancel();
    _ticker = null;

    await face.stop();
    await _voice.stop();
    await _speed.stop();
    try {
      await WakelockPlus.disable();
    } catch (_) {}
    await _tts.stop();

    final start = _startTime ?? DateTime.now();
    final end = DateTime.now();
    final session = DriveSession(
      id: 'sess_${start.millisecondsSinceEpoch}',
      start: start,
      end: end,
      distanceKm: _distanceKm,
      maxSpeedKmh: _maxSpeed,
      emotionSeconds: Map.of(_emotionSeconds),
      interventions: List.of(_interventions),
      timeline: List.of(_timeline),
      calmScore: DriveSession.computeCalmScore(_emotionSeconds),
      mode: mode == DriveMode.camera ? 'camera' : scenario.id,
    );

    if (end.difference(start) >= const Duration(seconds: 20)) {
      await StorageService.saveSession(session);
    }
    lastSession = session;

    state = DriveState.idle;
    cameraActive = false;
    micActive = false;
    gpsActive = false;
    activeIntervention = null;
    _sim = null;
    notifyListeners();
    return session;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    face.stop();
    _voice.dispose();
    _speed.stop();
    super.dispose();
  }
}
