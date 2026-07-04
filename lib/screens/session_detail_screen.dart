import 'package:flutter/material.dart';

import '../models/emotion.dart';
import '../models/intervention.dart';
import '../models/session.dart';
import '../theme.dart';
import '../widgets/calm_ring.dart';
import '../widgets/common.dart';
import '../widgets/sparkline.dart';

/// Tek bir surus oturumunun detay raporu.
class SessionDetailScreen extends StatelessWidget {
  final DriveSession session;

  const SessionDetailScreen({super.key, required this.session});

  static const _months = [
    'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
  ];

  @override
  Widget build(BuildContext context) {
    final s = session;
    final d = s.start;
    final title =
        '${d.day} ${_months[d.month - 1]} ${d.year}, ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

    final total = s.totalEmotionSeconds;
    final sorted = s.emotionSeconds.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(title: const Text('Sürüş Detayı')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          GlassCard(
            child: Row(
              children: [
                CalmRing(
                    score: s.calmScore.toDouble(), size: 88, label: 'PUAN'),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text(
                        '⏱ ${s.duration.inMinutes} dakika\n'
                        '📍 ${s.distanceKm.toStringAsFixed(1)} km • '
                        'Azami ${s.maxSpeedKmh.round()} km/s\n'
                        '${s.mode == 'camera' ? '📷 Gerçek sürüş' : '🎬 Demo senaryo'}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                                color: AppTheme.textSecondary, height: 1.6),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (s.timeline.length >= 2)
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Duygu Zaman Çizgisi',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  EmotionSparkline(samples: s.timeline, height: 110),
                ],
              ),
            ),
          const SizedBox(height: 14),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Duygu Dağılımı',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                for (final e in sorted)
                  PercentBar(
                    label: e.key.labelTr,
                    emoji: e.key.emoji,
                    fraction: e.value / total,
                    color: e.key.color,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Müdahaleler (${s.interventions.length})',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                if (s.interventions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Bu sürüşte müdahale gerekmedi. 🎉',
                        style: TextStyle(color: AppTheme.textSecondary)),
                  )
                else
                  for (final i in s.interventions)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: i.type.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child:
                                Icon(i.type.icon, size: 17, color: i.type.color),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(i.type.labelTr,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                                fontWeight: FontWeight.w700)),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${i.time.hour.toString().padLeft(2, '0')}:${i.time.minute.toString().padLeft(2, '0')}',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.textSecondary),
                                    ),
                                  ],
                                ),
                                Text(i.reason,
                                    style: const TextStyle(
                                        fontSize: 11.5,
                                        color: AppTheme.textSecondary)),
                              ],
                            ),
                          ),
                          if (i.accepted != null)
                            Icon(
                              i.accepted!
                                  ? Icons.thumb_up_alt_rounded
                                  : Icons.thumb_down_alt_rounded,
                              size: 16,
                              color: i.accepted!
                                  ? const Color(0xFF3DDC84)
                                  : AppTheme.textSecondary,
                            ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
