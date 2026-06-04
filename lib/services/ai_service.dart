import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
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
      final apiKey = dotenv.env['GROK_API_KEY'];

      if (apiKey == null || apiKey.trim().isEmpty) {
        return 'Помилка доступу до ШІ (ключ не знайдено).';
      }

      final systemPrompt =
          '''
        ШІ, на зв'язку! Короче є до тебе таке завдання. Уяви, що ти 
        працюєш метеорологом і твоя задача надавати користувачу інформацію про
        погодний стан на місцевості в реальному часі ( ${weather.cityName},
        ${weather.description}, ${weather.partOfDay}, $tempStr$unitStr, 
        $feelsLikeStr$unitStr, ${weather.windSpeed}, ${weather.precipitation}. 
        Отже справа твоя - це видати 1 суцільний абзац тексту до 5 зв'язних 
        речень із внятним, чітким, обгрунтованим, чистим та змістовним 
        прогнозом погоди для міста українською мовою.
      ''';

      final isGroq = apiKey.trim().startsWith('gsk_');

      final url = isGroq
          ? Uri.parse('https://api.groq.com/openai/v1/chat/completions')
          : Uri.parse('https://api.x.ai/v1/chat/completions');

      List<String> modelsToTry = [];

      if (isGroq) {
        modelsToTry = [
          'llama-3.3-70b-versatile',
          'llama-3.1-8b-instant',
          'gemma2-9b-it',
          'llama-3.2-3b-preview',
          'llama-3.2-1b-preview',
        ];
        print(
          'Виявлено ключ Groq (gsk_). Використовуємо API Groq замість xAI.',
        );
      } else {
        try {
          final modelsUrl = Uri.parse('https://api.x.ai/v1/models');
          final modelsRes = await http
              .get(modelsUrl, headers: {'Authorization': 'Bearer $apiKey'})
              .timeout(const Duration(seconds: 10));

          if (modelsRes.statusCode == 200) {
            final data = jsonDecode(modelsRes.body);
            final List modelsList = data['data'] ?? [];

            modelsToTry = modelsList
                .map((m) => m['id'].toString())
                .where(
                  (id) => id.contains('grok'),
                )
                .toList();

            print('Доступні моделі xAI для твого ключа: $modelsToTry');
          } else {
            print(
              'Не вдалося динамічно отримати список моделей. Статус: ${modelsRes.statusCode}',
            );
          }
        } catch (e) {
          print('Помилка при отриманні списку моделей: $e');
        }

        if (modelsToTry.isEmpty) {
          modelsToTry = ['grok-2-latest', 'grok-beta', 'grok-2'];
        }
      }

      String lastError = '';

      for (final modelName in modelsToTry) {
        try {
          final response = await http
              .post(
                url,
                headers: {
                  'Content-Type': 'application/json; charset=utf-8',
                  'Authorization': 'Bearer $apiKey',
                },
                body: jsonEncode({
                  'model': modelName,
                  'messages': [
                    {'role': 'system', 'content': systemPrompt}
                  ],
                  'temperature': 0.7,
                  'stream': false,
                }),
              ).timeout(const Duration(seconds: 15));

          if (response.statusCode == 200) {
            final responseBody = utf8.decode(response.bodyBytes);
            final data = jsonDecode(responseBody);

            final result = data['choices'][0]['message']['content']
                .toString()
                .trim();
            print('Успішно використано модель: $modelName');
            return result.replaceAll('**', '').replaceAll('*', '');
          } else {
            lastError =
                'Помилка $modelName: ${response.statusCode} - ${response.body}';
            print(lastError);

            if (response.statusCode == 401 || response.statusCode == 403) {
              return 'Помилка авторизації. Перевір GROK_API_KEY.';
            }
          }
        } on TimeoutException {
          print('Таймаут для моделі $modelName');
        } catch (e) {
          print('Помилка при запиті до $modelName: $e');
        }
      }
      return null;
    } catch (e) {
      print('Загальна помилка AiService: $e');
      return null;
    }
  }
}