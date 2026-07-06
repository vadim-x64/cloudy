import 'dart:math';
import 'package:flutter/material.dart';

enum WeatherType {
  clear,
  partlyCloudy,
  cloudy,
  rain,
  snow,
  thunderstorm,
  fog,
  wind,
  sunAndRain,
  sleet,
}

class AnimatedWeatherIcon extends StatefulWidget {
  final String iconCode;
  final double size;
  final String? partOfDay;

  const AnimatedWeatherIcon({
    super.key,
    required this.iconCode,
    this.size = 100,
    this.partOfDay,
  });

  @override
  State<AnimatedWeatherIcon> createState() => _AnimatedWeatherIconState();
}

class _AnimatedWeatherIconState extends State<AnimatedWeatherIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDay = widget.iconCode.contains('d');
    WeatherType type;

    if (widget.iconCode == 'wind') {
      type = WeatherType.wind;
    } else if (widget.iconCode == 'sleet') {
      type = WeatherType.sleet;
    } else if (widget.iconCode == '10d' || widget.iconCode == '10n') {
      type = WeatherType.sunAndRain;
    } else if (widget.iconCode.startsWith('01')) {
      type = WeatherType.clear;
    } else if (widget.iconCode.startsWith('02')) {
      type = WeatherType.partlyCloudy;
    } else if (widget.iconCode.startsWith('03') ||
        widget.iconCode.startsWith('04')) {
      type = WeatherType.cloudy;
    } else if (widget.iconCode.startsWith('09')) {
      type = WeatherType.rain;
    } else if (widget.iconCode.startsWith('11')) {
      type = WeatherType.thunderstorm;
    } else if (widget.iconCode.startsWith('13')) {
      type = WeatherType.snow;
    } else {
      type = WeatherType.fog;
    }

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: WeatherIconPainter(
              animationValue: _controller.value,
              type: type,
              isDay: isDay,
              partOfDay: widget.partOfDay,
            ),
          );
        },
      ),
    );
  }
}

class WeatherIconPainter extends CustomPainter {
  final double animationValue;
  final WeatherType type;
  final bool isDay;
  final String? partOfDay;

  WeatherIconPainter({
    required this.animationValue,
    required this.type,
    required this.isDay,
    this.partOfDay,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double center = size.width / 2;
    final Offset centerOffset = Offset(center, center);

    bool isSunrise = partOfDay == 'Світанок';
    bool isSunset = partOfDay == 'Вечір';
    bool isNightTime =
        partOfDay == 'Сутінки' ||
        partOfDay == 'Ніч' ||
        (!isDay && !isSunrise && !isSunset);

    if (type == WeatherType.clear || type == WeatherType.partlyCloudy) {
      if (type == WeatherType.partlyCloudy) {
        if (isNightTime) {
          _drawMoonAndStars(canvas, size, centerOffset, isPartial: true);
        } else {
          _drawSun(canvas, size, centerOffset, isPartial: true);
        }
      } else {
        if (isSunrise) {
          _drawHorizonSun(
            canvas,
            size,
            centerOffset,
            isPartial: false,
            isSunset: false,
          );
        } else if (isSunset) {
          _drawHorizonSun(
            canvas,
            size,
            centerOffset,
            isPartial: false,
            isSunset: true,
          );
        } else if (isNightTime) {
          _drawMoonAndStars(canvas, size, centerOffset, isPartial: false);
        } else {
          _drawSun(canvas, size, centerOffset, isPartial: false);
        }
      }
    }

    switch (type) {
      case WeatherType.rain:
      case WeatherType.thunderstorm:
        if (type == WeatherType.thunderstorm) {
          _drawLightning(canvas, size);
        }
        _drawRain(canvas, size);
        break;
      case WeatherType.snow:
        _drawSnow(canvas, size);
        break;
      case WeatherType.fog:
        _drawFog(canvas, size);
        break;
      case WeatherType.wind:
        _drawWind(canvas, size);
        break;
      case WeatherType.sunAndRain:
        if (isNightTime) {
          _drawMoonAndStars(canvas, size, centerOffset, isPartial: true);
        } else {
          _drawSun(canvas, size, centerOffset, isPartial: true);
        }
        _drawRain(canvas, size);
        break;
      case WeatherType.sleet:
        _drawRain(canvas, size);
        _drawSnow(canvas, size);
        break;
      default:
        break;
    }

    if (type != WeatherType.clear && type != WeatherType.wind) {
      _drawClouds(canvas, size, centerOffset);
    }
  }

  void _drawWind(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = size.width * 0.03
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final double offset = (animationValue * pi * 2);

    for (int i = 0; i < 3; i++) {
      double startX = size.width * 0.1 + (i * size.width * 0.1);
      double startY = size.height * 0.3 + (i * size.height * 0.2);
      double waveOffset = sin(offset + i) * 10;

      Path path = Path();
      path.moveTo(startX, startY);
      path.quadraticBezierTo(
        size.width * 0.5,
        startY - 20 + waveOffset,
        size.width * 0.8,
        startY + waveOffset,
      );

      paint.color = Colors.white.withOpacity(
        0.3 + (sin(offset + i * 2) + 1) * 0.2,
      );
      canvas.drawPath(path, paint);
    }
  }

  void _drawSun(
    Canvas canvas,
    Size size,
    Offset center, {
    bool isPartial = false,
  }) {
    final double radius = size.width * (isPartial ? 0.2 : 0.25);
    final Offset sunCenter = isPartial
        ? Offset(size.width * 0.65, size.height * 0.35)
        : center;

    final glowPaint = Paint()..color = Colors.orangeAccent.withOpacity(0.5);
    canvas.drawCircle(sunCenter, radius * 1.3, glowPaint);

    final paint = Paint()..color = Colors.amber;
    canvas.drawCircle(sunCenter, radius, paint);

    final double rayLength = radius * 0.55;
    final int rayCount = 8;
    final double rayStroke = size.width * 0.035;

    final rayPaint = Paint()
      ..color = Colors.amber
      ..strokeWidth = rayStroke
      ..strokeCap = StrokeCap.round;

    canvas.save();
    canvas.translate(sunCenter.dx, sunCenter.dy);
    canvas.rotate(animationValue * pi * 0.5);

    for (int i = 0; i < rayCount; i++) {
      canvas.rotate((2 * pi) / rayCount);
      canvas.drawLine(
        Offset(0, radius + radius * 0.25),
        Offset(0, radius + radius * 0.25 + rayLength),
        rayPaint,
      );
    }
    canvas.restore();
  }

  void _drawMoonAndStars(
    Canvas canvas,
    Size size,
    Offset center, {
    bool isPartial = false,
  }) {
    final double radius = size.width * (isPartial ? 0.2 : 0.25);
    final Offset moonCenter = isPartial
        ? Offset(size.width * 0.75, size.height * 0.3)
        : center;

    if (!isPartial) {
      final starPaint = Paint()..style = PaintingStyle.fill;
      final Random rand = Random(62);

      for (int i = 0; i < 10; i++) {
        double sx = size.width * 0.05 + rand.nextDouble() * (size.width * 0.9);
        double sy = size.height * 0.05 + rand.nextDouble() * (size.height);

        double opacity = (sin((animationValue * pi * 4) + i * 1.5) + 1) / 2;
        starPaint.color = Colors.white.withOpacity(0.25 + opacity * 0.75);
        double starRadius = size.width * (0.02 + rand.nextDouble() * 0.02);
        double inner = starRadius * 0.25;
        Path starPath = Path();
        starPath.moveTo(sx, sy - starRadius);
        starPath.quadraticBezierTo(sx + inner, sy - inner, sx + starRadius, sy);
        starPath.quadraticBezierTo(sx + inner, sy + inner, sx, sy + starRadius);
        starPath.quadraticBezierTo(sx - inner, sy + inner, sx - starRadius, sy);
        starPath.quadraticBezierTo(sx - inner, sy - inner, sx, sy - starRadius);
        starPath.close();
        canvas.drawPath(starPath, starPaint);
      }
    }

    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    double rockAngle = sin(animationValue * pi * 2) * 0.12;
    canvas.save();
    canvas.translate(moonCenter.dx, moonCenter.dy);
    canvas.rotate(rockAngle);

    final moonPaint = Paint()..color = Colors.blueGrey.shade100;
    canvas.drawCircle(Offset.zero, radius, moonPaint);

    final cutPaint = Paint()
      ..color = Colors.black
      ..blendMode = BlendMode.dstOut;

    canvas.drawCircle(
      Offset(radius * 0.4, -radius * 0.3),
      radius * 0.9,
      cutPaint,
    );

    canvas.restore();
    canvas.restore();
  }

  void _drawHorizonSun(
    Canvas canvas,
    Size size,
    Offset center, {
    bool isPartial = false,
    bool isSunset = false,
  }) {
    final double radius = size.width * (isPartial ? 0.2 : 0.25);
    final Offset sunCenter = isPartial
        ? Offset(size.width * 0.65, size.height * 0.35)
        : center;
    final Offset adjustedCenter = Offset(
      sunCenter.dx,
      sunCenter.dy + radius * 0.4,
    );
    final double horizonY = adjustedCenter.dy + radius * 0.2;
    final Color sunColor = isSunset ? Colors.deepOrangeAccent : Colors.amber;
    final Color glowColor = isSunset ? Colors.deepOrange : Colors.orangeAccent;
    final double lineThickness = size.width * 0.02;

    canvas.save();
    canvas.clipRect(
      Rect.fromLTRB(0, 0, size.width, horizonY - (lineThickness / 2)),
    );

    final glowPaint = Paint()..color = glowColor.withOpacity(0.5);
    canvas.drawCircle(adjustedCenter, radius * 1.3, glowPaint);

    final paint = Paint()..color = sunColor;
    canvas.drawCircle(adjustedCenter, radius, paint);

    final double rayLength = radius * 0.55;
    final int rayCount = 8;
    final double rayStroke = size.width * 0.035;

    final rayPaint = Paint()
      ..color = sunColor
      ..strokeWidth = rayStroke
      ..strokeCap = StrokeCap.round;

    canvas.save();
    canvas.translate(adjustedCenter.dx, adjustedCenter.dy);
    canvas.rotate(animationValue * pi * 0.5 * (isSunset ? 1 : -1));
    for (int i = 0; i < rayCount; i++) {
      canvas.rotate((2 * pi) / rayCount);
      canvas.drawLine(
        Offset(0, radius + radius * 0.25),
        Offset(0, radius + radius * 0.25 + rayLength),
        rayPaint,
      );
    }
    canvas.restore();
    canvas.restore();

    final horizonPaint = Paint()
      ..color = sunColor.withOpacity(0.8)
      ..strokeWidth = lineThickness
      ..strokeCap = StrokeCap.round;

    double hWidth = radius * 1.8;
    canvas.drawLine(
      Offset(adjustedCenter.dx - hWidth, horizonY),
      Offset(adjustedCenter.dx + hWidth, horizonY),
      horizonPaint,
    );
  }

  void _drawClouds(Canvas canvas, Size size, Offset center) {
    final double floatY = sin(animationValue * pi * 2) * (size.height * 0.02);
    final double floatX = cos(animationValue * pi * 2) * (size.width * 0.015);

    final Color cloudColor =
        type == WeatherType.rain || type == WeatherType.thunderstorm
        ? Colors.blueGrey.shade300
        : Colors.white;

    final cloudPaint = Paint()
      ..color = cloudColor
      ..style = PaintingStyle.fill;

    Path buildCloudPath(double cx, double cy, double scale) {
      Path path = Path();
      double w = size.width * 0.9 * scale;
      double h = size.width * 0.18 * scale;

      Rect baseRect = Rect.fromCenter(
        center: Offset(cx, cy + h * 0.5),
        width: w,
        height: h,
      );
      path.addRRect(RRect.fromRectAndRadius(baseRect, Radius.circular(h / 2)));

      path.addOval(
        Rect.fromCircle(
          center: Offset(cx - w * 0.05, cy - h * 0.3),
          radius: h * 1.2,
        ),
      );

      path.addOval(
        Rect.fromCircle(
          center: Offset(cx + w * 0.28, cy + h * 0.1),
          radius: h * 0.85,
        ),
      );

      path.addOval(
        Rect.fromCircle(
          center: Offset(cx - w * 0.32, cy + h * 0.1),
          radius: h * 0.7,
        ),
      );

      return path;
    }

    if (type == WeatherType.cloudy) {
      Path backCloud = buildCloudPath(
        size.width * 0.35 + floatX * 0.5,
        size.height * 0.35 + floatY * 0.5,
        0.85,
      );

      canvas.drawPath(backCloud, Paint()..color = cloudColor.withOpacity(0.7));
    }

    double mainX = size.width * 0.5 + floatX;
    double mainY = size.height * 0.5 + floatY;
    Path mainCloud = buildCloudPath(mainX, mainY, 1.0);

    canvas.drawPath(mainCloud, cloudPaint);
  }

  void _drawRain(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.lightBlueAccent.shade100
      ..strokeWidth = size.width * 0.03
      ..strokeCap = StrokeCap.round;

    final Random rand = Random(123);
    final int dropsCount = 12;

    for (int i = 0; i < dropsCount; i++) {
      double startX = size.width * 0.2 + rand.nextDouble() * (size.width * 0.7);
      double speedOffset = rand.nextDouble() * 3 + 1.2;
      double progress = (animationValue * speedOffset + (i * 0.2)) % 1.0;
      double startY = size.height * 0.45 + progress * (size.height * 0.55);
      double endY = startY + size.height * 0.12;

      if (startY < size.height) {
        canvas.drawLine(
          Offset(startX, startY),
          Offset(startX - size.width * 0.03, endY),
          paint,
        );
      }
    }
  }

  void _drawSnow(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final Random rand = Random(777);
    final int flakesCount = 7;

    for (int i = 0; i < flakesCount; i++) {
      double startX = size.width * 0.3 + rand.nextDouble() * (size.width * 0.4);
      double speedOffset = rand.nextDouble() * 1.5 + 0.5;
      double progress = (animationValue * speedOffset + (i * 0.15)) % 1.0;
      double y = size.height * 0.45 + progress * (size.height * 0.55);
      double x =
          startX + sin((animationValue * pi * 4) + i) * (size.width * 0.05);

      if (y < size.height) {
        canvas.drawCircle(Offset(x, y), size.width * 0.025, paint);
      }
    }
  }

  void _drawLightning(Canvas canvas, Size size) {
    bool shouldFlash =
        (animationValue > 0.1 && animationValue < 0.15) ||
        (animationValue > 0.6 && animationValue < 0.63);

    if (!shouldFlash) return;

    final paint = Paint()
      ..color = Colors.yellowAccent
      ..strokeWidth = size.width * 0.035
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    Path lightning = Path();
    double startX = size.width * 0.5;
    double startY = size.height * 0.4;

    lightning.moveTo(startX, startY);
    lightning.lineTo(startX - size.width * 0.1, startY + size.height * 0.2);
    lightning.lineTo(startX + size.width * 0.08, startY + size.height * 0.2);
    lightning.lineTo(startX - size.width * 0.15, startY + size.height * 0.45);

    canvas.drawPath(lightning, paint);
  }

  void _drawFog(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = size.width * 0.06
      ..strokeCap = StrokeCap.round;

    double offset1 = sin(animationValue * pi * 2) * (size.width * 0.08);
    double offset2 = cos(animationValue * pi * 2) * (size.width * 0.08);

    canvas.drawLine(
      Offset(size.width * 0.2 + offset1, size.height * 0.65),
      Offset(size.width * 0.8 + offset1, size.height * 0.65),
      paint,
    );

    canvas.drawLine(
      Offset(size.width * 0.3 - offset2, size.height * 0.8),
      Offset(size.width * 0.9 - offset2, size.height * 0.8),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant WeatherIconPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.type != type ||
        oldDelegate.isDay != isDay;
  }
}
