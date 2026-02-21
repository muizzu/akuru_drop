import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/particles.dart' as flame_particles;
import 'package:flutter/material.dart';
import '../../config/theme.dart';

class ParticleEffects {
  static final Random _random = Random();

  static Component tileBurstEffect(Vector2 position, Color color) {
    return ParticleSystemComponent(
      position: position,
      particle: flame_particles.Particle.generate(
        count: 12,
        lifespan: 0.5,
        generator: (i) {
          final angle = (i / 12) * 2 * pi + _random.nextDouble() * 0.5;
          final speed = 40.0 + _random.nextDouble() * 60;
          final velocity = Vector2(cos(angle) * speed, sin(angle) * speed);

          return flame_particles.AcceleratedParticle(
            speed: velocity,
            acceleration: Vector2(0, 100),
            child: flame_particles.ComputedParticle(
              renderer: (canvas, particle) {
                final opacity = 1.0 - particle.progress;
                final size = 3.0 * (1.0 - particle.progress * 0.5);
                final paint = Paint()
                  ..color = color.withValues(alpha: opacity)
                  ..style = PaintingStyle.fill;
                canvas.drawCircle(Offset.zero, size, paint);
              },
            ),
          );
        },
      ),
    );
  }

  static Component lineClearEffect(Vector2 position, bool horizontal, double boardSize) {
    return ParticleSystemComponent(
      position: position,
      particle: flame_particles.Particle.generate(
        count: 20,
        lifespan: 0.6,
        generator: (i) {
          final offset = (i / 20 - 0.5) * boardSize;
          final start = horizontal
              ? Vector2(offset, 0)
              : Vector2(0, offset);
          final speed = horizontal
              ? Vector2((i < 10 ? -1.0 : 1.0) * 200, _random.nextDouble() * 20 - 10)
              : Vector2(_random.nextDouble() * 20 - 10, (i < 10 ? -1.0 : 1.0) * 200);

          return flame_particles.AcceleratedParticle(
            position: start,
            speed: speed,
            child: flame_particles.ComputedParticle(
              renderer: (canvas, particle) {
                final opacity = 1.0 - particle.progress;
                final paint = Paint()
                  ..color = Colors.white.withValues(alpha: opacity)
                  ..style = PaintingStyle.fill;
                canvas.drawCircle(Offset.zero, 4.0 * (1 - particle.progress), paint);
              },
            ),
          );
        },
      ),
    );
  }

  static Component bombExplosionEffect(Vector2 position) {
    return ParticleSystemComponent(
      position: position,
      particle: flame_particles.Particle.generate(
        count: 24,
        lifespan: 0.7,
        generator: (i) {
          final angle = (i / 24) * 2 * pi;
          final speed = 60.0 + _random.nextDouble() * 80;
          final velocity = Vector2(cos(angle) * speed, sin(angle) * speed);
          final color = AppTheme.tileColors[_random.nextInt(AppTheme.tileColors.length)];

          return flame_particles.AcceleratedParticle(
            speed: velocity,
            acceleration: Vector2(0, 80),
            child: flame_particles.ComputedParticle(
              renderer: (canvas, particle) {
                final opacity = 1.0 - particle.progress;
                final size = 4.0 * (1.0 - particle.progress * 0.3);
                final paint = Paint()
                  ..color = color.withValues(alpha: opacity)
                  ..style = PaintingStyle.fill;
                canvas.drawRRect(
                  RRect.fromRectAndRadius(
                    Rect.fromCenter(center: Offset.zero, width: size, height: size),
                    const Radius.circular(1),
                  ),
                  paint,
                );
              },
            ),
          );
        },
      ),
    );
  }

  static Component starActivateEffect(Vector2 position) {
    return ParticleSystemComponent(
      position: position,
      particle: flame_particles.Particle.generate(
        count: 30,
        lifespan: 0.8,
        generator: (i) {
          final angle = _random.nextDouble() * 2 * pi;
          final speed = 100.0 + _random.nextDouble() * 150;
          final velocity = Vector2(cos(angle) * speed, sin(angle) * speed);
          final hue = (i / 30) * 360;
          final color = HSLColor.fromAHSL(1, hue, 1, 0.6).toColor();

          return flame_particles.AcceleratedParticle(
            speed: velocity,
            acceleration: Vector2(0, 50),
            child: flame_particles.ComputedParticle(
              renderer: (canvas, particle) {
                final opacity = 1.0 - particle.progress;
                final size = 3.0 + 2.0 * sin(particle.progress * pi);
                final paint = Paint()
                  ..color = color.withValues(alpha: opacity)
                  ..style = PaintingStyle.fill;
                canvas.drawCircle(Offset.zero, size, paint);
              },
            ),
          );
        },
      ),
    );
  }

  static Component confettiEffect(Vector2 position) {
    return ParticleSystemComponent(
      position: position,
      particle: flame_particles.Particle.generate(
        count: 50,
        lifespan: 2.0,
        generator: (i) {
          final angle = _random.nextDouble() * 2 * pi;
          final speed = 30.0 + _random.nextDouble() * 100;
          final velocity = Vector2(
            cos(angle) * speed,
            -50 - _random.nextDouble() * 100,
          );
          final color = AppTheme.tileColors[_random.nextInt(AppTheme.tileColors.length)];
          final rotSpeed = (_random.nextDouble() - 0.5) * 10;

          return flame_particles.AcceleratedParticle(
            speed: velocity,
            acceleration: Vector2(0, 120),
            child: flame_particles.ComputedParticle(
              renderer: (canvas, particle) {
                final opacity = 1.0 - particle.progress * 0.5;
                final rot = particle.progress * rotSpeed;
                canvas.save();
                canvas.rotate(rot);
                final paint = Paint()
                  ..color = color.withValues(alpha: opacity)
                  ..style = PaintingStyle.fill;
                canvas.drawRect(
                  const Rect.fromLTWH(-3, -2, 6, 4),
                  paint,
                );
                canvas.restore();
              },
            ),
          );
        },
      ),
    );
  }

  static Component scorePopup(Vector2 position, int score, {Color? color}) {
    return ParticleSystemComponent(
      position: position,
      particle: flame_particles.Particle.generate(
        count: 1,
        lifespan: 1.0,
        generator: (i) {
          return flame_particles.AcceleratedParticle(
            speed: Vector2(0, -40),
            child: flame_particles.ComputedParticle(
              renderer: (canvas, particle) {
                final opacity = 1.0 - particle.progress;
                final scale = 1.0 + particle.progress * 0.3;
                final textPainter = TextPainter(
                  text: TextSpan(
                    text: '+$score',
                    style: TextStyle(
                      fontSize: 14 * scale,
                      fontWeight: FontWeight.bold,
                      color: (color ?? Colors.white).withValues(alpha: opacity),
                      fontFamily: 'Permanent Marker',
                    ),
                  ),
                  textDirection: TextDirection.ltr,
                )..layout();
                textPainter.paint(
                  canvas,
                  Offset(-textPainter.width / 2, -textPainter.height / 2),
                );
              },
            ),
          );
        },
      ),
    );
  }

  static Component comboPopup(Vector2 position, int combo) {
    return ParticleSystemComponent(
      position: position,
      particle: flame_particles.Particle.generate(
        count: 1,
        lifespan: 1.2,
        generator: (i) {
          return flame_particles.AcceleratedParticle(
            speed: Vector2(0, -30),
            child: flame_particles.ComputedParticle(
              renderer: (canvas, particle) {
                final opacity = 1.0 - particle.progress;
                final scale = 1.0 + sin(particle.progress * pi) * 0.5;
                final textPainter = TextPainter(
                  text: TextSpan(
                    text: 'Combo x$combo!',
                    style: TextStyle(
                      fontSize: 18 * scale,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.softYellow.withValues(alpha: opacity),
                      fontFamily: 'Permanent Marker',
                    ),
                  ),
                  textDirection: TextDirection.ltr,
                )..layout();
                textPainter.paint(
                  canvas,
                  Offset(-textPainter.width / 2, -textPainter.height / 2),
                );
              },
            ),
          );
        },
      ),
    );
  }

  static Component wordBonusPopup(Vector2 position, String word, int multiplier) {
    return ParticleSystemComponent(
      position: position,
      particle: flame_particles.Particle.generate(
        count: 1,
        lifespan: 2.0,
        generator: (i) {
          return flame_particles.AcceleratedParticle(
            speed: Vector2(0, -20),
            child: flame_particles.ComputedParticle(
              renderer: (canvas, particle) {
                final opacity = particle.progress < 0.8
                    ? 1.0
                    : 1.0 - (particle.progress - 0.8) * 5;
                final scale = 1.0 + sin(particle.progress * pi * 2) * 0.1;
                final textPainter = TextPainter(
                  text: TextSpan(
                    text: '$word ${multiplier}x!',
                    style: TextStyle(
                      fontSize: 20 * scale,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'MVFaseyha',
                      color: AppTheme.turquoise.withValues(alpha: opacity.clamp(0.0, 1.0)),
                    ),
                  ),
                  textDirection: TextDirection.rtl,
                )..layout();
                textPainter.paint(
                  canvas,
                  Offset(-textPainter.width / 2, -textPainter.height / 2),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
