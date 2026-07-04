import 'package:flutter/material.dart';

/// Dokumandaki KDS mudahale secenekleri.
enum InterventionType { calmMusic, breathing, softNav, breakSuggestion, energize, emergency }

extension InterventionTypeX on InterventionType {
  String get labelTr => switch (this) {
        InterventionType.calmMusic => 'Sakinleştirici Müzik',
        InterventionType.breathing => 'Nefes Egzersizi',
        InterventionType.softNav => 'Yumuşak Sürüş Uyarısı',
        InterventionType.breakSuggestion => 'Mola Önerisi',
        InterventionType.energize => 'Enerji Müziği',
        InterventionType.emergency => 'Acil Durum Uyarısı',
      };

  IconData get icon => switch (this) {
        InterventionType.calmMusic => Icons.music_note_rounded,
        InterventionType.breathing => Icons.self_improvement_rounded,
        InterventionType.softNav => Icons.speed_rounded,
        InterventionType.breakSuggestion => Icons.local_cafe_rounded,
        InterventionType.energize => Icons.bolt_rounded,
        InterventionType.emergency => Icons.warning_amber_rounded,
      };

  Color get color => switch (this) {
        InterventionType.calmMusic => const Color(0xFF38E0C8),
        InterventionType.breathing => const Color(0xFF8A7CFF),
        InterventionType.softNav => const Color(0xFFFFD166),
        InterventionType.breakSuggestion => const Color(0xFFFF9F43),
        InterventionType.energize => const Color(0xFF3DDC84),
        InterventionType.emergency => const Color(0xFFFF4D5E),
      };
}

class InterventionEvent {
  final InterventionType type;
  final DateTime time;
  final String reason; // KDS tetik kurali (kullaniciya gosterilir)
  final String message; // Sesli/gorsel asistan mesaji
  bool? accepted; // kullanici geri bildirimi

  InterventionEvent({
    required this.type,
    required this.time,
    required this.reason,
    required this.message,
    this.accepted,
  });

  Map<String, dynamic> toMap() => {
        'type': type.name,
        't': time.millisecondsSinceEpoch,
        'reason': reason,
        'msg': message,
        'ok': accepted,
      };

  static InterventionEvent fromMap(Map<dynamic, dynamic> m) => InterventionEvent(
        type: InterventionType.values.firstWhere(
          (t) => t.name == m['type'],
          orElse: () => InterventionType.calmMusic,
        ),
        time: DateTime.fromMillisecondsSinceEpoch(m['t'] as int),
        reason: m['reason'] as String? ?? '',
        message: m['msg'] as String? ?? '',
        accepted: m['ok'] as bool?,
      );
}
