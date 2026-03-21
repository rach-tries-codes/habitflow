import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/theme.dart';
import '../services/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;
    final authService = AuthService();

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _ProfileBgPainter(isDark: isDark),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Profile picture
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF4A7040).withOpacity(0.4)
                            : AppTheme.sageLight.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: user?.photoURL != null
                          ? Image.network(user!.photoURL!)
                          : Container(
                              color: AppTheme.sage.withOpacity(0.2),
                              child: const Center(
                                child: Text('🌱',
                                    style: TextStyle(fontSize: 40)),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Name
                  Text(
                    user?.displayName ?? 'HabitFlow User',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppTheme.darkText : AppTheme.moss,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Email
                  Text(
                    user?.email ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppTheme.darkTextMid : AppTheme.textMid,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Stats card
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
                          'MY ACCOUNT',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.9,
                            color: isDark
                                ? AppTheme.darkTextMid
                                : AppTheme.textLight,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _ProfileItem(
                          icon: '🌱',
                          label: 'Member since',
                          value: user?.metadata.creationTime != null
                              ? '${user!.metadata.creationTime!.day}/${user.metadata.creationTime!.month}/${user.metadata.creationTime!.year}'
                              : 'Today',
                          isDark: isDark,
                        ),
                        _ProfileItem(
                          icon: '📧',
                          label: 'Email',
                          value: user?.email ?? '',
                          isDark: isDark,
                        ),
                        _ProfileItem(
                          icon: '🔒',
                          label: 'Account type',
                          value: 'Google',
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Premium card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.sage.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: AppTheme.sage.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text('✨', style: TextStyle(fontSize: 32)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Upgrade to Premium',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppTheme.darkText
                                      : AppTheme.moss,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Unlock AI insights, unlimited habits and more',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppTheme.darkTextMid
                                      : AppTheme.textMid,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Legal links
                  const SizedBox(height: 16),
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
                          'LEGAL',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.9,
                            color: isDark ? AppTheme.darkTextMid : AppTheme.textLight,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _LegalLink(
                          icon: '🔒',
                          label: 'Privacy Policy',
                          url: 'https://doc-hosting.flycricket.io/habitflow-privacy-policy/c7a185ad-1ddf-4427-8601-e2110fbd6be4/privacy',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 8),
                        _LegalLink(
                          icon: '📋',
                          label: 'Terms of Use',
                          url: 'https://doc-hosting.flycricket.io/habitflow-terms-of-use/7946cd7c-c7f2-4c86-97cd-32280c0432ce/terms',
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Sign out button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await authService.signOut();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.1),
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: Colors.red.withOpacity(0.3),
                          ),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Sign Out',
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

class _ProfileItem extends StatelessWidget {
  final String icon, label, value;
  final bool isDark;
  const _ProfileItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppTheme.darkTextMid : AppTheme.textLight,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppTheme.darkText : AppTheme.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileBgPainter extends CustomPainter {
  final bool isDark;
  _ProfileBgPainter({required this.isDark});

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
  bool shouldRepaint(_ProfileBgPainter old) => old.isDark != isDark;


}

class _LegalLink extends StatelessWidget {
  final String icon, label, url;
  final bool isDark;
  const _LegalLink({
    required this.icon,
    required this.label,
    required this.url,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? AppTheme.darkText : AppTheme.textDark,
            ),
          ),
          const Spacer(),
          Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: isDark ? AppTheme.darkTextMid : AppTheme.textLight,
          ),
        ],
      ),
    );
  }
}