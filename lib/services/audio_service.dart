import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'storage_service.dart';

enum SfxType {
  tileSwap,
  tileMatch,
  tileLand,
  combo,
  specialCreate,
  specialActivate,
  levelComplete,
  levelFail,
  buttonTap,
  starEarn,
}

class AudioService {
  final StorageService _storage;
  bool _musicPlaying = false;

  AudioService(this._storage);

  bool get soundOn => _storage.soundOn;
  bool get musicOn => _storage.musicOn;

  Future<void> init() async {
    // Pre-cache audio files
    try {
      await FlameAudio.audioCache.loadAll([
        'sfx/tile_swap.mp3',
        'sfx/tile_match.mp3',
        'sfx/tile_land.mp3',
        'sfx/combo.mp3',
        'sfx/special_create.mp3',
        'sfx/special_activate.mp3',
        'sfx/level_complete.mp3',
        'sfx/level_fail.mp3',
        'sfx/button_tap.mp3',
        'sfx/star_earn.mp3',
      ]);
    } catch (e) {
      debugPrint('Audio preload skipped (files may be missing): $e');
    }
  }

  void playSfx(SfxType type) {
    if (!soundOn) return;

    final file = switch (type) {
      SfxType.tileSwap => 'sfx/tile_swap.mp3',
      SfxType.tileMatch => 'sfx/tile_match.mp3',
      SfxType.tileLand => 'sfx/tile_land.mp3',
      SfxType.combo => 'sfx/combo.mp3',
      SfxType.specialCreate => 'sfx/special_create.mp3',
      SfxType.specialActivate => 'sfx/special_activate.mp3',
      SfxType.levelComplete => 'sfx/level_complete.mp3',
      SfxType.levelFail => 'sfx/level_fail.mp3',
      SfxType.buttonTap => 'sfx/button_tap.mp3',
      SfxType.starEarn => 'sfx/star_earn.mp3',
    };

    try {
      FlameAudio.play(file, volume: 0.5);
    } catch (e) {
      debugPrint('SFX play failed: $e');
    }
  }

  Future<void> startMusic() async {
    if (!musicOn || _musicPlaying) return;
    try {
      await FlameAudio.bgm.play('music/background.mp3', volume: 0.3);
      _musicPlaying = true;
    } catch (e) {
      debugPrint('Music play failed: $e');
    }
  }

  Future<void> stopMusic() async {
    try {
      FlameAudio.bgm.stop();
      _musicPlaying = false;
    } catch (e) {
      debugPrint('Music stop failed: $e');
    }
  }

  Future<void> toggleSound() async {
    await _storage.setSoundOn(!soundOn);
  }

  Future<void> toggleMusic() async {
    await _storage.setMusicOn(!musicOn);
    if (musicOn) {
      await startMusic();
    } else {
      await stopMusic();
    }
  }

  Future<void> pauseMusic() async {
    if (_musicPlaying) {
      FlameAudio.bgm.pause();
    }
  }

  Future<void> resumeMusic() async {
    if (_musicPlaying && musicOn) {
      FlameAudio.bgm.resume();
    }
  }

  void dispose() {
    FlameAudio.bgm.stop();
    FlameAudio.bgm.dispose();
  }
}
