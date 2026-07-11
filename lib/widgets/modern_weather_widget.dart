import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import '../models/weather_model.dart';

class ModernWeatherWidget extends StatefulWidget {
  final WeatherModel weather;
  final String conditionText;
  final String timeOfDay;
  final String airQuality;
  final String windSpeed;
  final Future<void> Function() onRefresh;

  const ModernWeatherWidget({
    super.key,
    required this.weather,
    required this.conditionText,
    required this.timeOfDay,
    required this.airQuality,
    required this.windSpeed,
    required this.onRefresh,
  });

  @override
  State<ModernWeatherWidget> createState() => _ModernWeatherWidgetState();
}

class _ModernWeatherWidgetState extends State<ModernWeatherWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _spinController;
  late Timer _timeTimer;
  late DateTime _currentTime;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _timeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      if (now.minute != _currentTime.minute) {
        setState(() {
          _currentTime = now;
        });
      }
    });
  }

  @override
  void dispose() {
    _spinController.dispose();
    _timeTimer.cancel();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    _spinController.repeat();
    await widget.onRefresh();
    _spinController.stop();
    _spinController.reset();
  }

  List<Color> _getBackgroundColors() {
    switch (widget.timeOfDay.toLowerCase()) {
      case 'світанок':
      case 'ранок':
        return [const Color(0xFFFF7E5F), const Color(0xFFFEB47B)];
      case 'полудень':
      case 'день':
        return [const Color(0xFF56CCF2), const Color(0xFF2F80ED)];
      case 'вечір':
        return [const Color(0xFFFF4E50), const Color(0xFFF9D423)];
      case 'сутінки':
        return [const Color(0xFF4B79A1), const Color(0xFF283E51)];
      case 'ніч':
        return [
          const Color(0xFF0F0C29),
          const Color(0xFF302B63),
          const Color(0xFF24243E),
        ];
      default:
        return [const Color(0xFF56CCF2), const Color(0xFF2F80ED)];
    }
  }

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(
      color: Colors.white,
      decoration: TextDecoration.none,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: _getBackgroundColors(),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.weather.cityName,
                      style: textStyle.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.weather.region,
                      style: textStyle.copyWith(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              RotationTransition(
                turns: _spinController,
                child: IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _handleRefresh,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Text(
                      '${widget.weather.temperature.round()}°',
                      key: ValueKey<double>(widget.weather.temperature),
                      style: textStyle.copyWith(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                    ),
                  ),
                  Text(
                    widget.conditionText,
                    style: textStyle.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    DateFormat('HH:mm').format(_currentTime),
                    style: textStyle.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    DateFormat('dd MMM yyyy').format(_currentTime),
                    style: textStyle.copyWith(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem(Icons.air, 'Вітер', widget.windSpeed, textStyle),
                _buildInfoItem(
                  Icons.eco_outlined,
                  'AQI',
                  widget.airQuality,
                  textStyle,
                ),
                _buildInfoItem(
                  Icons.access_time_filled,
                  'Час доби',
                  widget.timeOfDay,
                  textStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    IconData icon,
    String label,
    String value,
    TextStyle baseStyle,
  ) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: baseStyle.copyWith(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: baseStyle.copyWith(fontSize: 12, color: Colors.white54),
        ),
      ],
    );
  }
}
