import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/weather_model.dart';

class AiService {
  Future<String?> generateGreeting(WeatherModel weather) async {
    try {
      final apiKey = dotenv.env['GROK_API_KEY'];
      if (apiKey == null || apiKey.trim().isEmpty) return 'Привіт!';

      final isGroq = apiKey.trim().startsWith('gsk_');
      final url = isGroq
          ? Uri.parse('https://api.groq.com/openai/v1/chat/completions')
          : Uri.parse('https://api.x.ai/v1/chat/completions');

      final modelName = isGroq ? 'llama-3.1-8b-instant' : 'grok-beta';

      final systemContent = dotenv.env['AI_GREETING_PROMPT'];

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
                {'role': 'system', 'content': systemContent},
              ],
              'temperature': 0.7,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content']
            .toString()
            .trim()
            .replaceAll('"', '');
      }
      return 'Привіт! Чим можу допомогти?';
    } catch (e) {
      return 'Привіт! Чим можу допомогти?';
    }
  }

  Future<String?> sendChatMessage({
    required List<Map<String, String>> chatHistory,
    required WeatherModel weather,
    required String unitStr,
  }) async {
    try {
      final apiKey = dotenv.env['GROK_API_KEY'];

      if (apiKey == null || apiKey.trim().isEmpty) {
        return 'Помилка доступу до ШІ. Перевірте ключ API.';
      }

      final rawPrompt =
          dotenv.env['AI_CHAT_PROMPT'] ??
          '{cityName}{description}{partOfDay}{temperature}{unitStr}{feelsLike}{unitStr}{windSpeed}{precipitation}{humidity}{aqi}';

      final systemPrompt = rawPrompt
          .replaceAll(r'\n', '\n')
          .replaceAll('{cityName}', weather.cityName)
          .replaceAll('{description}', weather.description)
          .replaceAll('{partOfDay}', weather.partOfDay)
          .replaceAll('{temperature}', weather.temperature.toString())
          .replaceAll('{feelsLike}', weather.feelsLike.toString())
          .replaceAll('{unitStr}', unitStr)
          .replaceAll('{windSpeed}', weather.windSpeed.toString())
          .replaceAll('{precipitation}', weather.precipitation.toString())
          .replaceAll('{humidity}', weather.humidity.toString())
          .replaceAll('{aqi}', weather.aqi.toString());

      final isGroq = apiKey.trim().startsWith('gsk_');
      final url = isGroq
          ? Uri.parse('https://api.groq.com/openai/v1/chat/completions')
          : Uri.parse('https://api.x.ai/v1/chat/completions');

      List<String> modelsToTry = isGroq
          ? ['llama-3.3-70b-versatile', 'llama-3.1-8b-instant', 'gemma2-9b-it']
          : ['grok-2-latest', 'grok-beta'];

      List<Map<String, String>> apiMessages = [
        {'role': 'system', 'content': systemPrompt},
        ...chatHistory,
      ];

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
                  'messages': apiMessages,
                  'temperature': 0.7,
                  'stream': false,
                }),
              )
              .timeout(const Duration(seconds: 15));

          if (response.statusCode == 200) {
            final data = jsonDecode(utf8.decode(response.bodyBytes));
            final result = data['choices'][0]['message']['content']
                .toString()
                .trim();
            return result.replaceAll('**', '').replaceAll('*', '');
          }
        } catch (e) {
          print('Помилка $modelName: $e');
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
