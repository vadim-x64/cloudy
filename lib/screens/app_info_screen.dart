import 'dart:ui';
import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';

class _ExpandableDescription extends StatefulWidget {
  const _ExpandableDescription();

  @override
  State<_ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<_ExpandableDescription> {
  bool _isExpanded = false;

  final String _fullText =
      'Cloudy - розумне рішення нового покоління, створене для максимально точного та візуально динамічного моніторингу погоди. Розроблено для мобільних телефонів Android.\n\n'
      'Можливості застосунку:\n'
      '• детальна метеорологія - температура, відчуття, вологість, тиск, індекс якості повітря, графік на 24 години та прогноз на 5 днів.\n'
      '• динамічні фони - розумні градієнти та анімації, що плавно адаптуються під час доби (світанок, ранок, день, полудень, вечір, сутінки, ніч) та поточні погодні умови.\n'
      '• анімовані іконки та UI - унікальні кастомні іконки, інтерактивний термометр, математично згенеровані ефекти (дощ, сніг, блискавки, вітер, полярне сяйво, туман, хмари, сонце, місяць, захід та схід) та ефект матового скла.\n'
      '• ШІ-метеоролог - вбудований розумний чат зі збереженням контексту діалогу, який аналізує погоду і дає персоналізовані поради (щодо одягу, парасолі тощо).\n'
      '• інтерактивна геокартографія - глобальна карта з тайловими шарами (опади, хмарність, вітер, температура) та живий моніторинг катаклізмів (землетруси, пожежі).\n'
      '• смарт-локація та налаштування - високоточний GPS, автокомпліт для ручного пошуку будь-якого міста світу та зміна одиниць виміру (°C, °F, K).';

  final String _shortText =
      'Cloudy - розумне рішення нового покоління, створене для максимально точного та візуально динамічного моніторингу погоди.';

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
      alignment: Alignment.topCenter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isExpanded ? _fullText : _shortText,
            style: const TextStyle(
              color: Color(0xFFEEEEEE),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text(
                _isExpanded ? 'Приховати' : 'Детальніше',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
                    horizontal: 20.0,
                    vertical: 10,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 10),
                      _buildWelcomeCard(),
                      const SizedBox(height: 25),
                      _buildSectionTitle('Архітектура системи'),
                      const SizedBox(height: 10),
                      _buildArchitectureSection(),
                      const SizedBox(height: 25),
                      _buildSectionTitle('Інтеграція штучного інтелекту'),
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
    final appBarColor = backgroundColors.isNotEmpty
        ? backgroundColors.first.withOpacity(0.92)
        : Colors.blueGrey.shade900.withOpacity(0.92);

    return SliverAppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      backgroundColor: appBarColor,
      elevation: 4,
      shadowColor: Colors.black38,
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
              ),
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
                      FutureBuilder<PackageInfo>(
                        future: PackageInfo.fromPlatform(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            final version = snapshot.data!.version;
                            final buildNumber = snapshot.data!.buildNumber;
                            return Text(
                              'Версія $version (Збірка $buildNumber)',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            );
                          }
                          return const Text(
                            'Завантаження...',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            const _ExpandableDescription(),
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
              title: 'Обробка метеоданих',
              subtitle: 'Паралельні запити та фільтрація',
              description:
                  'Що робить? Забезпечує миттєве завантаження повної картини погоди.\n\n'
                  'Як працює? Система одночасно звертається до трьох різних ендпоінтів OpenWeather API: поточна погода, 5-денний прогноз та рівень забруднення повітря (AQI). Модуль парсингу містить функцію, яка аналізує масив погодних умов. Якщо API повертає одночасно "Сонце" та "Гроза", алгоритм обирає "Грозу" як пріоритетну подію для відображення.\n\n'
                  'Для чого? Це гарантує, що користувач завжди бачить найбільш критичний погодний стан і не чекає послідовного завантаження кожного блоку даних.',
            ),
            const Divider(color: Colors.white24, height: 24),
            _buildInteractiveTechItem(
              icon: Icons.gps_fixed_rounded,
              title: 'Смарт-геолокація та пошук',
              subtitle: 'Geolocator & Autocomplete',
              description:
                  'Що робить? Визначає місцезнаходження пристрою або дозволяє знайти будь-яке місто вручну.\n\n'
                  'Як працює? Пакет Geolocator запитує високоточні координати (GPS). Якщо дозвіл відсутній, система переходить у режим очікування ручного введення. Рядок пошуку підключений до API геокодингу, який під час введення тексту пропонує міста. Всі іншомовні назви міст та регіонів автоматично перекладаються українською через пакет translator та зберігаються у кеші.\n\n'
                  'Для чого? Забезпечує безперебійну роботу застосунку навіть за умови вимкненого GPS, пропонуючи зручний текстовий пошук рідною мовою.',
            ),
            const Divider(color: Colors.white24, height: 24),
            _buildInteractiveTechItem(
              icon: Icons.storage_rounded,
              title: 'Синхронізація та локальний кеш',
              subtitle: 'SharedPreferences та віджет',
              description:
                  'Що робить? Зберігає налаштування користувача та забезпечує роботу віджета робочого столу.\n\n'
                  'Як працює? Вибрані одиниці виміру (°C, °F, K) та стан показу інструкцій записуються у пам\'ять пристрою через SharedPreferences. Для Android-віджета застосунок рендерить спеціальний UI у прихований буфер розміром 900x600 пікселів, зберігає його як зображення і передає нативному AppWidgetManager.\n\n'
                  'Для чого? Зменшує кількість мережевих запитів, запам\'ятовує вподобання та дозволяє мати інформативний віджет на головному екрані без фонового споживання батареї.',
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
              title: 'Вбудований ШІ-асистент',
              subtitle: 'LLM інтеграція',
              description:
                  'Що робить? Надає персоналізовані поради на основі реальної погоди.\n\n'
                  'Як працює? При відкритті чату система генерує прихований системний промпт. У нього автоматично підставляються змінні: назва міста, температура, вологість, швидкість вітру, рівень опадів та AQI. Цей запит відправляється до хмарної великої мовної моделі. Модуль автоматично перемикається між моделями, якщо одна з них недоступна.\n\n'
                  'Для чого? Замість сухої статистики користувач може запитати "Що краще одягнути на пробіжку?" і отримати відповідь, яка враховує, що зараз на вулиці +5°C і сильний вітер.',
            ),
            const Divider(color: Colors.white24, height: 24),
            _buildInteractiveTechItem(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Контекстна пам\'ять',
              subtitle: 'Збереження історії діалогу',
              description:
                  'Що робить? Дозволяє вести логічну і зв\'язну бесіду з асистентом.\n\n'
                  'Як працює? Кожне повідомлення від користувача та відповідь від ШІ записуються у масив пам\'яті сесії. При кожному новому запиті весь цей масив відправляється на сервер. Анімація друку тексту активується лише для нових повідомлень.\n\n'
                  'Для чого? Якщо користувач запитає "Чи брати парасолю?", а потім напише "А ввечері?", ШІ зрозуміє, що мова все ще йде про дощ і парасолю, спираючись на попередні репліки.',
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
              title: 'Метеорологічна карта',
              subtitle: 'Система тайлових шарів',
              description:
                  'Що робить? Наочно демонструє розподіл погодних явищ на планеті.\n\n'
                  'Як працює? На базову карту накладаються прозорі растрові шари (тайли) від OpenWeather. Користувач може перемикатися між шарами: опади, хмарність, температура, вітер, тиск тощо. При натисканні на будь-яку точку карти активується зворотне геокодування, яке визначає назву локації та завантажує для неї погоду.\n\n'
                  'Для чого? Дає змогу відстежувати наближення циклонів, фронтів опадів та переглядати погоду в будь-якій точці світу одним дотиком.',
            ),
            const Divider(color: Colors.white24, height: 24),
            _buildInteractiveTechItem(
              icon: Icons.sensors_rounded,
              title: 'Моніторинг природних явищ',
              subtitle: 'Інтеграція NASA EONET та USGS',
              description:
                  'Що робить? Відстежує глобальні природні катаклізми у реальному часі.\n\n'
                  'Як працює? При виборі відповідного фільтра система робить запит до урядових агенцій США. Дані Геологічної служби (USGS) парсяться для виведення землетрусів (розмір та колір маркера залежать від магнітуди). Дані NASA EONET використовуються для відображення активних лісових пожеж та потужних штормів через GeoJSON координати.\n\n'
                  'Для чого? Перетворює застосунок із звичайного погодного інформера на повноцінний інструмент геопросторового моніторингу.',
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
              title: 'Процедурний рендеринг графіки',
              subtitle: 'Математична анімація',
              description:
                  'Що робить? Відтворює погодні ефекти (сніг, дощ, блискавки) без використання відеофайлів.\n\n'
                  'Як працює? Всі ефекти на екрані малюються математично за допомогою класу CustomPainter. Алгоритми використовують тригонометрію (синус, косинус), зсув фаз та генератори псевдовипадкових чисел. Наприклад, кожна крапля дощу або сніжинка має власну розраховану швидкість падіння та траєкторію, яка оновлюється з кожним кадром (60 FPS).\n\n'
                  'Для чого? Це дозволяє створювати плавні, унікальні анімації, які ніколи не повторюються, при цьому кардинально економлячи оперативну пам\'ять та заряд батареї пристрою.',
            ),
            const Divider(color: Colors.white24, height: 24),
            _buildInteractiveTechItem(
              icon: Icons.blur_on_rounded,
              title: 'Адаптивний UI та Glassmorphism',
              subtitle: 'Обчислення часу доби та ефекти розмиття',
              description:
                  'Що робить? Змінює зовнішній вигляд застосунку відповідно до реального часу та погоди.\n\n'
                  'Як працює? Метод обчислення фази доби аналізує точний час сходу та заходу сонця в поточній геолокації. На основі цього генерується градієнт фону. Якщо йде дощ або туман, функція Color.lerp динамічно домішує сірі відтінки у фон. Всі інформаційні панелі застосовують BackdropFilter (розмиття за Гаусом), створюючи ефект напівпрозорого матового скла.\n\n'
                  'Для чого? Забезпечує глибоке візуальне занурення. Інтерфейс інтуїтивно передає атмосферу за вікном, залишаючись читабельним за рахунок контрасту скла.',
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
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildTechChip('Flutter SDK', Colors.blue),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: _buildTechChip('Dart 3', Colors.cyan),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: _buildTechChip('OpenWeather API', Colors.orange),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: _buildTechChip('Cloud LLM API', Colors.deepPurple),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: _buildTechChip('FlutterMap', Colors.green),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: _buildTechChip('USGS GeoJSON', Colors.teal),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildTechChip('NASA EONET', Colors.red),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: _buildTechChip('Geolocator', Colors.indigo),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: _buildTechChip(
                        'Shared Preferences',
                        Colors.blueGrey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: _buildTechChip(
                        'Lottie Animations',
                        Colors.pinkAccent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: _buildTechChip('Home Widget', Colors.lightGreen),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: _buildTechChip('DotEnv Config', Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: _buildTechChip('Google Translator', Colors.amber),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: _buildTechChip('Intl Formatting', Colors.brown),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.center,
              child: Text(
                'Розроблено з дотриманням принципів Clean Architecture',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
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
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
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
          top: 8,
          bottom: 8,
          left: 4,
          right: 4,
        ),
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
