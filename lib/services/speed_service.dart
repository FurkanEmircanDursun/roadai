import 'dart:async';

import 'package:geolocator/geolocator.dart';

/// GPS tabanli hiz servisi (arac CAN Bus verisinin mobil karsiligi).
class SpeedService {
  StreamSubscription<Position>? _sub;
  double _speedKmh = 0;
  bool _available = false;

  double get speedKmh => _speedKmh;
  bool get available => _available;

  Future<bool> start() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return false;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return false;
      }
      _sub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 3,
        ),
      ).listen((pos) {
        // pos.speed m/s cinsinden
        final kmh = pos.speed * 3.6;
        _speedKmh = kmh.isFinite && kmh >= 0 ? kmh : 0;
      }, onError: (_) {});
      _available = true;
      return true;
    } catch (_) {
      _available = false;
      return false;
    }
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    _available = false;
    _speedKmh = 0;
  }
}
