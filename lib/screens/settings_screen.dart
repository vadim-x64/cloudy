import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  final List<Color> backgroundColors;

  const SettingsScreen({
    super.key,
    required this.backgroundColors,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _alwaysShowTutorial = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _alwaysShowTutorial = prefs.getBool('always_show_tutorial') ?? false;
    });
  }

  Future<void> _toggleTutorial(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _alwaysShowTutorial = value;
    });
    await prefs.setBool('always_show_tutorial', value);
  }

  @override
  Widget build(BuildContext context) {
    final appBarColor = widget.backgroundColors.isNotEmpty
        ? widget.backgroundColors.first.withOpacity(0.92)
        : Colors.blueGrey.shade900.withOpacity(0.92);

    return Scaffold(
      body: Stack(
        children: [
          // Динамічний фон
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.backgroundColors,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Ефект розмиття
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(color: Colors.transparent),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // AppBar
                AppBar(
                  backgroundColor: appBarColor,
                  elevation: 4,
                  shadowColor: Colors.black38,
                  surfaceTintColor: Colors.transparent,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  title: const Text(
                    'Налаштування',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  centerTitle: true,
                ),
                // Контент налаштувань
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildGlassContainer(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Показувати підказки',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: const Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Увімкнути або вимкнути показ навчальних підказок при старті застосунку.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                          leading: Icon(
                            _alwaysShowTutorial ? Icons.tips_and_updates : Icons.tips_and_updates_outlined,
                            color: _alwaysShowTutorial ? Colors.white : Colors.white54,
                            size: 28,
                          ),
                          // Сам перемикач тепер є окремим елементом
                          trailing: Switch(
                            activeColor: Colors.white,
                            activeTrackColor: Colors.white.withOpacity(0.4),
                            inactiveThumbColor: Colors.white54,
                            inactiveTrackColor: Colors.white.withOpacity(0.1),
                            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                            value: _alwaysShowTutorial,
                            onChanged: _toggleTutorial,
                          ),
                        ),
                      ),
                      // Місце для майбутніх налаштувань...
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassContainer({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: child,
        ),
      ),
    );
  }
}