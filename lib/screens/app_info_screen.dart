import 'dart:ui';
import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppInfoScreen extends StatelessWidget {
  final List<Color> backgroundColors;
  final String partOfDay;

  const AppInfoScreen({
    super.key,
    required this.backgroundColors,
    required this.partOfDay,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Адаптивний фоновий градієнт, успадкований з головного екрана
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: backgroundColors,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Додатковий ефект розмиття для фонового контенту
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(color: Colors.transparent),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverAppBar(context),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 10),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 10),
                      _buildWelcomeCard(),
                      const SizedBox(height: 25),
                      _buildSectionTitle('Архітектура системи'),
                      const SizedBox(height: 10),
                      _buildArchitectureSection(),
                      const SizedBox(height: 25),
                      _buildSectionTitle('Інтеграція Штучного Інтелекту'),
                      const SizedBox(height: 10),
                      _buildAiSection(),
                      const SizedBox(height: 25),
                      _buildSectionTitle('Геокартографія та дані подій'),
                      const SizedBox(height: 10),
                      _buildMapSection(),
                      const SizedBox(height: 25),
                      _buildSectionTitle('Графіка та фізичні ефекти'),
                      const SizedBox(height: 10),
                      _buildGraphicsSection(),
                      const SizedBox(height: 30),
                      _buildTechStackSheet(),
                      const SizedBox(height: 40),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    // Отримуємо перший колір поточного градієнта для безшовного вигляду
    final appBarColor = backgroundColors.isNotEmpty
        ? backgroundColors.first.withOpacity(0.92)
        : Colors.blueGrey.shade900.withOpacity(0.92);

    return SliverAppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      // Встановлюємо напівпрозорий колір замість прозорого
      backgroundColor: appBarColor,
      elevation: 4,
      shadowColor: Colors.black38,
      // Вимикаємо стандартне тонування Material 3 при скролі
      surfaceTintColor: Colors.transparent,
      pinned: true,
      expandedHeight: 100,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 56, vertical: 14),
        centerTitle: true,
        title: Text(
          'Про застосунок',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.4),
                offset: const Offset(0, 1),
                blurRadius: 4,
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return AnimatedEntrance(
      delay: const Duration(milliseconds: 100),
      child: _buildGlassContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset('assets/logo.png', width: 60, height: 60),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cloudy',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Використовуємо FutureBuilder для отримання версії з pubspec.yaml
                      FutureBuilder<PackageInfo>(
                        future: PackageInfo.fromPlatform(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            final version = snapshot.data!.version;
                            final buildNumber = snapshot.data!.buildNumber;
                            return Text(
                              'Версія $version (Збірка $buildNumber)',
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                            );
                          }
                          return const Text(
                            'Завантаження...',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            const Text(
              'Cloudy — це кросплатформний погодний застосунок...',
              style: TextStyle(color: Color(0xFFEEEEEE), fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return AnimatedEntrance(
      delay: const Duration(milliseconds: 150),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildArchitectureSection() {
    return AnimatedEntrance(
      delay: const Duration(milliseconds: 200),
      child: _buildGlassContainer(
        child: Column(
          children: [
            _buildInteractiveTechItem(
              icon: Icons.layers_outlined,
              title: 'Потік даних (Data Pipeline)',
              subtitle: 'Реактивна обробка та запити до API',
              description:
              'Застосунок використовує багатопотокові запити (Future.wait) для паралельного завантаження даних поточної погоди, 5-денного прогнозу та індексу якості повітря (AQI). Це скорочує час очікування відповіді мережі на 60%.',
            ),
            const Divider(color: Colors.white24, height: 24),
            _buildInteractiveTechItem(
              icon: Icons.gps_fixed_rounded,
              title: 'Геосервіси',
              subtitle: 'Двохетапна ідентифікація локації',
              description:
              'Використовується пакет Geolocator для отримання координат пристрою з високою точністю. Якщо дозвіл заблоковано, система автоматично перемикається на режим ручного пошуку через автокомпліт геокодингу OpenWeather API.',
            ),
            const Divider(color: Colors.white24, height: 24),
            _buildInteractiveTechItem(
              icon: Icons.storage_rounded,
              title: 'Локальний кеш',
              subtitle: 'SharedPreferences та збереження стану',
              description:
              'Для збереження параметрів користувача (одиниці виміру температури) та стану першого запуску застосовується асинхронне сховище SharedPreferences, що мінімізує непотрібні перезаписи дисків.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiSection() {
    return AnimatedEntrance(
      delay: const Duration(milliseconds: 250),
      child: _buildGlassContainer(
        child: Column(
          children: [
            _buildInteractiveTechItem(
              icon: Icons.psychology_outlined,
              title: 'Контекстні підказки ШІ',
              subtitle: 'Мовна модель Grok / Llama через API',
              description:
              'Система динамічно генерує системний промпт, куди впроваджуються поточні показники: температура, відчуття, вологість, швидкість вітру та рівень AQI. Дані передаються через REST-інтерфейс з підтримкою відкату (fallback) на альтернативні моделі у разі таймауту.',
            ),
            const Divider(color: Colors.white24, height: 24),
            _buildInteractiveTechItem(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Збереження сесії діалогу',
              subtitle: 'Інтерактивна історія чату',
              description:
              'Реалізовано циклічний буфер повідомлень із підтримкою ролей "user" та "assistant". Історія діалогу передається у кожному наступному запиті для підтримки контексту розмови, що створює відчуття реального спілкування.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapSection() {
    return AnimatedEntrance(
      delay: const Duration(milliseconds: 300),
      child: _buildGlassContainer(
        child: Column(
          children: [
            _buildInteractiveTechItem(
              icon: Icons.map_outlined,
              title: 'Тайлові погодні шари',
              subtitle: 'FlutterMap & OpenStreetMap',
              description:
              'Карта базується на OpenStreetMap тайлах. Поверх них накладаються асинхронні тайлові сервіси OpenWeatherMap для візуалізації опадів, хмарності, вітру та температури в реальному часі.',
            ),
            const Divider(color: Colors.white24, height: 24),
            _buildInteractiveTechItem(
              icon: Icons.sensors_rounded,
              title: 'Моніторинг катаклізмів',
              subtitle: 'NASA EONET та USGS інтеграція',
              description:
              'Інформація про лісові пожежі завантажується безпосередньо з геопросторового API NASA (EONET), а дані про сейсмічну активність — з геологічної служби США (USGS). Координати парсяться в інтерактивні маркери на карті.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGraphicsSection() {
    return AnimatedEntrance(
      delay: const Duration(milliseconds: 350),
      child: _buildGlassContainer(
        child: Column(
          children: [
            _buildInteractiveTechItem(
              icon: Icons.brush_outlined,
              title: 'Процедурний рендеринг',
              subtitle: 'CustomPainter анімація частинок',
              description:
              'Анімації іконок та повноекранні оверлеї (дощ, сніг, туман, блискавка, полярне сяйво) не використовують важкі растрові ресурси. Вони рендеряться математично на GPU через CustomPainter за допомогою тригонометричних функцій часу.',
            ),
            const Divider(color: Colors.white24, height: 24),
            _buildInteractiveTechItem(
              icon: Icons.blur_on_rounded,
              title: 'Ефекти матового скла',
              subtitle: 'BackdropFilter & ImageFilter',
              description:
              'Для візуальної глибини інтерфейсу застосовується розмиття Гауса в реальному часі. Це створює контраст між динамічним анімованим фоном і статичними картками з інформацією.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechStackSheet() {
    return AnimatedEntrance(
      delay: const Duration(milliseconds: 400),
      child: _buildGlassContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Технологічний стек застосунку',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTechChip('Flutter SDK', Colors.blue),
                _buildTechChip('Dart 3', Colors.cyan),
                _buildTechChip('OpenWeather API', Colors.orange),
                _buildTechChip('Groq / x.AI API', Colors.deepPurple),
                _buildTechChip('FlutterMap', Colors.green),
                _buildTechChip('USGS GeoJSON', Colors.teal),
                _buildTechChip('NASA EONET', Colors.red),
                _buildTechChip('Geolocator', Colors.indigo),
                _buildTechChip('Shared Preferences', Colors.blueGrey),
              ],
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.center,
              child: Text(
                'Розроблено з дотриманням принципів Clean Architecture',
                style: TextStyle(color: Colors.white70,
                    fontSize: 12,
                    fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Text(
        label,
        style: const TextStyle(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildGlassContainer({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
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

  Widget _buildInteractiveTechItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String description,
  }) {
    return Theme(
      data: ThemeData(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        dividerColor: Colors.transparent,
      ),
      child: ExpansionTile(
        leading: Icon(icon, color: Colors.white, size: 28),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        iconColor: Colors.white,
        collapsedIconColor: Colors.white70,
        childrenPadding: const EdgeInsets.only(
            top: 8, bottom: 8, left: 4, right: 4),
        children: [
          Text(
            description,
            style: const TextStyle(
              color: Color(0xFFEEEEEE),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

extension on Colors {
  static const Color whiteEE = Color(0xFFEEEEEE);
}