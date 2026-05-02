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
    if (currentJson['rain'] != null && currentJson['rain']['1h'] != null) {
      precip = (currentJson['rain']['1h'] as num).toDouble();
    } else if (currentJson['snow'] != null &&
        currentJson['snow']['1h'] != null) {
      precip = (currentJson['snow']['1h'] as num).toDouble();
    }

    int parsedAqi = 1;
    if (aqiJson != null &&
        aqiJson['list'] != null &&
        aqiJson['list'].isNotEmpty) {
      parsedAqi = aqiJson['list'][0]['main']['aqi'] ?? 1;
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

        if (hourly.length < 8) {
          hourly.add(
            HourlyForecast(
              time: dt,
              temperature: item['main']['temp'].toDouble(),
              iconCode: item['weather'][0]['icon'],
            ),
          );
        }

        String dateKey =
            "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
        double temp = item['main']['temp'].toDouble();
        String icon = item['weather'][0]['icon'];

        if (!dailyMap.containsKey(dateKey)) {
          dailyMap[dateKey] = DailyForecast(
            date: dt,
            minTemp: temp,
            maxTemp: temp,
            iconCode: icon.contains('d')
                ? icon
                : icon.replaceAll(
                    'n',
                    'd',
                  ),
          );
        } else {
          if (temp < dailyMap[dateKey]!.minTemp)
            dailyMap[dateKey]!.minTemp = temp;
          if (temp > dailyMap[dateKey]!.maxTemp)
            dailyMap[dateKey]!.maxTemp = temp;
          if (dt.hour >= 11 && dt.hour <= 16) {
            dailyMap[dateKey]!.iconCode = icon.contains('d')
                ? icon
                : icon.replaceAll('n', 'd');
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
      description: currentJson['weather'][0]['description'],
      iconCode: currentJson['weather'][0]['icon'],
      mainCondition: currentJson['weather'][0]['main'],
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
    return currentLocalTime.isAfter(sunrise) && currentLocalTime.isBefore(sunset);
  }

  String get partOfDay {
    final double timeInHours = currentLocalTime.hour + (currentLocalTime.minute / 60.0);
    final double sunriseTime = sunrise.hour + (sunrise.minute / 60.0);
    final double sunsetTime = sunset.hour + (sunset.minute / 60.0);

    if ((timeInHours - sunriseTime).abs() <= 1.0) return 'Світанок';
    if (timeInHours > sunriseTime + 1.0 && currentLocalTime.hour < 12) return 'Ранок';
    if (currentLocalTime.hour >= 12 && currentLocalTime.hour < 16) return 'День';
    if (currentLocalTime.hour >= 16 && timeInHours < sunsetTime) return 'Полудень';
    if (timeInHours >= sunsetTime && currentLocalTime.hour < 22) return 'Вечір';
    if (currentLocalTime.hour >= 22 && currentLocalTime.hour < 24) return 'Сутінки';
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

  factory CitySuggestion.fromJson(
    Map<String, dynamic> json,
    String translatedCountry,
    String translatedRegion,
  ) {
    final localNames = json['local_names'] ?? {};
    final ukName = localNames['uk'] ?? json['name'];

    return CitySuggestion(
      name: ukName,
      region: translatedRegion,
      country: translatedCountry,
      lat: json['lat'],
      lon: json['lon'],
    );
  }
}

class LocationException implements Exception {
  final String code;
  final String message;

  LocationException(this.code, this.message);

  @override
  String toString() => message;
}