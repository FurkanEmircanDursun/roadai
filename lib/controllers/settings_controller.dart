import 'package:flutter/foundation.dart';

import '../models/intervention.dart';
import '../services/storage_service.dart';

/// Kullanici profili + mudahale tercihleri (dokuman 8.4 Ayarlar ekrani).
class SettingsController extends ChangeNotifier {
  String name = '';
  String vehicle = '';
  bool onboardingDone = false;

  // Mudahale tercihleri
  final Map<InterventionType, bool> interventionEnabled = {
    for (final t in InterventionType.values) t: true,
  };

  bool voiceAlerts = true; // TTS
  bool hapticAlerts = true;
  double sensitivity = 0.5; // KDS hassasiyeti
  bool autoMusic = true; // mudahalede muzigi otomatik baslat

  SettingsController() {
    _load();
  }

  void _load() {
    name = StorageService.read('name', '');
    vehicle = StorageService.read('vehicle', '');
    onboardingDone = StorageService.read('onboardingDone', false);
    voiceAlerts = StorageService.read('voiceAlerts', true);
    hapticAlerts = StorageService.read('hapticAlerts', true);
    sensitivity = StorageService.read('sensitivity', 0.5);
    autoMusic = StorageService.read('autoMusic', true);
    for (final t in InterventionType.values) {
      interventionEnabled[t] = StorageService.read('int_${t.name}', true);
    }
  }

  Set<InterventionType> get enabledInterventions => interventionEnabled.entries
      .where((e) => e.value)
      .map((e) => e.key)
      .toSet();

  Future<void> setProfile({String? newName, String? newVehicle}) async {
    if (newName != null) {
      name = newName;
      await StorageService.write('name', name);
    }
    if (newVehicle != null) {
      vehicle = newVehicle;
      await StorageService.write('vehicle', vehicle);
    }
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    onboardingDone = true;
    await StorageService.write('onboardingDone', true);
    notifyListeners();
  }

  Future<void> setIntervention(InterventionType t, bool value) async {
    interventionEnabled[t] = value;
    await StorageService.write('int_${t.name}', value);
    notifyListeners();
  }

  Future<void> setVoiceAlerts(bool v) async {
    voiceAlerts = v;
    await StorageService.write('voiceAlerts', v);
    notifyListeners();
  }

  Future<void> setHapticAlerts(bool v) async {
    hapticAlerts = v;
    await StorageService.write('hapticAlerts', v);
    notifyListeners();
  }

  Future<void> setSensitivity(double v) async {
    sensitivity = v;
    await StorageService.write('sensitivity', v);
    notifyListeners();
  }

  Future<void> setAutoMusic(bool v) async {
    autoMusic = v;
    await StorageService.write('autoMusic', v);
    notifyListeners();
  }
}
