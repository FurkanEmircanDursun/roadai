import 'package:flutter/material.dart';

import '../models/emotion.dart';
import '../theme.dart';

/// Canli duygu zaman cizgisi: ofke / stres / yorgunluk egrileri.
class EmotionSparkline extends StatelessWidget {
  final List<EmotionSample> samples;
  final double height;
  final List<EmotionType> series;

  const EmotionSparkline({
    super.key,
    required this.samples,
    this.height = 90,
    this.series = const [
      EmotionType.angry,
      EmotionType.stressed,
      EmotionType.tired,
    ],
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: height,
          width: double.infinity,
          child: samples.length < 2
              ? const Center(
                  child: Text('Veri toplanıyor…',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                )
              : CustomPaint(
                  painter: _SparkPainter(samples: samples, series: series),
                ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 14,
          children: [
            for (final t in series)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration:
                        BoxDecoration(color: t.color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 5),
                  Text(t.labelTr,
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary)),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class _SparkPainter extends CustomPainter {
  final List<EmotionSample> samples;
  final List<EmotionType> series;

  _SparkPainter({required this.samples, required this.series});

  @override
  void paint(Canvas canvas, Size size) {
    // Izgara cizgileri
    final grid = Paint()
      ..color = AppTheme.cardBorder.withValues(alpha: 0.6)
      ..strokeWidth = 1;
    for (var i = 0; i <= 2; i++) {
      final y = size.height * i / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    for (final t in series) {
      final path = Path();
      final fill = Path();
      for (var i = 0; i < samples.length; i++) {
        final x = size.width * i / (samples.length - 1);
        final y = size.height * (1 - samples[i].score(t).clamp(0.0, 1.0));
        if (i == 0) {
          path.moveTo(x, y);
          fill.moveTo(x, size.height);
          fill.lineTo(x, y);
        } else {
          path.lineTo(x, y);
          fill.lineTo(x, y);
        }
      }
      fill.lineTo(size.width, size.height);
      fill.close();

      canvas.drawPath(
        fill,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [t.color.withValues(alpha: 0.18), Colors.transparent],
          ).createShader(Offset.zero & size),
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..color = t.color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) =>
      old.samples.length != samples.length ||
      (samples.isNotEmpty &&
          old.samples.isNotEmpty &&
          old.samples.last != samples.last);
}
