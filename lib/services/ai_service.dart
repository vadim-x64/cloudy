import 'dart:async';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/weather_model.dart';

class AiService {
  Future<String?> generateDynamicSummary(
      WeatherModel weather,
      String unitStr,
      ) async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];

      if (apiKey == null || apiKey.trim().isEmpty) {
        return 'Помилка доступу до ШІ.';
      }

      final prompt = '''
      Привіт, друже. Уяви, що ти метеоролог у додатку Cloudy. 
      Я звертаюсь до застосунку аби переглянути погоду. А ти 
      маєш написати чіткий, обгрунтований, внятний та 
      змістовний прогноз погоди для міста ${weather.cityName} 
      українською мовою. Там треба показати час доби ${weather.partOfDay},
      поточний стан погоди ${weather.description}, температуру 
      ${weather.temperature}$unitStr (відчувається як ${weather.feelsLike}$unitStr),
      швидкість і напрямок вітру ${weather.windSpeed} м/с й 
      км/год, чи будуть опади протягом 24 годин (доби) ${weather.precipitation} мм.
      
      Щоб краще мені надати відповідь, слідуй наступним рекомендаціям:
      1. Текст має складатися до 3-4 зв'язних речень одним суцільним абзацом. 
      2. Не можна писати лише одне слово чи одне речення.
      3. Погоду описуй своїми словами. Це головне завдання, не обмежуйся лише привітанням.
      4. Додай коротку пораду, типу чи брати парасолю, або чи варто тепло одягатися, 
      або чи гарний час для прогулянки тощо.
      5. Гарантовано заверши останню думку і постав крапку в кінці тексту.
      6. Усі числові значення залишай цифрами, не пиши словами.
      7. Уникай списків й маркдауну (ніяких зірочок чи жирного шрифту). 
      8. Пиши тепло і природно, як жива людина.
      9. Останнє речення - лише коротке тепле побажання відповідно до часу доби (${weather.partOfDay}).
      Приклади: бажаємо вам затишного вечора. Гарного й спокійного ранку. Тихої і спокійної ночі. Продуктивного дня.
      ''';

      final content = [Content.text(prompt)];

      final modelsToTry = [
        'gemini-2.5-flash',
        'gemini-2.0-flash',
        'gemini-1.5-flash',
        'gemini-pro',
      ];

      String lastError = '';

      for (final modelName in modelsToTry) {
        try {
          final model = GenerativeModel(
            model: modelName,
            apiKey: apiKey,
            generationConfig: GenerationConfig(
              temperature: 0.7,
              maxOutputTokens: 8192,
            ),
            safetySettings: [
              SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
              SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
              SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none),
              SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
            ],
          );

          final response = await model.generateContent(content).timeout(const Duration(seconds: 15));
          final result = response.text?.trim();

          if (result != null && result.isNotEmpty) {
            return result.replaceAll('**', '').replaceAll('*', '');
          }
        } on TimeoutException {
          lastError = 'Таймаут відповіді для $modelName';
        } catch (e) {
          lastError = e.toString();
        }
      }
      return 'ШІ не відповідає. Остання помилка: $lastError';
    } catch (e) {
      return 'Критична помилка ШІ: $e';
    }
  }
}