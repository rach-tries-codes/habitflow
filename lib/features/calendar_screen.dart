import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/theme.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDay;
  Map<String, dynamic> _dayData = {}; // key: 'yyyy-MM-dd', value: {completed, total, mood}
  bool _isLoading = true;

  // Selected day details
  List<Map<String, dynamic>> _selectedDayHabits = [];
  String _selectedDayMood = '';
  bool _isLoadingDetails = false;

  @override
  void initState() {
    super.initState();
    _loadMonthData();
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadMonthData() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;

    // Load journal entries for mood dots
    final journalSnapshot = await FirebaseFirestore.instance
        .collection('journal')
        .where('userId', isEqualTo: user?.uid)
        .get();

    Map<String, dynamic> dayData = {};

    for (final doc in journalSnapshot.docs) {
      final data = doc.data();
      final date = data['date'] as String?;
      if (date != null) {
        dayData[date] = {
          'mood': data['mood'] ?? '',
          'hasEntry': true,
        };
      }
    }

    // Load habit completion history
    final habitsSnapshot = await FirebaseFirestore.instance
        .collection('habits')
        .where('userId', isEqualTo: user?.uid)
        .get();

    // Check which days have completed habits using lastCompleted
    for (final doc in habitsSnapshot.docs) {
      final data = doc.data();
      final lastCompleted = data['lastCompleted'] as String?;
      if (lastCompleted != null) {
        if (dayData[lastCompleted] == null) {
          dayData[lastCompleted] = {};
        }
        dayData[lastCompleted]['hasCompletedHabit'] = true;
      }
    }

    setState(() {
      _dayData = dayData;
      _isLoading = false;
    });
  }

  Future<void> _loadDayDetails(DateTime day) async {
    setState(() {
      _isLoadingDetails = true;
      _selectedDayHabits = [];
      _selectedDayMood = '';
    });

    final user = FirebaseAuth.instance.currentUser;
    final dateKey = _dateKey(day);

    // Load journal entry for this day
    final journalDoc = await FirebaseFirestore.instance
        .collection('journal')
        .doc('${user?.uid}_$dateKey')
        .get();

    if (journalDoc.exists) {
      setState(() {
        _selectedDayMood = journalDoc.data()?['mood'] ?? '';
      });
    }

    // Load habits completed on this day
    final habitsSnapshot = await FirebaseFirestore.instance
        .collection('habits')
        .where('userId', isEqualTo: user?.uid)
        .get();

    List<Map<String, dynamic>> completedHabits = [];
    for (final doc in habitsSnapshot.docs) {
      final data = doc.data();
      final lastCompleted = data['lastCompleted'] as String?;
      if (lastCompleted == dateKey) {
        completedHabits.add({
          'name': data['name'] ?? '',
          'emoji': data['emoji'] ?? '🌱',
          'streak': data['streak'] ?? 0,
        });
      }
    }

    setState(() {
      _selectedDayHabits = completedHabits;
      _isLoadingDetails = false;
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
              painter: _CalendarBgPainter(isDark: isDark),
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
                          'Habit Calendar 🗓',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppTheme.darkText : AppTheme.moss,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Track your daily progress',
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

                  // Calendar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E301E).withOpacity(0.65)
                          : Colors.white.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF3A6040).withOpacity(0.25)
                            : AppTheme.sageLight.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Month navigation
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _focusedMonth = DateTime(
                                    _focusedMonth.year,
                                    _focusedMonth.month - 1,
                                  );
                                });
                                _loadMonthData();
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Icon(
                                  Icons.chevron_left,
                                  color: isDark
                                      ? AppTheme.darkText
                                      : AppTheme.moss,
                                ),
                              ),
                            ),
                            Text(
                              _monthName(_focusedMonth),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppTheme.darkText
                                    : AppTheme.moss,
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _focusedMonth = DateTime(
                                    _focusedMonth.year,
                                    _focusedMonth.month + 1,
                                  );
                                });
                                _loadMonthData();
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Icon(
                                  Icons.chevron_right,
                                  color: isDark
                                      ? AppTheme.darkText
                                      : AppTheme.moss,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Day labels
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                              .map((d) => SizedBox(
                                    width: 36,
                                    child: Center(
                                      child: Text(
                                        d,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? AppTheme.darkTextMid
                                              : AppTheme.textLight,
                                        ),
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 8),

                        // Calendar grid
                        _isLoading
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : _buildCalendarGrid(isDark),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Legend
                  Row(
                    children: [
                      _LegendItem(
                          color: AppTheme.sage, label: 'Habits done'),
                      const SizedBox(width: 16),
                      _LegendItem(
                          color: AppTheme.sageLight, label: 'Journal entry'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Selected day details
                  if (_selectedDay != null) ...[
                    _SectionLabel(
                      label:
                          'Details — ${_dateKey(_selectedDay!)}',
                      isDark: isDark,
                    ),
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
                      child: _isLoadingDetails
                          ? const Center(child: CircularProgressIndicator())
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Mood
                                if (_selectedDayMood.isNotEmpty) ...[
                                  Row(
                                    children: [
                                      Text(
                                        _selectedDayMood,
                                        style:
                                            const TextStyle(fontSize: 28),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Mood for the day',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDark
                                              ? AppTheme.darkTextMid
                                              : AppTheme.textMid,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                ],

                                // Habits
                                if (_selectedDayHabits.isEmpty)
                                  Text(
                                    _selectedDayMood.isEmpty
                                        ? 'No activity on this day 🌱'
                                        : 'No habits completed this day',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark
                                          ? AppTheme.darkTextMid
                                          : AppTheme.textLight,
                                    ),
                                  )
                                else ...[
                                  Text(
                                    'Habits completed:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? AppTheme.darkTextMid
                                          : AppTheme.textLight,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ..._selectedDayHabits.map(
                                    (habit) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 6),
                                      child: Row(
                                        children: [
                                          Text(
                                            habit['emoji'] as String,
                                            style: const TextStyle(
                                                fontSize: 18),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            habit['name'] as String,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: isDark
                                                  ? AppTheme.darkText
                                                  : AppTheme.textDark,
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            '🔥 ${habit['streak']} days',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isDark
                                                  ? AppTheme.darkTextMid
                                                  : AppTheme.textLight,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
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

  Widget _buildCalendarGrid(bool isDark) {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    // Monday = 1, so offset = weekday - 1
    final startOffset = firstDay.weekday - 1;

    List<Widget> cells = [];

    // Empty cells before first day
    for (int i = 0; i < startOffset; i++) {
      cells.add(const SizedBox(width: 36, height: 44));
    }

    // Day cells
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
      final dateKey = _dateKey(date);
      final isToday = dateKey == _dateKey(DateTime.now());
      final isSelected = _selectedDay != null &&
          _dateKey(_selectedDay!) == dateKey;
      final hasHabit = _dayData[dateKey]?['hasCompletedHabit'] == true;
      final hasMood = (_dayData[dateKey]?['mood'] ?? '').isNotEmpty;
      final mood = _dayData[dateKey]?['mood'] as String? ?? '';

      cells.add(
        InkWell(
          onTap: () {
            setState(() => _selectedDay = date);
            _loadDayDetails(date);
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 36,
            height: 44,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.sage.withOpacity(0.3)
                  : isToday
                      ? AppTheme.sage.withOpacity(0.15)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isToday || isSelected
                  ? Border.all(
                      color: AppTheme.sage,
                      width: isSelected ? 1.5 : 1,
                    )
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isToday || isSelected
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: isSelected || isToday
                        ? (isDark ? AppTheme.darkText : AppTheme.moss)
                        : (isDark
                            ? AppTheme.darkTextMid
                            : AppTheme.textDark),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (hasHabit)
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppTheme.sage,
                          shape: BoxShape.circle,
                        ),
                      ),
                    if (hasHabit && hasMood)
                      const SizedBox(width: 2),
                    if (hasMood)
                      Text(
                        mood,
                        style: const TextStyle(fontSize: 7),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 3,
      runSpacing: 4,
      children: cells,
    );
  }

  String _monthName(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

// Legend item
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.darkTextMid
                : AppTheme.textLight,
          ),
        ),
      ],
    );
  }
}

// Section label
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

// Background painter
class _CalendarBgPainter extends CustomPainter {
  final bool isDark;
  _CalendarBgPainter({required this.isDark});

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
  bool shouldRepaint(_CalendarBgPainter old) => old.isDark != isDark;
}