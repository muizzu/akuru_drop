import 'dart:math';
import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../game/models/tile_type.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _titleController;
  late AnimationController _lettersController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _titleSlide;
  late Animation<double> _titleOpacity;

  final List<_FallingLetter> _fallingLetters = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _lettersController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeIn),
    );
    _titleSlide = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.easeOut),
    );
    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.easeIn),
    );

    // Generate falling letters
    for (int i = 0; i < 20; i++) {
      _fallingLetters.add(_FallingLetter(
        letter: ThaanaLetter.values[_random.nextInt(ThaanaLetter.values.length)],
        x: _random.nextDouble(),
        startDelay: _random.nextDouble() * 1.5,
        speed: 0.3 + _random.nextDouble() * 0.5,
        size: 16 + _random.nextDouble() * 20,
      ));
    }

    _startAnimation();
  }

  Future<void> _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 600));
    _titleController.forward();
    _lettersController.repeat();
    await Future.delayed(const Duration(seconds: 2));
    widget.onComplete();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _titleController.dispose();
    _lettersController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Stack(
        children: [
          // Falling letters background
          AnimatedBuilder(
            animation: _lettersController,
            builder: (context, _) {
              return CustomPaint(
                size: MediaQuery.of(context).size,
                painter: _FallingLettersPainter(
                  letters: _fallingLetters,
                  progress: _lettersController.value,
                ),
              );
            },
          ),
          // Center content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Shaviyani Games logo
                AnimatedBuilder(
                  animation: _logoController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _logoOpacity.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.turquoise,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.turquoise.withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'ށ',
                            style: TextStyle(
                              fontFamily: kThaanaFontFamily,
                              fontSize: 40,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Shaviyani Games',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppTheme.textSecondary,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                // Game title
                AnimatedBuilder(
                  animation: _titleController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _titleOpacity.value,
                      child: Transform.translate(
                        offset: Offset(0, _titleSlide.value),
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Text(
                        'AKURU DROP',
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          fontFamily: kTitleFontFamily,
                          color: AppTheme.coral,
                          shadows: [
                            Shadow(
                              color: AppTheme.coral.withValues(alpha: 0.5),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        'އަކުރު ޑްރޮޕް',
                        style: TextStyle(
                          fontFamily: kThaanaFontFamily,
                          fontSize: 24,
                          color: AppTheme.turquoise,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FallingLetter {
  final ThaanaLetter letter;
  final double x;
  final double startDelay;
  final double speed;
  final double size;

  _FallingLetter({
    required this.letter,
    required this.x,
    required this.startDelay,
    required this.speed,
    required this.size,
  });
}

class _FallingLettersPainter extends CustomPainter {
  final List<_FallingLetter> letters;
  final double progress;

  _FallingLettersPainter({required this.letters, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final letter in letters) {
      final adjustedProgress = ((progress * 2 + letter.startDelay) % 2.0) / 2.0;
      final y = adjustedProgress * (size.height + 50) - 25;
      final x = letter.x * size.width;
      final opacity = (0.15 * (1 - adjustedProgress)).clamp(0.0, 0.15);

      final textPainter = TextPainter(
        text: TextSpan(
          text: letter.letter.letter,
          style: TextStyle(
            fontFamily: kThaanaFontFamily,
            fontSize: letter.size,
            color: letter.letter.color.withValues(alpha: opacity),
          ),
        ),
        textDirection: TextDirection.rtl,
      )..layout();

      textPainter.paint(canvas, Offset(x, y));
    }
  }

  @override
  bool shouldRepaint(covariant _FallingLettersPainter oldDelegate) => true;
}
