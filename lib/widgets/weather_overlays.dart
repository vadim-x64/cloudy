// ===== weather_overlays.dart =====

import 'dart:math' as math;
import 'package:flutter/material.dart';

class WeatherOverlayManager extends StatefulWidget {
  final String iconCode;

  const WeatherOverlayManager({super.key, required this.iconCode});

  @override
  State<WeatherOverlayManager> createState() => _WeatherOverlayManagerState();
}

class _WeatherOverlayManagerState extends State<WeatherOverlayManager>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
        TweenSequenceItem(tween: ConstantTween(1.0), weight: 70),
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 15),
      ]).animate(_controller),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _getPainterForWeather(widget.iconCode, _controller.value),
            size: Size.infinite,
          );
        },
      ),
    );
  }

  CustomPainter _getPainterForWeather(String iconCode, double progress) {
    if (iconCode.startsWith('01')) {
      return iconCode.contains('d')
          ? _SunPainter(progress)
          : _MoonPainter(progress);
    } else if (iconCode.startsWith('02') ||
        iconCode.startsWith('03') ||
        iconCode.startsWith('04')) {
      return _CloudPainter(progress, isNight: iconCode.contains('n'));
    } else if (iconCode.startsWith('09') || iconCode.startsWith('10')) {
      return _RainPainter(progress);
    } else if (iconCode.startsWith('11')) {
      return _StormPainter(progress);
    } else if (iconCode.startsWith('13')) {
      return _SnowPainter(progress);
    } else if (iconCode.startsWith('50')) {
      return _FogPainter(progress);
    }

    return _SunPainter(progress);
  }
}

class _SunPainter extends CustomPainter {
  final double progress;

  _SunPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2.5);
    final scale = 1.0 + math.sin(progress * math.pi) * 0.2;
    final baseRadius = size.width * 0.25 * scale;

    final glowPaint = Paint()
      ..color = Colors.orangeAccent.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
    canvas.drawCircle(center, baseRadius * 1.5, glowPaint);

    final sunPaint = Paint()..color = Colors.amber;
    canvas.drawCircle(center, baseRadius, sunPaint);

    final rayPaint = Paint()
      ..color = Colors.amberAccent
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(progress * math.pi * 0.5);

    for (int i = 0; i < 8; i++) {
      canvas.rotate((2 * math.pi) / 8);
      canvas.drawLine(
        Offset(0, baseRadius + 15),
        Offset(0, baseRadius + 45),
        rayPaint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SunPainter oldDelegate) => true;
}

class _MoonPainter extends CustomPainter {
  final double progress;

  _MoonPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final rand = math.Random(42);
    final starPaint = Paint()..color = Colors.white;

    for (int i = 0; i < 50; i++) {
      double sx = rand.nextDouble() * size.width;
      double sy = rand.nextDouble() * size.height;
      double maxRadius = rand.nextDouble() * 2 + 1;

      double twinkle = (math.sin((progress * math.pi * 10) + i) + 1) / 2;
      starPaint.color = Colors.white.withOpacity(twinkle * 0.8 + 0.2);

      canvas.drawCircle(Offset(sx, sy), maxRadius, starPaint);
    }

    final center = Offset(size.width / 2, size.height / 3);
    final radius = size.width * 0.2;

    final glowPaint = Paint()
      ..color = Colors.blue.shade100.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
    canvas.drawCircle(center, radius * 1.3, glowPaint);

    Path moonPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));

    Path cutOut = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(center.dx + radius * 0.4, center.dy - radius * 0.3),
          radius: radius * 0.9,
        ),
      );

    Path finalMoon = Path.combine(PathOperation.difference, moonPath, cutOut);

    canvas.drawPath(finalMoon, Paint()..color = Colors.blueGrey.shade100);
  }

  @override
  bool shouldRepaint(covariant _MoonPainter oldDelegate) => true;
}

class _CloudPainter extends CustomPainter {
  final double progress;
  final bool isNight;

  _CloudPainter(this.progress, {required this.isNight});

  @override
  void paint(Canvas canvas, Size size) {
    final cloudColor = isNight
        ? Colors.blueGrey.shade400.withOpacity(0.85)
        : Colors.white.withOpacity(0.9);

    final paint = Paint()..color = cloudColor;

    void drawCloud(double x, double y, double scale) {
      canvas.save();
      canvas.translate(x, y);
      canvas.scale(scale);

      Path path = Path();
      path.addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-60, 0, 120, 40),
          const Radius.circular(20),
        ),
      );
      path.addOval(const Rect.fromLTWH(-40, -30, 60, 60));
      path.addOval(const Rect.fromLTWH(0, -20, 50, 50));

      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.black12
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
      canvas.drawPath(path, paint);
      canvas.restore();
    }

    double moveX = progress * size.width * 0.5;
    drawCloud(size.width * 0.2 + moveX, size.height * 0.2, 1.5);
    drawCloud(size.width * 0.8 - moveX * 0.5, size.height * 0.4, 1.2);
    drawCloud(size.width * 0.1 + moveX * 1.2, size.height * 0.6, 1.8);
  }

  @override
  bool shouldRepaint(covariant _CloudPainter oldDelegate) => true;
}

class _RainPainter extends CustomPainter {
  final double progress;

  _RainPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.lightBlueAccent.withOpacity(0.7)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final rand = math.Random(123);

    for (int i = 0; i < 100; i++) {
      double startX = rand.nextDouble() * size.width * 1.5 - size.width * 0.2;
      double speedY = rand.nextDouble() * 3 + 2.0;

      double y =
          (rand.nextDouble() * size.height +
              (progress * 10 * speedY * size.height * 0.2)) %
          size.height;
      double x = startX - (y * 0.15);

      canvas.drawLine(Offset(x, y), Offset(x - 5, y + 20), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RainPainter oldDelegate) => true;
}

class _StormPainter extends _RainPainter {
  _StormPainter(super.progress);

  @override
  void paint(Canvas canvas, Size size) {
    super.paint(canvas, size);

    bool isFlash =
        (progress > 0.20 && progress < 0.25) ||
        (progress > 0.60 && progress < 0.63) ||
        (progress > 0.68 && progress < 0.70);

    if (isFlash) {
      final flashPaint = Paint()
        ..color = Colors.white.withOpacity(0.8)
        ..blendMode = BlendMode.srcOver;
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), flashPaint);
    }
  }
}

class _SnowPainter extends CustomPainter {
  final double progress;

  _SnowPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final rand = math.Random(777);

    for (int i = 0; i < 80; i++) {
      double startX = rand.nextDouble() * size.width;
      double speedY = rand.nextDouble() * 1.5 + 0.5;

      double y =
          (rand.nextDouble() * size.height +
              (progress * 5 * speedY * size.height * 0.2)) %
          size.height;
      double wobble = math.sin((progress * math.pi * 6) + i) * 25;
      double flakeSize = rand.nextDouble() * 4 + 2;

      paint.color = Colors.white.withOpacity(rand.nextDouble() * 0.5 + 0.5);
      canvas.drawCircle(Offset(startX + wobble, y), flakeSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SnowPainter oldDelegate) => true;
}

class _FogPainter extends CustomPainter {
  final double progress;

  _FogPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        1,
      );

    for (int i = 0; i < 4; i++) {
      double yBase =
          size.height * (0.2 + i * 0.2);
      double phase =
          (progress * math.pi * 2) +
          (i * 1.5);
      double amplitude = 20.0 + (i * 5.0);
      double frequency = 0.008 + (i * 0.002);

      Path path = Path();
      path.moveTo(-50, yBase + math.sin(phase) * amplitude);

      for (double x = 0; x <= size.width + 50; x += 20) {
        double y = yBase + math.sin((x * frequency) + phase) * amplitude;
        path.lineTo(x, y);
      }

      paint.strokeWidth = 40.0 + (i * 15.0);
      paint.color = Colors.white.withOpacity(0.2 + (i % 2) * 0.15);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FogPainter oldDelegate) => true;
}