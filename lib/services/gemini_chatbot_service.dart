import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:FitStart/model/chat_message.dart';
import 'package:FitStart/utils/dummy_data.dart';

class GeminiChatbotService {
  static const String _apiKey = 'REDACTED_GEMINI_KEY';
  late final GenerativeModel _model;
  late final ChatSession _chat;

  GeminiChatbotService() {
    print('🤖 Initializing Gemini chatbot service...');
    try {
      _model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _apiKey,
        systemInstruction: Content.system(_getSystemPrompt()),
      );
      _chat = _model.startChat();
      print('✅ Gemini chatbot service initialized successfully');
    } catch (e) {
      print('❌ Error initializing Gemini: $e');
      rethrow;
    }
  }

  String _getSystemPrompt() {
    // Build context about available venues
    final venueList = sportFieldList.map((field) {
      return '''
- ${field.name} (${field.category.name})
  Location: ${field.address}
  Price: ₹${field.price}/hour
  Rating: ${field.rating}/5
  Facilities: ${field.facilities.map((f) => f.name).join(', ')}
  Hours: ${field.openTime} - ${field.closeTime}
''';
    }).join('\n');

    return '''You are FitStart AI Assistant, a friendly and helpful chatbot for the FitStart app. Your role is to help users with:

1. **Sports Venue Booking**: Help users find and book sports venues (basketball, tennis, volleyball, football, table tennis courts)
2. **Health & Fitness Advice**: Provide general fitness tips, workout suggestions, and healthy lifestyle guidance
3. **Gym & Training Support**: Answer questions about training routines, exercise techniques, and fitness goals

**Available Venues in FitStart:**
$venueList

**Your Personality:**
- Be friendly, encouraging, and motivating
- Use emojis occasionally to be more engaging 🏀 💪 🎾
- Keep responses concise (2-3 sentences for simple queries, longer for detailed requests)
- Always promote an active, healthy lifestyle
- Be supportive of users' fitness journeys

**Guidelines:**
- When users ask about booking venues, suggest suitable options based on their preferences
- Provide accurate information about venue facilities, prices, and locations
- For health advice, give general wellness tips (not medical advice)
- Encourage users to stay active and use the app's features
- If asked about something outside your scope (venue booking, health, fitness), politely redirect to relevant topics
- Always mention checking the app for real-time availability and exact booking

**Response Style:**
- Start conversations warmly
- Use bullet points for lists
- Include relevant emojis
- End with encouraging or helpful notes
''';
  }

  Future<ChatMessage> sendMessage(String userMessage) async {
    try {
      print('🤖 Sending message to Gemini: $userMessage');

      final response =
          await _chat.sendMessage(Content.text(userMessage)).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timed out after 30 seconds');
        },
      );

      print('🤖 Gemini response received');
      print('🤖 Response text: ${response.text}');
      print('🤖 Response candidates: ${response.candidates.length}');

      final botResponse = response.text ??
          'I apologize, I couldn\'t process that. Could you try again?';

      return ChatMessage(
        text: botResponse,
        isUser: false,
      );
    } catch (e, stackTrace) {
      print('❌ Gemini error: $e');
      print('❌ Stack trace: $stackTrace');
      return ChatMessage(
        text:
            'I\'m having trouble connecting right now. Please check your internet connection and try again. 🔄\n\nError: ${e.toString()}',
        isUser: false,
      );
    }
  }

  Future<ChatMessage> getWelcomeMessage() async {
    try {
      print('🤖 Requesting welcome message from Gemini...');
      final response = await _chat.sendMessage(Content.text(
          'Greet the user warmly and briefly introduce yourself as their FitStart AI assistant.'));
      print('🤖 Welcome message received: ${response.text}');

      final botResponse = response.text ??
          'Hi! I\'m your FitStart AI assistant. How can I help you today? 💪';

      return ChatMessage(
        text: botResponse,
        isUser: false,
      );
    } catch (e) {
      print('❌ Welcome message error: $e');
      return ChatMessage(
        text:
            'Hi! I\'m your FitStart AI assistant. I can help you find sports venues, answer fitness questions, and support your health journey! 💪🏀',
        isUser: false,
      );
    }
  }

  void resetChat() {
    _chat = _model.startChat();
  }
}
