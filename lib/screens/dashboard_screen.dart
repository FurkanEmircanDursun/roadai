import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/drive_controller.dart';
import '../controllers/music_controller.dart';
import '../controllers/settings_controller.dart';
import '../models/emotion.dart';
import '../models/session.dart';
import '../services/simulation_engine.dart';
import '../theme.dart';
import '../widgets/calm_ring.dart';
import '../widgets/common.dart';
import '../widgets/emotion_aura.dart';
import '../widgets/intervention_banner.dart';
import '../widgets/sparkline.dart';
import 'breathing_screen.dart';

/// Ana ekran (dokuman 8.1): canli durum + mudahale + hizli eylemler.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final drive = context.watch<DriveController>();
    final settings = context.watch<SettingsController>();
    final driving = drive.state == DriveState.running;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
        children: [
          _Header(settings: settings, drive: drive),
          const SizedBox(height: 18),
          const InterventionBanner(),
          _LiveStatusCard(drive: drive),
          const SizedBox(height: 14),
          if (driving) ...[
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Duygu Akışı (canlı)',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  EmotionSparkline(samples: List.of(drive.history)),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          const _MiniPlayer(),
          _QuickActions(driving: driving),
          const SizedBox(height: 18),
          _DriveButton(drive: drive),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final SettingsController settings;
  final DriveController drive;

  const _Header({required this.settings, required this.drive});

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 6) return 'İyi geceler';
    if (h < 12) return 'Günaydın';
    if (h < 18) return 'İyi günler';
    return 'İyi akşamlar';
  }

  @override
  Widget build(BuildContext context) {
    final name = settings.name.isEmpty ? 'Sürücü' : settings.name;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$_greeting, $name 👋',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                drive.state == DriveState.running
                    ? '🟢 Sürüş aktif — RoadAI sizi izliyor'
                    : 'RoadAI hazır. İyi yolculuklar!',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
        if (drive.state == DriveState.running)
          CalmRing(score: drive.liveCalmScore, size: 72, label: 'PUAN'),
      ],
    );
  }
}

class _LiveStatusCard extends StatelessWidget {
  final DriveController drive;

  const _LiveStatusCard({required this.drive});

  @override
  Widget build(BuildContext context) {
    final driving = drive.state == DriveState.running;
    final sample = drive.current;
    final emotion = sample?.primary ?? EmotionType.neutral;
    final confidence = sample?.confidence ?? 0;
    final stress = sample?.score(EmotionType.stressed) ?? 0;

    final showCamera = driving &&
        drive.mode == DriveMode.camera &&
        drive.face.previewReady;

    return GlassCard(
      glow: driving ? emotion.color : null,
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: driving ? const Color(0xFF3DDC84) : AppTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                driving ? 'ANLIK DURUM • CANLI' : 'ANLIK DURUM',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.textSecondary, letterSpacing: 1.4),
              ),
              const Spacer(),
              if (driving)
                Text(
                  _fmtDuration(drive.sessionDuration),
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: AppTheme.accent, fontWeight: FontWeight.w800),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (showCamera)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: CameraPreview(drive.face.controller!),
              ),
            )
          else
            EmotionAura(
              emotion: driving ? emotion : EmotionType.neutral,
              intensity: driving ? confidence : 0.3,
              size: 170,
            ),
          const SizedBox(height: 16),
          if (driving) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emotion.emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Text(emotion.labelTr,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800, color: emotion.color)),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: emotion.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Güven %${(confidence * 100).round()}',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: emotion.color)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _MeterRow(
              label: 'Stres',
              value: stress,
              color: EmotionType.stressed.color,
            ),
            const SizedBox(height: 8),
            _MeterRow(
              label: 'Ses',
              value: sample?.voiceLevel ?? 0,
              color: AppTheme.accentAlt,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _InfoPill(
                  icon: Icons.speed_rounded,
                  text: '${(sample?.speedKmh ?? 0).round()} km/s',
                ),
                const SizedBox(width: 8),
                _InfoPill(
                  icon: Icons.videocam_rounded,
                  text: drive.mode == DriveMode.camera
                      ? (drive.cameraActive ? 'Kamera' : 'Kamera yok')
                      : 'Demo',
                  active: drive.mode != DriveMode.camera || drive.cameraActive,
                ),
                const SizedBox(width: 8),
                _InfoPill(
                  icon: Icons.mic_rounded,
                  text: drive.micActive ? 'Mikrofon' : 'Mik. yok',
                  active: drive.micActive || drive.mode == DriveMode.scenario,
                ),
                const SizedBox(width: 8),
                _InfoPill(
                  icon: Icons.shield_rounded,
                  text: 'Edge AI',
                  active: true,
                ),
              ],
            ),
            if (sample != null && !sample.faceVisible &&
                drive.mode == DriveMode.camera && drive.cameraActive)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    const Icon(Icons.visibility_off_rounded,
                        size: 16, color: AppTheme.warn),
                    const SizedBox(width: 6),
                    Text('Yüz algılanamıyor — kamerayı yüzünüze çevirin',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppTheme.warn)),
                  ],
                ),
              ),
          ] else
            Text(
              'Sürüşü başlatın; yüz ifadeniz, ses tonunuz ve hızınız '
              'gerçek zamanlı analiz edilsin. Tüm işlem cihazınızda kalır. 🔒',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.textSecondary),
            ),
        ],
      ),
    );
  }
}

String _fmtDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  final s = d.inSeconds % 60;
  if (h > 0) return '$h sa ${m.toString().padLeft(2, '0')} dk';
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

class _MeterRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _MeterRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 44,
          child: Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppTheme.textSecondary)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Stack(
              children: [
                Container(height: 8, color: AppTheme.cardBorder),
                AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 500),
                  alignment: Alignment.centerLeft,
                  widthFactor: value.clamp(0.02, 1.0),
                  child: Container(height: 8, color: color),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          width: 40,
          child: Text('%${(value * 100).round()}',
              textAlign: TextAlign.right,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool active;

  const _InfoPill({required this.icon, required this.text, this.active = true});

  @override
  Widget build(BuildContext context) {
    final color = active ? AppTheme.accent : AppTheme.textSecondary;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(height: 3),
            Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 9.5, color: color)),
          ],
        ),
      ),
    );
  }
}

/// Dokuman 8.1: ana ekranda "calan muzik" karti.
class _MiniPlayer extends StatelessWidget {
  const _MiniPlayer();

  String _fmt(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final music = context.watch<MusicController>();
    final t = music.current;
    if (t == null) return const SizedBox.shrink();

    final progress = music.duration.inMilliseconds == 0
        ? 0.0
        : (music.position.inMilliseconds / music.duration.inMilliseconds)
            .clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GlassCard(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            Text(t.mood.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    music.playing
                        ? '🎵 ${t.title}'
                        : '⏸ ${t.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Stack(
                            children: [
                              Container(height: 5, color: AppTheme.cardBorder),
                              FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: progress <= 0 ? 0.001 : progress,
                                child: Container(
                                    height: 5, color: AppTheme.accent),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_fmt(music.position)} / ${_fmt(music.duration)}',
                        style: const TextStyle(
                            fontSize: 10, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: music.toggle,
              icon: Icon(
                music.playing
                    ? Icons.pause_circle_filled_rounded
                    : Icons.play_circle_fill_rounded,
                color: AppTheme.accent,
                size: 34,
              ),
            ),
            IconButton(
              onPressed: music.next,
              icon: const Icon(Icons.skip_next_rounded,
                  color: AppTheme.textSecondary, size: 26),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final bool driving;

  const _QuickActions({required this.driving});

  @override
  Widget build(BuildContext context) {
    final music = context.read<MusicController>();
    return Row(
      children: [
        _ActionCard(
          emoji: '🧘',
          label: 'Nefes\nEgzersizi',
          color: AppTheme.accentAlt,
          onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BreathingScreen())),
        ),
        const SizedBox(width: 12),
        _ActionCard(
          emoji: '🌊',
          label: 'Sakin\nMüzik',
          color: AppTheme.accent,
          onTap: () {
            music.playMood(TrackMood.calm);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('🌊 Sakinleştirici müzik başlatıldı')));
          },
        ),
        const SizedBox(width: 12),
        _ActionCard(
          emoji: '☕',
          label: 'Mola Yeri\nBul',
          color: AppTheme.warn,
          onTap: () async {
            final uri = Uri.parse(
                'https://www.google.com/maps/search/dinlenme+tesisi');
            try {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } catch (_) {}
          },
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.emoji,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(height: 8),
              Text(label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700, height: 1.25)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DriveButton extends StatelessWidget {
  final DriveController drive;

  const _DriveButton({required this.drive});

  @override
  Widget build(BuildContext context) {
    final driving = drive.state == DriveState.running;
    return SizedBox(
      height: 58,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: driving ? AppTheme.danger : AppTheme.accent,
          foregroundColor:
              driving ? Colors.white : const Color(0xFF04211C),
        ),
        onPressed: drive.state == DriveState.starting
            ? null
            : () async {
                if (driving) {
                  final session = await drive.stop();
                  if (session != null && context.mounted) {
                    _showSummary(context, session);
                  }
                } else {
                  _showModePicker(context, drive);
                }
              },
        icon: Icon(driving ? Icons.stop_rounded : Icons.play_arrow_rounded,
            size: 28),
        label: Text(driving ? 'SÜRÜŞÜ BİTİR' : 'SÜRÜŞÜ BAŞLAT',
            style: const TextStyle(fontSize: 16, letterSpacing: 1)),
      ),
    );
  }

  void _showModePicker(BuildContext context, DriveController drive) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Sürüş modu seçin',
                  style: Theme.of(ctx)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              _ModeTile(
                emoji: '📷',
                title: 'Gerçek Sürüş (Kamera + Mikrofon)',
                subtitle:
                    'Yüz ifadesi ML Kit ile cihaz üzerinde analiz edilir. GPS hızı kullanılır.',
                highlight: true,
                onTap: () {
                  Navigator.pop(ctx);
                  drive.start(driveMode: DriveMode.camera);
                },
              ),
              const SizedBox(height: 10),
              const Divider(),
              const SizedBox(height: 6),
              Text('DEMO SENARYOLARI',
                  style: Theme.of(ctx).textTheme.labelSmall?.copyWith(
                      color: AppTheme.textSecondary, letterSpacing: 1.4)),
              const SizedBox(height: 10),
              for (final s in DriveScenario.all) ...[
                _ModeTile(
                  emoji: s.emoji,
                  title: s.title,
                  subtitle: s.subtitle,
                  onTap: () {
                    Navigator.pop(ctx);
                    drive.start(driveMode: DriveMode.scenario, scn: s);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showSummary(BuildContext context, DriveSession s) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Sürüş Tamamlandı 🏁',
                  style: Theme.of(ctx)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 18),
              CalmRing(score: s.calmScore.toDouble(), size: 110, label: 'SAKİN SÜRÜŞ'),
              const SizedBox(height: 18),
              Row(
                children: [
                  StatChip(
                    icon: Icons.timer_rounded,
                    label: 'Süre',
                    value: _fmtDuration(s.duration),
                  ),
                  const SizedBox(width: 10),
                  StatChip(
                    icon: Icons.route_rounded,
                    label: 'Mesafe',
                    value: '${s.distanceKm.toStringAsFixed(1)} km',
                  ),
                  const SizedBox(width: 10),
                  StatChip(
                    icon: Icons.support_agent_rounded,
                    label: 'Müdahale',
                    value: '${s.interventions.length}',
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                s.calmScore >= 70
                    ? 'Harika bir sürüş! Sakinliğinizi korudunuz. 👏'
                    : s.calmScore >= 40
                        ? 'Fena değil — RoadAI zor anlarda yanınızdaydı.'
                        : 'Zorlu bir sürüştü. Yola çıkmadan nefes egzersizi deneyin. 💜',
                textAlign: TextAlign.center,
                style: Theme.of(ctx)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Kapat'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final bool highlight;
  final VoidCallback onTap;

  const _ModeTile({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: highlight
              ? AppTheme.accent.withValues(alpha: 0.08)
              : AppTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: highlight ? AppTheme.accent : AppTheme.cardBorder),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}
