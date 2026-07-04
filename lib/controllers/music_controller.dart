import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Muzik kategorileri — KDS mudahale turlerine karsilik gelir.
enum TrackMood { calm, meditation, energetic }

extension TrackMoodX on TrackMood {
  String get labelTr => switch (this) {
        TrackMood.calm => 'Sakinleştirici',
        TrackMood.meditation => 'Meditasyon',
        TrackMood.energetic => 'Enerjik',
      };

  String get description => switch (this) {
        TrackMood.calm => 'Öfke ve gerginlik anları için yumuşak tonlar',
        TrackMood.meditation => 'Nefes egzersizi ve derin rahatlama',
        TrackMood.energetic => 'Yorgunluk hissinde canlandırıcı ritimler',
      };

  String get emoji => switch (this) {
        TrackMood.calm => '🌊',
        TrackMood.meditation => '🧘',
        TrackMood.energetic => '⚡',
      };
}

class MusicTrack {
  final String asset; // assets/audio altindaki dosya
  final String title;
  final String artist;
  final TrackMood mood;

  const MusicTrack(this.asset, this.title, this.artist, this.mood);
}

/// Uygulamaya gomulu telifsiz muzik kutuphanesi.
/// Tum parcalar: Kevin MacLeod (incompetech.com) — CC BY 4.0.
const List<MusicTrack> musicLibrary = [
  MusicTrack('audio/meditation_01.mp3', 'Meditation Impromptu 01',
      'Kevin MacLeod', TrackMood.calm),
  MusicTrack('audio/floating_cities.mp3', 'Floating Cities', 'Kevin MacLeod',
      TrackMood.calm),
  MusicTrack('audio/angel_share.mp3', 'Angel Share', 'Kevin MacLeod',
      TrackMood.calm),
  MusicTrack('audio/meditation_02.mp3', 'Meditation Impromptu 02',
      'Kevin MacLeod', TrackMood.meditation),
  MusicTrack('audio/meditation_03.mp3', 'Meditation Impromptu 03',
      'Kevin MacLeod', TrackMood.meditation),
  MusicTrack('audio/life_of_riley.mp3', 'Life of Riley', 'Kevin MacLeod',
      TrackMood.energetic),
  MusicTrack('audio/carefree.mp3', 'Carefree', 'Kevin MacLeod',
      TrackMood.energetic),
  MusicTrack('audio/upbeat_forever.mp3', 'Upbeat Forever', 'Kevin MacLeod',
      TrackMood.energetic),
];

class MusicController extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  final _rnd = Random();

  MusicTrack? current;
  bool playing = false;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  double volume = 0.8;

  MusicController() {
    _player.onPositionChanged.listen((p) {
      position = p;
      notifyListeners();
    });
    _player.onDurationChanged.listen((d) {
      duration = d;
      notifyListeners();
    });
    _player.onPlayerComplete.listen((_) => next());
  }

  List<MusicTrack> byMood(TrackMood mood) =>
      musicLibrary.where((t) => t.mood == mood).toList();

  Future<void> play(MusicTrack track) async {
    current = track;
    playing = true;
    notifyListeners();
    try {
      await _player.stop();
      await _player.setVolume(volume);
      await _player.play(AssetSource(track.asset));
    } catch (_) {
      playing = false;
      notifyListeners();
    }
  }

  /// KDS mudahalesi: kategoriden rastgele parca baslat.
  Future<void> playMood(TrackMood mood) async {
    final list = byMood(mood);
    if (list.isEmpty) return;
    await play(list[_rnd.nextInt(list.length)]);
  }

  Future<void> toggle() async {
    if (current == null) {
      await playMood(TrackMood.calm);
      return;
    }
    if (playing) {
      await _player.pause();
      playing = false;
    } else {
      await _player.resume();
      playing = true;
    }
    notifyListeners();
  }

  Future<void> next() async {
    if (current == null) return;
    final list = byMood(current!.mood);
    final i = list.indexOf(current!);
    await play(list[(i + 1) % list.length]);
  }

  Future<void> previous() async {
    if (current == null) return;
    final list = byMood(current!.mood);
    final i = list.indexOf(current!);
    await play(list[(i - 1 + list.length) % list.length]);
  }

  Future<void> seek(Duration d) => _player.seek(d);

  Future<void> setVolume(double v) async {
    volume = v.clamp(0.0, 1.0);
    await _player.setVolume(volume);
    notifyListeners();
  }

  Future<void> stop() async {
    await _player.stop();
    playing = false;
    current = null;
    position = Duration.zero;
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
