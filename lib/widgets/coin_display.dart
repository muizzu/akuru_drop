import 'package:flutter/material.dart';
import '../config/theme.dart';

class CoinDisplay extends StatelessWidget {
  final int coins;
  final double fontSize;

  const CoinDisplay({
    super.key,
    required this.coins,
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.coinColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.monetization_on, color: AppTheme.coinColor, size: fontSize),
          const SizedBox(width: 4),
          Text(
            '$coins',
            style: TextStyle(
              color: AppTheme.coinColor,
              fontWeight: FontWeight.bold,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }
}
