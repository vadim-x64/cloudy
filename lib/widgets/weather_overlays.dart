import 'dart:math' as math;
import 'package:flutter/material.dart';

class WeatherOverlayManager extends StatefulWidget {
  final String iconCode;
  final String partOfDay;
  final GlobalKey? sourceKey;

  const WeatherOverlayManager({
    super.key,
    required this.iconCode,
    required this.partOfDay,
    this.sourceKey,
  });

  @override
  State<WeatherOverlayManager> createState() => _WeatherOverlayManagerState();
}

class _WeatherOverlayManagerState extends State<WeatherOverlayManager>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Alignment _originAlignment = const Alignment(0.0, 0.5);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateOrigin();
    });
  }

  void _calculateOrigin() {
    if (widget.sourceKey?.currentContext != null) {
      final RenderBox box = widget.sourceKey!.currentContext!.findRenderObject() as RenderBox;
      final Offset position = box.localToGlobal(Offset.zero);
      final Size screenSize = MediaQuery.of(context).size;
      final double centerX = position.dx + box.size.width / 2;
      final double centerY = position.dy + box.size.height / 2;

      if (mounted) {
        setState(() {
          _originAlignment = Alignment(
            (centerX / screenSize.width) * 2 - 1,
            (centerY / screenSize.height) * 2 - 1,
          );
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scaleAnim = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.02, end: 1.0).chain(CurveTween(curve: Curves.easeOutBack)),
          weight: 20),
      TweenSequenceItem(
          tween: ConstantTween(1.0),
          weight: 60),
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.02).chain(CurveTween(curve: Curves.easeInOutCubic)),
          weight: 20),
    ]).animate(_controller);

    return ScaleTransition(
      scale: scaleAnim,
      alignment: _originAlignment,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _getPainterForWeather(widget.iconCode, _controller.value, widget.partOfDay),
            size: Size.infinite,
          );
        },
      ),
    );
  }

  CustomPainter _getPainterForWeather(String iconCode, double progress, String partOfDay) {
    if (iconCode.startsWith('01')) {
      if (partOfDay == 'Світанок' || partOfDay == 'Вечір') {
        return _HorizonSunPainter(progress, isSunset: partOfDay == 'Вечір');
      }
      return iconCode.contains('d') ? _SunPainter(progress) : _MoonPainter(progress);
    } else if (iconCode.startsWith('02')) {
      return _PartlyCloudyPainter(progress, isNight: iconCode.contains('n'), partOfDay: partOfDay);
    } else if (iconCode.startsWith('03') || iconCode.startsWith('04')) {
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

class _HorizonSunPainter extends CustomPainter {
  final double progress;
  final bool isSunset;

  _HorizonSunPainter(this.progress, {required this.isSunset});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final scale = 1.0 + math.sin(progress * math.pi) * 0.2;
    final baseRadius = size.width * 0.30 * scale;

    final sunColor = isSunset ? Colors.deepOrangeAccent : Colors.amber;
    final glowColor = isSunset ? Colors.deepOrange : Colors.orangeAccent;

    final horizonY = center.dy + baseRadius * 0.2;

    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, 0, size.width, horizonY));

    final glowPaint = Paint()
      ..color = glowColor.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
    canvas.drawCircle(center, baseRadius * 1.5, glowPaint);

    final sunPaint = Paint()..color = sunColor;
    canvas.drawCircle(center, baseRadius, sunPaint);

    final rayPaint = Paint()
      ..color = sunColor
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(progress * math.pi * 0.5 * (isSunset ? 1 : -1));

    for (int i = 0; i < 8; i++) {
      canvas.rotate((2 * math.pi) / 8);
      canvas.drawLine(
        Offset(0, baseRadius + 15),
        Offset(0, baseRadius + 45),
        rayPaint,
      );
    }
    canvas.restore();
    canvas.restore();

    final horizonPaint = Paint()
      ..color = sunColor.withOpacity(0.8)
      ..strokeWidth = size.width * 0.02
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(center.dx - baseRadius * 1.8, horizonY),
      Offset(center.dx + baseRadius * 1.8, horizonY),
      horizonPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _HorizonSunPainter oldDelegate) => true;
}

class _SunPainter extends CustomPainter {
  final double progress;

  _SunPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final scale = 1.0 + math.sin(progress * math.pi) * 0.2;
    final baseRadius = size.width * 0.30 * scale;

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

    final center = Offset(size.width / 2, size.height / 2);
    final pulse = math.sin(progress * math.pi * 2);
    final scale = 1.0 + pulse * 0.03;
    final radius = size.width * 0.30 * scale;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(pulse * 0.05);

    final glowPaint = Paint()
      ..color = Colors.blue.shade100.withOpacity(0.2 + pulse * 0.05)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
    canvas.drawCircle(Offset.zero, radius * 1.2, glowPaint);

    final moonBaseColor = const Color(0xFFE2E8F0);
    final shadowColor = const Color(0xFFCBD5E1);
    final moonPaint = Paint()..color = moonBaseColor;

    canvas.drawCircle(Offset.zero, radius, moonPaint);
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: radius)));

    final moonShadowPaint = Paint()
      ..color = shadowColor.withOpacity(0.7)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawCircle(Offset(radius * 0.15, radius * 0.15), radius * 0.85, moonShadowPaint);

    void drawIrregularCrater(double x, double y, double w, double h, double angle) {
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);

      canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: w, height: h),
          Paint()..color = shadowColor
      );

      canvas.drawOval(
          Rect.fromCenter(center: Offset(w * 0.1, h * 0.15), width: w * 0.85, height: h * 0.85),
          Paint()..color = moonBaseColor
      );

      canvas.restore();
    }

    drawIrregularCrater(-radius * 0.5, -radius * 0.6, radius * 0.45, radius * 0.3, -0.2);
    drawIrregularCrater(radius * 0.6, -radius * 0.4, radius * 0.35, radius * 0.5, 0.4);
    drawIrregularCrater(-radius * 0.75, radius * 0.1, radius * 0.5, radius * 0.25, 0.5);
    drawIrregularCrater(radius * 0.1, -radius * 0.2, radius * 0.25, radius * 0.18, 0.0);
    drawIrregularCrater(radius * 0.45, radius * 0.65, radius * 0.6, radius * 0.3, -0.3);
    drawIrregularCrater(-radius * 0.2, radius * 0.55, radius * 0.35, radius * 0.2, 0.1);
    drawIrregularCrater(radius * 0.8, radius * 0.2, radius * 0.4, radius * 0.6, 0.2);
    drawIrregularCrater(-radius * 0.1, -radius * 0.8, radius * 0.3, radius * 0.2, 0.1);

    canvas.restore();
    canvas.restore();
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
    final paint = Paint();

    void drawCloud(double x, double y, double scale, double opacity) {
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
          ..color = Colors.black12.withOpacity(0.1 * opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );

      canvas.drawPath(
        path,
        paint..color = Colors.white,
      );
      canvas.restore();
    }

    double fade = math.sin(progress * math.pi);
    double moveX = progress * size.width * 0.3;

    double floatY1 = math.sin(progress * math.pi * 2) * 15;
    double floatY2 = math.cos(progress * math.pi * 2) * 20;
    double floatY3 = math.sin(progress * math.pi * 2 + math.pi / 4) * 12;
    double floatY4 = math.cos(progress * math.pi * 2 + math.pi / 3) * 18;
    double floatY5 = math.sin(progress * math.pi * 2 - math.pi / 6) * 14;

    drawCloud(size.width * 0.1 + moveX * 0.8, size.height * 0.15 + floatY1, 1.4, fade * 0.6);
    drawCloud(size.width * 0.85 - moveX * 0.5, size.height * 0.25 + floatY2, 1.1, fade * 0.9);
    drawCloud(size.width * -0.05 + moveX * 1.2, size.height * 0.45 + floatY3, 0.8, fade * 0.4);
    drawCloud(size.width * 0.75 + moveX * 0.6, size.height * 0.65 + floatY4, 1.7, fade * 0.95);
    drawCloud(size.width * 0.25 + moveX * 0.9, size.height * 0.85 + floatY5, 1.2, fade * 0.7);
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
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100.0);

    for (int i = 0; i < 4; i++) {
      double phaseX = (progress * math.pi * 2) + (i * 2.0);
      double phaseY = (progress * math.pi * 1.5) + (i * 1.5);

      double x = size.width * 0.5 + math.sin(phaseX) * (size.width * 0.6);
      double y = size.height * (0.15 + i * 0.12) + math.cos(phaseY) * (size.height * 0.15);

      double w = size.width * 2.2;
      double h = size.height * 0.45;

      paint.color = Colors.white.withOpacity(0.25 + (i % 3) * 0.15);

      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: w, height: h),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FogPainter oldDelegate) => true;
}

class _PartlyCloudyPainter extends CustomPainter {
  final double progress;
  final bool isNight;
  final String partOfDay;

  _PartlyCloudyPainter(this.progress, {required this.isNight, required this.partOfDay});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width * 0.15, -size.height * 0.1);
    canvas.scale(0.85);

    if (isNight) {
      _MoonPainter(progress).paint(canvas, size);
    } else if (partOfDay == 'Світанок' || partOfDay == 'Вечір') {
      _HorizonSunPainter(progress, isSunset: partOfDay == 'Вечір').paint(canvas, size);
    } else {
      _SunPainter(progress).paint(canvas, size);
    }
    canvas.restore();

    _CloudPainter(progress, isNight: isNight).paint(canvas, size);
  }

  @override
  bool shouldRepaint(covariant _PartlyCloudyPainter oldDelegate) => true;
}