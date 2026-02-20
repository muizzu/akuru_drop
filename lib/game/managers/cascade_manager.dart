import 'dart:math';
import '../models/tile_type.dart';
import '../../config/constants.dart';

class CascadeResult {
  final List<TileFall> falls;
  final List<TileSpawn> spawns;

  const CascadeResult({required this.falls, required this.spawns});
}

class TileFall {
  final int fromRow;
  final int fromCol;
  final int toRow;
  final int toCol;

  const TileFall({
    required this.fromRow,
    required this.fromCol,
    required this.toRow,
    required this.toCol,
  });
}

class TileSpawn {
  final int row;
  final int col;
  final TileState state;

  const TileSpawn({
    required this.row,
    required this.col,
    required this.state,
  });
}

class CascadeManager {
  final Random _random = Random();

  CascadeResult applyCascade(
    List<List<TileState>> grid,
    List<ThaanaLetter> availableLetters,
  ) {
    final falls = <TileFall>[];
    final spawns = <TileSpawn>[];

    for (int c = 0; c < kBoardWidth; c++) {
      // Process each column bottom to top
      int writeRow = kBoardHeight - 1;

      // First, find the bottom-most non-empty tile and fill down
      for (int r = kBoardHeight - 1; r >= 0; r--) {
        if (!grid[r][c].isEmpty && grid[r][c].letter != null) {
          if (r != writeRow) {
            // Move tile down
            falls.add(TileFall(
              fromRow: r,
              fromCol: c,
              toRow: writeRow,
              toCol: c,
            ));
            grid[writeRow][c] = grid[r][c].copy();
            grid[r][c] = TileState(isEmpty: false, letter: null);
          }
          writeRow--;
        }
      }

      // Fill remaining empty slots from the top with new tiles
      for (int r = writeRow; r >= 0; r--) {
        final newLetter = availableLetters[_random.nextInt(availableLetters.length)];
        final newState = TileState(letter: newLetter);
        grid[r][c] = newState;
        spawns.add(TileSpawn(row: r, col: c, state: newState));
      }
    }

    return CascadeResult(falls: falls, spawns: spawns);
  }

  void shuffleBoard(
    List<List<TileState>> grid,
    List<ThaanaLetter> availableLetters,
  ) {
    for (int r = 0; r < kBoardHeight; r++) {
      for (int c = 0; c < kBoardWidth; c++) {
        if (grid[r][c].blocker != BlockerType.none) continue;
        if (grid[r][c].isEmpty) continue;
        grid[r][c].letter = availableLetters[_random.nextInt(availableLetters.length)];
        grid[r][c].special = SpecialTileType.none;
      }
    }
  }

  bool processDropItems(List<List<TileState>> grid) {
    bool anyDropped = false;

    for (int c = 0; c < kBoardWidth; c++) {
      for (int r = kBoardHeight - 2; r >= 0; r--) {
        if (grid[r][c].hasDropItem) {
          // Check if tile below is empty or was just cleared
          if (r + 1 < kBoardHeight && grid[r + 1][c].letter == null) {
            grid[r + 1][c].hasDropItem = true;
            grid[r][c].hasDropItem = false;
            anyDropped = true;
          }
        }
      }
    }
    return anyDropped;
  }

  int countDroppedItems(List<List<TileState>> grid) {
    int count = 0;
    for (int c = 0; c < kBoardWidth; c++) {
      if (grid[kBoardHeight - 1][c].hasDropItem) {
        count++;
        grid[kBoardHeight - 1][c].hasDropItem = false;
      }
    }
    return count;
  }
}
