import 'package:flutter_test/flutter_test.dart';
import 'package:akuru_drop/game/managers/match_manager.dart';
import 'package:akuru_drop/game/managers/score_manager.dart';
import 'package:akuru_drop/game/models/tile_type.dart';
import 'package:akuru_drop/config/constants.dart';

void main() {
  group('MatchManager', () {
    late MatchManager matchManager;

    setUp(() {
      matchManager = MatchManager();
    });

    test('detects horizontal match of 3', () {
      final grid = List.generate(
        kBoardHeight,
        (r) => List.generate(kBoardWidth, (c) => TileState()),
      );
      // Place 3 of the same letter in a row
      grid[0][0].letter = ThaanaLetter.haa;
      grid[0][1].letter = ThaanaLetter.haa;
      grid[0][2].letter = ThaanaLetter.haa;
      // Fill rest with different letter
      for (int r = 0; r < kBoardHeight; r++) {
        for (int c = 0; c < kBoardWidth; c++) {
          if (grid[r][c].letter == null) {
            grid[r][c].letter = ThaanaLetter.baa;
          }
        }
      }

      final matches = matchManager.findMatches(grid);
      expect(matches.isNotEmpty, true);
      expect(matches.first.positions.length, 3);
    });

    test('detects vertical match of 3', () {
      final grid = List.generate(
        kBoardHeight,
        (r) => List.generate(kBoardWidth, (c) => TileState()),
      );
      grid[0][0].letter = ThaanaLetter.noonu;
      grid[1][0].letter = ThaanaLetter.noonu;
      grid[2][0].letter = ThaanaLetter.noonu;
      for (int r = 0; r < kBoardHeight; r++) {
        for (int c = 0; c < kBoardWidth; c++) {
          if (grid[r][c].letter == null) {
            grid[r][c].letter = ThaanaLetter.raa;
          }
        }
      }

      final matches = matchManager.findMatches(grid);
      expect(matches.isNotEmpty, true);
    });

    test('no match when less than 3 in a row', () {
      final grid = List.generate(
        kBoardHeight,
        (r) => List.generate(kBoardWidth, (c) => TileState()),
      );
      // Alternate letters so no 3 in a row
      for (int r = 0; r < kBoardHeight; r++) {
        for (int c = 0; c < kBoardWidth; c++) {
          grid[r][c].letter = (r + c) % 2 == 0
              ? ThaanaLetter.haa
              : ThaanaLetter.baa;
        }
      }

      final matches = matchManager.findMatches(grid);
      expect(matches.isEmpty, true);
    });
  });

  group('ScoreManager', () {
    late ScoreManager scoreManager;

    setUp(() {
      scoreManager = ScoreManager();
    });

    test('starts with zero score', () {
      expect(scoreManager.score, 0);
    });

    test('increments moves', () {
      scoreManager.incrementMoves();
      scoreManager.incrementMoves();
      expect(scoreManager.movesUsed, 2);
    });

    test('combo multiplier increases with chain', () {
      scoreManager.startChain();
      expect(scoreManager.comboMultiplier, 1.0);
      scoreManager.addChainStep();
      expect(scoreManager.comboMultiplier, 1.0);
      scoreManager.addChainStep();
      expect(scoreManager.comboMultiplier, 2.0);
    });
  });

  group('ThaanaLetter', () {
    test('forLevel returns correct number of letters', () {
      expect(ThaanaLetter.forLevel(1).length, 6);
      expect(ThaanaLetter.forLevel(10).length, 8);
      expect(ThaanaLetter.forLevel(25).length, 10);
      expect(ThaanaLetter.forLevel(50).length, 12);
      expect(ThaanaLetter.forLevel(80).length, 12);
      expect(ThaanaLetter.forLevel(120).length, 24);
    });

    test('each letter has unique letter character', () {
      final letters = ThaanaLetter.values.map((l) => l.letter).toSet();
      expect(letters.length, ThaanaLetter.values.length);
    });
  });
}
