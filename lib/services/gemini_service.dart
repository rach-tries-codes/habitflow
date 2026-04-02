import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  
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

  // Generate a full analysis of all the user's habits
  Future<String> generateHabitAnalysis({
    required List<Map<String, dynamic>> habits,
  }) async {
    try {
      if (habits.isEmpty) {
        return 'Add some habits to unlock your personalised analysis! 🌱';
      }

      final habitLines = habits.map((h) {
        final streak = h['streak'] ?? 0;
        final done = h['done'] == true ? 'done today' : 'not done today';
        return '- ${h['emoji']} ${h['name']}: $streak day streak, $done';
      }).join('\n');

      final prompt = '''
You are a supportive habit coach. Here are the user\'s habits:
$habitLines

In under 80 words, give personalised advice as flowing text (no bullet points):
1. Briefly celebrate their strongest habit (highest streak)
2. Give one specific, actionable tip for their weakest habit (lowest streak)
3. One simple consistency strategy they can start today

Be warm and specific. Only return the advice, nothing else.
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text ?? 'Keep building those habits — every day counts! 🌿';
    } catch (e) {
      return 'Keep building those habits — every day counts! 🌿';
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