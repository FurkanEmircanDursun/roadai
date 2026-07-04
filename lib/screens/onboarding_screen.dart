import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/settings_controller.dart';
import '../models/emotion.dart';
import '../theme.dart';
import '../widgets/emotion_aura.dart';
import 'home_shell.dart';

/// Ilk acilis: deger onerisi + gizlilik + profil kurulumu.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  final _nameCtrl = TextEditingController();
  final _vehicleCtrl = TextEditingController();
  int _page = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    _nameCtrl.dispose();
    _vehicleCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < 2) {
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final settings = context.read<SettingsController>();
    await settings.setProfile(
        newName: _nameCtrl.text.trim(), newVehicle: _vehicleCtrl.text.trim());
    await settings.completeOnboarding();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeShell()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _InfoPage(
                    visual: const EmotionAura(
                        emotion: EmotionType.angry, intensity: 0.8, size: 200),
                    title: 'Öfkeni yolda bırakma,\nRoadAI\'a bırak 🛡️',
                    body:
                        'Öfkeli sürücülerde kaza riski 3 kat artar. RoadAI yüz '
                        'ifadenizi ve ses tonunuzu gerçek zamanlı analiz eder; '
                        'öfke, stres veya yorgunluk anını sizden önce fark eder.',
                  ),
                  _InfoPage(
                    visual: const EmotionAura(
                        emotion: EmotionType.neutral, intensity: 0.5, size: 200),
                    title: 'Kişisel sakinleştirme\nasistanınız 🧘',
                    body:
                        'Doğru anda doğru müdahale: sakinleştirici müzik, sesli '
                        'nefes egzersizi, mola önerisi. Sistem geri bildiriminizle '
                        'öğrenir, size göre kişiselleşir.\n\n🔒 Tüm analiz cihazınızda '
                        'yapılır — görüntü ve ses asla buluta gönderilmez.',
                  ),
                  _ProfilePage(nameCtrl: _nameCtrl, vehicleCtrl: _vehicleCtrl),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Row(
                children: [
                  for (var i = 0; i < 3; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: i == _page ? 26 : 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: i == _page ? AppTheme.accent : AppTheme.cardBorder,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _next,
                    child: Text(_page == 2 ? 'Başlayalım 🚀' : 'Devam'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPage extends StatelessWidget {
  final Widget visual;
  final String title;
  final String body;

  const _InfoPage({
    required this.visual,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: visual),
          const SizedBox(height: 36),
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w800, height: 1.2)),
          const SizedBox(height: 16),
          Text(body,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: AppTheme.textSecondary, height: 1.55)),
        ],
      ),
    );
  }
}

class _ProfilePage extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController vehicleCtrl;

  const _ProfilePage({required this.nameCtrl, required this.vehicleCtrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: Text('👋', style: TextStyle(fontSize: 64))),
          const SizedBox(height: 28),
          Text('Sizi tanıyalım',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Asistanınız size adınızla hitap etsin. (İsteğe bağlı)',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.textSecondary)),
          const SizedBox(height: 26),
          TextField(
            controller: nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Adınız',
              prefixIcon: Icon(Icons.person_rounded, color: AppTheme.textSecondary),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: vehicleCtrl,
            decoration: const InputDecoration(
              labelText: 'Aracınız (örn. 2024 Togg T10X)',
              prefixIcon:
                  Icon(Icons.directions_car_rounded, color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
