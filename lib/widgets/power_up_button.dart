import 'package:flutter/material.dart';
import '../config/theme.dart';

class PowerUpButton extends StatelessWidget {
  final String icon;
  final String label;
  final int cost;
  final bool isUsed;
  final bool isActive;
  final VoidCallback onTap;

  const PowerUpButton({
    super.key,
    required this.icon,
    required this.label,
    required this.cost,
    required this.isUsed,
    this.isActive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isUsed ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.turquoise.withValues(alpha: 0.3)
              : isUsed
                  ? Colors.black26
                  : const Color(0xFF1A2A44),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? AppTheme.turquoise
                : isUsed
                    ? Colors.white10
                    : AppTheme.turquoise.withValues(alpha: 0.3),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              icon,
              style: TextStyle(
                fontSize: 20,
                color: isUsed ? Colors.white30 : Colors.white,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isUsed ? Colors.white30 : Colors.white70,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.monetization_on,
                  size: 10,
                  color: isUsed ? Colors.white24 : AppTheme.coinColor,
                ),
                const SizedBox(width: 2),
                Text(
                  '$cost',
                  style: TextStyle(
                    fontSize: 10,
                    color: isUsed ? Colors.white24 : AppTheme.coinColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
