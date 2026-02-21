import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../game/models/tile_type.dart';
import '../services/storage_service.dart';
import '../services/audio_service.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onPlay;
  final VoidCallback onSettings;
  final VoidCallback onShop;

  const HomeScreen({
    super.key,
    required this.onPlay,
    required this.onSettings,
    required this.onShop,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _bgController;
  late AnimationController _pulseController;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bgController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storage = context.read<StorageService>();
    final audio = context.read<AudioService>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Stack(
        children: [
          // Animated background letters
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, _) {
              return CustomPaint(
                size: MediaQuery.of(context).size,
                painter: _FloatingLettersPainter(
                  progress: _bgController.value,
                ),
              );
            },
          ),
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Sound toggle
                      IconButton(
                        onPressed: () async {
                          await audio.toggleSound();
                          setState(() {});
                        },
                        icon: Icon(
                          audio.soundOn ? Icons.volume_up : Icons.volume_off,
                          color: Colors.white70,
                          size: 28,
                        ),
                      ),
                      // Coins
                      _CoinDisplay(coins: storage.coins),
                      // Settings
                      IconButton(
                        onPressed: widget.onSettings,
                        icon: const Icon(
                          Icons.settings,
                          color: Colors.white70,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // Game logo
                Column(
                  children: [
                    Text(
                      'AKURU DROP',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        fontFamily: kTitleFontFamily,
                        color: AppTheme.coral,
                        shadows: [
                          Shadow(
                            color: AppTheme.coral.withValues(alpha: 0.5),
                            blurRadius: 30,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'އަކުރު ޑްރޮޕް',
                      style: TextStyle(
                        fontFamily: kThaanaFontFamily,
                        fontSize: 22,
                        color: AppTheme.turquoise,
                      ),
                    ),
                  ],
                ),

                const Spacer(flex: 2),

                // Play button
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulse.value,
                      child: child,
                    );
                  },
                  child: GestureDetector(
                    onTap: () {
                      audio.playSfx(SfxType.buttonTap);
                      widget.onPlay();
                    },
                    child: Container(
                      width: 200,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.coral, Color(0xFFFF4757)],
                        ),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.coral.withValues(alpha: 0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'PLAY',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Permanent Marker',
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Shop button
                GestureDetector(
                  onTap: () {
                    audio.playSfx(SfxType.buttonTap);
                    widget.onShop();
                  },
                  child: Container(
                    width: 160,
                    height: 48,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.turquoise, width: 2),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Center(
                      child: Text(
                        'SHOP',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.turquoise,
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 1),

                // Daily reward
                if (storage.canClaimDailyReward)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GestureDetector(
                      onTap: () async {
                        await storage.claimDailyReward();
                        audio.playSfx(SfxType.starEarn);
                        if (!context.mounted) return;
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Daily reward: +$kDailyLoginCoins coins!'),
                              backgroundColor: AppTheme.turquoise,
                            ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.turquoise, AppTheme.skyBlue],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.turquoise.withValues(alpha: 0.3),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.card_giftcard, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Daily Reward',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CoinDisplay extends StatelessWidget {
  final int coins;

  const _CoinDisplay({required this.coins});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.coinColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on, color: AppTheme.coinColor, size: 20),
          const SizedBox(width: 6),
          Text(
            '$coins',
            style: const TextStyle(
              color: AppTheme.coinColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingLettersPainter extends CustomPainter {
  final double progress;
  final Random _random = Random(42);

  _FloatingLettersPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final letters = ThaanaLetter.values;
    for (int i = 0; i < 15; i++) {
      final letter = letters[_random.nextInt(letters.length)];
      final baseX = _random.nextDouble() * size.width;
      final baseY = _random.nextDouble() * size.height;
      final amplitude = 20 + _random.nextDouble() * 30;
      final phase = _random.nextDouble() * 2 * pi;
      final fontSize = 20 + _random.nextDouble() * 20;

      final x = baseX + sin(progress * 2 * pi + phase) * amplitude;
      final y = baseY + cos(progress * 2 * pi + phase * 0.7) * amplitude * 0.5;

      final textPainter = TextPainter(
        text: TextSpan(
          text: letter.letter,
          style: TextStyle(
            fontFamily: kThaanaFontFamily,
            fontSize: fontSize,
            color: letter.color.withValues(alpha: 0.08),
          ),
        ),
        textDirection: TextDirection.rtl,
      )..layout();

      textPainter.paint(canvas, Offset(x, y));
    }
  }

  @override
  bool shouldRepaint(covariant _FloatingLettersPainter oldDelegate) => true;
}
