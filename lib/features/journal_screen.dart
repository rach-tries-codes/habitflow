import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/theme.dart';
import '../services/gemini_service.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final _entryController = TextEditingController();
  String _selectedMood = '😊';
  bool _isSaving = false;
  String _aiPrompt = 'Loading your personalised prompt...';
  final GeminiService _geminiService = GeminiService();

  final List<Map<String, String>> _moods = [
    {'emoji': '😔', 'label': 'Low'},
    {'emoji': '😐', 'label': 'Okay'},
    {'emoji': '😊', 'label': 'Good'},
    {'emoji': '🤩', 'label': 'Great'},
  ];

  @override
  void initState() {
    super.initState();
    _loadAiPrompt();
  }

  String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadAiPrompt() async {
    final user = FirebaseAuth.instance.currentUser;
    final snapshot = await FirebaseFirestore.instance
        .collection('habits')
        .where('userId', isEqualTo: user?.uid)
        .get();

    final habitNames = snapshot.docs
        .map((doc) => doc.data()['name'] as String)
        .toList();

    if (habitNames.isEmpty) {
      setState(() => _aiPrompt = 'What are you grateful for today?');
      return;
    }

    final prompt = await _geminiService.generateJournalPrompt(habitNames);
    setState(() => _aiPrompt = prompt);
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
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance
          .collection('journal')
          .doc('${user?.uid}_$_todayKey')
          .set({
        'entry': _entryController.text.trim(),
        'mood': _selectedMood,
        'date': _todayKey,
        'userId': user?.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Journal saved! 🌿'),
            backgroundColor: AppTheme.sage,
          ),
        );
        _entryController.clear();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving: $e')),
      );
    }

    setState(() => _isSaving = false);
  }

  Future<void> _showEditDialog(
      BuildContext context, String docId, String currentEntry, String currentMood) async {
    final editController = TextEditingController(text: currentEntry);
    String editMood = currentMood;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return AlertDialog(
            backgroundColor:
                isDark ? const Color(0xFF1E301E) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Edit Entry',
              style: TextStyle(
                color: isDark ? AppTheme.darkText : AppTheme.moss,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Mood selector in dialog
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _moods.map((mood) {
                      final isSelected = mood['emoji'] == editMood;
                      return InkWell(
                        onTap: () =>
                            setDialogState(() => editMood = mood['emoji']!),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.sage.withOpacity(0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.sage
                                  : Colors.transparent,
                            ),
                          ),
                          child: Text(mood['emoji']!,
                              style: const TextStyle(fontSize: 24)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  // Edit text field
                  TextField(
                    controller: editController,
                    maxLines: 6,
                    style: TextStyle(
                      color: isDark ? AppTheme.darkText : AppTheme.textDark,
                      fontSize: 14,
                      height: 1.6,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Edit your entry...',
                      hintStyle: TextStyle(
                        color: isDark
                            ? AppTheme.darkTextMid
                            : AppTheme.textLight,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppTheme.sage.withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.sage),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel',
                    style: TextStyle(color: AppTheme.textLight)),
              ),
              TextButton(
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('journal')
                      .doc(docId)
                      .update({
                    'entry': editController.text.trim(),
                    'mood': editMood,
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
                  if (context.mounted) Navigator.pop(context);
                },
                child: Text('Save',
                    style: TextStyle(
                        color: AppTheme.sage, fontWeight: FontWeight.w600)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteEntry(String docId) async {
    await FirebaseFirestore.instance.collection('journal').doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;

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
                        child: InkWell(
                          onTap: () => setState(
                              () => _selectedMood = mood['emoji']!),
                          borderRadius: BorderRadius.circular(14),
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

                  // AI Prompt
                  Container(
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
                                'AI PROMPT · PREMIUM',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.9,
                                  color: AppTheme.sage,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _aiPrompt,
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
                  const SizedBox(height: 16),

                  // New entry text field
                  _SectionLabel("Write Today's Entry", isDark: isDark),
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
                      maxLines: 5,
                      style: TextStyle(
                        color:
                            isDark ? AppTheme.darkText : AppTheme.textDark,
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
                          ? const CircularProgressIndicator(
                              color: Colors.white)
                          : const Text(
                              'Save Journal 🌿',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Today's entry
                  _SectionLabel("Today's Entry", isDark: isDark),
                  const SizedBox(height: 8),
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('journal')
                        .doc('${user?.uid}_$_todayKey')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return Container(
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
                          child: Center(
                            child: Text(
                              'No entry yet today 🌱',
                              style: TextStyle(
                                color: isDark
                                    ? AppTheme.darkTextMid
                                    : AppTheme.textLight,
                              ),
                            ),
                          ),
                        );
                      }

                      final data =
                          snapshot.data!.data() as Map<String, dynamic>;
                      return _EntryCard(
                        docId: snapshot.data!.id,
                        entry: data['entry'] ?? '',
                        mood: data['mood'] ?? '😊',
                        date: 'Today',
                        isDark: isDark,
                        onEdit: () => _showEditDialog(
                          context,
                          snapshot.data!.id,
                          data['entry'] ?? '',
                          data['mood'] ?? '😊',
                        ),
                        onDelete: () => _deleteEntry(snapshot.data!.id),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Previous entries
                  _SectionLabel('Previous Entries', isDark: isDark),
                  const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('journal')
                        .where('userId', isEqualTo: user?.uid)
                        .orderBy('createdAt', descending: true)
                        .limit(10)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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

                      // Filter out today's entry
                      final pastDocs = snapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return data['date'] != _todayKey;
                      }).toList();

                      if (pastDocs.isEmpty) {
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
                        children: pastDocs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return _EntryCard(
                            docId: doc.id,
                            entry: data['entry'] ?? '',
                            mood: data['mood'] ?? '😊',
                            date: data['date'] ?? '',
                            isDark: isDark,
                            onEdit: () => _showEditDialog(
                              context,
                              doc.id,
                              data['entry'] ?? '',
                              data['mood'] ?? '😊',
                            ),
                            onDelete: () => _deleteEntry(doc.id),
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

// Entry card widget
class _EntryCard extends StatelessWidget {
  final String docId, entry, mood, date;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EntryCard({
    required this.docId,
    required this.entry,
    required this.mood,
    required this.date,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(mood, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                date,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppTheme.darkTextMid : AppTheme.textLight,
                ),
              ),
              const Spacer(),
              // Edit button
              InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.sage.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Edit',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.sage,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Delete button
              InkWell(
                onTap: () => _confirmDelete(context),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Delete',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            entry,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppTheme.darkText : AppTheme.textDark,
              height: 1.6,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E301E) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Delete entry?',
          style: TextStyle(
            color: isDark ? AppTheme.darkText : AppTheme.textDark,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'This cannot be undone.',
          style: TextStyle(
            color: isDark ? AppTheme.darkTextMid : AppTheme.textMid,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: TextStyle(color: AppTheme.textLight)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) onDelete();
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