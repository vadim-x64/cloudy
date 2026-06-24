class HourlyForecast {
  final DateTime time;
  final double temperature;
  final String iconCode;

  HourlyForecast({
    required this.time,
    required this.temperature,
    required this.iconCode,
  });
}

class DailyForecast {
  final DateTime date;
  double minTemp;
  double maxTemp;
  String iconCode;

  DailyForecast({
    required this.date,
    required this.minTemp,
    required this.maxTemp,
    required this.iconCode,
  });
}

int _getWeatherPriority(String icon) {
  final code = icon.replaceAll('d', '').replaceAll('n', '');
  switch (code) {
    case '11':
      return 7;
    case '13':
      return 6;
    case '09':
      return 5;
    case '10':
      return 4;
    case '50':
      return 3;
    case '04':
      return 2;
    case '03':
      return 1;
    case '02':
      return 0;
    case '01':
      return -1;
    default:
      return -2;
  }
}

class WeatherModel {
  final String cityName;
  final String region;
  final String country;
  final double temperature;
  final double feelsLike;
  final String description;
  final String iconCode;
  final String mainCondition;
  final int humidity;
  final double windSpeed;
  final double precipitation;
  final int pressure;
  final int aqi;
  final DateTime localTime;
  final int timezoneOffset;
  final DateTime sunrise;
  final DateTime sunset;
  final List<HourlyForecast> hourlyForecast;
  final List<DailyForecast> dailyForecast;

  WeatherModel({
    required this.cityName,
    required this.region,
    required this.country,
    required this.temperature,
    required this.feelsLike,
    required this.description,
    required this.iconCode,
    required this.mainCondition,
    required this.humidity,
    required this.windSpeed,
    required this.precipitation,
    required this.pressure,
    required this.aqi,
    required this.localTime,
    required this.timezoneOffset,
    required this.sunrise,
    required this.sunset,
    required this.hourlyForecast,
    required this.dailyForecast,
  });

  DateTime get currentLocalTime {
    return DateTime.now().toUtc().add(Duration(seconds: timezoneOffset));
  }

  factory WeatherModel.fromJson(
    Map<String, dynamic> currentJson,
    Map<String, dynamic>? forecastJson,
    Map<String, dynamic>? aqiJson,
    String cityName,
    String region,
    String country,
  ) {
    int timezoneOffset = currentJson['timezone'] ?? 0;

    DateTime calcLocalTime = DateTime.now().toUtc().add(
      Duration(seconds: timezoneOffset),
    );
    DateTime calcSunrise = DateTime.fromMillisecondsSinceEpoch(
      currentJson['sys']['sunrise'] * 1000,
      isUtc: true,
    ).add(Duration(seconds: timezoneOffset));
    DateTime calcSunset = DateTime.fromMillisecondsSinceEpoch(
      currentJson['sys']['sunset'] * 1000,
      isUtc: true,
    ).add(Duration(seconds: timezoneOffset));

    double precip = 0.0;
    if (currentJson['rain'] != null) {
      precip =
          ((currentJson['rain']['1h'] ?? currentJson['rain']['3h'] ?? 0.0)
                  as num)
              .toDouble();
    } else if (currentJson['snow'] != null) {
      precip =
          ((currentJson['snow']['1h'] ?? currentJson['snow']['3h'] ?? 0.0)
                  as num)
              .toDouble();
    }

    int parsedAqi = 1;
    if (aqiJson != null &&
        aqiJson['list'] != null &&
        aqiJson['list'].isNotEmpty) {
      parsedAqi = aqiJson['list'][0]['main']['aqi'] ?? 1;
    }

    var currentWeathers = currentJson['weather'] as List;
    var bestCurrentWeather = currentWeathers[0];
    for (var w in currentWeathers) {
      if (_getWeatherPriority(w['icon']) >
          _getWeatherPriority(bestCurrentWeather['icon'])) {
        bestCurrentWeather = w;
      }
    }

    List<HourlyForecast> hourly = [];
    List<DailyForecast> daily = [];
    if (forecastJson != null && forecastJson['list'] != null) {
      final list = forecastJson['list'] as List;
      Map<String, DailyForecast> dailyMap = {};

      for (int i = 0; i < list.length; i++) {
        var item = list[i];
        DateTime dt = DateTime.fromMillisecondsSinceEpoch(
          item['dt'] * 1000,
          isUtc: true,
        ).add(Duration(seconds: timezoneOffset));

        var itemWeathers = item['weather'] as List;
        var bestItemWeather = itemWeathers[0];
        for (var w in itemWeathers) {
          if (_getWeatherPriority(w['icon']) >
              _getWeatherPriority(bestItemWeather['icon'])) {
            bestItemWeather = w;
          }
        }
        String hourlyIcon = bestItemWeather['icon'];

        if (hourly.length < 8) {
          hourly.add(
            HourlyForecast(
              time: dt,
              temperature: item['main']['temp'].toDouble(),
              iconCode: hourlyIcon,
            ),
          );
        }

        String dateKey =
            "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
        double temp = item['main']['temp'].toDouble();
        String normalizedIcon = hourlyIcon.contains('d')
            ? hourlyIcon
            : hourlyIcon.replaceAll('n', 'd');

        if (!dailyMap.containsKey(dateKey)) {
          dailyMap[dateKey] = DailyForecast(
            date: dt,
            minTemp: temp,
            maxTemp: temp,
            iconCode: normalizedIcon,
          );
        } else {
          if (temp < dailyMap[dateKey]!.minTemp)
            dailyMap[dateKey]!.minTemp = temp;
          if (temp > dailyMap[dateKey]!.maxTemp)
            dailyMap[dateKey]!.maxTemp = temp;

          if (_getWeatherPriority(normalizedIcon) >
              _getWeatherPriority(dailyMap[dateKey]!.iconCode)) {
            dailyMap[dateKey]!.iconCode = normalizedIcon;
          }
        }
      }
      daily = dailyMap.values.toList();
      if (daily.isNotEmpty && daily.first.date.day == calcLocalTime.day) {
        daily.removeAt(0);
      }
    }

    return WeatherModel(
      cityName: cityName,
      region: region,
      country: country,
      temperature: currentJson['main']['temp'].toDouble(),
      feelsLike: currentJson['main']['feels_like'].toDouble(),
      description: bestCurrentWeather['description'],
      iconCode: bestCurrentWeather['icon'],
      mainCondition: bestCurrentWeather['main'],
      humidity: currentJson['main']['humidity'],
      windSpeed: currentJson['wind']['speed'].toDouble(),
      precipitation: precip,
      pressure: currentJson['main']['pressure'] ?? 1013,
      aqi: parsedAqi,
      localTime: calcLocalTime,
      timezoneOffset: timezoneOffset,
      sunrise: calcSunrise,
      sunset: calcSunset,
      hourlyForecast: hourly,
      dailyForecast: daily,
    );
  }

  bool get isDayTime {
    return currentLocalTime.isAfter(sunrise) &&
        currentLocalTime.isBefore(sunset);
  }

  String get partOfDay {
    final now = currentLocalTime;
    final dawnStart = sunrise.subtract(const Duration(minutes: 45));
    final morningStart = sunrise.add(const Duration(minutes: 45));
    final eveningStart = sunset.subtract(const Duration(minutes: 60));
    final duskEnd = sunset.add(const Duration(minutes: 45));
    final int daylightMinutes = eveningStart.difference(morningStart).inMinutes;
    final noonStart = morningStart.add(Duration(minutes: daylightMinutes ~/ 3));
    final afternoonStart = morningStart.add(
      Duration(minutes: (daylightMinutes ~/ 3) * 2),
    );

    if (now.isBefore(dawnStart)) return 'Ніч';
    if (now.isBefore(morningStart)) return 'Світанок';
    if (now.isBefore(noonStart)) return 'Ранок';
    if (now.isBefore(afternoonStart)) return 'День';
    if (now.isBefore(eveningStart)) return 'Полудень';
    if (now.isBefore(sunset)) return 'Вечір';
    if (now.isBefore(duskEnd)) return 'Сутінки';
    return 'Ніч';
  }
}

class CitySuggestion {
  final String name;
  final String region;
  final String country;
  final double lat;
  final double lon;

  CitySuggestion({
    required this.name,
    required this.region,
    required this.country,
    required this.lat,
    required this.lon,
  });
}

class LocationException implements Exception {
  final String code;
  final String message;

  LocationException(this.code, this.message);

  @override
  String toString() => message;
}
