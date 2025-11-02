import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const apiKey = 'REDACTED_GEMINI_KEY';

  print('Listing available Gemini models...\n');

  try {
    // List models
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey');

    final response = await http.get(url);

    print('Status code: ${response.statusCode}\n');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('✅ Available models:');
      for (var model in data['models']) {
        final name = model['name'];
        final supportedMethods = model['supportedGenerationMethods'] ?? [];
        if (supportedMethods.contains('generateContent')) {
          print('  - $name ✅ (supports generateContent)');
        }
      }
    } else {
      print('❌ Error: ${response.body}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
