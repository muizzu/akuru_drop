import 'package:hive_flutter/hive_flutter.dart';
import '../config/constants.dart';

class StorageService {
  static const String _progressBox = 'progress';
  static const String _settingsBox = 'settings';
  static const String _economyBox = 'economy';

  late Box _progress;
  late Box _settings;
  late Box _economy;

  Future<void> init() async {
    await Hive.initFlutter();
    _progress = await Hive.openBox(_progressBox);
    _settings = await Hive.openBox(_settingsBox);
    _economy = await Hive.openBox(_economyBox);

    if (!_economy.containsKey('coins')) {
      await _economy.put('coins', kStartingCoins);
    }
  }

  // Progress
  int get highestLevelReached => _progress.get('highestLevel', defaultValue: 0) as int;

  Future<void> setHighestLevel(int level) async {
    final current = highestLevelReached;
    if (level > current) {
      await _progress.put('highestLevel', level);
    }
  }

  int getLevelStars(int level) =>
      _progress.get('stars_$level', defaultValue: 0) as int;

  Future<void> setLevelStars(int level, int stars) async {
    final current = getLevelStars(level);
    if (stars > current) {
      await _progress.put('stars_$level', stars);
    }
  }

  int getLevelHighScore(int level) =>
      _progress.get('highscore_$level', defaultValue: 0) as int;

  Future<void> setLevelHighScore(int level, int score) async {
    final current = getLevelHighScore(level);
    if (score > current) {
      await _progress.put('highscore_$level', score);
    }
  }

  int get totalStars {
    int total = 0;
    for (int i = 1; i <= highestLevelReached; i++) {
      total += getLevelStars(i);
    }
    return total;
  }

  // Economy
  int get coins => _economy.get('coins', defaultValue: kStartingCoins) as int;

  Future<void> setCoins(int amount) async {
    await _economy.put('coins', amount);
  }

  Future<void> addCoins(int amount) async {
    await _economy.put('coins', coins + amount);
  }

  Future<bool> spendCoins(int amount) async {
    if (coins >= amount) {
      await _economy.put('coins', coins - amount);
      return true;
    }
    return false;
  }

  DateTime? get lastDailyReward {
    final ms = _economy.get('lastDailyReward') as int?;
    return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

  Future<void> claimDailyReward() async {
    await _economy.put('lastDailyReward', DateTime.now().millisecondsSinceEpoch);
    await addCoins(kDailyLoginCoins);
  }

  bool get canClaimDailyReward {
    final last = lastDailyReward;
    if (last == null) return true;
    final now = DateTime.now();
    return now.year != last.year || now.month != last.month || now.day != last.day;
  }

  // Settings
  bool get soundOn => _settings.get('soundOn', defaultValue: true) as bool;
  Future<void> setSoundOn(bool value) => _settings.put('soundOn', value);

  bool get musicOn => _settings.get('musicOn', defaultValue: true) as bool;
  Future<void> setMusicOn(bool value) => _settings.put('musicOn', value);

  bool get notificationsOn => _settings.get('notificationsOn', defaultValue: true) as bool;
  Future<void> setNotificationsOn(bool value) => _settings.put('notificationsOn', value);

  bool get isDhivehi => _settings.get('isDhivehi', defaultValue: false) as bool;
  Future<void> setIsDhivehi(bool value) => _settings.put('isDhivehi', value);

  int get levelsCompletedSinceAd =>
      _settings.get('levelsCompletedSinceAd', defaultValue: 0) as int;
  Future<void> setLevelsCompletedSinceAd(int value) =>
      _settings.put('levelsCompletedSinceAd', value);

  DateTime? get lastAdTime {
    final ms = _settings.get('lastAdTime') as int?;
    return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

  Future<void> recordAdShown() async {
    await _settings.put('lastAdTime', DateTime.now().millisecondsSinceEpoch);
    await _settings.put('levelsCompletedSinceAd', 0);
  }

  // Power-ups inventory
  int getPowerUpCount(String type) =>
      _economy.get('powerup_$type', defaultValue: 0) as int;

  Future<void> setPowerUpCount(String type, int count) =>
      _economy.put('powerup_$type', count);

  // Reset
  Future<void> resetProgress() async {
    await _progress.clear();
    await _economy.put('coins', kStartingCoins);
  }
}
