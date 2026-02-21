import '../models/tile_type.dart';
import '../../config/constants.dart';

class MatchResult {
  final List<TilePosition> positions;
  final SpecialTileType? createdSpecial;
  final TilePosition? specialPosition;
  final int score;

  const MatchResult({
    required this.positions,
    this.createdSpecial,
    this.specialPosition,
    required this.score,
  });

  int get length => positions.length;
}

class TilePosition {
  final int row;
  final int col;

  const TilePosition(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TilePosition && row == other.row && col == other.col;

  @override
  int get hashCode => row.hashCode ^ (col.hashCode * 31);

  @override
  String toString() => 'TilePosition($row, $col)';
}

class MatchManager {
  List<MatchResult> findMatches(List<List<TileState>> grid) {
    final matches = <MatchResult>[];
    final matched = <TilePosition>{};

    // Find all horizontal runs
    final hRuns = _findHorizontalRuns(grid);
    // Find all vertical runs
    final vRuns = _findVerticalRuns(grid);

    // Check for L/T shapes by finding intersections
    final ltMatches = _findLTMatches(hRuns, vRuns, grid);

    // Add L/T matches first (they have priority)
    for (final lt in ltMatches) {
      matches.add(lt);
      for (final pos in lt.positions) {
        matched.add(pos);
      }
    }

    // Add remaining horizontal runs not consumed by L/T matches
    for (final run in hRuns) {
      final positions = run.where((p) => !matched.contains(p)).toList();
      if (positions.length >= 3) {
        // Check if original run had enough for special
        final special = _specialForRun(run, true);
        final specialPos = run.isNotEmpty ? run[run.length ~/ 2] : null;
        matches.add(MatchResult(
          positions: run,
          createdSpecial: special,
          specialPosition: specialPos,
          score: _scoreForMatch(run.length, special),
        ));
        for (final pos in run) {
          matched.add(pos);
        }
      }
    }

    // Add remaining vertical runs
    for (final run in vRuns) {
      final positions = run.where((p) => !matched.contains(p)).toList();
      if (positions.length >= 3) {
        final special = _specialForRun(run, false);
        final specialPos = run.isNotEmpty ? run[run.length ~/ 2] : null;
        matches.add(MatchResult(
          positions: run,
          createdSpecial: special,
          specialPosition: specialPos,
          score: _scoreForMatch(run.length, special),
        ));
        for (final pos in run) {
          matched.add(pos);
        }
      }
    }

    return matches;
  }

  List<List<TilePosition>> _findHorizontalRuns(List<List<TileState>> grid) {
    final runs = <List<TilePosition>>[];

    for (int r = 0; r < kBoardHeight; r++) {
      int c = 0;
      while (c < kBoardWidth) {
        if (!grid[r][c].isMatchable || grid[r][c].letter == null) {
          c++;
          continue;
        }

        final letter = grid[r][c].letter!;
        final run = <TilePosition>[TilePosition(r, c)];

        int nc = c + 1;
        while (nc < kBoardWidth &&
            grid[r][nc].isMatchable &&
            grid[r][nc].letter == letter) {
          run.add(TilePosition(r, nc));
          nc++;
        }

        if (run.length >= 3) {
          runs.add(run);
        }
        c = nc;
      }
    }
    return runs;
  }

  List<List<TilePosition>> _findVerticalRuns(List<List<TileState>> grid) {
    final runs = <List<TilePosition>>[];

    for (int c = 0; c < kBoardWidth; c++) {
      int r = 0;
      while (r < kBoardHeight) {
        if (!grid[r][c].isMatchable || grid[r][c].letter == null) {
          r++;
          continue;
        }

        final letter = grid[r][c].letter!;
        final run = <TilePosition>[TilePosition(r, c)];

        int nr = r + 1;
        while (nr < kBoardHeight &&
            grid[nr][c].isMatchable &&
            grid[nr][c].letter == letter) {
          run.add(TilePosition(nr, c));
          nr++;
        }

        if (run.length >= 3) {
          runs.add(run);
        }
        r = nr;
      }
    }
    return runs;
  }

  List<MatchResult> _findLTMatches(
    List<List<TilePosition>> hRuns,
    List<List<TilePosition>> vRuns,
    List<List<TileState>> grid,
  ) {
    final results = <MatchResult>[];
    final usedH = <int>{};
    final usedV = <int>{};

    for (int hi = 0; hi < hRuns.length; hi++) {
      for (int vi = 0; vi < vRuns.length; vi++) {
        if (usedH.contains(hi) || usedV.contains(vi)) continue;

        final hRun = hRuns[hi];
        final vRun = vRuns[vi];

        // Check if same letter
        final hLetter = grid[hRun[0].row][hRun[0].col].letter;
        final vLetter = grid[vRun[0].row][vRun[0].col].letter;
        if (hLetter != vLetter) continue;

        // Find intersection
        TilePosition? intersection;
        for (final hp in hRun) {
          for (final vp in vRun) {
            if (hp == vp) {
              intersection = hp;
              break;
            }
          }
          if (intersection != null) break;
        }

        if (intersection != null) {
          final combined = <TilePosition>{...hRun, ...vRun}.toList();
          usedH.add(hi);
          usedV.add(vi);
          results.add(MatchResult(
            positions: combined,
            createdSpecial: SpecialTileType.bomb,
            specialPosition: intersection,
            score: kBaseLTMatchScore,
          ));
        }
      }
    }

    return results;
  }

  SpecialTileType? _specialForRun(List<TilePosition> run, bool horizontal) {
    if (run.length == 4) {
      return horizontal ? SpecialTileType.lineHorizontal : SpecialTileType.lineVertical;
    }
    if (run.length >= 5) {
      return SpecialTileType.star;
    }
    return null;
  }

  int _scoreForMatch(int length, SpecialTileType? special) {
    if (special == SpecialTileType.bomb) return kBaseLTMatchScore;
    if (length >= 5) return kBaseMatch5Score;
    if (length == 4) return kBaseMatch4Score;
    return kBaseMatch3Score;
  }

  bool isValidSwap(
    List<List<TileState>> grid,
    int r1,
    int c1,
    int r2,
    int c2,
  ) {
    // Check adjacency
    final dr = (r1 - r2).abs();
    final dc = (c1 - c2).abs();
    if (dr + dc != 1) return false;

    // Check swappability
    if (!grid[r1][c1].isSwappable || !grid[r2][c2].isSwappable) return false;

    // Star tile can swap with anything
    if (grid[r1][c1].special == SpecialTileType.star ||
        grid[r2][c2].special == SpecialTileType.star) {
      return true;
    }

    // Try swap and check for matches
    final temp = grid[r1][c1].letter;
    grid[r1][c1].letter = grid[r2][c2].letter;
    grid[r2][c2].letter = temp;

    final matches = findMatches(grid);

    // Swap back
    grid[r2][c2].letter = grid[r1][c1].letter;
    grid[r1][c1].letter = temp;

    return matches.isNotEmpty;
  }

  bool hasAnyValidMoves(List<List<TileState>> grid) {
    for (int r = 0; r < kBoardHeight; r++) {
      for (int c = 0; c < kBoardWidth; c++) {
        if (!grid[r][c].isSwappable) continue;
        // Check right
        if (c + 1 < kBoardWidth && isValidSwap(grid, r, c, r, c + 1)) return true;
        // Check down
        if (r + 1 < kBoardHeight && isValidSwap(grid, r, c, r + 1, c)) return true;
      }
    }
    return false;
  }

  TilePosition? findHint(List<List<TileState>> grid) {
    for (int r = 0; r < kBoardHeight; r++) {
      for (int c = 0; c < kBoardWidth; c++) {
        if (!grid[r][c].isSwappable) continue;
        if (c + 1 < kBoardWidth && isValidSwap(grid, r, c, r, c + 1)) {
          return TilePosition(r, c);
        }
        if (r + 1 < kBoardHeight && isValidSwap(grid, r, c, r + 1, c)) {
          return TilePosition(r, c);
        }
      }
    }
    return null;
  }
}
