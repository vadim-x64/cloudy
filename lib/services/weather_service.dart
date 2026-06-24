import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:translator/translator.dart';
import '../models/weather_model.dart';

class WeatherService {
  static const String _weatherUrl =
      'https://api.openweathermap.org/data/2.5/weather';
  static const String _forecastUrl =
      'https://api.openweathermap.org/data/2.5/forecast';
  static const String _airPollutionUrl =
      'https://api.openweathermap.org/data/2.5/air_pollution';
  static const String _geoUrl = 'https://api.openweathermap.org/geo/1.0';

  final GoogleTranslator _translator = GoogleTranslator();
  final Map<String, String> _translationCache = {};

  final Map<String, String> _uaRegions = {
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

  Future<String> _translateToUk(String text) async {
    if (text.isEmpty) return '';
    if (_uaRegions.containsKey(text)) return _uaRegions[text]!;
    if (_translationCache.containsKey(text)) return _translationCache[text]!;
    if (RegExp(r'[А-Яа-яІіЇїЄєҐґ]').hasMatch(text)) return text;

    try {
      final translation = await _translator.translate(
        text,
        from: 'en',
        to: 'uk',
      );
      String result = translation.text;
      result = result
          .replaceAll('Область', 'обл.')
          .replaceAll('область', 'обл.');
      _translationCache[text] = result;
      return result;
    } catch (e) {
      return text;
    }
  }

  String translateCountry(String code) {
    const Map<String, String> countries = {
      'AD': 'Андорра',
      'AE': 'ОАЕ',
      'AF': 'Афганістан',
      'AG': 'Антигуа і Барбуда',
      'AI': 'Ангілья',
      'AL': 'Албанія',
      'AM': 'Вірменія',
      'AO': 'Ангола',
      'AQ': 'Антарктида',
      'AR': 'Аргентина',
      'AS': 'Американське Самоа',
      'AT': 'Австрія',
      'AU': 'Австралія',
      'AW': 'Аруба',
      'AX': 'Аландські острови',
      'AZ': 'Азербайджан',
      'BA': 'Боснія і Герцеговина',
      'BB': 'Барбадос',
      'BD': 'Бангладеш',
      'BE': 'Бельгія',
      'BF': 'Буркіна-Фасо',
      'BG': 'Болгарія',
      'BH': 'Бахрейн',
      'BI': 'Бурунді',
      'BJ': 'Бенін',
      'BL': 'Сен-Бартельмі',
      'BM': 'Бермудські острови',
      'BN': 'Бруней',
      'BO': 'Болівія',
      'BQ': 'Бонайре, Сінт-Естатіус і Саба',
      'BR': 'Бразилія',
      'BS': 'Багамські Острови',
      'BT': 'Бутан',
      'BV': 'Острів Буве',
      'BW': 'Ботсвана',
      'BZ': 'Беліз',
      'CA': 'Канада',
      'CC': 'Кокосові острови',
      'CD': 'ДР Конго',
      'CF': 'ЦАР',
      'CG': 'Республіка Конго',
      'CH': 'Швейцарія',
      'CI': "Кот-д'Івуар",
      'CK': 'Острови Кука',
      'CL': 'Чилі',
      'CM': 'Камерун',
      'CN': 'Китай',
      'CO': 'Колумбія',
      'CR': 'Коста-Рика',
      'CU': 'Куба',
      'CV': 'Кабо-Верде',
      'CW': 'Кюрасао',
      'CX': 'Острів Різдва',
      'CY': 'Кіпр',
      'CZ': 'Чехія',
      'DE': 'Німеччина',
      'DJ': 'Джибуті',
      'DK': 'Данія',
      'DM': 'Домініка',
      'DO': 'Домініканська Республіка',
      'DZ': 'Алжир',
      'EC': 'Еквадор',
      'EE': 'Естонія',
      'EG': 'Єгипет',
      'EH': 'Західна Сахара',
      'ER': 'Еритрея',
      'ES': 'Іспанія',
      'ET': 'Ефіопія',
      'FI': 'Фінляндія',
      'FJ': 'Фіджі',
      'FK': 'Фолклендські острови',
      'FM': 'Мікронезія',
      'FO': 'Фарерські острови',
      'FR': 'Франція',
      'GA': 'Габон',
      'GB': 'Велика Британія',
      'GD': 'Гренада',
      'GE': 'Грузія',
      'GF': 'Французька Гвіана',
      'GG': 'Гернсі',
      'GH': 'Гана',
      'GI': 'Гібралтар',
      'GL': 'Гренландія',
      'GM': 'Гамбія',
      'GN': 'Гвінея',
      'GP': 'Гваделупа',
      'GQ': 'Екваторіальна Гвінея',
      'GR': 'Греція',
      'GS': 'Південна Джорджія та Південні Сандвічеві острови',
      'GT': 'Гватемала',
      'GU': 'Гуам',
      'GW': 'Гвінея-Бісау',
      'GY': 'Гаяна',
      'HK': 'Гонконг',
      'HM': 'Острів Герд і острови Макдональд',
      'HN': 'Гондурас',
      'HR': 'Хорватія',
      'HT': 'Гаїті',
      'HU': 'Угорщина',
      'ID': 'Індонезія',
      'IE': 'Ірландія',
      'IL': 'Ізраїль',
      'IM': 'Острів Мен',
      'IN': 'Індія',
      'IO': 'Британська територія в Індійському океані',
      'IQ': 'Ірак',
      'IR': 'Іран',
      'IS': 'Ісландія',
      'IT': 'Італія',
      'JE': 'Джерсі',
      'JM': 'Ямайка',
      'JO': 'Йорданія',
      'JP': 'Японія',
      'KE': 'Кенія',
      'KG': 'Киргизстан',
      'KH': 'Камбоджа',
      'KI': 'Кірибаті',
      'KM': 'Коморські Острови',
      'KN': 'Сент-Кіттс і Невіс',
      'KP': 'КНДР',
      'KR': 'Південна Корея',
      'KW': 'Кувейт',
      'KY': 'Кайманові острови',
      'KZ': 'Казахстан',
      'LA': 'Лаос',
      'LB': 'Ліван',
      'LC': 'Сент-Люсія',
      'LI': 'Ліхтенштейн',
      'LK': 'Шрі-Ланка',
      'LR': 'Ліберія',
      'LS': 'Лесото',
      'LT': 'Литва',
      'LU': 'Люксембург',
      'LV': 'Латвія',
      'LY': 'Лівія',
      'MA': 'Марокко',
      'MC': 'Монако',
      'MD': 'Молдова',
      'ME': 'Чорногорія',
      'MF': 'Сен-Мартен',
      'MG': 'Мадагаскар',
      'MH': 'Маршаллові Острови',
      'MK': 'Північна Македонія',
      'ML': 'Малі',
      'MM': "М'янма",
      'MN': 'Монголія',
      'MO': 'Макао',
      'MP': 'Північні Маріанські острови',
      'MQ': 'Мартиніка',
      'MR': 'Мавританія',
      'MS': 'Монтсеррат',
      'MT': 'Мальта',
      'MU': 'Маврикій',
      'MV': 'Мальдіви',
      'MW': 'Малаві',
      'MX': 'Мексика',
      'MY': 'Малайзія',
      'MZ': 'Мозамбік',
      'NA': 'Намібія',
      'NC': 'Нова Каледонія',
      'NE': 'Нігер',
      'NF': 'Острів Норфолк',
      'NG': 'Нігерія',
      'NI': 'Нікарагуа',
      'NL': 'Нідерланди',
      'NO': 'Норвегія',
      'NP': 'Непал',
      'NR': 'Науру',
      'NU': 'Ніуе',
      'NZ': 'Нова Зеландія',
      'OM': 'Оман',
      'PA': 'Панама',
      'PE': 'Перу',
      'PF': 'Французька Полінезія',
      'PG': 'Папуа Нова Гвінея',
      'PH': 'Філіппіни',
      'PK': 'Пакистан',
      'PL': 'Польща',
      'PM': "Сен-П'єр і Мікелон",
      'PN': 'Піткерн',
      'PR': 'Пуерто-Рико',
      'PS': 'Палестина',
      'PT': 'Португалія',
      'PW': 'Палау',
      'PY': 'Парагвай',
      'QA': 'Катар',
      'RE': 'Реюньйон',
      'RO': 'Румунія',
      'RS': 'Сербія',
      'RW': 'Руанда',
      'SA': 'Саудівська Аравія',
      'SB': 'Соломонові Острови',
      'SC': 'Сейшельські Острови',
      'SD': 'Судан',
      'SE': 'Швеція',
      'SG': 'Сінгапур',
      'SH': 'Острови Святої Єлени, Вознесіння і Тристан-да-Кунья',
      'SI': 'Словенія',
      'SJ': 'Шпіцберген і Ян-Маєн',
      'SK': 'Словаччина',
      'SL': 'Сьєрра-Леоне',
      'SM': 'Сан-Марино',
      'SN': 'Сенегал',
      'SO': 'Сомалі',
      'SR': 'Суринам',
      'SS': 'Південний Судан',
      'ST': 'Сан-Томе і Принсіпі',
      'SV': 'Сальвадор',
      'SX': 'Сінт-Мартен',
      'SY': 'Сирія',
      'SZ': 'Есватіні',
      'TC': 'Острови Теркс і Кайкос',
      'TD': 'Чад',
      'TF': 'Французькі Південні і Антарктичні Території',
      'TG': 'Того',
      'TH': 'Таїланд',
      'TJ': 'Таджикистан',
      'TK': 'Токелау',
      'TL': 'Східний Тимор',
      'TM': 'Туркменістан',
      'TN': 'Туніс',
      'TO': 'Тонга',
      'TR': 'Туреччина',
      'TT': 'Тринідад і Тобаго',
      'TV': 'Тувалу',
      'TW': 'Тайвань',
      'TZ': 'Танзанія',
      'UA': 'Україна',
      'UG': 'Уганда',
      'UM': 'Зовнішні малі острови США',
      'US': 'США',
      'UY': 'Уругвай',
      'UZ': 'Узбекистан',
      'VA': 'Ватикан',
      'VC': 'Сент-Вінсент і Гренадини',
      'VE': 'Венесуела',
      'VG': 'Британські Віргінські острови',
      'VI': 'Американські Віргінські острови',
      'VN': "В'єтнам",
      'VU': 'Вануату',
      'WF': 'Уолліс і Футуна',
      'WS': 'Самоа',
      'YE': 'Ємен',
      'YT': 'Майотта',
      'ZA': 'ПАР',
      'ZM': 'Замбія',
      'ZW': 'Зімбабве',
    };
    return countries[code] ?? code;
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

        final futures = data.map((json) async {
          final localNames = json['local_names'] ?? {};
          String cityName =
              localNames['uk'] ?? await _translateToUk(json['name'] ?? '');
          String regionName = await _translateToUk(json['state'] ?? '');
          String countryName = translateCountry(json['country'] ?? '');

          return CitySuggestion(
            name: cityName,
            region: regionName,
            country: countryName,
            lat: json['lat'],
            lon: json['lon'],
          );
        });

        return await Future.wait(futures);
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
            ukName =
                localNames['uk'] ??
                await _translateToUk(geoData[0]['name'] ?? '');
            region = await _translateToUk(geoData[0]['state'] ?? '');
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
        Map<String, dynamic>? forecastJson = forecastRes.statusCode == 200
            ? jsonDecode(forecastRes.body)
            : null;
        Map<String, dynamic>? aqiJson = aqiRes.statusCode == 200
            ? jsonDecode(aqiRes.body)
            : null;

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
      if (e.toString().contains('SocketException'))
        throw Exception('no_internet');
      throw Exception('Помилка підключення: $e');
    }
  }
}