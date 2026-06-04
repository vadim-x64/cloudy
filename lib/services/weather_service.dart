import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/weather_model.dart';

class WeatherService {
  static const String _weatherUrl =
      'https://api.openweathermap.org/data/2.5/weather';
  static const String _forecastUrl =
      'https://api.openweathermap.org/data/2.5/forecast';
  static const String _airPollutionUrl =
      'https://api.openweathermap.org/data/2.5/air_pollution';
  static const String _geoUrl = 'https://api.openweathermap.org/geo/1.0';

  String translateCountry(String code) {
    const Map<String, String> countries = {
      'UA': 'Україна',
      'PL': 'Польща',
      'US': 'США',
      'GB': 'Велика Британія',
      'DE': 'Німеччина',
      'FR': 'Франція',
      'IT': 'Італія',
      'ES': 'Іспанія',
      'CA': 'Канада',
      'AU': 'Австралія',
      'JP': 'Японія',
      'CN': 'Китай',
      'CZ': 'Чехія',
      'SK': 'Словаччина',
      'RO': 'Румунія',
      'MD': 'Молдова',
      'HU': 'Угорщина',
      'AT': 'Австрія',
      'CH': 'Швейцарія',
      'SE': 'Швеція',
      'NO': 'Норвегія',
      'FI': 'Фінляндія',
      'DK': 'Данія',
      'NL': 'Нідерланди',
      'BE': 'Бельгія',
      'PT': 'Португалія',
      'GR': 'Греція',
      'TR': 'Туреччина',
      'BR': 'Бразилія',
      'AR': 'Аргентина',
      'MX': 'Мексика',
      'IN': 'Індія',
      'IL': 'Ізраїль',
      'GE': 'Грузія',
      'LT': 'Литва',
      'LV': 'Латвія',
      'EE': 'Естонія',
    };
    return countries[code] ?? code;
  }

  String cleanRegionName(String? region) {
    if (region == null || region.isEmpty) return '';

    const Map<String, String> ukrainianRegions = {
      'Kyiv Oblast': 'Київська обл.',
      'Kyiv City': 'м. Київ',
      'Kyiv': 'м. Київ',
      'Lviv Oblast': 'Львівська обл.',
      'Kharkiv Oblast': 'Харківська обл.',
      'Odesa Oblast': 'Одеська обл.',
      'Dnipro Oblast': 'Дніпропетровська обл.',
      'Dnipropetrovsk Oblast': 'Дніпропетровська обл.',
      'Donetsk Oblast': 'Донецька обл.',
      'Zaporizhia Oblast': 'Запорізька обл.',
      'Zaporizhzhia Oblast': 'Запорізька обл.',
      'Ivano-Frankivsk Oblast': 'Івано-Франківська обл.',
      'Volyn Oblast': 'Волинська обл.',
      'Ternopil Oblast': 'Тернопільська обл.',
      'Rivne Oblast': 'Рівненська обл.',
      'Zhytomyr Oblast': 'Житомирська обл.',
      'Khmelnytskyi Oblast': 'Хмельницька обл.',
      'Khmelnytskyy Oblast': 'Хмельницька обл.',
      'Chernivtsi Oblast': 'Чернівецька обл.',
      'Zakarpattia Oblast': 'Закарпатська обл.',
      'Vinnytsia Oblast': 'Вінницька обл.',
      'Cherkasy Oblast': 'Черкаська обл.',
      'Kirovohrad Oblast': 'Кіровоградська обл.',
      'Poltava Oblast': 'Полтавська обл.',
      'Chernihiv Oblast': 'Чернігівська обл.',
      'Sumy Oblast': 'Сумська обл.',
      'Mykolaiv Oblast': 'Миколаївська обл.',
      'Kherson Oblast': 'Херсонська обл.',
      'Luhansk Oblast': 'Луганська обл.',
      'Autonomous Republic of Crimea': 'АР Крим',
      'Crimea': 'АР Крим',
      'Sevastopol City': 'м. Севастополь',
      'Sevastopol': 'м. Севастополь',
    };

    return ukrainianRegions[region] ??
        region.replaceAll(' Oblast', ' обл.').replaceAll('Oblast', 'обл.');
  }

  Future<List<CitySuggestion>> fetchCitySuggestions(String query) async {
    if (query.length < 2) return [];

    final apiKey = dotenv.env['OPENWEATHER_API_KEY'];
    if (apiKey == null) return [];

    try {
      final response = await http
          .get(Uri.parse('$_geoUrl/direct?q=$query&limit=5&appid=$apiKey'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((json) {
          return CitySuggestion.fromJson(
            json,
            translateCountry(json['country'] ?? ''),
            cleanRegionName(json['state']),
          );
        }).toList();
      }
    } catch (e) {
      return [];
    }
    return [];
  }

  Future<WeatherModel> fetchWeatherByCoordinates(
    double lat,
    double lon, [
    String? knownCityName,
  ]) async {
    final apiKey = dotenv.env['OPENWEATHER_API_KEY'];
    if (apiKey == null) throw Exception('API Key not found');

    try {
      String ukName = knownCityName ?? 'Невідоме місце';
      String region = '';
      String country = '';

      if (knownCityName == null) {
        final geoResponse = await http
            .get(
              Uri.parse(
                '$_geoUrl/reverse?lat=$lat&lon=$lon&limit=1&appid=$apiKey',
              ),
            )
            .timeout(const Duration(seconds: 10));

        if (geoResponse.statusCode == 200) {
          final List geoData = jsonDecode(geoResponse.body);
          if (geoData.isNotEmpty) {
            final localNames = geoData[0]['local_names'] ?? {};
            ukName = localNames['uk'] ?? geoData[0]['name'];
            region = cleanRegionName(geoData[0]['state']);
            country = translateCountry(geoData[0]['country'] ?? '');
          }
        }
      }

      final weatherUrl = Uri.parse(
        '$_weatherUrl?lat=$lat&lon=$lon&appid=$apiKey&units=metric&lang=uk',
      );
      final forecastUrl = Uri.parse(
        '$_forecastUrl?lat=$lat&lon=$lon&appid=$apiKey&units=metric&lang=uk',
      );
      final aqiUrl = Uri.parse(
        '$_airPollutionUrl?lat=$lat&lon=$lon&appid=$apiKey',
      );

      final responses = await Future.wait([
        http.get(weatherUrl),
        http.get(forecastUrl),
        http.get(aqiUrl),
      ]).timeout(const Duration(seconds: 15));

      final weatherRes = responses[0];
      final forecastRes = responses[1];
      final aqiRes = responses[2];

      if (weatherRes.statusCode == 200) {
        final weatherJson = jsonDecode(weatherRes.body);

        Map<String, dynamic>? forecastJson;
        if (forecastRes.statusCode == 200) {
          forecastJson = jsonDecode(forecastRes.body);
        }

        Map<String, dynamic>? aqiJson;
        if (aqiRes.statusCode == 200) {
          aqiJson = jsonDecode(aqiRes.body);
        }

        return WeatherModel.fromJson(
          weatherJson,
          forecastJson,
          aqiJson,
          ukName,
          region,
          country,
        );
      } else {
        throw Exception('Не вдалося завантажити погоду');
      }
    } on SocketException {
      throw Exception('no_internet');
    } on TimeoutException {
      throw Exception('weak_signal');
    } on http.ClientException {
      throw Exception('dropped_connection');
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        throw Exception('no_internet');
      }
      throw Exception('Помилка підключення: $e');
    }
  }
}
