import 'dart:math' as math;
import 'package:flutter/material.dart';

class DynamicLoader extends StatefulWidget {
  final double size;
  const DynamicLoader({super.key, this.size = 80.0});

  @override
  State<DynamicLoader> createState() => _DynamicLoaderState();
}

class _DynamicLoaderState extends State<DynamicLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _LiquidGlossyPainter(_controller.value),
          );
        },
      ),
    );
  }
}

class _LiquidGlossyPainter extends CustomPainter {
  final double progress;
  _LiquidGlossyPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width / 2.2;

    final path = Path();
    const points = 60;

    for (int i = 0; i <= points; i++) {
      final theta = (i / points) * 2 * math.pi;

      final wave1 = math.sin(theta * 3 + progress * math.pi * 2) * 4;
      final wave2 = math.cos(theta * 2 - progress * math.pi * 4) * 3;
      final radius = baseRadius + wave1 + wave2;

      final x = center.dx + radius * math.cos(theta);
      final y = center.dy + radius * math.sin(theta);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment(-1.0 + math.sin(progress * math.pi * 2) * 0.5, -1.0 + math.cos(progress * math.pi) * 0.5),
        end: Alignment(1.0 + math.cos(progress * math.pi * 2) * 0.5, 1.0 + math.sin(progress * math.pi) * 0.5),
        colors: const [
          Colors.white,
          Color(0xFFFAFAFA),
          Color(0xFFEFEFEF),
          Colors.white,
        ],
        stops: const [0.0, 0.4, 0.7, 1.0],
        transform: GradientRotation(progress * math.pi * 2),
      ).createShader(Rect.fromCircle(center: center, radius: baseRadius));

    canvas.drawPath(path, gradientPaint);

    final highlightPath = Path();
    for (int i = 0; i <= points; i++) {
      final theta = (i / points) * 2 * math.pi;
      final wave1 = math.sin(theta * 3 + progress * math.pi * 2) * 4;
      final wave2 = math.cos(theta * 2 - progress * math.pi * 4) * 3;
      final radius = (baseRadius * 0.85) + wave1 + wave2;
      final x = center.dx + radius * math.cos(theta) - 4;
      final y = center.dy + radius * math.sin(theta) - 4;

      if (i == 0) {
        highlightPath.moveTo(x, y);
      } else {
        highlightPath.lineTo(x, y);
      }
    }
    highlightPath.close();

    final highlightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.9),
          Colors.white.withOpacity(0.0),
        ],
        stops: const [0.0, 0.5],
      ).createShader(Rect.fromCircle(center: center, radius: baseRadius));

    canvas.drawPath(highlightPath, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant _LiquidGlossyPainter oldDelegate) => true;
}