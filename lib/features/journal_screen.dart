import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/theme.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final _entryController = TextEditingController();
  String _selectedMood = '😊';
  bool _isSaving = false;

  final List<Map<String, String>> _moods = [
    {'emoji': '😔', 'label': 'Low'},
    {'emoji': '😐', 'label': 'Okay'},
    {'emoji': '😊', 'label': 'Good'},
    {'emoji': '🤩', 'label': 'Great'},
  ];

  String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  Future<void> _saveEntry() async {
    if (_entryController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write something first!')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance
          .collection('journal')
          .doc(_todayKey)
          .set({
        'entry': _entryController.text.trim(),
        'mood': _selectedMood,
        'date': _todayKey,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Journal entry saved! 🌿'),
            backgroundColor: AppTheme.sage,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving: $e')),
      );
    }

    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _JournalBgPainter(isDark: isDark),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
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
                          'Daily Journal 📓',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppTheme.darkText : AppTheme.moss,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _todayKey,
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

                  // Mood selector
                  _SectionLabel('How are you feeling?', isDark: isDark),
                  const SizedBox(height: 8),
                  Row(
                    children: _moods.map((mood) {
                      final isSelected = mood['emoji'] == _selectedMood;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedMood = mood['emoji']!),
                          child: Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(vertical: 10),
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
                                        : AppTheme.sageLight.withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(mood['emoji']!,
                                    style: const TextStyle(fontSize: 22)),
                                const SizedBox(height: 4),
                                Text(
                                  mood['label']!,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDark
                                        ? AppTheme.darkTextMid
                                        : AppTheme.textLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Journal entry
                  _SectionLabel("Today's Entry", isDark: isDark),
                  const SizedBox(height: 8),
                  Container(
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
                    child: TextField(
                      controller: _entryController,
                      maxLines: 6,
                      style: TextStyle(
                        color: isDark ? AppTheme.darkText : AppTheme.textDark,
                        fontSize: 14,
                        height: 1.6,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            'How was your day? What are you grateful for?',
                        hintStyle: TextStyle(
                          color: isDark
                              ? AppTheme.darkTextMid
                              : AppTheme.textLight,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Past entries
                  _SectionLabel('Past Entries', isDark: isDark),
                  const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('journal')
                        .orderBy('createdAt', descending: true)
                        .limit(5)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData ||
                          snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Text(
                            'No past entries yet 🌱',
                            style: TextStyle(
                              color: isDark
                                  ? AppTheme.darkTextMid
                                  : AppTheme.textLight,
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: snapshot.data!.docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
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
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['mood'] ?? '😊',
                                  style: const TextStyle(fontSize: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['date'] ?? '',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark
                                              ? AppTheme.darkTextMid
                                              : AppTheme.textLight,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        data['entry'] ?? '',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDark
                                              ? AppTheme.darkText
                                              : AppTheme.textDark,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveEntry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.sage,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Save Entry 🌿',
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
          ),
        ],
      ),
    );
  }
}

// Section label
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

// Background painter
class _JournalBgPainter extends CustomPainter {
  final bool isDark;
  _JournalBgPainter({required this.isDark});

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
  bool shouldRepaint(_JournalBgPainter old) => old.isDark != isDark;
}