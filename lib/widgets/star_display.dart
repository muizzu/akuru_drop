import 'package:flutter/material.dart';
import '../config/theme.dart';

class StarDisplay extends StatelessWidget {
  final int stars;
  final double size;

  const StarDisplay({
    super.key,
    required this.stars,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Icon(
          i < stars ? Icons.star : Icons.star_border,
          size: size,
          color: i < stars ? AppTheme.starColor : Colors.white30,
        );
      }),
    );
  }
}
