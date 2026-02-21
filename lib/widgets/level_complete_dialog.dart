import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../utils/extensions.dart';

class LevelCompleteDialog extends StatefulWidget {
  final int score;
  final int stars;
  final int levelNumber;
  final VoidCallback onNext;
  final VoidCallback onReplay;
  final VoidCallback onWatchAd;

  const LevelCompleteDialog({
    super.key,
    required this.score,
    required this.stars,
    required this.levelNumber,
    required this.onNext,
    required this.onReplay,
    required this.onWatchAd,
  });

  @override
  State<LevelCompleteDialog> createState() => _LevelCompleteDialogState();
}

class _LevelCompleteDialogState extends State<LevelCompleteDialog>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _starController;
  late Animation<Offset> _slideAnimation;
  final List<Animation<double>> _starAnimations = [];

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _starController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    for (int i = 0; i < 3; i++) {
      _starAnimations.add(
        Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: _starController,
            curve: Interval(
              i * 0.25,
              0.5 + i * 0.25,
              curve: Curves.elasticOut,
            ),
          ),
        ),
      );
    }

    _slideController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _starController.forward();
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _starController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.overlayDark,
      child: Center(
        child: SlideTransition(
          position: _slideAnimation,
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2A44),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.turquoise.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.turquoise.withValues(alpha: 0.2),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'LEVEL COMPLETE!',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.turquoise,
                    fontFamily: 'Permanent Marker',
                  ),
                ),
                const SizedBox(height: 20),

                // Stars
                AnimatedBuilder(
                  animation: _starController,
                  builder: (context, _) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) {
                        final scale = i < widget.stars
                            ? _starAnimations[i].value
                            : 0.5;
                        return Transform.scale(
                          scale: scale,
                          child: Icon(
                            i < widget.stars ? Icons.star : Icons.star_border,
                            size: 50,
                            color: i < widget.stars
                                ? AppTheme.starColor
                                : Colors.white24,
                          ),
                        );
                      }),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Score
                Text(
                  widget.score.withCommas,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'points',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white54,
                  ),
                ),

                const SizedBox(height: 24),

                // Watch ad for 2x coins
                GestureDetector(
                  onTap: widget.onWatchAd,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.turquoise, AppTheme.skyBlue],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_circle, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Watch Ad for 2x Coins',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: widget.onReplay,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white30),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'REPLAY',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: widget.onNext,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: AppTheme.coral,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'NEXT LEVEL',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
