import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../game/models/level_data.dart';
import '../services/storage_service.dart';
import '../services/audio_service.dart';

class LevelSelectScreen extends StatefulWidget {
  final void Function(int level) onLevelSelected;
  final VoidCallback onBack;

  const LevelSelectScreen({
    super.key,
    required this.onLevelSelected,
    required this.onBack,
  });

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentLevel();
    });
  }

  void _scrollToCurrentLevel() {
    final storage = context.read<StorageService>();
    final currentLevel = storage.highestLevelReached + 1;
    // Approximate scroll position
    final atollIndex = atolls.indexWhere(
      (a) => currentLevel >= a.startLevel && currentLevel <= a.endLevel,
    );
    if (atollIndex > 0) {
      final offset = atollIndex * 500.0; // approximate
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          offset,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storage = context.read<StorageService>();
    final audio = context.read<AudioService>();
    final highestLevel = storage.highestLevelReached;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const Expanded(
                    child: Text(
                      'SELECT LEVEL',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Permanent Marker',
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the back button
                ],
              ),
            ),

            // Level map
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: atolls.length,
                itemBuilder: (context, atollIndex) {
                  final atoll = atolls[atollIndex];
                  return _AtollSection(
                    atoll: atoll,
                    highestLevel: highestLevel,
                    storage: storage,
                    onLevelTap: (level) {
                      audio.playSfx(SfxType.buttonTap);
                      widget.onLevelSelected(level);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AtollSection extends StatelessWidget {
  final AtollInfo atoll;
  final int highestLevel;
  final StorageService storage;
  final void Function(int level) onLevelTap;

  const _AtollSection({
    required this.atoll,
    required this.highestLevel,
    required this.storage,
    required this.onLevelTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Atoll header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.turquoise.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.turquoise.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  atoll.nameDv,
                  style: const TextStyle(
                    fontFamily: kThaanaFontFamily,
                    fontSize: 18,
                    color: AppTheme.turquoise,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                atoll.nameEn,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
              const Spacer(),
              // Star count for this atoll
              _AtollStarCount(
                atoll: atoll,
                storage: storage,
              ),
            ],
          ),
        ),

        // Level nodes grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: atoll.endLevel - atoll.startLevel + 1,
          itemBuilder: (context, index) {
            final levelNum = atoll.startLevel + index;
            final isUnlocked = levelNum <= highestLevel + 1;
            final isCurrent = levelNum == highestLevel + 1;
            final stars = storage.getLevelStars(levelNum);

            return _LevelNode(
              levelNumber: levelNum,
              stars: stars,
              isUnlocked: isUnlocked,
              isCurrent: isCurrent,
              onTap: isUnlocked ? () => onLevelTap(levelNum) : null,
            );
          },
        ),

        const SizedBox(height: 8),
        // Dotted separator
        Center(
          child: Container(
            width: 2,
            height: 30,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white24,
                style: BorderStyle.solid,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LevelNode extends StatelessWidget {
  final int levelNumber;
  final int stars;
  final bool isUnlocked;
  final bool isCurrent;
  final VoidCallback? onTap;

  const _LevelNode({
    required this.levelNumber,
    required this.stars,
    required this.isUnlocked,
    required this.isCurrent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: isCurrent
              ? AppTheme.coral
              : isUnlocked
                  ? const Color(0xFF1A3050)
                  : const Color(0xFF0D1929),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrent
                ? AppTheme.coral
                : isUnlocked
                    ? AppTheme.turquoise.withValues(alpha: 0.3)
                    : Colors.white10,
            width: isCurrent ? 2 : 1,
          ),
          boxShadow: isCurrent
              ? [
                  BoxShadow(
                    color: AppTheme.coral.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$levelNumber',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isUnlocked ? Colors.white : Colors.white30,
              ),
            ),
            if (isUnlocked && stars > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  return Icon(
                    i < stars ? Icons.star : Icons.star_border,
                    size: 10,
                    color: i < stars ? AppTheme.starColor : Colors.white30,
                  );
                }),
              ),
            if (!isUnlocked)
              const Icon(Icons.lock, size: 12, color: Colors.white24),
          ],
        ),
      ),
    );
  }
}

class _AtollStarCount extends StatelessWidget {
  final AtollInfo atoll;
  final StorageService storage;

  const _AtollStarCount({
    required this.atoll,
    required this.storage,
  });

  @override
  Widget build(BuildContext context) {
    int totalStars = 0;
    final maxStars = (atoll.endLevel - atoll.startLevel + 1) * 3;
    for (int i = atoll.startLevel; i <= atoll.endLevel; i++) {
      totalStars += storage.getLevelStars(i);
    }

    return Row(
      children: [
        const Icon(Icons.star, size: 14, color: AppTheme.starColor),
        const SizedBox(width: 4),
        Text(
          '$totalStars/$maxStars',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }
}
