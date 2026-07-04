import 'dart:math';

import 'package:flutter/material.dart';

import '../models/emotion.dart';

/// Duyguya gore renk degistiren, nefes alan halka animasyonu.
/// Kamera olmadiginda "canli durum" gorseli olarak kullanilir.
class EmotionAura extends StatefulWidget {
  final EmotionType emotion;
  final double intensity; // 0..1 — halka hizini/buyuklugunu etkiler
  final double size;

  const EmotionAura({
    super.key,
    required this.emotion,
    this.intensity = 0.5,
    this.size = 180,
  });

  @override
  State<EmotionAura> createState() => _EmotionAuraState();
}

class _EmotionAuraState extends State<EmotionAura>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.emotion.color;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _AuraPainter(
              progress: _ctrl.value,
              color: color,
              intensity: widget.intensity,
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Text(
                  widget.emotion.emoji,
                  key: ValueKey(widget.emotion),
                  style: TextStyle(fontSize: widget.size * 0.3),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AuraPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double intensity;

  _AuraPainter({
    required this.progress,
    required this.color,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width / 2;
    final baseR = maxR * 0.42;

    // Dolu merkez daire
    canvas.drawCircle(
      center,
      baseR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: 0.35),
            color.withValues(alpha: 0.08),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: baseR)),
    );
    canvas.drawCircle(
      center,
      baseR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color.withValues(alpha: 0.8),
    );

    // Disari yayilan 3 halka
    for (var i = 0; i < 3; i++) {
      final p = (progress + i / 3) % 1.0;
      final r = baseR + (maxR - baseR) * p;
      final alpha = (1 - p) * (0.35 + intensity * 0.4);
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 - p * 1.5
          ..color = color.withValues(alpha: alpha.clamp(0.0, 1.0)),
      );
    }

    // Nabiz noktasi (uydu)
    final angle = progress * 2 * pi;
    final orbit = baseR + (maxR - baseR) * 0.5;
    final dot = Offset(
      center.dx + cos(angle) * orbit,
      center.dy + sin(angle) * orbit,
    );
    canvas.drawCircle(dot, 4, Paint()..color = color);
    canvas.drawCircle(
      dot,
      8,
      Paint()..color = color.withValues(alpha: 0.3),
    );
  }

  @override
  bool shouldRepaint(covariant _AuraPainter old) =>
      old.progress != progress || old.color != color;
}
