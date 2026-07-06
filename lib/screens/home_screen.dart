import 'dart:ui';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:geolocator/geolocator.dart';
import '../widgets/dynamic_loader.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';
import '../services/location_service.dart';
import '../widgets/animated_weather_icon.dart';
import '../widgets/weather_overlays.dart';
import '../widgets/ai_chat_modal.dart';
import '../widgets/weather_map_modal.dart';
import '../widgets/tutorial_overlay.dart';
import 'dart:math' as math;
import 'app_info_screen.dart';
import 'settings_screen.dart';
import '../services/widget_service.dart';

enum TempUnit { celsius, fahrenheit, kelvin }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _weatherService = WeatherService();
  final _locationService = LocationService();
  final GlobalKey _smallWeatherIconKey = GlobalKey();
  final GlobalKey _searchKey = GlobalKey();
  final GlobalKey _settingsKey = GlobalKey();
  final GlobalKey _tempKey = GlobalKey();
  final GlobalKey _detailsKey = GlobalKey();
  final GlobalKey _aiChatKey = GlobalKey();
  final GlobalKey _locationKey = GlobalKey();

  WeatherModel? _weather;
  DateTime? _lastUpdated;
  bool _isLoading = false;
  String? _errorMessage;
  TempUnit _selectedUnit = TempUnit.celsius;
  bool _showDetails = false;
  Timer? _clockTimer;
  int _lastMinute = DateTime.now().minute;

  bool _showTempAnimation = false;
  bool _isUsingGps = true;
  CitySuggestion? _currentSuggestion;

  double _currentLat = 0.0;
  double _currentLon = 0.0;

  bool _isSettingsExpanded = false;
  final List<Map<String, String>> _aiChatHistory = [];

  bool _alwaysShowTutorial = false;
  bool _tutorialShownThisSession = false;

  @override
  void initState() {
    super.initState();

    _loadSettings();

    WidgetsBinding.instance.addObserver(this);
    _loadWeatherByLocation();

    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _weather != null) {
        final now = DateTime.now();
        final currentMinute = now.minute;

        if (_lastMinute != currentMinute) {
          _lastMinute = currentMinute;
          setState(() {});

          if (_lastUpdated != null &&
              now.difference(_lastUpdated!).inMinutes >= 30) {
            _refreshDataSilently();
          }
        }
      }
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _alwaysShowTutorial = prefs.getBool('always_show_tutorial') ?? false;
    });
  }

  Future<void> _checkAndShowTutorial() async {
    if (_tutorialShownThisSession) return; // Показувати лише раз за сесію додатка

    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('is_first_launch') ?? true;

    if ((isFirstLaunch || _alwaysShowTutorial) && _weather != null && mounted) {
      if (isFirstLaunch) {
        await prefs.setBool('is_first_launch', false);
      }
      _tutorialShownThisSession = true; // Фіксуємо, що в цій сесії вже показали

      Future.delayed(const Duration(milliseconds: 1000), () {
        if (!mounted) return;

        TutorialOverlay.show(context, [
          TutorialStep(
            key: _searchKey,
            title: 'Розумний пошук',
            description:
            'Шукайте будь-яке місто у світі, щоб дізнатися там погоду.',
          ),
          TutorialStep(
            key: _settingsKey,
            title: 'Меню налаштувань',
            description:
            'Натисніть на шестерню, щоб змінити одиниці виміру, відкрити погодну карту, дізнатися більше про застосунок або увімкнути/вимкнути показ цих підказок при старті.', // <-- Оновлено опис
          ),
          TutorialStep(
            key: _locationKey,
            title: 'Моя локація',
            description:
            'Натисніть сюди, щоб миттєво визначити координати по GPS і оновити погоду для вашого поточного місця.',
          ),
          TutorialStep(
            key: _tempKey,
            title: 'Секретна анімація',
            description:
            'Натисніть на температуру, щоб побачити круту повноекранну погодну анімацію!',
          ),
          TutorialStep(
            key: _detailsKey,
            title: 'Більше деталей',
            description:
            'Розгорніть це меню для перегляду вологості, тиску, якості повітря та прогнозу на 5 днів.',
          ),
          TutorialStep(
            key: _aiChatKey,
            title: 'ШІ-Асистент',
            description:
            'Ваш персональний метеоролог! Запитуйте поради щодо одягу або парасолі.',
          ),
        ], _weather!.partOfDay);
      });
    }
  }

  Future<void> _refreshDataSilently() async {
    try {
      if (_isUsingGps) {
        final position = await _locationService.getCurrentPosition();
        _currentLat = position.latitude;
        _currentLon = position.longitude;
        final weather = await _weatherService.fetchWeatherByCoordinates(
          position.latitude,
          position.longitude,
        );
        if (mounted) {
          setState(() {
            _weather = weather;
            _lastUpdated = DateTime.now();
          });
        }
      } else if (_currentSuggestion != null) {
        _currentLat = _currentSuggestion!.lat;
        _currentLon = _currentSuggestion!.lon;
        final weather = await _weatherService.fetchWeatherByCoordinates(
          _currentSuggestion!.lat,
          _currentSuggestion!.lon,
          _currentSuggestion!.name,
        );
        if (mounted) {
          setState(() {
            _weather = WeatherModel(
              cityName: weather.cityName,
              region: _currentSuggestion!.region,
              country: _currentSuggestion!.country,
              temperature: weather.temperature,
              feelsLike: weather.feelsLike,
              description: weather.description,
              iconCode: weather.iconCode,
              mainCondition: weather.mainCondition,
              humidity: weather.humidity,
              windSpeed: weather.windSpeed,
              precipitation: weather.precipitation,
              pressure: weather.pressure,
              aqi: weather.aqi,
              localTime: weather.localTime,
              timezoneOffset: weather.timezoneOffset,
              sunrise: weather.sunrise,
              sunset: weather.sunset,
              hourlyForecast: weather.hourlyForecast,
              dailyForecast: weather.dailyForecast,
            );
            _lastUpdated = DateTime.now();
          });
        }
      }
    } catch (e) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshDataSilently();
    }
  }

  void _handleTempTap() {
    if (_showTempAnimation || _weather == null) return;
    setState(() {
      _showTempAnimation = true;
    });

    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        setState(() {
          _showTempAnimation = false;
        });
      }
    });
  }

  void _openAiChat() {
    if (_weather == null) return;

    for (var msg in _aiChatHistory) {
      msg['isNew'] = 'false';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (context) => AiChatModal(
        weather: _weather!,
        selectedUnit: _selectedUnit,
        chatHistory: _aiChatHistory,
      ),
    );
  }

  String _formatTemp(double tempC) {
    switch (_selectedUnit) {
      case TempUnit.fahrenheit:
        return '${(tempC * 9 / 5 + 32).round()}°F';
      case TempUnit.kelvin:
        return '${(tempC + 273.15).round()}K';
      case TempUnit.celsius:
      default:
        return '${tempC.round()}°';
    }
  }

  String _formatTempOnlyNumber(double tempC) {
    switch (_selectedUnit) {
      case TempUnit.fahrenheit:
        return '${(tempC * 9 / 5 + 32).round()}';
      case TempUnit.kelvin:
        return '${(tempC + 273.15).round()}';
      case TempUnit.celsius:
      default:
        return '${tempC.round()}';
    }
  }

  String _formatPressure(int hPa) {
    return '${(hPa * 0.750062).round()} мм рт.ст.';
  }

  Map<String, dynamic> _getAqiInfo(int aqi) {
    switch (aqi) {
      case 1:
        return {'text': 'Відмінно', 'color': const Color(0xFF00E676)};
      case 2:
        return {'text': 'Добре', 'color': const Color(0xFF76FF03)};
      case 3:
        return {'text': 'Помірно', 'color': const Color(0xFFFDD835)};
      case 4:
        return {'text': 'Погано', 'color': const Color(0xFFF57F17)};
      case 5:
        return {'text': 'Небезпечно', 'color': const Color(0xFFE64A19)};
      default:
        return {'text': 'Невідомо', 'color': Colors.white};
    }
  }

  void _handleNetworkError(dynamic e) {
    String errorMsg = e.toString();
    if (errorMsg.contains('no_internet')) {
      setState(() {
        _errorMessage =
            'Немає підключення до інтернету.\nПеревірте з\'єднання та спробуйте ще раз.';
      });
    } else if (errorMsg.contains('weak_signal')) {
      setState(() {
        _errorMessage =
            'Ваше інтернет-з\'єднання нестабільне.\nДані завантажуються занадто довго.';
      });
    } else if (errorMsg.contains('dropped_connection')) {
      setState(() {
        _errorMessage =
            'З\'єднання обірвалось під час завантаження.\nСпробуйте оновити дані ще раз.';
      });
    } else {
      setState(() => _errorMessage = 'Сталася помилка: $e');
    }
  }

  Future<void> _loadWeatherByLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isUsingGps = true;
      _currentSuggestion = null;
    });

    try {
      final position = await _locationService.getCurrentPosition();
      _currentLat = position.latitude;
      _currentLon = position.longitude;
      final weather = await _weatherService.fetchWeatherByCoordinates(
        position.latitude,
        position.longitude,
      );
      setState(() {
        _weather = weather;
        _lastUpdated = DateTime.now();
        _showDetails = false;
      });
      _checkAndShowTutorial();
      WidgetService.updateWeatherWidget(_weather!);
    } catch (e) {
      if (e is LocationException) {
        _showLocationErrorDialog(e);
        setState(
          () => _errorMessage =
              'Немає доступу до геолокації. Введіть місто вручну.',
        );
      } else {
        _handleNetworkError(e);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showLocationErrorDialog(LocationException error) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.blueGrey.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Увага', style: TextStyle(color: Colors.white)),
        content: Text(
          error.message,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Закрити', style: TextStyle(color: Colors.grey)),
          ),
          if (error.code == 'gps_disabled')
            TextButton(
              onPressed: () {
                Geolocator.openLocationSettings();
                Navigator.of(ctx).pop();
              },
              child: const Text(
                'Увімкнути GPS',
                style: TextStyle(color: Colors.blueAccent),
              ),
            ),
          if (error.code == 'permission_denied_forever')
            TextButton(
              onPressed: () {
                Geolocator.openAppSettings();
                Navigator.of(ctx).pop();
              },
              child: const Text(
                'В налаштування',
                style: TextStyle(color: Colors.blueAccent),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _loadWeatherBySuggestion(CitySuggestion suggestion) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isUsingGps = false;
      _currentSuggestion = suggestion;
    });

    try {
      _currentLat = suggestion.lat;
      _currentLon = suggestion.lon;
      final weather = await _weatherService.fetchWeatherByCoordinates(
        suggestion.lat,
        suggestion.lon,
        suggestion.name,
      );

      setState(() {
        _weather = WeatherModel(
          cityName: weather.cityName,
          region: suggestion.region,
          country: suggestion.country,
          temperature: weather.temperature,
          feelsLike: weather.feelsLike,
          description: weather.description,
          iconCode: weather.iconCode,
          mainCondition: weather.mainCondition,
          humidity: weather.humidity,
          windSpeed: weather.windSpeed,
          precipitation: weather.precipitation,
          pressure: weather.pressure,
          aqi: weather.aqi,
          localTime: weather.localTime,
          timezoneOffset: weather.timezoneOffset,
          sunrise: weather.sunrise,
          sunset: weather.sunset,
          hourlyForecast: weather.hourlyForecast,
          dailyForecast: weather.dailyForecast,
        );
        _lastUpdated = DateTime.now();
        _showDetails = false;
      });
      _checkAndShowTutorial();
    } catch (e) {
      _handleNetworkError(e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getUkrainianWeekday(int weekday) {
    const days = [
      'Понеділок',
      'Вівторок',
      'Середа',
      'Четвер',
      'П\'ятниця',
      'Субота',
      'Неділя',
    ];
    return days[weekday - 1];
  }

  String _cleanWeatherDescription(String raw) {
    String desc = raw
        .toLowerCase()
        .replaceAll('часткова хмарність', 'хмарно з проясненнями')
        .replaceAll('місцями хмарно', 'мінлива хмарність')
        .replaceAll('кілька хмар', 'малохмарно')
        .replaceAll('чисте небо', 'ясно')
        .replaceAll('мряка', 'дрібний дощ')
        .replaceAll('димка', 'імла')
        .replaceAll('імла', 'туман');
    return desc.isEmpty ? '' : '${desc[0].toUpperCase()}${desc.substring(1)}';
  }

  List<Color> _getBackgroundColors() {
    if (_weather == null) return [Colors.blue.shade900, Colors.blue.shade400];

    String condition = _weather!.mainCondition.toLowerCase();
    String partOfDay = _weather!.partOfDay;

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
        baseColors = [
          const Color(0xFF14001F),
          const Color(0xFF310051),
          const Color(0xFF320057),
          const Color(0xFF3A0066),
        ];
        break;
      case 'Ніч':
      default:
        baseColors = [
          const Color(0xFF050314),
          const Color(0xFF10092B),
          const Color(0xFF0B1736),
          const Color(0xFF0A1B3F),
        ];
        break;
    }

    if (condition.contains('rain') ||
        condition.contains('drizzle') ||
        condition.contains('snow') ||
        condition.contains('fog') ||
        condition.contains('mist')) {
      return baseColors
          .map((c) => Color.lerp(c, Colors.blueGrey.shade800, 0.55)!)
          .toList();
    } else if (condition.contains('cloud')) {
      return baseColors
          .map((c) => Color.lerp(c, Colors.grey.shade400, 0.25)!)
          .toList();
    }

    return baseColors;
  }

  String? _getBackgroundLottie() {
    if (_weather == null) return null;
    String condition = _weather!.mainCondition.toLowerCase();
    bool isDay = _weather!.isDayTime;

    if (condition.contains('rain') || condition.contains('drizzle')) {
      return 'https://lottie.host/932a3536-cb72-46a4-bc32-720df54546ef/j0kZJbJzJv.json';
    } else if (condition.contains('snow')) {
      return 'https://lottie.host/1792fc8b-03da-4796-9304-7ed6e290f612/8lQz7eOqZ3.json';
    } else if (condition.contains('cloud')) {
      return isDay
          ? 'https://lottie.host/43a50de4-6ef2-488d-a4fc-b03a60a747c3/GjX4Jp8g1U.json'
          : 'https://lottie.host/a618dc2e-5f8f-4ed3-adbf-8c3fb46e1008/Q3Jj6xS97R.json';
    } else if (condition.contains('fog') || condition.contains('mist')) {
      return 'https://lottie.host/0202d689-d1cf-4d94-a159-f2e1edb7df08/K2h2g4hV7a.json';
    }
    return isDay
        ? null
        : 'https://lottie.host/a618dc2e-5f8f-4ed3-adbf-8c3fb46e1008/Q3Jj6xS97R.json';
  }

  Widget _buildThermometer(double tempC) {
    double minT = -30;
    double maxT = 40;
    double range = maxT - minT;
    double percent = ((tempC - minT) / range).clamp(0.0, 1.0);

    bool isHot = tempC >= 10.0;
    Color thermoColor = isHot ? Colors.redAccent.shade700 : Colors.blue.shade500;

    return SizedBox(
      height: 145, // Трохи збільшили висоту під іконку
      width: 45,
      child: Column(
        children: [
          MiniThermoIcon(isHot: isHot), // Наша нова анімована іконка
          const SizedBox(height: 5),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Container(
                        width: 12,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white54, width: 1),
                        ),
                      ),
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(
                          begin: 0.15,
                          end: (percent * 0.75) + 0.15,
                        ),
                        duration: const Duration(milliseconds: 1500),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          return FractionallySizedBox(
                            heightFactor: value,
                            alignment: Alignment.bottomCenter,
                            child: child,
                          );
                        },
                        child: Container(
                          width: 8,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: thermoColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: thermoColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white54, width: 1),
                        ),
                      ),
                      Positioned(
                        bottom: 14,
                        right: 6,
                        child: Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(7, (index) {
                        bool isMajor = index % 2 == 0;
                        return Container(
                          height: 2,
                          width: isMajor ? 12 : 6,
                          decoration: const BoxDecoration(color: Colors.white),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassContainer({
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: child,
        ),
      ),
    );
  }

  bool get _showAurora {
    if (_weather == null) return false;
    bool isCold = _weather!.temperature <= 10.0;
    bool isNight =
        _weather!.partOfDay == 'Ніч' || _weather!.partOfDay == 'Сутінки';
    return isCold && isNight;
  }

  @override
  Widget build(BuildContext context) {
    String? bgLottie = _getBackgroundLottie();
    Key weatherKey = ValueKey(_weather?.cityName ?? 'loading');

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        extendBody: true,
        floatingActionButton: _weather != null
            ? Transform.translate(
                offset: const Offset(0, 0),
                child: AnimatedEntrance(
                  delay: const Duration(milliseconds: 600),
                  child: FloatingActionButton(
                    key: _aiChatKey,
                    onPressed: _openAiChat,
                    backgroundColor: Colors.black.withOpacity(0.25),
                    elevation: 0,
                    highlightElevation: 0,
                    focusElevation: 0,
                    hoverElevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(200),
                      side: BorderSide(color: Colors.white.withOpacity(0.6)),
                    ),
                    child: const AnimatedAiIcon(),
                  ),
                ),
              )
            : null,
        body: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(seconds: 2),
              curve: Curves.easeInOut,
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _getBackgroundColors(),
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            AnimatedOpacity(
              opacity: _showAurora ? 1.0 : 0.0,
              duration: const Duration(seconds: 2),
              child: const IgnorePointer(child: AuroraOverlay()),
            ),
            if (bgLottie != null)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.25,
                  child: Lottie.network(
                    bgLottie,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => const SizedBox(),
                  ),
                ),
              ),
            SafeArea(
              child: RefreshIndicator(
                onRefresh: _loadWeatherByLocation,
                color: Colors.blueAccent,
                backgroundColor: Colors.white,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 10,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              key: _searchKey,
                              child: Autocomplete<CitySuggestion>(
                                optionsBuilder:
                                    (TextEditingValue textEditingValue) async {
                                      return await _weatherService
                                          .fetchCitySuggestions(
                                            textEditingValue.text,
                                          );
                                    },
                                displayStringForOption:
                                    (CitySuggestion option) => option.name,
                                onSelected: _loadWeatherBySuggestion,
                                fieldViewBuilder:
                                    (
                                      context,
                                      controller,
                                      focusNode,
                                      onEditingComplete,
                                    ) {
                                      return ValueListenableBuilder<
                                        TextEditingValue
                                      >(
                                        valueListenable: controller,
                                        builder: (context, value, child) {
                                          return TextField(
                                            controller: controller,
                                            focusNode: focusNode,
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                            decoration: InputDecoration(
                                              hintText: 'Пошук',
                                              hintStyle: const TextStyle(
                                                color: Colors.white70,
                                              ),
                                              filled: true,
                                              fillColor: Colors.white
                                                  .withOpacity(0.2),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(25),
                                                borderSide: BorderSide.none,
                                              ),
                                              prefixIcon: const Icon(
                                                Icons.search,
                                                color: Colors.white70,
                                              ),
                                              suffixIcon: value.text.isNotEmpty
                                                  ? IconButton(
                                                      icon: const Icon(
                                                        Icons.clear,
                                                        color: Colors.white70,
                                                      ),
                                                      onPressed: () {
                                                        controller.clear();
                                                        focusNode.unfocus();
                                                      },
                                                    )
                                                  : null,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 0,
                                                  ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                optionsViewBuilder: (context, onSelected, options) {
                                  return Align(
                                    alignment: Alignment.topLeft,
                                    child: Material(
                                      color: Colors.transparent,
                                      child: Container(
                                        width:
                                            MediaQuery.of(context).size.width -
                                            130,
                                        margin: const EdgeInsets.only(top: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.blueGrey.shade900
                                              .withOpacity(0.95),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.black26,
                                              blurRadius: 10,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: ListView.builder(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                          shrinkWrap: true,
                                          itemCount: options.length,
                                          itemBuilder: (context, index) {
                                            final option = options.elementAt(
                                              index,
                                            );
                                            return ListTile(
                                              title: Text(
                                                option.name,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              subtitle: Text(
                                                '${option.region.isNotEmpty ? '${option.region}, ' : ''}${option.country}',
                                                style: const TextStyle(
                                                  color: Colors.white54,
                                                ),
                                              ),
                                              leading: const Icon(
                                                Icons.location_city,
                                                color: Colors.white70,
                                              ),
                                              onTap: () => onSelected(option),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              key: _settingsKey,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: AnimatedSize(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_isSettingsExpanded) ...[
                                      PopupMenuButton<TempUnit>(
                                        elevation: 0,
                                        icon: const Icon(
                                          Icons.thermostat,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                        color: Colors.blueGrey.shade900,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                        ),
                                        onSelected: (unit) => setState(
                                          () => _selectedUnit = unit,
                                        ),
                                        itemBuilder: (context) => [
                                          PopupMenuItem(
                                            value: TempUnit.celsius,
                                            child: Text(
                                              '°C - Цельсій',
                                              style: TextStyle(
                                                color:
                                                    _selectedUnit ==
                                                        TempUnit.celsius
                                                    ? Colors.blueAccent
                                                    : Colors.white,
                                              ),
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: TempUnit.fahrenheit,
                                            child: Text(
                                              '°F - Фаренгейт',
                                              style: TextStyle(
                                                color:
                                                    _selectedUnit ==
                                                        TempUnit.fahrenheit
                                                    ? Colors.blueAccent
                                                    : Colors.white,
                                              ),
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: TempUnit.kelvin,
                                            child: Text(
                                              'K - Кельвін',
                                              style: TextStyle(
                                                color:
                                                    _selectedUnit ==
                                                        TempUnit.kelvin
                                                    ? Colors.blueAccent
                                                    : Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.public,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                        onPressed: () {
                                          if (_weather != null) {
                                            showModalBottomSheet(
                                              context: context,
                                              isScrollControlled: true,
                                              backgroundColor:
                                                  Colors.transparent,
                                              elevation: 0,
                                              builder: (context) =>
                                                  WeatherMapModal(
                                                    lat: _currentLat,
                                                    lon: _currentLon,
                                                  ),
                                            );
                                          }
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.info_outline,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            PageRouteBuilder(
                                              transitionDuration:
                                                  const Duration(
                                                    milliseconds: 500,
                                                  ),
                                              reverseTransitionDuration:
                                                  const Duration(
                                                    milliseconds: 500,
                                                  ),
                                              pageBuilder:
                                                  (
                                                    context,
                                                    animation,
                                                    secondaryAnimation,
                                                  ) => AppInfoScreen(
                                                    backgroundColors:
                                                        _getBackgroundColors(),
                                                    partOfDay:
                                                        _weather?.partOfDay ??
                                                        'День',
                                                  ),
                                              transitionsBuilder:
                                                  (
                                                    context,
                                                    animation,
                                                    secondaryAnimation,
                                                    child,
                                                  ) {
                                                    final curvedAnimation =
                                                        CurvedAnimation(
                                                          parent: animation,
                                                          curve: Curves
                                                              .easeInOutCubic,
                                                        );
                                                    return SlideTransition(
                                                      position:
                                                          Tween<Offset>(
                                                            begin: const Offset(
                                                              1.0,
                                                              0.0,
                                                            ),
                                                            end: Offset.zero,
                                                          ).animate(
                                                            curvedAnimation,
                                                          ),
                                                      child: child,
                                                    );
                                                  },
                                            ),
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.tune_rounded, // Або Icons.build_circle_outlined, якщо більше подобається ключ
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                        tooltip: 'Налаштування',
                                        onPressed: () async {
                                          // Перехід на екран налаштувань з плавною анімацією
                                          await Navigator.of(context).push(
                                            PageRouteBuilder(
                                              transitionDuration: const Duration(milliseconds: 500),
                                              reverseTransitionDuration: const Duration(milliseconds: 500),
                                              pageBuilder: (context, animation, secondaryAnimation) =>
                                                  SettingsScreen(
                                                    backgroundColors: _getBackgroundColors(),
                                                  ),
                                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                                final curvedAnimation = CurvedAnimation(
                                                  parent: animation,
                                                  curve: Curves.easeInOutCubic,
                                                );
                                                return SlideTransition(
                                                  position: Tween<Offset>(
                                                    begin: const Offset(1.0, 0.0),
                                                    end: Offset.zero,
                                                  ).animate(curvedAnimation),
                                                  child: child,
                                                );
                                              },
                                            ),
                                          );
                                          // Після повернення оновлюємо налаштування (на випадок, якщо тумблер перемкнули)
                                          if (mounted) {
                                            _loadSettings();
                                          }
                                        },
                                      ),
                                    ],
                                    AnimatedRotation(
                                      turns: _isSettingsExpanded ? 0.5 : 0.0,
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.settings,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _isSettingsExpanded =
                                                !_isSettingsExpanded;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              key: _locationKey,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.my_location,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                onPressed: _loadWeatherByLocation,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),

                        if (_isLoading)
                          Padding(
                            padding: const EdgeInsets.only(top: 100),
                            child: Column(
                              children: [
                                const DynamicLoader(size: 75),
                                const SizedBox(height: 25),
                                const Text(
                                  'Чекайте хвильку, отримуємо дані...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 50),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.wifi_off_rounded,
                                  color: Colors.white70,
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: Colors.redAccent.shade100,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: _loadWeatherByLocation,
                                  icon: const Icon(
                                    Icons.refresh,
                                    color: Colors.blueAccent,
                                  ),
                                  label: const Text(
                                    'Спробувати ще раз',
                                    style: TextStyle(color: Colors.blueAccent),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (_weather != null)
                          Column(
                            key: weatherKey,
                            children: [
                              AnimatedEntrance(
                                delay: const Duration(milliseconds: 0),
                                child: _buildGlassContainer(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                    horizontal: 20,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            DateFormat('HH').format(
                                              _weather!.currentLocalTime,
                                            ),
                                            style: const TextStyle(
                                              fontSize: 44,
                                              fontWeight: FontWeight.w300,
                                              color: Colors.white,
                                              height: 1.0,
                                              fontFeatures: [
                                                FontFeature.tabularFigures(),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            DateFormat('mm').format(
                                              _weather!.currentLocalTime,
                                            ),
                                            style: const TextStyle(
                                              fontSize: 44,
                                              fontWeight: FontWeight.w300,
                                              color: Colors.white,
                                              height: 1.0,
                                              fontFeatures: [
                                                FontFeature.tabularFigures(),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 20),
                                      Container(
                                        width: 1,
                                        height: 80,
                                        color: Colors.white.withOpacity(0.3),
                                      ),
                                      const SizedBox(width: 20),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.location_on,
                                                  color: Colors.white,
                                                  size: 18,
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    _weather!.cityName,
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              '${_weather!.region.isNotEmpty ? '${_weather!.region}, ' : ''}${_weather!.country}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.white.withOpacity(
                                                  0.8,
                                                ),
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              '${DateFormat('dd.MM.yyyy').format(_weather!.currentLocalTime)} • ${_getUkrainianWeekday(_weather!.currentLocalTime.weekday)}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.white.withOpacity(
                                                  0.9,
                                                ),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(
                                                  0.2,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                _weather!.partOfDay,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              if (_lastUpdated != null)
                                AnimatedEntrance(
                                  delay: const Duration(milliseconds: 50),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.update,
                                        color: Colors.white.withOpacity(0.9),
                                        size: 14,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Дані оновлено востаннє о ${DateFormat('HH:mm').format(_lastUpdated!)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 15),

                              if (_weather!.aqi >= 4)
                                AnimatedEntrance(
                                  delay: const Duration(milliseconds: 100),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 15),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                        color: Colors.redAccent.withOpacity(
                                          0.5,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.warning_amber_rounded,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            'Погана якість повітря! Рекомендується залишатися вдома та зачинити вікна.',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              AnimatedEntrance(
                                delay: const Duration(milliseconds: 150),
                                child: SizedBox(
                                  width: 160,
                                  height: 160,
                                  child: AnimatedWeatherIcon(
                                    iconCode: _weather!.isDayTime
                                        ? '01d'
                                        : '01n',
                                    size: 160,
                                    partOfDay: _weather!.partOfDay,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 15),
                              AnimatedEntrance(
                                delay: const Duration(milliseconds: 200),
                                child: GestureDetector(
                                  key: _tempKey,
                                  onTap: _handleTempTap,
                                  behavior: HitTestBehavior.opaque,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _buildThermometer(_weather!.temperature),
                                      const SizedBox(width: 15),
                                      Text(
                                        _formatTemp(_weather!.temperature) +
                                            (_selectedUnit == TempUnit.celsius
                                                ? 'C'
                                                : ''),
                                        style: const TextStyle(
                                          fontSize: 80,
                                          fontWeight: FontWeight.w200,
                                          color: Colors.white,
                                          height: 1.1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              AnimatedEntrance(
                                delay: const Duration(milliseconds: 250),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Opacity(
                                      opacity: _showTempAnimation ? 0.0 : 1.0,
                                      child: AnimatedWeatherIcon(
                                        key: _smallWeatherIconKey,
                                        iconCode: _weather!.iconCode,
                                        size: 50,
                                        partOfDay: _weather!.partOfDay,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Flexible(
                                      child: Text(
                                        _cleanWeatherDescription(
                                          _weather!.description,
                                        ),
                                        style: const TextStyle(
                                          fontSize: 22,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 1.2,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 15),
                              AnimatedEntrance(
                                delay: const Duration(milliseconds: 280),
                                child: _buildWindStatus(_weather!.windSpeed),
                              ),
                              const SizedBox(height: 30),
                              if (_weather!.hourlyForecast.isNotEmpty) ...[
                                AnimatedEntrance(
                                  delay: const Duration(milliseconds: 300),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Прогноз на 24 години',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                AnimatedEntrance(
                                  delay: const Duration(milliseconds: 350),
                                  child: _buildGlassContainer(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 20,
                                      horizontal: 0,
                                    ),
                                    child: SizedBox(
                                      height: 150,
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        physics: const BouncingScrollPhysics(),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                          ),
                                          child: HourlyTemperatureChart(
                                            forecast: _weather!.hourlyForecast,
                                            formatTempNumber:
                                                _formatTempOnlyNumber,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 30),
                              ],
                              AnimatedEntrance(
                                delay: const Duration(milliseconds: 400),
                                child: TextButton.icon(
                                  key: _detailsKey,
                                  onPressed: () {
                                    setState(() {
                                      _showDetails = !_showDetails;
                                    });
                                  },
                                  icon: Icon(
                                    _showDetails
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down,
                                    color: Colors.white70,
                                  ),
                                  label: Text(
                                    _showDetails
                                        ? 'Сховати деталі'
                                        : 'Детальний прогноз',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 24,
                                    ),
                                    backgroundColor: Colors.white.withOpacity(
                                      0.1,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 15),
                              AnimatedSize(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                                alignment: Alignment.topCenter,
                                child: _showDetails
                                    ? Column(
                                        children: [
                                          AnimatedEntrance(
                                            delay: const Duration(
                                              milliseconds: 50,
                                            ),
                                            child: _buildGlassContainer(
                                              child: Column(
                                                children: [
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceAround,
                                                    children: [
                                                      _buildWeatherDetail(
                                                        Icons.thermostat_auto,
                                                        'Відчувається',
                                                        _formatTemp(
                                                          _weather!.feelsLike,
                                                        ),
                                                      ),
                                                      _buildWeatherDetail(
                                                        Icons.water_drop,
                                                        'Вологість',
                                                        '${_weather!.humidity}%',
                                                      ),
                                                      _buildWeatherDetail(
                                                        Icons.umbrella,
                                                        'Опади',
                                                        '${_weather!.precipitation} мм',
                                                      ),
                                                    ],
                                                  ),
                                                  const Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          vertical: 15.0,
                                                        ),
                                                    child: Divider(
                                                      color: Colors.white24,
                                                    ),
                                                  ),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceAround,
                                                    children: [
                                                      _buildWeatherDetail(
                                                        Icons.air,
                                                        'Вітер',
                                                        '${_weather!.windSpeed} м/с\n${(_weather!.windSpeed * 3.6).toStringAsFixed(1)} км/г',
                                                      ),
                                                      _buildWeatherDetail(
                                                        Icons.wb_twilight,
                                                        'Схід',
                                                        DateFormat(
                                                          'HH:mm',
                                                        ).format(
                                                          _weather!.sunrise,
                                                        ),
                                                      ),
                                                      _buildWeatherDetail(
                                                        Icons.nights_stay,
                                                        'Захід',
                                                        DateFormat(
                                                          'HH:mm',
                                                        ).format(
                                                          _weather!.sunset,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          vertical: 15.0,
                                                        ),
                                                    child: Divider(
                                                      color: Colors.white24,
                                                    ),
                                                  ),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceAround,
                                                    children: [
                                                      _buildWeatherDetail(
                                                        Icons.speed,
                                                        'Тиск',
                                                        _formatPressure(
                                                          _weather!.pressure,
                                                        ),
                                                      ),
                                                      _buildWeatherDetail(
                                                        Icons.masks,
                                                        'Якість повітря',
                                                        _getAqiInfo(
                                                          _weather!.aqi,
                                                        )['text'],
                                                        valueColor: _getAqiInfo(
                                                          _weather!.aqi,
                                                        )['color'],
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 30),
                                          if (_weather!
                                              .dailyForecast
                                              .isNotEmpty) ...[
                                            AnimatedEntrance(
                                              delay: const Duration(
                                                milliseconds: 100,
                                              ),
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  'Прогноз на 5 днів',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white
                                                        .withOpacity(0.9),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            AnimatedEntrance(
                                              delay: const Duration(
                                                milliseconds: 150,
                                              ),
                                              child: _buildGlassContainer(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 10,
                                                      horizontal: 15,
                                                    ),
                                                child: ListView.separated(
                                                  physics:
                                                      const NeverScrollableScrollPhysics(),
                                                  shrinkWrap: true,
                                                  itemCount: _weather!
                                                      .dailyForecast
                                                      .length,
                                                  separatorBuilder:
                                                      (context, index) =>
                                                          const Divider(
                                                            color:
                                                                Colors.white24,
                                                            height: 1,
                                                          ),
                                                  itemBuilder: (context, index) {
                                                    final daily = _weather!
                                                        .dailyForecast[index];
                                                    return Padding(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 8,
                                                          ),
                                                      child: Row(
                                                        children: [
                                                          SizedBox(
                                                            width: 100,
                                                            child: Text(
                                                              _getUkrainianWeekday(
                                                                daily
                                                                    .date
                                                                    .weekday,
                                                              ),
                                                              style: const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                            ),
                                                          ),
                                                          Expanded(
                                                            child: Align(
                                                              alignment:
                                                                  Alignment
                                                                      .center,
                                                              child: AnimatedWeatherIcon(
                                                                iconCode: daily
                                                                    .iconCode,
                                                                size: 45,
                                                              ),
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            width: 120,
                                                            child: Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .end,
                                                              children: [
                                                                SizedBox(
                                                                  width: 50,
                                                                  child: Text(
                                                                    _formatTemp(
                                                                      daily
                                                                          .minTemp,
                                                                    ),
                                                                    textAlign:
                                                                        TextAlign
                                                                            .right,
                                                                    style: const TextStyle(
                                                                      color: Colors
                                                                          .white70,
                                                                      fontSize:
                                                                          16,
                                                                      fontFeatures: [
                                                                        FontFeature.tabularFigures(),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                  width: 10,
                                                                ),
                                                                SizedBox(
                                                                  width: 50,
                                                                  child: Text(
                                                                    _formatTemp(
                                                                      daily
                                                                          .maxTemp,
                                                                    ),
                                                                    textAlign:
                                                                        TextAlign
                                                                            .right,
                                                                    style: const TextStyle(
                                                                      color: Colors
                                                                          .white,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      fontSize:
                                                                          16,
                                                                      fontFeatures: [
                                                                        FontFeature.tabularFigures(),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 30),
                                          ],
                                          AnimatedEntrance(
                                            delay: const Duration(
                                              milliseconds: 200,
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                top: 10.0,
                                                bottom: 20.0,
                                              ),
                                              child: Text(
                                                '© 2026 Cloudy\ndeveloped by voitsekhovskyi',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.normal,
                                                  height: 1.5,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : const SizedBox(width: double.infinity),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_showTempAnimation && _weather != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: WeatherOverlayManager(
                    iconCode: _weather!.iconCode,
                    partOfDay: _weather!.partOfDay,
                    sourceKey: _smallWeatherIconKey,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDetail(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWindStatus(double windSpeed) {
    String statusText;
    if (windSpeed <= 1.5) statusText = 'Штиль';
    else if (windSpeed <= 5.0) statusText = 'Легкий вітер';
    else if (windSpeed <= 10.0) statusText = 'Помірний вітер';
    else if (windSpeed <= 15.0) statusText = 'Сильний вітер';
    else statusText = 'Штормовий вітер';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        MiniWindIcon(windSpeed: windSpeed),
        const SizedBox(width: 10),
        Text(
          '$statusText • ${windSpeed.toStringAsFixed(1)} м/с',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class MiniWindIcon extends StatefulWidget {
  final double windSpeed;
  const MiniWindIcon({super.key, required this.windSpeed});

  @override
  State<MiniWindIcon> createState() => _MiniWindIconState();
}

class _MiniWindIconState extends State<MiniWindIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _setControllerDuration();
    _controller.repeat();
  }

  @override
  void didUpdateWidget(MiniWindIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.windSpeed != widget.windSpeed) {
      _setControllerDuration();
      _controller.repeat();
    }
  }

  void _setControllerDuration() {
    int durationMs = widget.windSpeed > 10.0
        ? 800
        : (widget.windSpeed > 5.0 ? 1200 : (widget.windSpeed > 1.5 ? 2000 : 4000));
    _controller.duration = Duration(milliseconds: durationMs);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(24, 24),
          painter: _WindPillPainter(_controller.value, widget.windSpeed),
        );
      },
    );
  }
}

class _WindPillPainter extends CustomPainter {
  final double progress;
  final double windSpeed;

  _WindPillPainter(this.progress, this.windSpeed);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.0;

    bool isCalm = windSpeed <= 1.5;
    double t = progress * math.pi * 2;

    for (int i = 0; i < 3; i++) {
      double y = size.height * 0.3 + i * (size.height * 0.2);

      if (isCalm) {
        // Легке погойдування для штилю
        double shiftX = math.sin(t + i) * 2;
        Path path = Path();
        path.moveTo(size.width * 0.2 + shiftX, y);
        path.lineTo(size.width * 0.8 + shiftX, y);
        paint.color = Colors.white.withOpacity(0.4);
        canvas.drawPath(path, paint);
      } else {
        // Ефект швидкого потоку повітря з градієнтним шлейфом
        double offset = (progress * size.width * 2 + i * 15) % (size.width * 2);
        double startX = offset - size.width;
        double endX = offset;

        Path path = Path();
        path.moveTo(startX, y);
        path.quadraticBezierTo(
            (startX + endX) / 2, y - (math.sin(t * 3 + i) * 2),
            endX, y
        );

        paint.shader = LinearGradient(
          colors: [
            Colors.white.withOpacity(0.0),
            Colors.white.withOpacity(0.9),
            Colors.white.withOpacity(0.0)
          ],
          stops: const [0.0, 0.8, 1.0],
        ).createShader(Rect.fromLTRB(startX, y - 2, endX, y + 2));

        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WindPillPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.windSpeed != windSpeed;
  }
}

class AnimatedAiIcon extends StatefulWidget {
  const AnimatedAiIcon({super.key});

  @override
  State<AnimatedAiIcon> createState() => _AnimatedAiIconState();
}

class _AnimatedAiIconState extends State<AnimatedAiIcon> {
  int _currentIndex = 0;

  final List<IconData> _icons = [
    Icons.auto_awesome,
    Icons.lightbulb_outline_rounded,
    Icons.access_time_rounded,
    Icons.chat_bubble_outline_rounded,
    Icons.help_outline_rounded,
    Icons.edit_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _startIconLoop();
  }

  void _startIconLoop() async {
    while (mounted) {
      await Future.delayed(const Duration(milliseconds: 2000));
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _icons.length;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      reverseDuration: const Duration(milliseconds: 400),
      transitionBuilder: (Widget child, Animation<double> animation) {
        final scaleAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInBack,
        );

        final rotateAnimation = Tween<double>(begin: -0.15, end: 0.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutQuart),
        );

        return ScaleTransition(
          scale: scaleAnimation,
          child: RotationTransition(
            turns: rotateAnimation,
            child: FadeTransition(opacity: animation, child: child),
          ),
        );
      },
      child: Icon(
        _icons[_currentIndex],
        key: ValueKey<int>(_currentIndex),
        color: Colors.white,
        size: 26,
      ),
    );
  }
}

class AnimatedEntrance extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final double offsetY;

  const AnimatedEntrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offsetY = 30.0,
  });

  @override
  State<AnimatedEntrance> createState() => _AnimatedEntranceState();
}

class _AnimatedEntranceState extends State<AnimatedEntrance>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _slide = Tween<Offset>(
      begin: Offset(0, widget.offsetY),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fade.value,
          child: Transform.translate(offset: _slide.value, child: child),
        );
      },
      child: widget.child,
    );
  }
}

class HourlyTemperatureChart extends StatelessWidget {
  final List<HourlyForecast> forecast;
  final String Function(double) formatTempNumber;

  const HourlyTemperatureChart({
    super.key,
    required this.forecast,
    required this.formatTempNumber,
  });

  @override
  Widget build(BuildContext context) {
    const double itemWidth = 65.0;
    final double chartWidth = forecast.length * itemWidth;

    return SizedBox(
      width: chartWidth,
      height: 150,
      child: Stack(
        children: [
          Positioned(
            top: 50,
            bottom: 30,
            left: 0,
            right: 0,
            child: CustomPaint(
              painter: _TemperatureChartPainter(
                forecast: forecast,
                itemWidth: itemWidth,
              ),
            ),
          ),
          Row(
            children: List.generate(forecast.length, (index) {
              final hourly = forecast[index];
              return SizedBox(
                width: itemWidth,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('HH:mm').format(hourly.time),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    AnimatedWeatherIcon(iconCode: hourly.iconCode, size: 45),
                    Text(
                      '${formatTempNumber(hourly.temperature)}°',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _TemperatureChartPainter extends CustomPainter {
  final List<HourlyForecast> forecast;
  final double itemWidth;

  _TemperatureChartPainter({required this.forecast, required this.itemWidth});

  @override
  void paint(Canvas canvas, Size size) {
    if (forecast.isEmpty) return;

    double minTemp = forecast
        .map((e) => e.temperature)
        .reduce((a, b) => a < b ? a : b);
    double maxTemp = forecast
        .map((e) => e.temperature)
        .reduce((a, b) => a > b ? a : b);

    if (minTemp == maxTemp) {
      minTemp -= 1;
      maxTemp += 1;
    }
    double tempRange = maxTemp - minTemp;

    final path = Path();
    final points = <Offset>[];

    for (int i = 0; i < forecast.length; i++) {
      double x = (i * itemWidth) + (itemWidth / 2);
      double normalizedTemp = (forecast[i].temperature - minTemp) / tempRange;
      double y = size.height - (normalizedTemp * size.height);
      points.add(Offset(x, y));

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        double previousX = points[i - 1].dx;
        double previousY = points[i - 1].dy;
        double controlPointX = previousX + (x - previousX) / 2;
        path.cubicTo(controlPointX, previousY, controlPointX, y, x, y);
      }
    }

    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);

    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white.withOpacity(0.3), Colors.white.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (var point in points) {
      canvas.drawCircle(point, 4.0, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final TextAlign textAlign;

  const TypewriterText({
    super.key,
    required this.text,
    required this.style,
    this.textAlign = TextAlign.start,
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _characterCount;

  @override
  void initState() {
    super.initState();
    int charCount = widget.text.characters.length;
    _controller = AnimationController(
      duration: Duration(milliseconds: charCount * 25),
      vsync: this,
    );
    _characterCount = StepTween(
      begin: 0,
      end: charCount,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      int charCount = widget.text.characters.length;
      _controller.duration = Duration(milliseconds: charCount * 25);
      _characterCount = StepTween(
        begin: 0,
        end: charCount,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _characterCount,
      builder: (context, child) {
        String visibleText = widget.text.characters
            .take(_characterCount.value)
            .toString();
        return Text(
          visibleText,
          style: widget.style,
          textAlign: widget.textAlign,
        );
      },
    );
  }
}

class AuroraOverlay extends StatefulWidget {
  const AuroraOverlay({super.key});

  @override
  State<AuroraOverlay> createState() => _AuroraOverlayState();
}

class _AuroraOverlayState extends State<AuroraOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
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
      height: MediaQuery.of(context).size.height * 0.55,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(painter: AuroraPainter(_controller.value));
        },
      ),
    );
  }
}

class AuroraPainter extends CustomPainter {
  final double progress;

  AuroraPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 45.0);

    for (int i = 0; i < 4; i++) {
      final path = Path();
      final yOffset = size.height * 0.15 + (i * 35);
      final amplitude = 30.0 + (i * 15);
      final phase = (progress * 2 * math.pi) + (i * 1.5);

      path.moveTo(-50, yOffset);
      for (double x = 0; x <= size.width + 50; x += 20) {
        double y = yOffset + math.sin((x * 0.008) + phase) * amplitude;
        path.lineTo(x, y);
      }

      paint.color = (i % 2 == 0 ? Colors.greenAccent : Colors.tealAccent)
          .withOpacity(0.35 - (i * 0.06));
      paint.strokeWidth = 70.0 - (i * 10);

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant AuroraPainter oldDelegate) => true;
}

class MiniThermoIcon extends StatefulWidget {
  final bool isHot;
  const MiniThermoIcon({super.key, required this.isHot});

  @override
  State<MiniThermoIcon> createState() => _MiniThermoIconState();
}

class _MiniThermoIconState extends State<MiniThermoIcon> with SingleTickerProviderStateMixin {
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (widget.isHot) {
          // Повільне обертання для сонечка
          return Transform.rotate(
            angle: _controller.value * 2 * math.pi,
            child: const Icon(Icons.wb_sunny_rounded, color: Colors.amber, size: 20),
          );
        } else {
          // Пульсація для сніжинки
          final scale = 0.8 + (math.sin(_controller.value * math.pi * 2).abs() * 0.3);
          return Transform.scale(
            scale: scale,
            child: const Icon(Icons.ac_unit_rounded, color: Colors.lightBlueAccent, size: 20),
          );
        }
      },
    );
  }
}