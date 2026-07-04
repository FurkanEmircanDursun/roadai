import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/music_controller.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Muzik terapisi kutuphanesi + calar.
class MusicScreen extends StatelessWidget {
  const MusicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final music = context.watch<MusicController>();

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              children: [
                Text('Müzik Terapisi 🎵',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(
                  'Telifsiz, çevrimdışı çalışan terapi müzikleri. '
                  'KDS müdahaleleri bu kütüphaneyi kullanır.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 18),
                for (final mood in TrackMood.values) ...[
                  _MoodSection(mood: mood, music: music),
                  const SizedBox(height: 16),
                ],
                const SizedBox(height: 80),
              ],
            ),
          ),
          if (music.current != null) _PlayerBar(music: music),
        ],
      ),
    );
  }
}

class _MoodSection extends StatelessWidget {
  final TrackMood mood;
  final MusicController music;

  const _MoodSection({required this.mood, required this.music});

  @override
  Widget build(BuildContext context) {
    final tracks = music.byMood(mood);
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(mood.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mood.labelTr,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    Text(mood.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => music.playMood(mood),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.accent.withValues(alpha: 0.12),
                ),
                icon: const Icon(Icons.shuffle_rounded,
                    color: AppTheme.accent, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final t in tracks) _TrackTile(track: t, music: music),
        ],
      ),
    );
  }
}

class _TrackTile extends StatelessWidget {
  final MusicTrack track;
  final MusicController music;

  const _TrackTile({required this.track, required this.music});

  @override
  Widget build(BuildContext context) {
    final isCurrent = music.current == track;
    final isPlaying = isCurrent && music.playing;

    return InkWell(
      onTap: () => isCurrent ? music.toggle() : music.play(track),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: isCurrent
              ? AppTheme.accent.withValues(alpha: 0.07)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isCurrent
                    ? AppTheme.accent.withValues(alpha: 0.15)
                    : AppTheme.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: isPlaying
                  ? const _EqualizerIcon()
                  : Icon(
                      isCurrent ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      size: 20,
                      color: isCurrent ? AppTheme.accent : AppTheme.textSecondary,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(track.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight:
                              isCurrent ? FontWeight.w800 : FontWeight.w600,
                          color: isCurrent
                              ? AppTheme.accent
                              : AppTheme.textPrimary)),
                  Text(track.artist,
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Calan parca icin mini animasyonlu ekolayzer.
class _EqualizerIcon extends StatefulWidget {
  const _EqualizerIcon();

  @override
  State<_EqualizerIcon> createState() => _EqualizerIconState();
}

class _EqualizerIconState extends State<_EqualizerIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < 3; i++) ...[
            Container(
              width: 3.5,
              height: 6 +
                  10 * (0.5 + 0.5 * sin((_ctrl.value * 2 * pi) + i * 2.1)),
              margin: const EdgeInsets.symmetric(horizontal: 1.2),
              decoration: BoxDecoration(
                color: AppTheme.accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
          const SizedBox(height: 22),
        ],
      ),
    );
  }
}

class _PlayerBar extends StatelessWidget {
  final MusicController music;

  const _PlayerBar({required this.music});

  String _fmt(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final t = music.current!;
    final progress = music.duration.inMilliseconds == 0
        ? 0.0
        : music.position.inMilliseconds / music.duration.inMilliseconds;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accent.withValues(alpha: 0.15),
            blurRadius: 24,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(t.mood.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    Text('${t.artist} • ${t.mood.labelTr}',
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              IconButton(
                onPressed: music.previous,
                icon: const Icon(Icons.skip_previous_rounded, size: 26),
              ),
              IconButton(
                onPressed: music.toggle,
                style: IconButton.styleFrom(backgroundColor: AppTheme.accent),
                icon: Icon(
                  music.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: const Color(0xFF04211C),
                  size: 26,
                ),
              ),
              IconButton(
                onPressed: music.next,
                icon: const Icon(Icons.skip_next_rounded, size: 26),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(_fmt(music.position),
                  style: const TextStyle(
                      fontSize: 10, color: AppTheme.textSecondary)),
              const SizedBox(width: 8),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 12),
                  ),
                  child: Slider(
                    value: progress.clamp(0.0, 1.0),
                    onChanged: (v) {
                      final target = Duration(
                          milliseconds:
                              (music.duration.inMilliseconds * v).round());
                      music.seek(target);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(_fmt(music.duration),
                  style: const TextStyle(
                      fontSize: 10, color: AppTheme.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}
