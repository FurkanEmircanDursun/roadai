import 'package:hive_flutter/hive_flutter.dart';

import '../models/session.dart';

/// Hive tabanli yerel depolama. Tum veriler cihazda kalir (Edge AI / KVKK).
class StorageService {
  static const _settingsBox = 'settings';
  static const _sessionsBox = 'sessions';

  static Future<void> init() async {
    await Hive.initFlutter('roadai');
    await Hive.openBox(_settingsBox);
    await Hive.openBox(_sessionsBox);
  }

  static Box get settings => Hive.box(_settingsBox);
  static Box get _sessions => Hive.box(_sessionsBox);

  // ---- Oturumlar ----
  static Future<void> saveSession(DriveSession s) async {
    await _sessions.put(s.id, s.toMap());
  }

  static List<DriveSession> allSessions() {
    final list = _sessions.values
        .map((v) => DriveSession.fromMap(Map<dynamic, dynamic>.from(v as Map)))
        .toList();
    list.sort((a, b) => b.start.compareTo(a.start));
    return list;
  }

  static List<DriveSession> sessionsSince(DateTime since) =>
      allSessions().where((s) => s.start.isAfter(since)).toList();

  static Future<void> deleteAllData() async {
    await _sessions.clear();
  }

  // ---- Ayarlar ----
  static T read<T>(String key, T fallback) {
    final v = settings.get(key);
    if (v is T) return v;
    return fallback;
  }

  static Future<void> write(String key, dynamic value) async {
    await settings.put(key, value);
  }
}
