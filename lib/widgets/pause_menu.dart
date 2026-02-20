import 'package:flutter/material.dart';
import '../config/theme.dart';

class PauseMenu extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onLevelSelect;

  const PauseMenu({
    super.key,
    required this.onResume,
    required this.onRestart,
    required this.onLevelSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.overlayDark,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2A44),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.turquoise.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'PAUSED',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Permanent Marker',
                ),
              ),
              const SizedBox(height: 32),
              _MenuButton(
                text: 'RESUME',
                color: AppTheme.turquoise,
                onTap: onResume,
              ),
              const SizedBox(height: 12),
              _MenuButton(
                text: 'RESTART',
                color: AppTheme.coral,
                onTap: onRestart,
              ),
              const SizedBox(height: 12),
              _MenuButton(
                text: 'LEVEL SELECT',
                color: const Color(0xFF546E7A),
                onTap: onLevelSelect,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback onTap;

  const _MenuButton({
    required this.text,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
