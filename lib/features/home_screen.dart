import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'add_habit_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  _GreetingCard(isDark: isDark),
                  const SizedBox(height: 12),
                  _StreakRow(isDark: isDark),
                  const SizedBox(height: 16),
                  _SectionLabel(label: "Today's Habits", isDark: isDark),
                  const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                      .collection('habits')
                      .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                      .orderBy('createdAt', descending: false)
                      .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
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
                                  color: isDark ? AppTheme.darkTextMid : AppTheme.textLight,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return Column(
                        children: snapshot.data!.docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return _HabitItem(
                              emoji: data['emoji'] ?? '🌱',
                              name: data['name'] ?? '',
                              streak: '${data['streak'] ?? 0} days',
                              done: data['done'] ?? false,
                              isDark: isDark,
                              docId: doc.id,
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
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
  const _GreetingCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            'Good morning,\nRachita 🌿',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.darkText : AppTheme.moss,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '3 habits to complete today',
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
              '🗓 Friday, Mar 20',
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
  const _StreakRow({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StreakCard(emoji: '🔥', value: '12', label: 'streak', isDark: isDark),
        const SizedBox(width: 8),
        _StreakCard(emoji: '✅', value: '2/3', label: 'today', isDark: isDark),
        const SizedBox(width: 8),
        _StreakCard(emoji: '🌱', value: '87%', label: 'week', isDark: isDark),
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
    await FirebaseFirestore.instance
        .collection('habits')
        .doc(docId)
        .update({'done': !done});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
          GestureDetector(
            onTap: () => _toggleDone(context),
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
    );
  }
}