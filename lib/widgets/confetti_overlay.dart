import 'dart:math';
import 'package:flutter/material.dart';

/// Pluie de confettis jouée une seule fois, sans dépendance externe.
/// Remplit son parent (à placer dans un [Stack] au-dessus du contenu).
class ConfettiBox extends StatefulWidget {
  /// Durée de la chute avant disparition.
  final Duration duration;

  /// Nombre de confettis.
  final int count;

  const ConfettiBox({
    super.key,
    this.duration = const Duration(milliseconds: 2600),
    this.count = 60,
  });

  @override
  State<ConfettiBox> createState() => _ConfettiBoxState();
}

class _ConfettiBoxState extends State<ConfettiBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;

  static const _colors = [
    Color(0xFFC8752E),
    Color(0xFF9C4A1E),
    Color(0xFF305868),
    Color(0xFF4E7A3E),
    Color(0xFFE8A855),
    Color(0xFF8C3B4A),
  ];

  @override
  void initState() {
    super.initState();
    final rnd = Random();
    _particles = List.generate(widget.count, (_) {
      return _Particle(
        x: rnd.nextDouble(),
        startY: -rnd.nextDouble() * 0.4,
        fallSpeed: 0.7 + rnd.nextDouble() * 0.8,
        drift: (rnd.nextDouble() - 0.5) * 0.4,
        size: 5 + rnd.nextDouble() * 7,
        color: _colors[rnd.nextInt(_colors.length)],
        rotationSpeed: (rnd.nextDouble() - 0.5) * 12,
        phase: rnd.nextDouble() * pi * 2,
      );
    });
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.isCompleted) return const SizedBox.shrink();
          return CustomPaint(
            painter: _ConfettiPainter(_particles, _controller.value),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _Particle {
  final double x; // position horizontale relative [0..1]
  final double startY; // départ (relatif) au-dessus du cadre
  final double fallSpeed; // fraction de hauteur par unité de temps
  final double drift; // dérive horizontale
  final double size;
  final Color color;
  final double rotationSpeed;
  final double phase;

  const _Particle({
    required this.x,
    required this.startY,
    required this.fallSpeed,
    required this.drift,
    required this.size,
    required this.color,
    required this.rotationSpeed,
    required this.phase,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double t; // progression [0..1]

  _ConfettiPainter(this.particles, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    // Fondu en fin d'animation.
    final fade = t > 0.8 ? (1 - (t - 0.8) / 0.2).clamp(0.0, 1.0) : 1.0;
    for (final p in particles) {
      final y = (p.startY + p.fallSpeed * t) * size.height;
      if (y < -20 || y > size.height + 20) continue;
      final x =
          (p.x + p.drift * t + 0.02 * sin(p.phase + t * 10)) * size.width;
      paint.color = p.color.withValues(alpha: fade);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.phase + p.rotationSpeed * t);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: p.size,
          height: p.size * 0.5,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
