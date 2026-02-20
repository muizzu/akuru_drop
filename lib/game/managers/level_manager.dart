import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import '../models/level_data.dart';
import '../models/tile_type.dart';
import '../models/objective.dart';
import '../../config/constants.dart';

class LevelManager {
  final Map<int, LevelData> _levels = {};
  bool _loaded = false;

  Future<void> loadLevels() async {
    if (_loaded) return;

    try {
      final jsonStr = await rootBundle.loadString('assets/levels/levels.json');
      final List<dynamic> jsonList = json.decode(jsonStr) as List<dynamic>;
      for (final item in jsonList) {
        final level = LevelData.fromJson(item as Map<String, dynamic>);
        _levels[level.levelNumber] = level;
      }
    } catch (e) {
      // Generate default levels if JSON not found
      _generateDefaultLevels();
    }
    _loaded = true;
  }

  LevelData? getLevel(int levelNumber) => _levels[levelNumber];

  int get totalLevels => _levels.length;

  void _generateDefaultLevels() {
    final random = Random(42); // Fixed seed for reproducibility

    for (int i = 1; i <= 160; i++) {
      final letters = ThaanaLetter.forLevel(i);
      final moveLimit = _movesForLevel(i);
      final targetScore = _scoreTargetForLevel(i);

      LevelObjective objective;
      List<BlockerPosition> blockers = [];
      List<DropItemPosition> dropItems = [];

      // Determine objective type based on level
      if (i <= 5) {
        // Pure score levels for tutorial
        objective = LevelObjective.score(target: targetScore, moves: moveLimit);
      } else if (i % 5 == 0 && i > 10) {
        // Every 5th level after 10: drop items
        final dropCount = 1 + (i ~/ 30);
        dropItems = _generateDropItemPositions(dropCount, random);
        objective = LevelObjective.dropItems(count: dropCount, moves: moveLimit);
      } else if (i % 3 == 0 && i > 5) {
        // Every 3rd level: clear specific letters
        final numLetterTypes = 1 + (i ~/ 40);
        final targets = <ThaanaLetter, int>{};
        for (int t = 0; t < numLetterTypes && t < letters.length; t++) {
          targets[letters[random.nextInt(letters.length)]] = 10 + (i ~/ 5) * 2;
        }
        objective = LevelObjective.clearLetters(targets: targets, moves: moveLimit);
      } else if (i > 30 && i % 7 == 0) {
        // Timed levels after level 30
        objective = LevelObjective.timed(
          target: targetScore,
          seconds: 60 + (i ~/ 10) * 10,
        );
      } else {
        objective = LevelObjective.score(target: targetScore, moves: moveLimit);
      }

      // Add blockers for higher levels
      if (i > 10) {
        blockers = _generateBlockers(i, random);
      }

      _levels[i] = LevelData(
        levelNumber: i,
        objective: objective,
        availableLetters: letters,
        star1Score: targetScore,
        blockers: blockers,
        dropItems: dropItems,
      );
    }
  }

  int _movesForLevel(int level) {
    if (level <= 5) return 30;
    if (level <= 20) return 25;
    if (level <= 50) return 22;
    if (level <= 100) return 20;
    return 18;
  }

  int _scoreTargetForLevel(int level) {
    if (level <= 5) return 1000 + level * 200;
    if (level <= 20) return 2000 + level * 300;
    if (level <= 50) return 5000 + level * 400;
    if (level <= 100) return 10000 + level * 500;
    return 15000 + level * 600;
  }

  List<BlockerPosition> _generateBlockers(int level, Random random) {
    final blockers = <BlockerPosition>[];
    final numBlockers = (level ~/ 15).clamp(0, 8);

    for (int i = 0; i < numBlockers; i++) {
      final row = random.nextInt(kBoardHeight);
      final col = random.nextInt(kBoardWidth);

      BlockerType type;
      if (level < 25) {
        type = BlockerType.ice;
      } else if (level < 50) {
        type = random.nextBool() ? BlockerType.ice : BlockerType.coral;
      } else {
        final r = random.nextInt(3);
        type = r == 0
            ? BlockerType.ice
            : r == 1
                ? BlockerType.coral
                : BlockerType.chain;
      }

      blockers.add(BlockerPosition(row: row, col: col, type: type));
    }
    return blockers;
  }

  List<DropItemPosition> _generateDropItemPositions(int count, Random random) {
    final positions = <DropItemPosition>[];
    final used = <String>{};

    for (int i = 0; i < count; i++) {
      int row, col;
      do {
        row = random.nextInt(3); // Top 3 rows
        col = random.nextInt(kBoardWidth);
      } while (used.contains('$row,$col'));
      used.add('$row,$col');
      positions.add(DropItemPosition(row: row, col: col));
    }
    return positions;
  }
}
