import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/theme.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int _totalHabits = 0;
  int _completedToday = 0;
  int _totalJournalEntries = 0;
  int _longestStreak = 0;
  Map<String, int> _moodCounts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final user = FirebaseAuth.instance.currentUser;

    // Load habits
    final habitsSnapshot = await FirebaseFirestore.instance
        .collection('habits')
        .where('userId', isEqualTo: user?.uid)
        .get();

    int completed = 0;
    int longestStreak = 0;

    for (final doc in habitsSnapshot.docs) {
      final data = doc.data();
      if (data['done'] == true) completed++;
      final streak = data['streak'] ?? 0;
      if (streak > longestStreak) longestStreak = streak;
    }

    // Load journal entries
    final journalSnapshot = await FirebaseFirestore.instance
        .collection('journal')
        .where('userId', isEqualTo: user?.uid)
        .get();

    // Count moods
    Map<String, int> moodCounts = {};
    for (final doc in journalSnapshot.docs) {
      final mood = doc.data()['mood'] as String?;
      if (mood != null) {
        moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
      }
    }

    setState(() {
      _totalHabits = habitsSnapshot.docs.length;
      _completedToday = completed;
      _longestStreak = longestStreak;
      _totalJournalEntries = journalSnapshot.docs.length;
      _moodCounts = moodCounts;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _StatsBgPainter(isDark: isDark),
            ),
          ),
          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E301E).withOpacity(0.75)
                                : Colors.white.withOpacity(0.72),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF4A7040).withOpacity(0.25)
                                  : const Color(0xFFB4D4A0).withOpacity(0.35),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your Stats 📊',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppTheme.darkText
                                      : AppTheme.moss,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Track your progress over time',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? AppTheme.darkTextMid
                                      : AppTheme.textMid,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Stats grid
                        _SectionLabel(label: 'Overview', isDark: isDark),
                        const SizedBox(height: 8),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1.5,
                          children: [
                            _StatCard(
                              emoji: '🌱',
                              value: '$_totalHabits',
                              label: 'Total habits',
                              isDark: isDark,
                            ),
                            _StatCard(
                              emoji: '✅',
                              value: '$_completedToday',
                              label: 'Completed today',
                              isDark: isDark,
                            ),
                            _StatCard(
                              emoji: '🔥',
                              value: '$_longestStreak',
                              label: 'Longest streak',
                              isDark: isDark,
                            ),
                            _StatCard(
                              emoji: '📓',
                              value: '$_totalJournalEntries',
                              label: 'Journal entries',
                              isDark: isDark,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Completion bar
                        _SectionLabel(label: 'Today\'s completion', isDark: isDark),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E301E).withOpacity(0.65)
                                : Colors.white.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF3A6040).withOpacity(0.25)
                                  : AppTheme.sageLight.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '$_completedToday / $_totalHabits habits',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? AppTheme.darkText
                                          : AppTheme.textDark,
                                    ),
                                  ),
                                  Text(
                                    _totalHabits > 0
                                        ? '${((_completedToday / _totalHabits) * 100).toStringAsFixed(0)}%'
                                        : '0%',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.sage,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: _totalHabits > 0
                                      ? _completedToday / _totalHabits
                                      : 0,
                                  backgroundColor: isDark
                                      ? const Color(0xFF3A6040).withOpacity(0.3)
                                      : AppTheme.mint.withOpacity(0.4),
                                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.sage),
                                  minHeight: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Mood history
                        if (_moodCounts.isNotEmpty) ...[
                          _SectionLabel(label: 'Mood history', isDark: isDark),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E301E).withOpacity(0.65)
                                  : Colors.white.withOpacity(0.65),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF3A6040).withOpacity(0.25)
                                    : AppTheme.sageLight.withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              children: _moodCounts.entries.map((entry) {
                                final total = _moodCounts.values
                                    .fold(0, (a, b) => a + b);
                                final percentage = entry.value / total;
                                return Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    children: [
                                      Text(entry.key,
                                          style: const TextStyle(
                                              fontSize: 20)),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          child: LinearProgressIndicator(
                                            value: percentage,
                                            backgroundColor: isDark
                                                ? const Color(0xFF3A6040)
                                                    .withOpacity(0.3)
                                                : AppTheme.mint
                                                    .withOpacity(0.4),
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(AppTheme.sage),
                                            minHeight: 8,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        '${entry.value}x',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? AppTheme.darkTextMid
                                              : AppTheme.textLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String emoji, value, label;
  final bool isDark;
  const _StatCard({
    required this.emoji,
    required this.value,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E301E).withOpacity(0.65)
            : Colors.white.withOpacity(0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? const Color(0xFF3A6040).withOpacity(0.25)
              : AppTheme.sageLight.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: isDark ? AppTheme.darkText : AppTheme.moss,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppTheme.darkTextMid : AppTheme.textLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SectionLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.9,
        color: isDark ? AppTheme.darkTextMid : AppTheme.textLight,
      ),
    );
  }
}

class _StatsBgPainter extends CustomPainter {
  final bool isDark;
  _StatsBgPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark
          ? const Color(0xFF2A4028).withOpacity(0.8)
          : const Color(0xFFC8D9B8).withOpacity(0.5)
      ..style = PaintingStyle.fill;

    _drawPebble(canvas, paint, 18, 60, 9, 6, -0.35);
    _drawPebble(canvas, paint, size.width - 30, 40, 7, 5, 0.26);
    _drawPebble(canvas, paint, 12, 200, 10, 6.5, 0.44);
    _drawPebble(canvas, paint, size.width - 25, 310, 7, 4.5, -0.26);

    final grassPaint = Paint()
      ..color = isDark
          ? const Color(0xFF4A7040).withOpacity(0.6)
          : const Color(0xFF90B878).withOpacity(0.5)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    _drawGrass(canvas, grassPaint, size.width - 22, 20);
    _drawGrass(canvas, grassPaint, size.width - 17, 22);
    _drawGrass(canvas, grassPaint, 8, size.height - 40);
  }

  void _drawPebble(Canvas canvas, Paint paint, double cx, double cy,
      double rx, double ry, double angle) {
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(angle);
    canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2),
        paint);
    canvas.restore();
  }

  void _drawGrass(Canvas canvas, Paint paint, double x, double y) {
    final path = Path();
    path.moveTo(x, y);
    path.quadraticBezierTo(x + 4, y - 12, x + 8, y - 2);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_StatsBgPainter old) => old.isDark != isDark;
}