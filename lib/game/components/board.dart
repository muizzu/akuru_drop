import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../models/tile_type.dart';
import '../models/level_data.dart';
import '../models/objective.dart';
import '../managers/match_manager.dart';
import '../managers/cascade_manager.dart';
import '../managers/score_manager.dart';
import '../managers/word_bonus_manager.dart';
import '../effects/particle_effects.dart';
import 'tile.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';

enum BoardState {
  idle,
  swapping,
  matching,
  cascading,
  animating,
}

class GameBoard extends PositionComponent with TapCallbacks, DragCallbacks {
  final LevelData levelData;
  final ScoreManager scoreManager;
  final WordBonusManager wordBonusManager;
  final MatchManager _matchManager = MatchManager();
  final CascadeManager _cascadeManager = CascadeManager();
  final Random _random = Random();

  late List<List<TileState>> grid;
  late List<List<GameTile?>> tileComponents;

  BoardState _state = BoardState.idle;
  int? _selectedRow;
  int? _selectedCol;
  Vector2? _dragStart;
  int _movesRemaining = 0;
  double _timeRemaining = 0;
  bool _levelComplete = false;
  bool _levelFailed = false;
  bool _singleRemoveMode = false;

  // Callbacks
  void Function(int score)? onScoreChanged;
  void Function(int movesLeft)? onMovesChanged;
  void Function(double timeLeft)? onTimeChanged;
  void Function(int combo)? onCombo;
  void Function(int score, int stars)? onLevelComplete;
  void Function()? onLevelFailed;
  void Function(String word, int multiplier)? onWordBonus;
  void Function()? onNoMoreMoves;

  // Objective tracking
  final Map<ThaanaLetter, int> _lettersClearedForObjective = {};
  int _itemsDroppedForObjective = 0;

  GameBoard({
    required this.levelData,
    required this.scoreManager,
    required this.wordBonusManager,
    super.position,
  }) : super(
          size: Vector2(
            kBoardWidth * (kTileSize + kTileSpacing) + kBoardPadding * 2,
            kBoardHeight * (kTileSize + kTileSpacing) + kBoardPadding * 2,
          ),
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _initBoard();
  }

  void _initBoard() {
    grid = List.generate(
      kBoardHeight,
      (r) => List.generate(kBoardWidth, (c) => TileState()),
    );
    tileComponents = List.generate(
      kBoardHeight,
      (r) => List.generate(kBoardWidth, (c) => null),
    );

    _movesRemaining = levelData.objective.moveLimit;
    if (levelData.objective.type == ObjectiveType.timed) {
      _timeRemaining = levelData.objective.timeLimit.toDouble();
    }

    // Apply blockers
    for (final blocker in levelData.blockers) {
      if (blocker.row < kBoardHeight && blocker.col < kBoardWidth) {
        grid[blocker.row][blocker.col].blocker = blocker.type;
        if (blocker.type == BlockerType.ice) {
          grid[blocker.row][blocker.col].iceHealth = 2;
        }
      }
    }

    // Apply drop items
    for (final item in levelData.dropItems) {
      if (item.row < kBoardHeight && item.col < kBoardWidth) {
        grid[item.row][item.col].hasDropItem = true;
      }
    }

    // Fill board ensuring no initial matches
    _fillBoardWithoutMatches();

    // Create tile components
    for (int r = 0; r < kBoardHeight; r++) {
      for (int c = 0; c < kBoardWidth; c++) {
        _createTileComponent(r, c);
      }
    }

    scoreManager.reset();
  }

  void _fillBoardWithoutMatches() {
    final letters = levelData.availableLetters;

    for (int r = 0; r < kBoardHeight; r++) {
      for (int c = 0; c < kBoardWidth; c++) {
        if (grid[r][c].isEmpty) continue;

        ThaanaLetter letter;
        int attempts = 0;
        do {
          letter = letters[_random.nextInt(letters.length)];
          grid[r][c].letter = letter;
          attempts++;
        } while (_wouldCreateMatch(r, c) && attempts < 50);
      }
    }
  }

  bool _wouldCreateMatch(int r, int c) {
    final letter = grid[r][c].letter;
    if (letter == null) return false;

    // Check horizontal
    if (c >= 2 &&
        grid[r][c - 1].letter == letter &&
        grid[r][c - 2].letter == letter) {
      return true;
    }

    // Check vertical
    if (r >= 2 &&
        grid[r - 1][c].letter == letter &&
        grid[r - 2][c].letter == letter) {
      return true;
    }

    return false;
  }

  void _createTileComponent(int r, int c) {
    final tile = GameTile(
      state: grid[r][c],
      row: r,
      col: c,
      position: _tilePosition(r, c),
    );
    tileComponents[r][c] = tile;
    add(tile);
  }

  Vector2 _tilePosition(int r, int c) {
    return Vector2(
      c * (kTileSize + kTileSpacing) + kBoardPadding,
      r * (kTileSize + kTileSpacing) + kBoardPadding,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_levelComplete || _levelFailed) return;

    // Timer for timed levels
    if (levelData.objective.type == ObjectiveType.timed && _state == BoardState.idle) {
      _timeRemaining -= dt;
      onTimeChanged?.call(_timeRemaining);
      if (_timeRemaining <= 0) {
        _timeRemaining = 0;
        _checkLevelEnd();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    // Draw board background
    final boardRect = Rect.fromLTWH(0, 0, size.x, size.y);
    final rrect = RRect.fromRectAndRadius(boardRect, const Radius.circular(12));
    final paint = Paint()..color = const Color(0xFF0D1F3C);
    canvas.drawRRect(rrect, paint);

    // Draw grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFF1A3050)
      ..strokeWidth = 1;
    for (int r = 0; r <= kBoardHeight; r++) {
      final y = r * (kTileSize + kTileSpacing) + kBoardPadding;
      canvas.drawLine(
        Offset(kBoardPadding, y),
        Offset(size.x - kBoardPadding, y),
        gridPaint,
      );
    }
    for (int c = 0; c <= kBoardWidth; c++) {
      final x = c * (kTileSize + kTileSpacing) + kBoardPadding;
      canvas.drawLine(
        Offset(x, kBoardPadding),
        Offset(x, size.y - kBoardPadding),
        gridPaint,
      );
    }

    super.render(canvas);
  }

  // Input handling
  TilePosition? _positionFromLocal(Vector2 local) {
    final col = ((local.x - kBoardPadding) / (kTileSize + kTileSpacing)).floor();
    final row = ((local.y - kBoardPadding) / (kTileSize + kTileSpacing)).floor();

    if (row >= 0 && row < kBoardHeight && col >= 0 && col < kBoardWidth) {
      return TilePosition(row, col);
    }
    return null;
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (_state != BoardState.idle) return;
    if (_levelComplete || _levelFailed) return;

    final pos = _positionFromLocal(event.localPosition);
    if (pos == null) return;

    // Single remove mode
    if (_singleRemoveMode) {
      _removeSingleTile(pos.row, pos.col);
      return;
    }

    if (_selectedRow != null && _selectedCol != null) {
      // Check if tapped adjacent to selected
      final dr = (pos.row - _selectedRow!).abs();
      final dc = (pos.col - _selectedCol!).abs();
      if (dr + dc == 1) {
        _attemptSwap(_selectedRow!, _selectedCol!, pos.row, pos.col);
      } else {
        _selectTile(pos.row, pos.col);
      }
    } else {
      _selectTile(pos.row, pos.col);
    }
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (_state != BoardState.idle) return;
    if (_levelComplete || _levelFailed) return;

    final pos = _positionFromLocal(event.localPosition);
    if (pos == null) return;
    _dragStart = Vector2.zero();
    _selectTile(pos.row, pos.col);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _dragStart = null;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (_state != BoardState.idle || _selectedRow == null || _dragStart == null) return;

    _dragStart!.add(event.localDelta);
    final delta = _dragStart!;
    if (delta.length < kTileSize * 0.3) return;

    int dr = 0, dc = 0;
    if (delta.x.abs() > delta.y.abs()) {
      dc = delta.x > 0 ? 1 : -1;
    } else {
      dr = delta.y > 0 ? 1 : -1;
    }

    final targetRow = _selectedRow! + dr;
    final targetCol = _selectedCol! + dc;

    if (targetRow >= 0 &&
        targetRow < kBoardHeight &&
        targetCol >= 0 &&
        targetCol < kBoardWidth) {
      _attemptSwap(_selectedRow!, _selectedCol!, targetRow, targetCol);
    }
    _dragStart = null;
  }

  void _selectTile(int row, int col) {
    // Deselect previous
    if (_selectedRow != null && _selectedCol != null) {
      tileComponents[_selectedRow!][_selectedCol!]?.isSelected = false;
    }

    if (grid[row][col].isSwappable && grid[row][col].letter != null) {
      _selectedRow = row;
      _selectedCol = col;
      tileComponents[row][col]?.isSelected = true;
    } else {
      _selectedRow = null;
      _selectedCol = null;
    }
  }

  void _deselectAll() {
    if (_selectedRow != null && _selectedCol != null) {
      tileComponents[_selectedRow!][_selectedCol!]?.isSelected = false;
    }
    _selectedRow = null;
    _selectedCol = null;
  }

  // Swap logic
  Future<void> _attemptSwap(int r1, int c1, int r2, int c2) async {
    if (_state != BoardState.idle) return;

    // Check if star tile interaction
    final isStarSwap = grid[r1][c1].special == SpecialTileType.star ||
        grid[r2][c2].special == SpecialTileType.star;

    if (!isStarSwap && !_matchManager.isValidSwap(grid, r1, c1, r2, c2)) {
      // Invalid swap - animate bounce back
      _state = BoardState.swapping;
      await _animateSwap(r1, c1, r2, c2);
      await Future.delayed(const Duration(milliseconds: 100));
      await _animateSwap(r2, c2, r1, c1);
      _state = BoardState.idle;
      _deselectAll();
      return;
    }

    _state = BoardState.swapping;
    _deselectAll();

    // Perform swap
    await _animateSwap(r1, c1, r2, c2);
    _swapTileState(r1, c1, r2, c2);

    // Handle star tile activation
    if (isStarSwap) {
      await _handleStarActivation(r1, c1, r2, c2);
    }

    // Consume a move
    _movesRemaining--;
    scoreManager.incrementMoves();
    onMovesChanged?.call(_movesRemaining);

    // Process matches and cascades
    scoreManager.startChain();
    await _processMatchesAndCascades();

    // Check level end conditions
    _checkLevelEnd();

    // Check for valid moves
    if (_state != BoardState.idle) return;
    if (!_matchManager.hasAnyValidMoves(grid)) {
      onNoMoreMoves?.call();
      _cascadeManager.shuffleBoard(grid, levelData.availableLetters);
      _rebuildTileComponents();

      // If still no moves after shuffle, shuffle again
      int shuffleAttempts = 0;
      while (!_matchManager.hasAnyValidMoves(grid) && shuffleAttempts < 10) {
        _cascadeManager.shuffleBoard(grid, levelData.availableLetters);
        shuffleAttempts++;
      }
      _rebuildTileComponents();
    }
  }

  Future<void> _animateSwap(int r1, int c1, int r2, int c2) async {
    final tile1 = tileComponents[r1][c1];
    final tile2 = tileComponents[r2][c2];

    final pos1 = _tilePosition(r1, c1);
    final pos2 = _tilePosition(r2, c2);

    final futures = <Future>[];
    if (tile1 != null) {
      final completer = _FutureCompleter();
      tile1.animateMoveTo(pos2, onComplete: completer.complete);
      futures.add(completer.future);
    }
    if (tile2 != null) {
      final completer = _FutureCompleter();
      tile2.animateMoveTo(pos1, onComplete: completer.complete);
      futures.add(completer.future);
    }
    await Future.wait(futures);
  }

  void _swapTileState(int r1, int c1, int r2, int c2) {
    // Swap grid state
    final temp = grid[r1][c1];
    grid[r1][c1] = grid[r2][c2];
    grid[r2][c2] = temp;

    // Swap tile components
    final tempTile = tileComponents[r1][c1];
    tileComponents[r1][c1] = tileComponents[r2][c2];
    tileComponents[r2][c2] = tempTile;

    // Update tile row/col
    tileComponents[r1][c1]?.row = r1;
    tileComponents[r1][c1]?.col = c1;
    tileComponents[r2][c2]?.row = r2;
    tileComponents[r2][c2]?.col = c2;
  }

  Future<void> _handleStarActivation(int r1, int c1, int r2, int c2) async {
    ThaanaLetter? targetLetter;
    TilePosition starPos;

    if (grid[r1][c1].special == SpecialTileType.star) {
      starPos = TilePosition(r1, c1);
      targetLetter = grid[r2][c2].letter;
    } else {
      starPos = TilePosition(r2, c2);
      targetLetter = grid[r1][c1].letter;
    }

    if (targetLetter == null) return;

    // Clear all tiles of target letter type
    add(ParticleEffects.starActivateEffect(_tilePosition(starPos.row, starPos.col) + Vector2.all(kTileSize / 2)));

    final toClear = <TilePosition>[];
    for (int r = 0; r < kBoardHeight; r++) {
      for (int c = 0; c < kBoardWidth; c++) {
        if (grid[r][c].letter == targetLetter) {
          toClear.add(TilePosition(r, c));
        }
      }
    }
    toClear.add(starPos);

    await _clearTiles(toClear);
    scoreManager.addBonusScore(kBaseMatch5Score * toClear.length);
    onScoreChanged?.call(scoreManager.score);
  }

  // Match processing
  Future<void> _processMatchesAndCascades() async {
    bool hasMatches = true;

    while (hasMatches) {
      _state = BoardState.matching;
      final matches = _matchManager.findMatches(grid);

      if (matches.isEmpty) {
        hasMatches = false;
        _state = BoardState.idle;
        break;
      }

      scoreManager.addChainStep();
      if (scoreManager.comboCount > 1) {
        onCombo?.call(scoreManager.comboCount);
        final center = Vector2(size.x / 2, size.y / 2);
        add(ParticleEffects.comboPopup(center, scoreManager.comboCount));
      }

      // Calculate and add score
      final stepScore = scoreManager.addMatchScore(matches);
      onScoreChanged?.call(scoreManager.score);

      // Collect all positions to clear and handle specials
      final allPositions = <TilePosition>{};
      final specialsToCreate = <TilePosition, SpecialTileType>{};

      for (final match in matches) {
        // Process special tile activations
        for (final pos in match.positions) {
          await _handleSpecialTileActivation(pos, allPositions);
        }

        allPositions.addAll(match.positions);

        // Create special tiles
        if (match.createdSpecial != null && match.specialPosition != null) {
          specialsToCreate[match.specialPosition!] = match.createdSpecial!;
        }
      }

      // Track letters cleared for objectives
      for (final pos in allPositions) {
        final letter = grid[pos.row][pos.col].letter;
        if (letter != null) {
          _lettersClearedForObjective[letter] =
              (_lettersClearedForObjective[letter] ?? 0) + 1;
          scoreManager.recordLetterCleared(letter.letter, 1);
        }
      }

      // Check word bonuses
      final wordBonuses = wordBonusManager.checkForWords(grid, allPositions.toList());
      for (final bonus in wordBonuses) {
        scoreManager.addBonusScore(bonus.bonusScore);
        onWordBonus?.call(bonus.word, bonus.multiplier);
        add(ParticleEffects.wordBonusPopup(
          Vector2(size.x / 2, size.y / 2),
          bonus.word,
          bonus.multiplier,
        ));
      }

      // Show score popup
      if (allPositions.isNotEmpty) {
        final firstPos = allPositions.first;
        add(ParticleEffects.scorePopup(
          _tilePosition(firstPos.row, firstPos.col) + Vector2.all(kTileSize / 2),
          stepScore,
        ));
      }

      // Clear matched tiles with animation
      await _clearTiles(allPositions.toList());

      // Create special tiles in place
      for (final entry in specialsToCreate.entries) {
        final pos = entry.key;
        final specialType = entry.value;
        if (pos.row < kBoardHeight && pos.col < kBoardWidth) {
          grid[pos.row][pos.col] = TileState(
            letter: grid[pos.row][pos.col].letter ?? levelData.availableLetters[0],
            special: specialType,
          );
          // Recreate tile component
          _removeTileComponent(pos.row, pos.col);
          _createTileComponent(pos.row, pos.col);
          tileComponents[pos.row][pos.col]?.animateSpawn();
        }
      }

      // Handle drop items
      _cascadeManager.processDropItems(grid);
      final droppedItems = _cascadeManager.countDroppedItems(grid);
      if (droppedItems > 0) {
        _itemsDroppedForObjective += droppedItems;
        scoreManager.recordItemDropped(droppedItems);
      }

      // Cascade
      _state = BoardState.cascading;
      await _applyCascade();

      // Brief delay before next match check
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<void> _handleSpecialTileActivation(
    TilePosition pos,
    Set<TilePosition> allPositions,
  ) async {
    final tile = grid[pos.row][pos.col];

    switch (tile.special) {
      case SpecialTileType.lineHorizontal:
        add(ParticleEffects.lineClearEffect(
          _tilePosition(pos.row, pos.col) + Vector2.all(kTileSize / 2),
          true,
          size.x,
        ));
        for (int c = 0; c < kBoardWidth; c++) {
          allPositions.add(TilePosition(pos.row, c));
        }
        break;

      case SpecialTileType.lineVertical:
        add(ParticleEffects.lineClearEffect(
          _tilePosition(pos.row, pos.col) + Vector2.all(kTileSize / 2),
          false,
          size.y,
        ));
        for (int r = 0; r < kBoardHeight; r++) {
          allPositions.add(TilePosition(r, pos.col));
        }
        break;

      case SpecialTileType.bomb:
        add(ParticleEffects.bombExplosionEffect(
          _tilePosition(pos.row, pos.col) + Vector2.all(kTileSize / 2),
        ));
        for (int dr = -1; dr <= 1; dr++) {
          for (int dc = -1; dc <= 1; dc++) {
            final nr = pos.row + dr;
            final nc = pos.col + dc;
            if (nr >= 0 && nr < kBoardHeight && nc >= 0 && nc < kBoardWidth) {
              allPositions.add(TilePosition(nr, nc));
            }
          }
        }
        break;

      case SpecialTileType.star:
        // Star handled separately in swap
        break;

      case SpecialTileType.none:
        break;
    }
  }

  Future<void> _clearTiles(List<TilePosition> positions) async {
    final futures = <Future>[];

    for (final pos in positions) {
      if (pos.row >= kBoardHeight || pos.col >= kBoardWidth) continue;

      final tile = grid[pos.row][pos.col];

      // Handle ice blocker
      if (tile.blocker == BlockerType.ice && tile.iceHealth > 1) {
        tile.iceHealth--;
        continue;
      }

      // Handle coral (clear the coral)
      if (tile.blocker == BlockerType.coral) {
        tile.blocker = BlockerType.none;
      }

      // Particle burst
      final color = tile.letter?.color ?? AppTheme.coral;
      add(ParticleEffects.tileBurstEffect(
        _tilePosition(pos.row, pos.col) + Vector2.all(kTileSize / 2),
        color,
      ));

      // Animate clear
      final tileComp = tileComponents[pos.row][pos.col];
      if (tileComp != null) {
        final completer = _FutureCompleter();
        tileComp.animateMatchClear(onComplete: () {
          tileComp.removeFromParent();
          completer.complete();
        });
        futures.add(completer.future);
      }

      // Clear grid state
      grid[pos.row][pos.col] = TileState();
      tileComponents[pos.row][pos.col] = null;
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }

  Future<void> _applyCascade() async {
    final result = _cascadeManager.applyCascade(grid, levelData.availableLetters);

    final futures = <Future>[];

    // Animate falls
    for (final fall in result.falls) {
      final tile = tileComponents[fall.fromRow][fall.fromCol];
      if (tile != null) {
        tileComponents[fall.toRow][fall.toCol] = tile;
        tileComponents[fall.fromRow][fall.fromCol] = null;
        tile.row = fall.toRow;
        tile.col = fall.toCol;
        tile.state = grid[fall.toRow][fall.toCol];

        final delay = (fall.toRow - fall.fromRow) * 0.03;
        final completer = _FutureCompleter();
        tile.animateFallTo(
          _tilePosition(fall.toRow, fall.toCol),
          delay,
          onComplete: completer.complete,
        );
        futures.add(completer.future);
      }
    }

    // Spawn new tiles
    for (final spawn in result.spawns) {
      final startPos = _tilePosition(-1, spawn.col); // Spawn above board
      final endPos = _tilePosition(spawn.row, spawn.col);

      final tile = GameTile(
        state: spawn.state,
        row: spawn.row,
        col: spawn.col,
        position: startPos,
      );
      tileComponents[spawn.row][spawn.col] = tile;
      add(tile);

      final delay = spawn.row * 0.03 + 0.1;
      final completer = _FutureCompleter();
      tile.animateFallTo(endPos, delay, onComplete: completer.complete);
      futures.add(completer.future);
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }

  void _removeTileComponent(int r, int c) {
    tileComponents[r][c]?.removeFromParent();
    tileComponents[r][c] = null;
  }

  void _rebuildTileComponents() {
    // Remove all tile components
    for (int r = 0; r < kBoardHeight; r++) {
      for (int c = 0; c < kBoardWidth; c++) {
        _removeTileComponent(r, c);
      }
    }

    // Recreate all
    for (int r = 0; r < kBoardHeight; r++) {
      for (int c = 0; c < kBoardWidth; c++) {
        _createTileComponent(r, c);
      }
    }
  }

  // Level end checking
  void _checkLevelEnd() {
    if (_levelComplete || _levelFailed) return;

    switch (levelData.objective.type) {
      case ObjectiveType.score:
        if (scoreManager.score >= levelData.objective.targetScore) {
          _completLevel();
        } else if (_movesRemaining <= 0) {
          _failLevel();
        }
        break;

      case ObjectiveType.clearLetters:
        bool allCleared = true;
        for (final entry in levelData.objective.letterTargets.entries) {
          if ((_lettersClearedForObjective[entry.key] ?? 0) < entry.value) {
            allCleared = false;
            break;
          }
        }
        if (allCleared) {
          _completLevel();
        } else if (_movesRemaining <= 0) {
          _failLevel();
        }
        break;

      case ObjectiveType.dropItems:
        if (_itemsDroppedForObjective >= levelData.objective.dropItemCount) {
          _completLevel();
        } else if (_movesRemaining <= 0) {
          _failLevel();
        }
        break;

      case ObjectiveType.timed:
        if (scoreManager.score >= levelData.objective.targetScore) {
          _completLevel();
        } else if (_timeRemaining <= 0) {
          _failLevel();
        }
        break;
    }
  }

  void _completLevel() {
    _levelComplete = true;
    _state = BoardState.idle;

    // Add remaining moves bonus
    if (levelData.objective.type != ObjectiveType.timed) {
      scoreManager.calculateRemainingMovesBonus(_movesRemaining);
    }

    final stars = levelData.starsForScore(scoreManager.score);

    // Confetti
    add(ParticleEffects.confettiEffect(Vector2(size.x / 2, 0)));

    onScoreChanged?.call(scoreManager.score);
    onLevelComplete?.call(scoreManager.score, stars);
  }

  void _failLevel() {
    _levelFailed = false; // Don't set immediately, allow extra moves purchase
    _state = BoardState.idle;
    onLevelFailed?.call();
  }

  // Power-up actions
  void addExtraMoves(int count) {
    _movesRemaining += count;
    _levelFailed = false;
    onMovesChanged?.call(_movesRemaining);
  }

  Future<void> shuffleBoard() async {
    _cascadeManager.shuffleBoard(grid, levelData.availableLetters);
    _rebuildTileComponents();

    // Ensure no initial matches after shuffle
    var matches = _matchManager.findMatches(grid);
    int attempts = 0;
    while (matches.isNotEmpty && attempts < 20) {
      _cascadeManager.shuffleBoard(grid, levelData.availableLetters);
      matches = _matchManager.findMatches(grid);
      attempts++;
    }
    _rebuildTileComponents();
  }

  void setSingleRemoveMode(bool active) {
    _singleRemoveMode = active;
  }

  Future<void> _removeSingleTile(int row, int col) async {
    _singleRemoveMode = false;
    if (grid[row][col].letter == null) return;

    await _clearTiles([TilePosition(row, col)]);
    await _applyCascade();
    await _processMatchesAndCascades();
    _checkLevelEnd();
  }

  // Getters
  int get movesRemaining => _movesRemaining;
  double get timeRemaining => _timeRemaining;
  bool get isLevelComplete => _levelComplete;
  bool get isLevelFailed => _levelFailed;
  Map<ThaanaLetter, int> get lettersClearedForObjective =>
      Map.unmodifiable(_lettersClearedForObjective);
  int get itemsDroppedForObjective => _itemsDroppedForObjective;
}

class _FutureCompleter {
  bool _completed = false;

  late final Future<void> future = Future<void>(() async {
    if (_completed) return;
    await Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 16));
      return !_completed;
    });
  });

  void complete() {
    _completed = true;
  }
}
