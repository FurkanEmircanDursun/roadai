import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/settings_controller.dart';
import '../models/intervention.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Ayarlar (dokuman 8.4): profil, mudahale tercihleri, gizlilik, hakkinda.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
        children: [
          Text('Ayarlar ⚙️',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),
          const SectionHeader('PROFİL'),
          GlassCard(
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppTheme.accent, AppTheme.accentAlt],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    settings.name.isEmpty
                        ? '🚗'
                        : settings.name.characters.first.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF04211C)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(settings.name.isEmpty ? 'Sürücü' : settings.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      Text(
                        settings.vehicle.isEmpty
                            ? 'Araç bilgisi eklenmedi'
                            : '🚙 ${settings.vehicle}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _editProfile(context, settings),
                  icon: const Icon(Icons.edit_rounded,
                      size: 20, color: AppTheme.accent),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader('MÜDAHALE TERCİHLERİ'),
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              children: [
                for (final t in InterventionType.values)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: Icon(t.icon, color: t.color, size: 22),
                    title: Text(t.labelTr,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                    value: settings.interventionEnabled[t] ?? true,
                    onChanged: (v) => settings.setIntervention(t, v),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader('ASİSTAN'),
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.record_voice_over_rounded,
                      color: AppTheme.accent, size: 22),
                  title: const Text('Sesli Uyarılar (TTS)',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  subtitle: const Text('Asistan Türkçe konuşur',
                      style: TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary)),
                  value: settings.voiceAlerts,
                  onChanged: settings.setVoiceAlerts,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.vibration_rounded,
                      color: AppTheme.accentAlt, size: 22),
                  title: const Text('Titreşim',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  value: settings.hapticAlerts,
                  onChanged: settings.setHapticAlerts,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.queue_music_rounded,
                      color: AppTheme.warn, size: 22),
                  title: const Text('Müziği Otomatik Başlat',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  subtitle: const Text('Müdahale anında uygun müzik çalar',
                      style: TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary)),
                  value: settings.autoMusic,
                  onChanged: settings.setAutoMusic,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.tune_rounded,
                        color: AppTheme.accent, size: 22),
                    const SizedBox(width: 14),
                    const Text('Hassasiyet',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                    Expanded(
                      child: Slider(
                        value: settings.sensitivity,
                        onChanged: settings.setSensitivity,
                      ),
                    ),
                    Text(
                      settings.sensitivity < 0.35
                          ? 'Az'
                          : settings.sensitivity > 0.65
                              ? 'Çok'
                              : 'Orta',
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader('VERİ VE GİZLİLİK'),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3DDC84).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.shield_rounded,
                          color: Color(0xFF3DDC84), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Edge AI — %100 Cihaz İçi İşleme',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w800)),
                          Text(
                            'Kamera ve mikrofon verileri asla cihazdan çıkmaz. '
                            'Buluta hiçbir görüntü/ses gönderilmez (KVKK & GDPR uyumlu).',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: AppTheme.textSecondary,
                                    fontSize: 11.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.danger,
                      side: BorderSide(
                          color: AppTheme.danger.withValues(alpha: 0.5)),
                    ),
                    onPressed: () => _confirmDelete(context),
                    icon: const Icon(Icons.delete_forever_rounded, size: 20),
                    label: const Text('Tüm Sürüş Verilerimi Sil'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader('HAKKINDA'),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🛡️', style: TextStyle(fontSize: 26)),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('RoadAI',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800)),
                        const Text('Sürüm 2.0.1',
                            style: TextStyle(
                                fontSize: 12, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Yol Öfkesi Analizörü ve Sakinleştirici Asistan — yüz ifadesi, '
                  'ses tonu ve sürüş verilerinden duygusal durumunuzu analiz eder; '
                  'öfke, stres veya yorgunluk anlarında sizi sakinleştirir.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppTheme.textSecondary, height: 1.5),
                ),
                const Divider(height: 24),
                Text('Müzik Lisansları',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(
                  'Tüm müzikler: Kevin MacLeod (incompetech.com)\n'
                  'Creative Commons: By Attribution 4.0 License\n'
                  'creativecommons.org/licenses/by/4.0',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary, fontSize: 11, height: 1.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _editProfile(BuildContext context, SettingsController settings) {
    final nameCtrl = TextEditingController(text: settings.name);
    final vehicleCtrl = TextEditingController(text: settings.vehicle);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Profili Düzenle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Adınız'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: vehicleCtrl,
              decoration: const InputDecoration(
                  labelText: 'Aracınız (örn. 2024 Togg T10X)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          FilledButton(
            onPressed: () {
              settings.setProfile(
                  newName: nameCtrl.text.trim(),
                  newVehicle: vehicleCtrl.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Emin misiniz?'),
        content: const Text(
            'Tüm sürüş geçmişi ve duygu kayıtları kalıcı olarak silinecek. '
            'Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppTheme.danger,
                foregroundColor: Colors.white),
            onPressed: () async {
              await StorageService.deleteAllData();
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                    content: Text('🗑️ Tüm veriler silindi')));
              }
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}
