import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'add_habit_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/gemini_service.dart';
import '../services/auth_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';

String _getGreeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

String _formatDate() {
  final now = DateTime.now();
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '🗓 ${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _weeklyInsight = 'Loading your weekly insight...';
  final GeminiService _geminiService = GeminiService();

  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadWeeklyInsight();
    _resetHabitsIfNewDay();
    _loadBannerAd();
  }

  Future<void> _loadBannerAd() async {
    final ad = await AdService.loadBannerAd();
    if (ad != null) {
      setState(() {
        _bannerAd = ad;
        _isBannerLoaded = true;
      });
    }
  }
  @override
  void dispose() {
    AdService.disposeBannerAd();
    super.dispose();
  }
  Future<void> _resetHabitsIfNewDay() async {
    final authService = AuthService();
    await authService.resetHabitsIfNewDay();
  }

  Future<void> _loadWeeklyInsight() async {
    final user = FirebaseAuth.instance.currentUser;
    final snapshot = await FirebaseFirestore.instance
        .collection('habits')
        .where('userId', isEqualTo: user?.uid)
        .get();

    final total = snapshot.docs.length;
    final completed = snapshot.docs
        .where((doc) => doc.data()['done'] == true)
        .length;

    if (total == 0) {
      setState(() => _weeklyInsight = 'Add some habits to get your weekly insight! 🌱');
      return;
    }

    final insight = await _geminiService.generateWeeklyInsight(
      completedHabits: completed,
      totalHabits: total,
      topMood: '😊',
    );
    setState(() => _weeklyInsight = insight);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;
    final firstName = user?.displayName?.split(' ').first ?? 'there';
    return Scaffold(
      bottomSheet: _isBannerLoaded && _bannerAd != null
          ? SizedBox(
              height: _bannerAd!.size.height.toDouble(),
              width: double.infinity,
              child: AdWidget(ad: _bannerAd!),
            )
          : null,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddHabitScreen(),
            ),
          );
        },
        backgroundColor: AppTheme.sage,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Stack(
        children: [
          // Nature background
          _NatureBackground(isDark: isDark),
          // Main content
          SafeArea(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('habits')
                  .where('userId', isEqualTo: user?.uid)
                  .orderBy('createdAt', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];
                final totalCount = docs.length;
                final completedCount = docs
                    .where((doc) =>
                        (doc.data() as Map<String, dynamic>)['done'] == true)
                    .length;
                final incompleteCount = totalCount - completedCount;
                final longestStreak = docs.fold<int>(0, (max, doc) {
                  final streak =
                      (doc.data() as Map<String, dynamic>)['streak'] as int? ??
                          0;
                  return streak > max ? streak : max;
                });
                final completionPct = totalCount > 0
                    ? ((completedCount / totalCount) * 100).round()
                    : 0;

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      _GreetingCard(
                        isDark: isDark,
                        userName: firstName,
                        incompleteCount: incompleteCount,
                        totalCount: totalCount,
                        dateLabel: _formatDate(),
                      ),
                      const SizedBox(height: 12),
                      _StreakRow(
                        isDark: isDark,
                        longestStreak: longestStreak,
                        completedCount: completedCount,
                        totalCount: totalCount,
                        completionPct: completionPct,
                      ),
                      const SizedBox(height: 16),
                      // Weekly AI Insight card
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.sage.withOpacity(0.13),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.sage.withOpacity(0.25),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('✨', style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'WEEKLY INSIGHT · AI',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.9,
                                      color: AppTheme.sage,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _weeklyInsight,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark
                                          ? AppTheme.darkText
                                          : AppTheme.textDark,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      _SectionLabel(label: "Today's Habits", isDark: isDark),
                      const SizedBox(height: 8),
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          docs.isEmpty)
                        const Center(child: CircularProgressIndicator())
                      else if (docs.isEmpty)
                        Center(
                          child: Column(
                            children: [
                              const SizedBox(height: 40),
                              const Text('🌱', style: TextStyle(fontSize: 48)),
                              const SizedBox(height: 12),
                              Text(
                                'No habits yet!\nTap + to add your first habit.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark
                                      ? AppTheme.darkTextMid
                                      : AppTheme.textLight,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Column(
                          children: docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final streak = data['streak'] ?? 0;
                            final streakText = streak > 0
                                ? '🔥 $streak days'
                                : 'Start your streak!';

                            return _HabitItem(
                              emoji: data['emoji'] ?? '🌱',
                              name: data['name'] ?? '',
                              streak: streakText,
                              done: data['done'] ?? false,
                              isDark: isDark,
                              docId: doc.id,
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Nature background ──
class _NatureBackground extends StatelessWidget {
  final bool isDark;
  const _NatureBackground({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(
        painter: _NaturePainter(isDark: isDark),
      ),
    );
  }
}

class _NaturePainter extends CustomPainter {
  final bool isDark;
  _NaturePainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final pebblePaint = Paint()
      ..color = isDark
          ? const Color(0xFF2A4028).withOpacity(0.8)
          : const Color(0xFFC8D9B8).withOpacity(0.5)
      ..style = PaintingStyle.fill;

    // Draw pebbles
    _drawPebble(canvas, pebblePaint, 18, 60, 9, 6, -0.35);
    _drawPebble(canvas, pebblePaint, size.width - 30, 40, 7, 5, 0.26);
    _drawPebble(canvas, pebblePaint, size.width - 15, 130, 8, 5.5, -0.17);
    _drawPebble(canvas, pebblePaint, 12, 200, 10, 6.5, 0.44);
    _drawPebble(canvas, pebblePaint, size.width - 25, 310, 7, 4.5, -0.26);
    _drawPebble(canvas, pebblePaint, 22, 370, 8, 5, 0.17);
    _drawPebble(canvas, pebblePaint, size.width - 40, 420, 9, 6, -0.44);

    // Draw grass blades
    final grassPaint = Paint()
      ..color = isDark
          ? const Color(0xFF4A7040).withOpacity(0.6)
          : const Color(0xFF90B878).withOpacity(0.5)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    _drawGrassBlade(canvas, grassPaint, size.width - 22, 20);
    _drawGrassBlade(canvas, grassPaint, size.width - 17, 22);
    _drawGrassBlade(canvas, grassPaint, size.width - 27, 24);
    _drawGrassBlade(canvas, grassPaint, 8, size.height - 40);
    _drawGrassBlade(canvas, grassPaint, 13, size.height - 38);
  }

  void _drawPebble(Canvas canvas, Paint paint, double cx, double cy,
      double rx, double ry, double angle) {
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(angle);
    canvas.drawOval(Rect.fromCenter(
        center: Offset.zero, width: rx * 2, height: ry * 2), paint);
    canvas.restore();
  }

  void _drawGrassBlade(Canvas canvas, Paint paint, double x, double y) {
    final path = Path();
    path.moveTo(x, y);
    path.quadraticBezierTo(x + 4, y - 12, x + 8, y - 2);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_NaturePainter old) => old.isDark != isDark;
}

// ── Greeting card ──
class _GreetingCard extends StatelessWidget {
  final bool isDark;
  final String userName;
  final int incompleteCount;
  final int totalCount;
  final String dateLabel;

  const _GreetingCard({
    required this.isDark,
    required this.userName,
    required this.incompleteCount,
    required this.totalCount,
    required this.dateLabel,
  });

  String get _habitSubtitle {
    if (totalCount == 0) return 'No habits yet — tap + to get started';
    if (incompleteCount == 0) return 'All habits done for today! 🎉';
    return '$incompleteCount habit${incompleteCount == 1 ? '' : 's'} to complete today';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
            '${_getGreeting()},$userName 🌿',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.darkText : AppTheme.moss,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _habitSubtitle,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppTheme.darkTextMid : AppTheme.textMid,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF3A5830).withOpacity(0.4)
                  : const Color(0xFF78AA5A).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              dateLabel,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppTheme.sageLight : AppTheme.moss,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Streak row ──
class _StreakRow extends StatelessWidget {
  final bool isDark;
  final int longestStreak;
  final int completedCount;
  final int totalCount;
  final int completionPct;

  const _StreakRow({
    required this.isDark,
    required this.longestStreak,
    required this.completedCount,
    required this.totalCount,
    required this.completionPct,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StreakCard(
          emoji: '🔥',
          value: '$longestStreak',
          label: 'streak',
          isDark: isDark,
        ),
        const SizedBox(width: 8),
        _StreakCard(
          emoji: '✅',
          value: '$completedCount/$totalCount',
          label: 'today',
          isDark: isDark,
        ),
        const SizedBox(width: 8),
        _StreakCard(
          emoji: '🌱',
          value: '$completionPct%',
          label: 'done',
          isDark: isDark,
        ),
      ],
    );
  }
}

class _StreakCard extends StatelessWidget {
  final String emoji, value, label;
  final bool isDark;
  const _StreakCard(
      {required this.emoji,
      required this.value,
      required this.label,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E301E).withOpacity(0.65)
              : Colors.white.withOpacity(0.65),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? const Color(0xFF3A6040).withOpacity(0.25)
                : const Color(0xFFAACC90).withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.darkText : AppTheme.moss,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? AppTheme.darkTextMid : AppTheme.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section label ──
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

// ── Habit item ──
class _HabitItem extends StatelessWidget {
  final String emoji, name, streak, docId;
  final bool done, isDark;
  const _HabitItem({
    required this.emoji,
    required this.name,
    required this.streak,
    required this.done,
    required this.isDark,
    required this.docId,
  });

  Future<void> _toggleDone(BuildContext context) async {
  try {
    final now = DateTime.now();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final docRef = FirebaseFirestore.instance
        .collection('habits')
        .doc(docId);

    final doc = await docRef.get();
    final data = doc.data() as Map<String, dynamic>;
    final currentDone = data['done'] ?? false;
    int currentStreak = data['streak'] ?? 0;

    if (!currentDone) {
      // Mark as done — update streak
      final lastCompleted = data['lastCompleted'] as String?;

      if (lastCompleted == null) {
        currentStreak = 1;
      } else {
        try {
          final last = DateTime.parse(lastCompleted);
          final difference = now.difference(last).inDays;
          if (difference == 1) {
            currentStreak += 1;
          } else if (difference == 0) {
            // Same day — keep current streak or set to 1
            if (currentStreak == 0) currentStreak = 1;
          } else {
            currentStreak = 1;
          }
        } catch (e) {
          currentStreak = 1;
        }
      }

      await docRef.update({
        'done': true,
        'streak': currentStreak,
        'lastCompleted': today,
      });
    } else {
      // Unmark as done
      if (currentStreak > 0) currentStreak -= 1;
      await docRef.update({
        'done': false,
        'streak': currentStreak,
      });
    }
  } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating habit: $e')),
      );
    }
  }

  Future<void> _showDeleteDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E301E)
            : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Delete habit?',
          style: TextStyle(
            color: isDark ? AppTheme.darkText : AppTheme.textDark,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "$name"? This cannot be undone.',
          style: TextStyle(
            color: isDark ? AppTheme.darkTextMid : AppTheme.textMid,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.sage),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection('habits')
          .doc(docId)
          .delete();
    }
  }
  @override
  Widget build(BuildContext context) {

    return GestureDetector(
      onLongPress: () => _showDeleteDialog(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E301E).withOpacity(0.65)
              : Colors.white.withOpacity(0.60),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? const Color(0xFF3A6040).withOpacity(0.18)
                : const Color(0xFFAACC90).withOpacity(0.25),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF3A5830).withOpacity(0.5)
                    : const Color(0xFF98C88C).withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppTheme.darkText : AppTheme.textDark,
                      decoration: done ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    streak,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppTheme.darkTextMid : AppTheme.textLight,
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
            onTap: () => _toggleDone(context),
            borderRadius: BorderRadius.circular(13),
            child: Container(
              width: 26,
              height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? AppTheme.sage : Colors.transparent,
                  border: done
                      ? null
                      : Border.all(
                          color: isDark
                              ? const Color(0xFF3A6040)
                              : AppTheme.sageLight,
                          width: 1.5,
                        ),
                ),
                child: done
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}