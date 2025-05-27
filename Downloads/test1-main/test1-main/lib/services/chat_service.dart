import 'package:google_generative_ai/google_generative_ai.dart';
import '../constants/constants.dart';
import '../models/chat_message.dart';

class ChatService {
  final GenerativeModel _model;
  final List<ChatMessage> _history = [];
  
  ChatService() : _model = GenerativeModel(
    model: 'gemini-2.0-flash',
    apiKey: Constants.apiKey,
  );

  List<ChatMessage> get history => List.unmodifiable(_history);

  Future<String> sendMessage(String message) async {
    try {
      final prompt = message;
      _history.add(ChatMessage(text: message, type: MessageType.user));

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      final botMessage = response.text ?? 'Sorry, I could not generate a response';
      _history.add(ChatMessage(text: botMessage, type: MessageType.bot));
      
      return botMessage;
    } catch (e) {
      final errorMessage = 'Error: $e';
      _history.add(ChatMessage(text: errorMessage, type: MessageType.bot));
      return errorMessage;
    }
  }

  void clearHistory() {
    _history.clear();
  }
} 