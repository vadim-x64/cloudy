import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import '../models/weather_model.dart';
import '../widgets/animated_weather_icon.dart';

class WidgetService {
  static const String androidWidgetName = 'WeatherWidgetProvider';

  static Future<void> updateWeatherWidget(WeatherModel weather) async {
    await HomeWidget.renderFlutterWidget(
      WeatherWidgetUI(weather: weather),
      logicalSize: const Size(900, 600),
      key: 'widget_image',
    );

    await HomeWidget.updateWidget(
      name: androidWidgetName,
      androidName: androidWidgetName,
    );
  }
}

class WeatherWidgetUI extends StatelessWidget {
  final WeatherModel weather;

  const WeatherWidgetUI({super.key, required this.weather});

  List<Color> _getBackgroundColors() {
    String condition = weather.mainCondition.toLowerCase();
    String partOfDay = weather.partOfDay;
    List<Color> baseColors;

    switch (partOfDay) {
      case 'Світанок':
        baseColors = [Colors.orange.shade900, Colors.orange.shade600];
        break;
      case 'Ранок':
        baseColors = [const Color(0xFF1F6F5E), Colors.greenAccent.shade700];
        break;
      case 'День':
        baseColors = [Colors.blue.shade700, Colors.lightBlue.shade500];
        break;
      case 'Полудень':
        baseColors = [Colors.indigoAccent.shade700, Colors.blue.shade600];
        break;
      case 'Вечір':
        baseColors = [Colors.deepOrange.shade900, Colors.deepOrange.shade700];
        break;
      case 'Сутінки':
      case 'Ніч':
      default:
        baseColors = [const Color(0xFF10092B), const Color(0xFF0A1B3F)];
        break;
    }

    if (condition.contains('rain') ||
        condition.contains('snow') ||
        condition.contains('fog')) {
      return baseColors
          .map((c) => Color.lerp(c, Colors.blueGrey.shade800, 0.55)!)
          .toList();
    }
    return baseColors;
  }

  @override
  Widget build(BuildContext context) {
    String desc = weather.description.isNotEmpty
        ? '${weather.description[0].toUpperCase()}${weather.description.substring(1)}'
        : '';

    final daily = weather.dailyForecast.isNotEmpty
        ? weather.dailyForecast.first
        : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(60),
      child: Container(
        width: 900,
        height: 600,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _getBackgroundColors(),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white.withOpacity(0.25), width: 2),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    weather.cityName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 45,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    desc,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${weather.temperature.round()}°',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 140,
                          fontWeight: FontWeight.w200,
                          height: 1.0,
                        ),
                      ),
                      if (daily != null)
                        Text(
                          'Макс: ${daily.maxTemp.round()}° · Мін: ${daily.minTemp.round()}°',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 26,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(
                    width: 170,
                    height: 170,
                    child: AnimatedWeatherIcon(
                      iconCode: weather.iconCode,
                      size: 170,
                      partOfDay: weather.partOfDay,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(35),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: weather.hourlyForecast.take(5).map((hourly) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(hourly.time),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: 55,
                        height: 55,
                        child: AnimatedWeatherIcon(
                          iconCode: hourly.iconCode,
                          size: 55,
                          partOfDay: weather.partOfDay,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${hourly.temperature.round()}°',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
