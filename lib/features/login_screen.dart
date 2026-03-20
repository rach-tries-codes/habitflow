import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    final user = await _authService.signInWithGoogle();

    if (mounted) {
      setState(() => _isLoading = false);
      if (user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome ${user.displayName}! 🌿'),
            backgroundColor: AppTheme.sage,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in cancelled')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Nature background
          Positioned.fill(
            child: CustomPaint(
              painter: _LoginBgPainter(isDark: isDark),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Spacer(),
                  // App icon and name
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E301E).withOpacity(0.75)
                          : Colors.white.withOpacity(0.72),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF4A7040).withOpacity(0.25)
                            : const Color(0xFFB4D4A0).withOpacity(0.35),
                      ),
                    ),
                    child: const Center(
                      child: Text('🌱', style: TextStyle(fontSize: 48)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'HabitFlow',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppTheme.darkText : AppTheme.moss,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Build habits. Track growth.\nLive intentionally.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: isDark ? AppTheme.darkTextMid : AppTheme.textMid,
                    ),
                  ),
                  const Spacer(),
                  // Google sign in button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleGoogleSignIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? const Color(0xFF1E301E)
                            : Colors.white,
                        foregroundColor:
                            isDark ? AppTheme.darkText : AppTheme.textDark,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isDark
                                ? const Color(0xFF3A6040).withOpacity(0.4)
                                : AppTheme.sageLight.withOpacity(0.5),
                          ),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.network(
                                  'https://www.google.com/favicon.ico',
                                  width: 20,
                                  height: 20,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Continue with Google',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your data is private and secure 🔒',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppTheme.darkTextMid : AppTheme.textLight,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginBgPainter extends CustomPainter {
  final bool isDark;
  _LoginBgPainter({required this.isDark});

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
    _drawPebble(canvas, paint, size.width - 25, 310, 7, 4.5, -0.26);
    _drawPebble(canvas, paint, 22, size.height - 100, 8, 5, 0.17);

    final grassPaint = Paint()
      ..color = isDark
          ? const Color(0xFF4A7040).withOpacity(0.6)
          : const Color(0xFF90B878).withOpacity(0.5)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    _drawGrass(canvas, grassPaint, size.width - 22, 20);
    _drawGrass(canvas, grassPaint, size.width - 17, 22);
    _drawGrass(canvas, grassPaint, size.width - 27, 24);
    _drawGrass(canvas, grassPaint, 8, size.height - 40);
    _drawGrass(canvas, grassPaint, 13, size.height - 38);
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
  bool shouldRepaint(_LoginBgPainter old) => old.isDark != isDark;
}