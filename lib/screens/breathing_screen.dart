import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../controllers/music_controller.dart';
import '../controllers/settings_controller.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../theme.dart';

enum _Phase { ready, inhale, hold, exhale, done }

/// 4-7-8 nefes egzersizi (dokuman 8.3): animasyonlu daire + sesli rehber.
class BreathingScreen extends StatefulWidget {
  const BreathingScreen({super.key});

  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<BreathingScreen>
    with SingleTickerProviderStateMixin {
  static const inhaleSec = 4, holdSec = 7, exhaleSec = 8;
  int totalCycles = 6;

  _Phase phase = _Phase.ready;
  int cycle = 0;
  int phaseRemaining = 0;
  Timer? _timer;
  late final AnimationController _scale;
  final _tts = TtsService();

  @override
  void initState() {
    super.initState();
    _scale = AnimationController(
      vsync: this,
      duration: const Duration(seconds: inhaleSec),
      lowerBound: 0.55,
      upperBound: 1.0,
    );
  }

  int get totalSeconds => totalCycles * (inhaleSec + holdSec + exhaleSec);

  int get elapsedSeconds {
    final perCycle = inhaleSec + holdSec + exhaleSec;
    var done = cycle * perCycle;
    done += switch (phase) {
      _Phase.inhale => inhaleSec - phaseRemaining,
      _Phase.hold => inhaleSec + (holdSec - phaseRemaining),
      _Phase.exhale => inhaleSec + holdSec + (exhaleSec - phaseRemaining),
      _ => 0,
    };
    return done;
  }

  void _start() {
    final settings = context.read<SettingsController>();
    _tts.enabled = settings.voiceAlerts;
    setState(() {
      cycle = 0;
      phase = _Phase.inhale;
      phaseRemaining = inhaleSec;
    });
    _tts.speak('Başlıyoruz. Burnunuzdan derin bir nefes alın.');
    _scale.duration = const Duration(seconds: inhaleSec);
    _scale.forward(from: 0.55);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!mounted) return;
    setState(() {
      phaseRemaining--;
      if (phaseRemaining > 0) return;
      switch (phase) {
        case _Phase.inhale:
          phase = _Phase.hold;
          phaseRemaining = holdSec;
          _tts.speak('Nefesinizi tutun.');
          HapticFeedback.lightImpact();
        case _Phase.hold:
          phase = _Phase.exhale;
          phaseRemaining = exhaleSec;
          _tts.speak('Ağzınızdan yavaşça verin.');
          _scale.duration = const Duration(seconds: exhaleSec);
          _scale.reverse(from: 1.0);
          HapticFeedback.lightImpact();
        case _Phase.exhale:
          cycle++;
          if (cycle >= totalCycles) {
            _finish();
          } else {
            phase = _Phase.inhale;
            phaseRemaining = inhaleSec;
            _tts.speak('Tekrar nefes alın.');
            _scale.duration = const Duration(seconds: inhaleSec);
            _scale.forward(from: 0.55);
            HapticFeedback.lightImpact();
          }
        default:
          break;
      }
    });
  }

  void _finish() {
    _timer?.cancel();
    phase = _Phase.done;
    _tts.speak('Harika. Egzersiz tamamlandı. Kendinizi daha sakin hissetmelisiniz.');
    final done = StorageService.read<int>('breathingCompleted', 0) + 1;
    StorageService.write('breathingCompleted', done);
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scale.dispose();
    _tts.stop();
    super.dispose();
  }

  String get phaseText => switch (phase) {
        _Phase.ready => 'Hazır olduğunuzda başlayın',
        _Phase.inhale => 'Nefes Al',
        _Phase.hold => 'Tut',
        _Phase.exhale => 'Yavaşça Ver',
        _Phase.done => 'Tamamlandı 🎉',
      };

  Color get phaseColor => switch (phase) {
        _Phase.inhale => AppTheme.accent,
        _Phase.hold => const Color(0xFFFFD166),
        _Phase.exhale => AppTheme.accentAlt,
        _Phase.done => const Color(0xFF3DDC84),
        _ => AppTheme.textSecondary,
      };

  @override
  Widget build(BuildContext context) {
    final music = context.watch<MusicController>();
    final remaining = totalSeconds - elapsedSeconds;

    return Scaffold(
      appBar: AppBar(
        title: const Text('🧘 Nefes Egzersizi'),
        actions: [
          if (phase == _Phase.ready)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: DropdownButton<int>(
                value: totalCycles,
                underline: const SizedBox.shrink(),
                dropdownColor: AppTheme.card,
                items: const [
                  DropdownMenuItem(value: 4, child: Text('4 döngü')),
                  DropdownMenuItem(value: 6, child: Text('6 döngü')),
                  DropdownMenuItem(value: 10, child: Text('10 döngü')),
                ],
                onChanged: (v) => setState(() => totalCycles = v ?? 6),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Text('Nefes Döngüsü 4-7-8',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: AppTheme.textSecondary)),
              const Spacer(),
              // Animasyonlu nefes dairesi
              AnimatedBuilder(
                animation: _scale,
                builder: (context, _) => Container(
                  width: 260,
                  height: 260,
                  alignment: Alignment.center,
                  child: Container(
                    width: 260 * _scale.value,
                    height: 260 * _scale.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          phaseColor.withValues(alpha: 0.45),
                          phaseColor.withValues(alpha: 0.06),
                        ],
                      ),
                      border: Border.all(color: phaseColor, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: phaseColor.withValues(alpha: 0.35),
                          blurRadius: 60,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(phaseText,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800)),
                          if (phase != _Phase.ready && phase != _Phase.done)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text('$phaseRemaining',
                                  style: Theme.of(context)
                                      .textTheme
                                      .displaySmall
                                      ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: phaseColor)),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              if (phase != _Phase.ready && phase != _Phase.done) ...[
                Text(
                  '⏱ Kalan: ${(remaining ~/ 60)}:${(remaining % 60).toString().padLeft(2, '0')}   •   Döngü ${cycle + 1} / $totalCycles',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 16),
              ],
              if (phase == _Phase.done)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    '“Sakinleşmek her zaman mümkün.”',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: AppTheme.textSecondary),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        if (music.playing) {
                          music.toggle();
                        } else {
                          music.playMood(TrackMood.meditation);
                        }
                      },
                      icon: Icon(
                        music.playing
                            ? Icons.music_off_rounded
                            : Icons.music_note_rounded,
                        size: 18,
                      ),
                      label: Text(
                          music.playing ? 'Müziği Durdur' : 'Müzik Eşliğinde'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: switch (phase) {
                        _Phase.ready => _start,
                        _Phase.done => () => Navigator.of(context).pop(),
                        _ => null,
                      },
                      icon: Icon(
                        phase == _Phase.done
                            ? Icons.check_rounded
                            : Icons.play_arrow_rounded,
                      ),
                      label: Text(switch (phase) {
                        _Phase.ready => 'Başla',
                        _Phase.done => 'Bitti',
                        _ => 'Devam ediyor…',
                      }),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
