import 'package:flame/game.dart' as flame;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../game/akuru_drop_game.dart';
import '../game/models/level_data.dart';
import '../game/models/objective.dart';
import '../game/models/tile_type.dart';
import '../game/managers/level_manager.dart';
import '../game/managers/power_up_manager.dart';
import '../services/storage_service.dart';
import '../services/audio_service.dart';
import '../services/ad_service.dart';
import '../widgets/pause_menu.dart';
import '../widgets/level_complete_dialog.dart';
import '../widgets/level_failed_dialog.dart';
import '../widgets/power_up_button.dart';
import '../utils/extensions.dart';

class GameScreen extends StatefulWidget {
  final int levelNumber;
  final VoidCallback onBack;
  final VoidCallback onNextLevel;

  const GameScreen({
    super.key,
    required this.levelNumber,
    required this.onBack,
    required this.onNextLevel,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  AkuruDropGame? _game;
  int _score = 0;
  int _movesLeft = 0;
  double _timeLeft = 0;
  bool _isPaused = false;
  bool _showComplete = false;
  bool _showFailed = false;
  int _finalScore = 0;
  int _finalStars = 0;
  late LevelData _levelData;
  late PowerUpManager _powerUpManager;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  Future<void> _initGame() async {
    final levelManager = context.read<LevelManager>();
    final storage = context.read<StorageService>();
    final audio = context.read<AudioService>();

    await levelManager.loadLevels();
    _levelData = levelManager.getLevel(widget.levelNumber) ??
        LevelData(
          levelNumber: widget.levelNumber,
          objective: LevelObjective.score(target: 2000, moves: 25),
          availableLetters: ThaanaLetter.forLevel(widget.levelNumber),
          star1Score: 2000,
        );

    _powerUpManager = PowerUpManager(storage);
    _powerUpManager.resetForLevel();

    _movesLeft = _levelData.objective.moveLimit;
    if (_levelData.objective.type == ObjectiveType.timed) {
      _timeLeft = _levelData.objective.timeLimit.toDouble();
    }

    final game = AkuruDropGame(
      levelData: _levelData,
      audioService: audio,
      powerUpManager: _powerUpManager,
    );

    game.onScoreChanged = (score) {
      if (mounted) setState(() => _score = score);
    };
    game.onMovesChanged = (moves) {
      if (mounted) setState(() => _movesLeft = moves);
    };
    game.onTimeChanged = (time) {
      if (mounted) setState(() => _timeLeft = time);
    };
    game.onCombo = (combo) {
      // Visual handled by game
    };
    game.onLevelComplete = (score, stars) {
      if (mounted) {
        setState(() {
          _finalScore = score;
          _finalStars = stars;
          _showComplete = true;
        });
        _handleLevelComplete(score, stars);
      }
    };
    game.onLevelFailed = () {
      if (mounted) {
        setState(() => _showFailed = true);
      }
    };

    if (mounted) {
      setState(() => _game = game);
    }
  }

  Future<void> _handleLevelComplete(int score, int stars) async {
    final storage = context.read<StorageService>();
    final adService = context.read<AdService>();

    await storage.setHighestLevel(widget.levelNumber);
    await storage.setLevelStars(widget.levelNumber, stars);
    await storage.setLevelHighScore(widget.levelNumber, score);

    // Coins reward
    final coinReward = kCoinsPerLevel + stars * kCoinsPerStar;
    await storage.addCoins(coinReward);

    // Ad tracking
    adService.recordLevelComplete();
    if (adService.shouldShowInterstitial) {
      await adService.showInterstitial();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_game == null) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        body: Center(child: CircularProgressIndicator(color: AppTheme.coral)),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Stack(
        children: [
          // Game
          flame.GameWidget(game: _game!),

          // Top HUD
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                children: [
                  _buildTopBar(),
                  const SizedBox(height: 8),
                  _buildObjectiveBar(),
                  const SizedBox(height: 4),
                  _buildScoreProgressBar(),
                ],
              ),
            ),
          ),

          // Bottom power-ups
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 12,
            left: 0,
            right: 0,
            child: _buildPowerUpBar(),
          ),

          // Overlays
          if (_isPaused) _buildPauseOverlay(),
          if (_showComplete) _buildCompleteOverlay(),
          if (_showFailed) _buildFailedOverlay(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        // Level number
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black38,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Level ${widget.levelNumber}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),

        const Spacer(),

        // Score
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black38,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${_score.withCommas}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),

        const Spacer(),

        // Moves or time
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _movesLeft <= 5 && _levelData.objective.type != ObjectiveType.timed
                ? AppTheme.coral.withValues(alpha: 0.5)
                : Colors.black38,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                _levelData.objective.type == ObjectiveType.timed
                    ? Icons.timer
                    : Icons.swap_horiz,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                _levelData.objective.type == ObjectiveType.timed
                    ? Duration(seconds: _timeLeft.round()).mmss
                    : '$_movesLeft',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        // Pause button
        GestureDetector(
          onTap: () => setState(() => _isPaused = true),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.pause, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildObjectiveBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.flag, color: AppTheme.turquoise, size: 16),
          const SizedBox(width: 8),
          Text(
            _levelData.objective.description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreProgressBar() {
    final target = _levelData.star1Score;
    final progress = (_score / _levelData.computedStar3).clamp(0.0, 1.0);
    final star1Pos = (target / _levelData.computedStar3).clamp(0.0, 1.0);
    final star2Pos = (_levelData.computedStar2 / _levelData.computedStar3).clamp(0.0, 1.0);

    return SizedBox(
      height: 20,
      child: Stack(
        children: [
          // Background
          Container(
            height: 6,
            margin: const EdgeInsets.only(top: 7),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          // Progress
          FractionallySizedBox(
            widthFactor: progress,
            child: Container(
              height: 6,
              margin: const EdgeInsets.only(top: 7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.turquoise, AppTheme.coral],
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          // Star markers
          ..._buildStarMarkers(star1Pos, star2Pos),
        ],
      ),
    );
  }

  List<Widget> _buildStarMarkers(double star1Pos, double star2Pos) {
    return [
      _starMarker(star1Pos, _score >= _levelData.star1Score),
      _starMarker(star2Pos, _score >= _levelData.computedStar2),
      _starMarker(1.0, _score >= _levelData.computedStar3),
    ];
  }

  Widget _starMarker(double position, bool filled) {
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: position,
        child: Align(
          alignment: Alignment.centerRight,
          child: Icon(
            filled ? Icons.star : Icons.star_border,
            size: 18,
            color: filled ? AppTheme.starColor : Colors.white30,
          ),
        ),
      ),
    );
  }

  Widget _buildPowerUpBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        PowerUpButton(
          icon: '+5',
          label: 'Moves',
          cost: kExtraMoveCost,
          isUsed: _powerUpManager.extraMovesUsed,
          onTap: () async {
            await _game?.useExtraMoves();
            setState(() {});
          },
        ),
        const SizedBox(width: 16),
        PowerUpButton(
          icon: '⟳',
          label: 'Shuffle',
          cost: kShuffleCost,
          isUsed: _powerUpManager.shuffleUsed,
          onTap: () async {
            await _game?.useShuffle();
            setState(() {});
          },
        ),
        const SizedBox(width: 16),
        PowerUpButton(
          icon: '✕',
          label: 'Remove',
          cost: kSingleRemoveCost,
          isUsed: _powerUpManager.singleRemoveUsed,
          isActive: _powerUpManager.singleRemoveActive,
          onTap: () async {
            await _game?.activateSingleRemove();
            setState(() {});
          },
        ),
      ],
    );
  }

  Widget _buildPauseOverlay() {
    return PauseMenu(
      onResume: () => setState(() => _isPaused = false),
      onRestart: () {
        setState(() {
          _isPaused = false;
          _score = 0;
          _showComplete = false;
          _showFailed = false;
          _game = null;
        });
        _initGame();
      },
      onLevelSelect: widget.onBack,
    );
  }

  Widget _buildCompleteOverlay() {
    return LevelCompleteDialog(
      score: _finalScore,
      stars: _finalStars,
      levelNumber: widget.levelNumber,
      onNext: widget.onNextLevel,
      onReplay: () {
        setState(() {
          _showComplete = false;
          _score = 0;
          _game = null;
        });
        _initGame();
      },
      onWatchAd: () async {
        final adService = context.read<AdService>();
        final storage = context.read<StorageService>();
        final result = await adService.showRewardedAd(
          onReward: (amount) async {
            final coins = kCoinsPerLevel + _finalStars * kCoinsPerStar;
            await storage.addCoins(coins); // Double coins
          },
        );
        if (mounted && result) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bonus coins earned!'),
              backgroundColor: AppTheme.turquoise,
            ),
          );
        }
      },
    );
  }

  Widget _buildFailedOverlay() {
    return LevelFailedDialog(
      onRetry: () {
        setState(() {
          _showFailed = false;
          _score = 0;
          _game = null;
        });
        _initGame();
      },
      onLevelSelect: widget.onBack,
      onWatchAdForMoves: () async {
        final adService = context.read<AdService>();
        final result = await adService.showRewardedAd(
          onReward: (amount) {
            _game?.addExtraMovesFromAd();
            setState(() {
              _showFailed = false;
              _movesLeft += kExtraMoveCount;
            });
          },
        );
        if (!result && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ad not available'),
              backgroundColor: AppTheme.coral,
            ),
          );
        }
      },
      onBuyMoves: () async {
        final storage = context.read<StorageService>();
        if (await storage.spendCoins(100)) {
          _game?.addExtraMovesFromAd();
          setState(() {
            _showFailed = false;
            _movesLeft += kExtraMoveCount;
          });
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Not enough coins!'),
                backgroundColor: AppTheme.coral,
              ),
            );
          }
        }
      },
    );
  }
}
