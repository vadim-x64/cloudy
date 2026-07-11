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
        baseColors = [const Color(0xFF14001F), const Color(0xFF310051)];
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

  String _cleanDesc(String raw) {
    String desc = raw
        .toLowerCase()
        .replaceAll('часткова хмарність', 'хмарно з проясненнями')
        .replaceAll('місцями хмарно', 'мінлива хмарність')
        .replaceAll('кілька хмар', 'малохмарно')
        .replaceAll('чисте небо', 'ясно')
        .replaceAll('мряка', 'дрібний дощ')
        .replaceAll('димка', 'імла');
    return desc.isNotEmpty
        ? '${desc[0].toUpperCase()}${desc.substring(1)}'
        : '';
  }

  String _getUkrainianWeekdayShort(int weekday) {
    const days = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'НД'];
    return days[weekday - 1];
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            decoration: TextDecoration.none,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    String desc = _cleanDesc(weather.description);
    String pressureStr = '${(weather.pressure * 0.750062).round()} мм';
    String sunriseStr = DateFormat('HH:mm').format(weather.sunrise);
    String sunsetStr = DateFormat('HH:mm').format(weather.sunset);

    return ClipRRect(
      borderRadius: BorderRadius.circular(50),
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
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    weather.cityName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.refresh, color: Colors.white, size: 38),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('HH:mm').format(weather.currentLocalTime),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 70,
                        fontWeight: FontWeight.w300,
                        height: 1.0,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${DateFormat('dd.MM.yyyy').format(weather.currentLocalTime)} • ${weather.partOfDay}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '${weather.temperature.round()}°',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 85,
                        fontWeight: FontWeight.w200,
                        height: 1.0,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Відчувається: ${weather.feelsLike.round()}°',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 150,
                      child: Text(
                        desc,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.none,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: AnimatedWeatherIcon(
                          iconCode: weather.iconCode,
                          size: 120,
                          partOfDay: weather.partOfDay,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildDetailItem(
                    Icons.water_drop,
                    'Вологість',
                    '${weather.humidity}%',
                  ),
                  _buildDetailItem(
                    Icons.umbrella,
                    'Опади',
                    '${weather.precipitation} мм',
                  ),
                  _buildDetailItem(
                    Icons.air,
                    'Вітер',
                    '${weather.windSpeed} м/с',
                  ),
                  _buildDetailItem(Icons.speed, 'Тиск', pressureStr),
                  _buildDetailItem(Icons.wb_twilight, 'Схід', sunriseStr),
                  _buildDetailItem(Icons.nights_stay, 'Захід', sunsetStr),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: weather.dailyForecast.take(4).map((daily) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getUkrainianWeekdayShort(daily.date.weekday),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: AnimatedWeatherIcon(
                            iconCode: daily.iconCode,
                            size: 60,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${daily.maxTemp.round()}° / ${daily.minTemp.round()}°',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          decoration: TextDecoration.none,
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
