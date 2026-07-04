import 'package:flutter/material.dart';

import '../models/emotion.dart';
import '../models/intervention.dart';
import '../models/session.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import '../widgets/calm_ring.dart';
import '../widgets/common.dart';
import 'session_detail_screen.dart';

enum _Range { today, week, all }

/// Surus raporlari (dokuman 8.2): dagilim, istatistik, rozetler, gecmis.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  _Range range = _Range.today;

  List<DriveSession> get _sessions {
    final now = DateTime.now();
    return switch (range) {
      _Range.today =>
        StorageService.sessionsSince(DateTime(now.year, now.month, now.day)),
      _Range.week =>
        StorageService.sessionsSince(now.subtract(const Duration(days: 7))),
      _Range.all => StorageService.allSessions(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final sessions = _sessions;
    final all = StorageService.allSessions();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
        children: [
          Text('Sürüş Raporları 📊',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          _RangeSelector(
            range: range,
            onChanged: (r) => setState(() => range = r),
          ),
          const SizedBox(height: 18),
          if (sessions.isEmpty)
            const _EmptyState()
          else ...[
            _SummaryRow(sessions: sessions),
            const SizedBox(height: 14),
            _EmotionDistribution(sessions: sessions),
            const SizedBox(height: 14),
            _WeeklyChart(sessions: all),
            const SizedBox(height: 14),
            _InterventionStats(sessions: sessions),
          ],
          const SizedBox(height: 14),
          _Badges(all: all),
          if (sessions.isNotEmpty) ...[
            const SizedBox(height: 18),
            const SectionHeader('Sürüş Geçmişi'),
            for (final s in sessions.take(20)) _SessionTile(session: s),
          ],
        ],
      ),
    );
  }
}

class _RangeSelector extends StatelessWidget {
  final _Range range;
  final ValueChanged<_Range> onChanged;

  const _RangeSelector({required this.range, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget seg(_Range r, String label) {
      final selected = r == range;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(r),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? AppTheme.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: selected ? const Color(0xFF04211C) : AppTheme.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          seg(_Range.today, 'Bugün'),
          seg(_Range.week, 'Bu Hafta'),
          seg(_Range.all, 'Tümü'),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Text('🛣️', style: TextStyle(fontSize: 44)),
          const SizedBox(height: 12),
          Text('Henüz sürüş kaydı yok',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
            'Ana ekrandan bir sürüş (veya demo senaryosu) başlatın; '
            'raporlarınız burada birikecek.',
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

class _SummaryRow extends StatelessWidget {
  final List<DriveSession> sessions;

  const _SummaryRow({required this.sessions});

  @override
  Widget build(BuildContext context) {
    final totalMin =
        sessions.fold<int>(0, (a, s) => a + s.duration.inMinutes);
    final km = sessions.fold<double>(0, (a, s) => a + s.distanceKm);
    final avgScore = sessions.isEmpty
        ? 0
        : sessions.fold<int>(0, (a, s) => a + s.calmScore) ~/ sessions.length;

    return Row(
      children: [
        StatChip(
          icon: Icons.timer_rounded,
          label: 'Toplam Süre',
          value: totalMin >= 60
              ? '${totalMin ~/ 60} sa ${totalMin % 60} dk'
              : '$totalMin dk',
        ),
        const SizedBox(width: 10),
        StatChip(
          icon: Icons.route_rounded,
          label: 'Mesafe',
          value: '${km.toStringAsFixed(0)} km',
        ),
        const SizedBox(width: 10),
        StatChip(
          icon: Icons.favorite_rounded,
          label: 'Ort. Puan',
          value: '$avgScore',
          color: avgScore >= 70
              ? const Color(0xFF3DDC84)
              : avgScore >= 40
                  ? const Color(0xFFFFD166)
                  : AppTheme.danger,
        ),
      ],
    );
  }
}

class _EmotionDistribution extends StatelessWidget {
  final List<DriveSession> sessions;

  const _EmotionDistribution({required this.sessions});

  @override
  Widget build(BuildContext context) {
    final totals = <EmotionType, double>{
      for (final t in EmotionType.values) t: 0,
    };
    for (final s in sessions) {
      s.emotionSeconds.forEach((t, v) => totals[t] = (totals[t] ?? 0) + v);
    }
    final total = totals.values.fold(0.0, (a, b) => a + b);
    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Duygu Dağılımı',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          if (total <= 0)
            const Text('Veri yok',
                style: TextStyle(color: AppTheme.textSecondary))
          else
            for (final e in sorted.where((e) => e.value > 0))
              PercentBar(
                label: e.key.labelTr,
                emoji: e.key.emoji,
                fraction: e.value / total,
                color: e.key.color,
              ),
        ],
      ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  final List<DriveSession> sessions;

  const _WeeklyChart({required this.sessions});

  static const _dayNames = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(7, (i) {
      final d = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: 6 - i));
      final daySessions = sessions.where((s) =>
          s.start.year == d.year &&
          s.start.month == d.month &&
          s.start.day == d.day);
      final scores = daySessions.map((s) => s.calmScore).toList();
      final avg = scores.isEmpty
          ? 0.0
          : scores.reduce((a, b) => a + b) / scores.length;
      return (d, avg);
    });

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Haftalık Sakin Sürüş Puanı',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final (d, avg) in days)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (avg > 0)
                            Text('${avg.round()}',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: avg >= 70
                                        ? const Color(0xFF3DDC84)
                                        : avg >= 40
                                            ? const Color(0xFFFFD166)
                                            : AppTheme.danger)),
                          const SizedBox(height: 4),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: avg / 100),
                            duration: const Duration(milliseconds: 700),
                            curve: Curves.easeOutCubic,
                            builder: (_, v, _) => Container(
                              height: 4 + 76 * v,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: avg <= 0
                                      ? [AppTheme.cardBorder, AppTheme.cardBorder]
                                      : [
                                          AppTheme.accent.withValues(alpha: 0.3),
                                          AppTheme.accent,
                                        ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(_dayNames[d.weekday - 1],
                              style: const TextStyle(
                                  fontSize: 10, color: AppTheme.textSecondary)),
                        ],
                      ),
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

class _InterventionStats extends StatelessWidget {
  final List<DriveSession> sessions;

  const _InterventionStats({required this.sessions});

  @override
  Widget build(BuildContext context) {
    final all = sessions.expand((s) => s.interventions).toList();
    final accepted = all.where((i) => i.accepted == true).length;
    final rate = all.isEmpty ? 0 : (accepted * 100 ~/ all.length);

    final byType = <String, int>{};
    for (final i in all) {
      final label = i.type.labelTr;
      byType[label] = (byType[label] ?? 0) + 1;
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Müdahale İstatistikleri',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF3DDC84).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('✅ %$rate faydalı',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF3DDC84))),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('Toplam ${all.length} müdahale',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in byType.entries)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Text('${e.key}: ${e.value}',
                      style: const TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badges extends StatelessWidget {
  final List<DriveSession> all;

  const _Badges({required this.all});

  @override
  Widget build(BuildContext context) {
    final breathing = StorageService.read<int>('breathingCompleted', 0);
    final calmSessions = all.where((s) => s.calmScore >= 70).length;
    final totalKm = all.fold<double>(0, (a, s) => a + s.distanceKm);

    final badges = <(String, String, bool)>[
      ('🚗', 'İlk Sürüş', all.isNotEmpty),
      ('🧘', 'Nefes Ustası', breathing >= 3),
      ('😌', 'Sakin Sürücü', calmSessions >= 3),
      ('🛣️', '100 km Kulübü', totalKm >= 100),
      ('🏆', 'Altın Sürücü', calmSessions >= 10),
      ('🔥', '5 Sürüş Serisi', all.length >= 5),
    ];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rozetler',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final (emoji, label, earned) in badges)
                Opacity(
                  opacity: earned ? 1 : 0.35,
                  child: Container(
                    width: 92,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: earned
                          ? AppTheme.accent.withValues(alpha: 0.08)
                          : AppTheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: earned ? AppTheme.accent : AppTheme.cardBorder),
                    ),
                    child: Column(
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 24)),
                        const SizedBox(height: 6),
                        Text(label,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 10.5, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final DriveSession session;

  const _SessionTile({required this.session});

  static const _months = [
    'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
    'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara',
  ];

  @override
  Widget build(BuildContext context) {
    final s = session;
    final d = s.start;
    final dateStr =
        '${d.day} ${_months[d.month - 1]} • ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    final dominant = s.emotionSeconds.entries.reduce(
        (a, b) => a.value >= b.value ? a : b);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => SessionDetailScreen(session: s))),
        child: Row(
          children: [
            CalmRing(score: s.calmScore.toDouble(), size: 52),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dateStr,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(
                    '${s.duration.inMinutes} dk • ${s.distanceKm.toStringAsFixed(1)} km • '
                    '${s.interventions.length} müdahale',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppTheme.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
            Text(dominant.key.emoji, style: const TextStyle(fontSize: 20)),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}
