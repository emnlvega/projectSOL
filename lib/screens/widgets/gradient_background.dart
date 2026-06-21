import 'package:flutter/material.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;
  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: const [
            Color(0xFF0A0E17),
            Color(0xFF1A1F2E),
            Color(0xFF0D111C),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: DotPatternPainter(),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double spacing = 25.0; // Más juntos para que se note más
    final double radius = 2.0; // Más grandes

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        // Calcular opacidad: más oscuro abajo y más claro arriba
        final opacity = 0.035 - (y / size.height) * 0.03;

        final paint = Paint()
          ..color = Colors.white.withOpacity(opacity.clamp(0.005, 0.035))
          ..style = PaintingStyle.fill;

        final offsetX = (x + (y * 0.5)) % spacing;
        final offsetY = (y + (x * 0.3)) % spacing;
        canvas.drawCircle(
          Offset(offsetX + x, offsetY + y),
          radius,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}