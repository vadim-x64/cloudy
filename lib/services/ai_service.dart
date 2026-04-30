import 'dart:async';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/weather_model.dart';

class AiService {
  Future<String?> generateDynamicSummary(
    WeatherModel weather,
    String unitStr,
    String tempStr,
    String feelsLikeStr,
  ) async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];

      if (apiKey == null || apiKey.trim().isEmpty) {
        return 'Помилка доступу до ШІ.';
      }

      final prompt =
          '''
      Привіт друже! Уяви, що ти привітний метеоролог у додатку Cloudy. 
      Твоє завдання - написати один суцільний абзац тексту 
      з 4-5 зв'язних речень із чітким, обгрунтованим та 
      змістовним прогнозом погоди для міста ${weather.cityName} 
      українською мовою. Опиши своїми словами поточну погоду 
      (${weather.description}) для поточного часу доби (${weather.partOfDay}). 
      Обов'язково вкажи температуру $tempStr$unitStr 
      (відчувається як $feelsLikeStr$unitStr), швидкість і напрямок вітру 
      ${weather.windSpeed} м/с (додай також значення у км/год) та очікувану 
      кількість опадів протягом доби ${weather.precipitation} мм. Усі числові 
      значення залишай виключно цифрами. Пиши природно і по суті, як жива людина, 
      абсолютно без використання маркдауну, списків, зірочок чи жирного шрифту. 
      На основі цих погодних даних додай коротку пораду, наприклад, 
      чи брати парасолю, чи варто тепліше одягнутися, або чи гарний зараз 
      час для прогулянки. Текст має гарантовано завершуватися логічною 
      думкою з крапкою, де останнє речення - це виключно коротке 
      побажання відповідно до часу доби (${weather.partOfDay}), наприклад: 
      Продуктивного дня. Затишного вечора. Тихої і спокійної ночі.
      ''';

      final content = [Content.text(prompt)];

      final modelsToTry = [
        'gemini-2.5-flash',
        'gemini-2.0-flash',
        'gemini-1.5-flash',
        'gemini-1.5-pro',
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
              SafetySetting(
                HarmCategory.sexuallyExplicit,
                HarmBlockThreshold.none,
              ),
              SafetySetting(
                HarmCategory.dangerousContent,
                HarmBlockThreshold.none,
              ),
            ],
          );

          final response = await model
              .generateContent(content)
              .timeout(const Duration(seconds: 15));
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
      return null;
    } catch (e) {
      return null;
    }
  }
}
