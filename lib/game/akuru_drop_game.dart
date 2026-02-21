import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'components/board.dart';
import 'managers/score_manager.dart';
import 'managers/word_bonus_manager.dart';
import 'managers/power_up_manager.dart';
import 'models/level_data.dart';
import '../config/constants.dart';
import '../services/audio_service.dart';

class AkuruDropGame extends FlameGame {
  final LevelData levelData;
  final AudioService audioService;
  final PowerUpManager powerUpManager;
  final ScoreManager scoreManager = ScoreManager();
  final WordBonusManager wordBonusManager = WordBonusManager();

  late GameBoard board;

  // Callbacks for Flutter UI layer
  void Function(int score)? onScoreChanged;
  void Function(int movesLeft)? onMovesChanged;
  void Function(double timeLeft)? onTimeChanged;
  void Function(int combo)? onCombo;
  void Function(int score, int stars)? onLevelComplete;
  void Function()? onLevelFailed;
  void Function(String word, int multiplier)? onWordBonus;

  AkuruDropGame({
    required this.levelData,
    required this.audioService,
    required this.powerUpManager,
  });

  @override
  Color backgroundColor() => const Color(0xFF0A1628);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await wordBonusManager.loadDictionary();

    // Calculate board position to center it
    final boardWidth = kBoardWidth * (kTileSize + kTileSpacing) + kBoardPadding * 2;
    final boardHeight = kBoardHeight * (kTileSize + kTileSpacing) + kBoardPadding * 2;
    final boardX = (size.x - boardWidth) / 2;
    final boardY = (size.y - boardHeight) / 2;

    board = GameBoard(
      levelData: levelData,
      scoreManager: scoreManager,
      wordBonusManager: wordBonusManager,
      position: Vector2(boardX, boardY),
    );

    // Wire up callbacks
    board.onScoreChanged = (score) {
      onScoreChanged?.call(score);
    };
    board.onMovesChanged = (moves) {
      onMovesChanged?.call(moves);
      audioService.playSfx(SfxType.tileSwap);
    };
    board.onTimeChanged = (time) {
      onTimeChanged?.call(time);
    };
    board.onCombo = (combo) {
      onCombo?.call(combo);
      audioService.playSfx(SfxType.combo);
    };
    board.onLevelComplete = (score, stars) {
      audioService.playSfx(SfxType.levelComplete);
      onLevelComplete?.call(score, stars);
    };
    board.onLevelFailed = () {
      audioService.playSfx(SfxType.levelFail);
      onLevelFailed?.call();
    };
    board.onWordBonus = (word, multiplier) {
      onWordBonus?.call(word, multiplier);
    };
    board.onNoMoreMoves = () {
      audioService.playSfx(SfxType.tileSwap);
    };

    add(board);
  }

  // Power-up actions exposed to UI
  Future<void> useExtraMoves() async {
    if (await powerUpManager.useExtraMoves()) {
      board.addExtraMoves(kExtraMoveCount);
    }
  }

  Future<void> useShuffle() async {
    if (await powerUpManager.useShuffle()) {
      await board.shuffleBoard();
    }
  }

  Future<void> activateSingleRemove() async {
    if (await powerUpManager.activateSingleRemove()) {
      board.setSingleRemoveMode(true);
    }
  }

  void addExtraMovesFromAd() {
    board.addExtraMoves(kExtraMoveCount);
  }
}
