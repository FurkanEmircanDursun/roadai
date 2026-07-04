import '../models/emotion.dart';
import '../models/intervention.dart';
import 'storage_service.dart';

/// Karar Destek Sistemi (KDS).
///
/// Iki motor (dokuman Bolum 5.4):
///  1) Kural tabanli motor  — sabit IF/THEN esikleri
///  2) Ogrenme tabanli motor — kullanici geri bildirimiyle esik kisisellestirme
class DecisionEngine {
  /// Mudahale turu basina bekleme suresi (ayni mudahaleyi arka arkaya yapma).
  static const cooldowns = <InterventionType, Duration>{
    InterventionType.calmMusic: Duration(minutes: 8),
    InterventionType.breathing: Duration(minutes: 10),
    InterventionType.softNav: Duration(minutes: 4),
    InterventionType.breakSuggestion: Duration(minutes: 25),
    InterventionType.energize: Duration(minutes: 12),
    InterventionType.emergency: Duration(minutes: 5),
  };

  final Map<InterventionType, DateTime> _lastFired = {};
  final Map<InterventionType, double> _thresholdOffset = {};

  /// Kullanicinin kapattigi mudahale turleri (Ayarlar ekranindan).
  Set<InterventionType> enabledTypes = InterventionType.values.toSet();

  /// 0..1 hassasiyet: yuksek deger = daha erken mudahale.
  double sensitivity = 0.5;

  DecisionEngine() {
    _load();
  }

  void _load() {
    for (final t in InterventionType.values) {
      _thresholdOffset[t] =
          StorageService.read<double>('kds_offset_${t.name}', 0.0);
    }
  }

  double _threshold(double base, InterventionType t) {
    // Hassasiyet: 0.5 notr; 1.0 -> esik -0.10, 0.0 -> esik +0.10
    final sens = (0.5 - sensitivity) * 0.2;
    return (base + sens + (_thresholdOffset[t] ?? 0)).clamp(0.3, 0.97);
  }

  bool _onCooldown(InterventionType t, DateTime now) {
    final last = _lastFired[t];
    if (last == null) return false;
    return now.difference(last) < (cooldowns[t] ?? const Duration(minutes: 5));
  }

  /// Ana karar fonksiyonu. Oncelik sirasi dokumandaki senaryolara gore.
  InterventionEvent? decide({
    required EmotionSample sample,
    required Duration sessionDuration,
    required double sustainedAnger, // son 30 sn ortalama ofke
  }) {
    final now = sample.time;
    final angry = sample.score(EmotionType.angry);
    final stressed = sample.score(EmotionType.stressed);
    final tired = sample.score(EmotionType.tired);

    InterventionEvent? propose(
        InterventionType t, double value, double base, String reason, String msg) {
      if (!enabledTypes.contains(t)) return null;
      if (_onCooldown(t, now)) return null;
      if (value < _threshold(base, t)) return null;
      _lastFired[t] = now;
      return InterventionEvent(type: t, time: now, reason: reason, message: msg);
    }

    // 1) ACIL: 30 sn boyunca kritik ofke
    final emergency = propose(
      InterventionType.emergency,
      sustainedAnger,
      0.90,
      'Öfke 30 sn boyunca kritik seviyede',
      'Lütfen güvenli bir yerde durun. Sakinleşene kadar sürüşe ara vermenizi öneririm.',
    );
    if (emergency != null) return emergency;

    // 2) Ofke + yuksek hiz -> yavasla uyarisi (IF ofke>0.8 VE hiz>90)
    if (sample.speedKmh > 90) {
      final slow = propose(
        InterventionType.softNav,
        angry,
        0.80,
        'Öfke > %80 ve hız > 90 km/s',
        'Hızınızı düşürmenizi öneririm. Derin bir nefes alalım.',
      );
      if (slow != null) return slow;
    }

    // 3) Yuksek ofke -> sakinlestirici muzik
    final music = propose(
      InterventionType.calmMusic,
      angry,
      0.72,
      'Öfke seviyesi yükseldi',
      'Sakin olmanıza yardımcı olabilir miyim? Sakinleştirici müzik başlatıyorum.',
    );
    if (music != null) return music;

    // 4) Stres + uzun yolculuk -> mola (IF stres>0.7 VE seyahat>2s)
    if (sessionDuration > const Duration(hours: 2)) {
      final rest = propose(
        InterventionType.breakSuggestion,
        stressed,
        0.70,
        'Stres > %70 ve yolculuk 2 saati aştı',
        'Uzun süredir araç kullanıyorsunuz. 15 dakikalık bir mola öneririm.',
      );
      if (rest != null) return rest;
    }

    // 5) Stres -> nefes egzersizi
    final breath = propose(
      InterventionType.breathing,
      stressed,
      0.68,
      'Stres belirtileri tespit edildi',
      'Sakinleşmek için kısa bir nefes egzersizi öneririm.',
    );
    if (breath != null) return breath;

    // 6) Yorgunluk -> mola + enerjik muzik
    final tiredBreak = propose(
      InterventionType.breakSuggestion,
      tired,
      0.72,
      'Yorgunluk belirtileri (göz kapanması, baş sallama)',
      'Yorgunluk belirtileri görüyorum. En yakın dinlenme noktasında mola verin.',
    );
    if (tiredBreak != null) return tiredBreak;

    final energize = propose(
      InterventionType.energize,
      tired,
      0.60,
      'Hafif yorgunluk tespit edildi',
      'Sizi canlandırmak için enerjik bir müzik açıyorum.',
    );
    if (energize != null) return energize;

    return null;
  }

  /// Ogrenme tabanli motor: geri bildirim esikleri gunceller.
  /// Reddedilen mudahale -> esik yukselir (daha az rahatsiz et),
  /// kabul edilen -> esik hafif duser (daha proaktif ol).
  Future<void> learn(InterventionType t, bool accepted) async {
    final cur = _thresholdOffset[t] ?? 0;
    final next = (accepted ? cur - 0.02 : cur + 0.05).clamp(-0.10, 0.15);
    _thresholdOffset[t] = next;
    await StorageService.write('kds_offset_${t.name}', next);
  }

  double offsetFor(InterventionType t) => _thresholdOffset[t] ?? 0;

  void resetSession() => _lastFired.clear();
}
