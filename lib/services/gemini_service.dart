import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static const String _apiKey = 'AIzaSyDcvxQCMaxCOwKJncuFdBKxtN51p6P0OtE';
  
  final GenerativeModel _model = GenerativeModel(
    model: 'gemini-pro',
    apiKey: _apiKey,
  );

  // Generate a journaling prompt based on user's habits
  Future<String> generateJournalPrompt(List<String> habitNames) async {
    try {
      final habitsText = habitNames.join(', ');
      final prompt = '''
You are a supportive wellness coach. Based on these habits the user is tracking: $habitsText
Generate ONE short, thoughtful journaling prompt (max 20 words) that relates to their habits.
Only return the prompt, nothing else.
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text ?? 'How did your habits make you feel today?';
    } catch (e) {
      return 'How did your habits make you feel today?';
    }
  }

  // Generate weekly insight based on habit completion
  Future<String> generateWeeklyInsight({
    required int completedHabits,
    required int totalHabits,
    required String topMood,
  }) async {
    try {
      final prompt = '''
You are a supportive wellness coach. A user completed $completedHabits out of $totalHabits habit check-ins this week. Their most common mood was $topMood.
Write ONE encouraging insight (max 30 words). Be warm and specific.
Only return the insight, nothing else.
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text ?? 'Great effort this week! Keep building those habits one day at a time.';
    } catch (e) {
      return 'Great effort this week! Keep building those habits one day at a time.';
    }
  }

  // Generate habit coaching tip
  Future<String> generateHabitTip(String habitName) async {
    try {
      final prompt = '''
You are a habit coach. Give ONE practical tip (max 25 words) to help someone stick to this habit: $habitName
Only return the tip, nothing else.
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text ?? 'Start small and be consistent — even 5 minutes counts!';
    } catch (e) {
      return 'Start small and be consistent — even 5 minutes counts!';
    }
  }
}