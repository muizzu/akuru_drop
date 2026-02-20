import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../models/tile_type.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';

class GameTile extends PositionComponent with HasGameRef {
  TileState state;
  int row;
  int col;

  bool isSelected = false;
  bool isHinted = false;
  bool isMatching = false;
  bool isAnimating = false;

  double _pulsePhase = 0;
  double _shimmerPhase = 0;

  static final Random _random = Random();

  GameTile({
    required this.state,
    required this.row,
    required this.col,
    super.position,
  }) : super(size: Vector2.all(kTileSize));

  Vector2 get boardPosition => Vector2(
        col * (kTileSize + kTileSpacing) + kBoardPadding,
        row * (kTileSize + kTileSpacing) + kBoardPadding,
      );

  void updateBoardPosition() {
    position = boardPosition;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (state.special != SpecialTileType.none) {
      _shimmerPhase += dt * 3;
    }
    if (isSelected || isHinted) {
      _pulsePhase += dt * 4;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (state.isEmpty || state.letter == null) return;

    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(kTileBorderRadius));

    // Draw blocker background
    if (state.blocker == BlockerType.coral) {
      final coralPaint = Paint()..color = const Color(0xFF8B4513).withValues(alpha: 0.5);
      canvas.drawRRect(rrect, coralPaint);
    }

    // Draw main tile
    _drawTileBackground(canvas, rrect);

    // Draw ice overlay
    if (state.blocker == BlockerType.ice) {
      _drawIceOverlay(canvas, rrect);
    }

    // Draw chain
    if (state.blocker == BlockerType.chain) {
      _drawChainOverlay(canvas, rect);
    }

    // Draw letter
    _drawLetter(canvas, rect);

    // Draw special indicator
    if (state.special != SpecialTileType.none) {
      _drawSpecialIndicator(canvas, rect);
    }

    // Draw drop item
    if (state.hasDropItem) {
      _drawDropItem(canvas, rect);
    }

    // Draw selection highlight
    if (isSelected) {
      _drawSelectionHighlight(canvas, rrect);
    }

    // Draw hint glow
    if (isHinted) {
      _drawHintGlow(canvas, rrect);
    }
  }

  void _drawTileBackground(Canvas canvas, RRect rrect) {
    final color = state.letter!.color;

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawRRect(rrect.shift(const Offset(1, 2)), shadowPaint);

    // Main gradient
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        color,
        Color.lerp(color, Colors.black, 0.2)!,
      ],
    );
    final paint = Paint()..shader = gradient.createShader(rrect.outerRect);
    canvas.drawRRect(rrect, paint);

    // Top highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    final highlightRect = RRect.fromLTRBAndCorners(
      rrect.left,
      rrect.top,
      rrect.right,
      rrect.top + size.y * 0.4,
      topLeft: const Radius.circular(kTileBorderRadius),
      topRight: const Radius.circular(kTileBorderRadius),
    );
    canvas.drawRRect(highlightRect, highlightPaint);
  }

  void _drawLetter(Canvas canvas, Rect rect) {
    final textStyle = TextStyle(
      fontFamily: kThaanaFontFamily,
      fontSize: kTileSize * 0.55,
      color: Colors.white,
      fontWeight: FontWeight.bold,
      shadows: const [
        Shadow(
          color: Color(0x66000000),
          offset: Offset(1, 1),
          blurRadius: 2,
        ),
      ],
    );

    final textSpan = TextSpan(
      text: state.letter!.letter,
      style: textStyle,
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: ui.TextDirection.rtl,
      textAlign: TextAlign.center,
    )..layout();

    final offset = Offset(
      (rect.width - textPainter.width) / 2,
      (rect.height - textPainter.height) / 2,
    );
    textPainter.paint(canvas, offset);
  }

  void _drawSpecialIndicator(Canvas canvas, Rect rect) {
    final shimmer = (sin(_shimmerPhase) + 1) / 2;
    final glowColor = Colors.white.withValues(alpha: 0.3 + shimmer * 0.3);

    switch (state.special) {
      case SpecialTileType.lineHorizontal:
        final paint = Paint()
          ..color = glowColor
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
          Offset(4, rect.height / 2),
          Offset(rect.width - 4, rect.height / 2),
          paint,
        );
        // Arrow indicators
        _drawArrow(canvas, Offset(6, rect.height / 2), true, glowColor);
        _drawArrow(canvas, Offset(rect.width - 6, rect.height / 2), false, glowColor);
        break;

      case SpecialTileType.lineVertical:
        final paint = Paint()
          ..color = glowColor
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
          Offset(rect.width / 2, 4),
          Offset(rect.width / 2, rect.height - 4),
          paint,
        );
        break;

      case SpecialTileType.bomb:
        final paint = Paint()
          ..color = glowColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawCircle(
          Offset(rect.width / 2, rect.height / 2),
          rect.width * 0.35,
          paint,
        );
        // Inner cross
        final cross = Paint()
          ..color = glowColor
          ..strokeWidth = 1.5;
        final center = Offset(rect.width / 2, rect.height / 2);
        final r = rect.width * 0.2;
        canvas.drawLine(center - Offset(r, 0), center + Offset(r, 0), cross);
        canvas.drawLine(center - Offset(0, r), center + Offset(0, r), cross);
        break;

      case SpecialTileType.star:
        _drawStar(canvas, Offset(rect.width / 2, rect.height / 2),
            rect.width * 0.35, glowColor);
        break;

      case SpecialTileType.none:
        break;
    }
  }

  void _drawArrow(Canvas canvas, Offset pos, bool left, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final dir = left ? 1.0 : -1.0;
    final path = Path()
      ..moveTo(pos.dx + dir * 4, pos.dy - 4)
      ..lineTo(pos.dx, pos.dy)
      ..lineTo(pos.dx + dir * 4, pos.dy + 4);
    canvas.drawPath(path, paint);
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final angle = -pi / 2 + i * 4 * pi / 5;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawIceOverlay(Canvas canvas, RRect rrect) {
    final alpha = state.iceHealth == 2 ? 0.5 : 0.3;
    final paint = Paint()
      ..color = const Color(0xFFADD8E6).withValues(alpha: alpha)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, paint);

    // Ice cracks for health 1
    if (state.iceHealth == 1) {
      final crackPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      final path = Path()
        ..moveTo(size.x * 0.3, size.y * 0.2)
        ..lineTo(size.x * 0.5, size.y * 0.5)
        ..lineTo(size.x * 0.4, size.y * 0.8)
        ..moveTo(size.x * 0.5, size.y * 0.5)
        ..lineTo(size.x * 0.7, size.y * 0.6);
      canvas.drawPath(path, crackPaint);
    }
  }

  void _drawChainOverlay(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..color = const Color(0xFF888888)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw chain links
    for (int i = 0; i < 3; i++) {
      final y = rect.height * (0.25 + i * 0.25);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(rect.width / 2, y),
          width: rect.width * 0.5,
          height: rect.height * 0.2,
        ),
        paint,
      );
    }
  }

  void _drawDropItem(Canvas canvas, Rect rect) {
    // Coconut icon
    final paint = Paint()..color = const Color(0xFF8B4513);
    canvas.drawCircle(
      Offset(rect.width - 10, 10),
      6,
      paint,
    );
    final innerPaint = Paint()..color = const Color(0xFFA0522D);
    canvas.drawCircle(
      Offset(rect.width - 10, 10),
      4,
      innerPaint,
    );
  }

  void _drawSelectionHighlight(Canvas canvas, RRect rrect) {
    final pulse = (sin(_pulsePhase) + 1) / 2;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3 + pulse * 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(rrect.inflate(2), paint);
  }

  void _drawHintGlow(Canvas canvas, RRect rrect) {
    final pulse = (sin(_pulsePhase) + 1) / 2;
    final paint = Paint()
      ..color = AppTheme.softYellow.withValues(alpha: 0.2 + pulse * 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, paint);
  }

  void animateMoveTo(Vector2 target, {VoidCallback? onComplete}) {
    isAnimating = true;
    add(
      MoveEffect.to(
        target,
        EffectController(duration: 0.2, curve: Curves.easeInOut),
        onComplete: () {
          isAnimating = false;
          onComplete?.call();
        },
      ),
    );
  }

  void animateFallTo(Vector2 target, double delay, {VoidCallback? onComplete}) {
    isAnimating = true;
    add(
      MoveEffect.to(
        target,
        EffectController(
          startDelay: delay,
          duration: 0.15,
          curve: Curves.bounceOut,
        ),
        onComplete: () {
          isAnimating = false;
          onComplete?.call();
        },
      ),
    );
  }

  void animateMatchClear({VoidCallback? onComplete}) {
    isMatching = true;
    isAnimating = true;
    add(
      SequenceEffect([
        ScaleEffect.to(
          Vector2.all(1.2),
          EffectController(duration: 0.1),
        ),
        ScaleEffect.to(
          Vector2.zero(),
          EffectController(duration: 0.15, curve: Curves.easeIn),
        ),
      ], onComplete: () {
        isMatching = false;
        isAnimating = false;
        onComplete?.call();
      }),
    );
  }

  void animateSpawn() {
    scale = Vector2.zero();
    isAnimating = true;
    add(
      ScaleEffect.to(
        Vector2.all(1.0),
        EffectController(duration: 0.2, curve: Curves.elasticOut),
        onComplete: () {
          isAnimating = false;
        },
      ),
    );
  }
}
