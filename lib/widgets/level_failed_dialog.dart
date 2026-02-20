import 'package:flutter/material.dart';
import '../config/theme.dart';

class LevelFailedDialog extends StatefulWidget {
  final VoidCallback onRetry;
  final VoidCallback onLevelSelect;
  final VoidCallback onWatchAdForMoves;
  final VoidCallback onBuyMoves;

  const LevelFailedDialog({
    super.key,
    required this.onRetry,
    required this.onLevelSelect,
    required this.onWatchAdForMoves,
    required this.onBuyMoves,
  });

  @override
  State<LevelFailedDialog> createState() => _LevelFailedDialogState();
}

class _LevelFailedDialogState extends State<LevelFailedDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
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
              border: Border.all(color: AppTheme.coral.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.coral.withValues(alpha: 0.2),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.sentiment_dissatisfied,
                  color: AppTheme.coral,
                  size: 50,
                ),
                const SizedBox(height: 12),
                const Text(
                  'OUT OF MOVES!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.coral,
                    fontFamily: 'Permanent Marker',
                  ),
                ),
                const SizedBox(height: 24),

                // Watch ad for extra moves
                GestureDetector(
                  onTap: widget.onWatchAdForMoves,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
                          'Watch Ad for +5 Moves',
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

                const SizedBox(height: 8),

                // Buy extra moves
                GestureDetector(
                  onTap: widget.onBuyMoves,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.coral.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.coral.withValues(alpha: 0.5)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.monetization_on, color: AppTheme.coinColor, size: 18),
                        SizedBox(width: 8),
                        Text(
                          '100 Coins for +5 Moves',
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

                const SizedBox(height: 16),

                // Bottom buttons
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: widget.onLevelSelect,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white30),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'LEVELS',
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
                        onTap: widget.onRetry,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: AppTheme.coral,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'RETRY',
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
