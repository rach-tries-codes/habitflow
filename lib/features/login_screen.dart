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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isSignUp = false;
  bool _obscurePassword = true;
  String _errorMessage = '';

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final user = await _authService.signInWithGoogle();
      if (mounted && user == null) {
        setState(() => _errorMessage = 'Google sign in cancelled');
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _handleEmailAuth() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (_isSignUp) {
        final credential = await _authService.signUpWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (mounted && credential != null) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF1E301E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                'Verify your email 📧',
                style: TextStyle(color: AppTheme.darkText),
              ),
              content: Text(
                'We sent a verification email to ${_emailController.text.trim()}. Please verify before signing in!',
                style: TextStyle(color: AppTheme.darkTextMid),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() => _isSignUp = false);
                  },
                  child: Text('Got it!',
                      style: TextStyle(color: AppTheme.sage)),
                ),
              ],
            ),
          );
        }
      } else {
        await _authService.signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        String msg = e.toString();
        if (msg.contains('user-not-found')) {
          msg = 'No account found with this email';
        } else if (msg.contains('wrong-password')) {
          msg = 'Incorrect password';
        } else if (msg.contains('email-already-in-use')) {
          msg = 'An account already exists with this email';
        } else if (msg.contains('weak-password')) {
          msg = 'Password must be at least 6 characters';
        } else if (msg.contains('invalid-email')) {
          msg = 'Please enter a valid email address';
        } else {
          msg = 'Something went wrong. Please try again';
        }
        setState(() => _errorMessage = msg);
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _handleForgotPassword() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Enter your email first');
      return;
    }
    try {
      await _authService.resetPassword(_emailController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Password reset email sent! 📧'),
            backgroundColor: AppTheme.sage,
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _LoginBgPainter(isDark: isDark),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  // App icon
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
                  const SizedBox(height: 16),
                  Text(
                    'HabitFlow',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppTheme.darkText : AppTheme.moss,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Build habits. Track growth.\nLive intentionally.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: isDark
                          ? AppTheme.darkTextMid
                          : AppTheme.textMid,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Toggle sign in / sign up
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E301E).withOpacity(0.65)
                          : Colors.white.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF3A6040).withOpacity(0.25)
                            : AppTheme.sageLight.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () =>
                                setState(() => _isSignUp = false),
                            borderRadius: const BorderRadius.horizontal(
                                left: Radius.circular(14)),
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !_isSignUp
                                    ? AppTheme.sage.withOpacity(0.2)
                                    : Colors.transparent,
                                borderRadius: const BorderRadius.horizontal(
                                    left: Radius.circular(14)),
                                border: !_isSignUp
                                    ? Border.all(color: AppTheme.sage)
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: !_isSignUp
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: isDark
                                        ? AppTheme.darkText
                                        : AppTheme.moss,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () =>
                                setState(() => _isSignUp = true),
                            borderRadius: const BorderRadius.horizontal(
                                right: Radius.circular(14)),
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _isSignUp
                                    ? AppTheme.sage.withOpacity(0.2)
                                    : Colors.transparent,
                                borderRadius: const BorderRadius.horizontal(
                                    right: Radius.circular(14)),
                                border: _isSignUp
                                    ? Border.all(color: AppTheme.sage)
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: _isSignUp
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: isDark
                                        ? AppTheme.darkText
                                        : AppTheme.moss,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Email field
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E301E).withOpacity(0.65)
                          : Colors.white.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF3A6040).withOpacity(0.25)
                            : AppTheme.sageLight.withOpacity(0.3),
                      ),
                    ),
                    child: TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(
                        color:
                            isDark ? AppTheme.darkText : AppTheme.textDark,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Email address',
                        hintStyle: TextStyle(
                          color: isDark
                              ? AppTheme.darkTextMid
                              : AppTheme.textLight,
                        ),
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: isDark
                              ? AppTheme.darkTextMid
                              : AppTheme.textLight,
                        ),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Password field
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E301E).withOpacity(0.65)
                          : Colors.white.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF3A6040).withOpacity(0.25)
                            : AppTheme.sageLight.withOpacity(0.3),
                      ),
                    ),
                    child: TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: TextStyle(
                        color:
                            isDark ? AppTheme.darkText : AppTheme.textDark,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Password',
                        hintStyle: TextStyle(
                          color: isDark
                              ? AppTheme.darkTextMid
                              : AppTheme.textLight,
                        ),
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: isDark
                              ? AppTheme.darkTextMid
                              : AppTheme.textLight,
                        ),
                        suffixIcon: InkWell(
                          onTap: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                          child: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: isDark
                                ? AppTheme.darkTextMid
                                : AppTheme.textLight,
                          ),
                        ),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),

                  // Forgot password
                  if (!_isSignUp) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: InkWell(
                        onTap: _handleForgotPassword,
                        child: Text(
                          'Forgot password?',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.sage,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],

                  // Error message
                  if (_errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(
                            color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Email auth button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleEmailAuth,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.sage,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white)
                          : Text(
                              _isSignUp ? 'Create Account 🌱' : 'Sign In 🌿',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Divider
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: isDark
                              ? const Color(0xFF3A6040).withOpacity(0.3)
                              : AppTheme.sageLight.withOpacity(0.4),
                        ),
                      ),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'or',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppTheme.darkTextMid
                                : AppTheme.textLight,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: isDark
                              ? const Color(0xFF3A6040).withOpacity(0.3)
                              : AppTheme.sageLight.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Google sign in
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleGoogleSignIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? const Color(0xFF1E301E)
                            : Colors.white,
                        foregroundColor: isDark
                            ? AppTheme.darkText
                            : AppTheme.textDark,
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
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
                      child: Row(
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
                      color: isDark
                          ? AppTheme.darkTextMid
                          : AppTheme.textLight,
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
        Rect.fromCenter(
            center: Offset.zero, width: rx * 2, height: ry * 2),
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