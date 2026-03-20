import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddHabitScreen extends StatefulWidget {
  const AddHabitScreen({super.key});

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  final _nameController = TextEditingController();
  String _selectedEmoji = '🌱';
  String _selectedFrequency = 'Daily';

  final List<String> _emojis = [
    '🌱', '🧘', '📚', '💧', '🏃', '✍️',
    '🎯', '💪', '🍎', '😴', '🎨', '🎵',
  ];

  final List<String> _frequencies = ['Daily', 'Weekly'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'New Habit',
          style: TextStyle(
            color: isDark ? AppTheme.darkText : AppTheme.moss,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: isDark
            ? const Color(0xFF182818)
            : AppTheme.cream,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDark ? AppTheme.darkText : AppTheme.moss,
        ),
      ),
      
      body: Stack(
        children: [
          // Same nature background
          Positioned.fill(
            child: CustomPaint(
              painter: _BgPainter(isDark: isDark),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Habit name input
                _SectionLabel('Habit Name', isDark: isDark),
                const SizedBox(height: 8),
                _InputCard(
                  isDark: isDark,
                  child: TextField(
                    controller: _nameController,
                    style: TextStyle(
                      color: isDark ? AppTheme.darkText : AppTheme.textDark,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. Morning meditation',
                      hintStyle: TextStyle(
                        color: isDark
                            ? AppTheme.darkTextMid
                            : AppTheme.textLight,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Emoji picker
                _SectionLabel('Choose Icon', isDark: isDark),
                const SizedBox(height: 8),
                _InputCard(
                  isDark: isDark,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _emojis.map((emoji) {
                      final isSelected = emoji == _selectedEmoji;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedEmoji = emoji),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.sage.withOpacity(0.25)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.sage
                                  : Colors.transparent,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 22),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),

                // Frequency selector
                _SectionLabel('Frequency', isDark: isDark),
                const SizedBox(height: 8),
                Row(
                  children: _frequencies.map((freq) {
                    final isSelected = freq == _selectedFrequency;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _selectedFrequency = freq),
                        child: Container(
                          margin: EdgeInsets.only(
                            right: freq == 'Daily' ? 8 : 0,
                          ),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.sage.withOpacity(0.2)
                                : isDark
                                    ? const Color(0xFF1E301E)
                                        .withOpacity(0.65)
                                    : Colors.white.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.sage
                                  : isDark
                                      ? const Color(0xFF3A6040)
                                          .withOpacity(0.25)
                                      : AppTheme.sageLight
                                          .withOpacity(0.3),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              freq,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isSelected
                                    ? AppTheme.moss
                                    : isDark
                                        ? AppTheme.darkTextMid
                                        : AppTheme.textMid,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveHabit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.sage,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Save Habit 🌱',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveHabit() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a habit name!')),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('habits').add({
        'name': _nameController.text.trim(),
        'emoji': _selectedEmoji,
        'frequency': _selectedFrequency,
        'createdAt': FieldValue.serverTimestamp(),
        'streak': 0,
        'userId': user?.uid,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$_selectedEmoji ${_nameController.text} saved!'),
            backgroundColor: AppTheme.sage,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving habit: $e')),
      );
    }
  }
}

// ── Helpers ──
class _SectionLabel extends StatelessWidget {
  final String text;
  final bool isDark;
  const _SectionLabel(this.text, {required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.9,
        color: isDark ? AppTheme.darkTextMid : AppTheme.textLight,
      ),
    );
  }
}

class _InputCard extends StatelessWidget {
  final Widget child;
  final bool isDark;
  const _InputCard({required this.child, required this.isDark});

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
      child: child,
    );
  }
}

class _BgPainter extends CustomPainter {
  final bool isDark;
  _BgPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark
          ? const Color(0xFF2A4028).withOpacity(0.8)
          : const Color(0xFFC8D9B8).withOpacity(0.5)
      ..style = PaintingStyle.fill;

    _drawPebble(canvas, paint, 18, 60, 9, 6, -0.35);
    _drawPebble(canvas, paint, size.width - 30, 40, 7, 5, 0.26);
    _drawPebble(canvas, paint, size.width - 15, 130, 8, 5.5, -0.17);
    _drawPebble(canvas, paint, 12, 200, 10, 6.5, 0.44);

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
  bool shouldRepaint(_BgPainter old) => old.isDark != isDark;
}