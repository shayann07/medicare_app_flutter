import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatbotController extends GetxController {
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get messages => _messages;
  bool get isLoading => _isLoading;

//   static const String medicalDisclaimer = """
// IMPORTANT: I am not a doctor. I can provide general health information but this is not medical advice.
// For any health concerns, please consult a qualified healthcare professional.
// In emergencies, call your local emergency number immediately.
//
// Now, regarding your question:""";

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    _addMessage(text, true);

    try {
      _setLoading(true);
      final response = await _getAIResponse(text);
      _addMessage(response, false);
    } catch (e) {
      _addMessage("Sorry, I encountered an error. Please try again later.", false);
    } finally {
      _setLoading(false);
    }
  }

  Future<String> _getAIResponse(String prompt) async {
    final apiKey = "YOUR_OPENAI_API_KEY";
    const maxRetries = 2;
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        final url = Uri.parse('https://api.openai.com/v1/chat/completions');
        final headers = {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        };

        final messages = [
          {
            "role": "system",
            "content": "You are a helpful medical information assistant. "
                "ALWAYS begin your response with the exact disclaimer"
                "NEVER diagnose conditions, recommend treatments, or suggest medications. "
                "Only provide general health information available in public medical resources. "
                "If asked about emergencies, instruct to call local emergency services immediately."
          },
          {"role": "user", "content": prompt}
        ];

        final body = jsonEncode({
          "model": "gpt-4o-mini",
          "messages": messages,
          "temperature": 0.3,
          "max_tokens": 50,
        });

        final response = await http
            .post(url, headers: headers, body: body)
            .timeout(const Duration(seconds: 15));
        print("Response Status Code: ${response.statusCode}");

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['choices'][0]['message']['content'];
        } else if (response.statusCode == 429) {
          print("Rate limited: ${response.body}");
          await Future.delayed(const Duration(seconds: 2));
          retryCount++;
          continue;
        } else {
          print("Unexpected error: ${response.body}");
          throw Exception('API error: ${response.statusCode}');
        }
      } catch (e) {
        if (retryCount < maxRetries - 1) {
          retryCount++;
          await Future.delayed(const Duration(seconds: 1));
          continue;
        }
        rethrow;
      }
    }
    throw Exception('Max retries exceeded');
  }


  void _addMessage(String text, bool isUser) {
    _messages.insert(0, {
      'text': text,
      'isUser': isUser,
      'timestamp': DateTime.now(),
    });
    update();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    update();
  }
}

/*"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";*/
