import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/social_sign_in_button.dart';
import '../../widgets/app_logo.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  String? _errorMessage;
  bool _isLoading = false;

  late final AnimationController _fadeController;
  late final AnimationController _slideController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    Future.delayed(const Duration(milliseconds: 100), () {
      _fadeController.forward();
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailLogin() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });
    try {
      final user = await _authService.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (user == null) {
        setState(() => _errorMessage = 'Email hoặc mật khẩu không chính xác.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      });
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });
    try {
      final user = await _authService.signInWithGoogle();
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (user == null) {
        setState(() => _errorMessage = 'Đăng nhập Google thất bại hoặc bị huỷ.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: isWide ? _buildWideLayout() : _buildNarrowLayout(),
    );
  }

  // ─── Wide layout (tablet / web) ──────────────────────────────────────────
  Widget _buildWideLayout() {
    return Row(
      children: [
        const Expanded(
          flex: 5,
          child: _HeroPanel(),
        ),
        Expanded(
          flex: 4,
          child: Container(
            color: const Color(0xFF111111),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 40,
                ),
                child: _buildWideFormContent(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Narrow layout (phone) ────────────────────────────────────────────────
  Widget _buildNarrowLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalHeight = constraints.maxHeight;
        final heroHeight = totalHeight * 0.22;
        final formTop = totalHeight * 0.16;

        return Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: heroHeight,
              child: const _HeroPanel(showTagline: false),
            ),
            Positioned(
              top: formTop,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF111111),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 24, 28, 16),
                  child: _buildNarrowFormContent(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ─── Narrow form ─────────────────────────────────────────────────────────
  Widget _buildNarrowFormContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppLogoLockup(iconSize: 40, fontSize: 18),
            const SizedBox(height: 20),

            const Text(
              'Chào mừng trở lại',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontFamily: 'Georgia',
                fontWeight: FontWeight.w700,
                height: 1.2,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Đăng nhập để trải nghiệm ứng dụng trọn vẹn',
              style: TextStyle(
                color: Colors.white.withOpacity(0.45),
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 20),

            if (_errorMessage != null) ...[
              _ErrorBanner(message: _errorMessage!),
              const SizedBox(height: 12),
            ],

            CustomTextField(
              controller: _emailController,
              label: 'Email',
              hint: 'example@email.com',
              prefixIcon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),

            CustomTextField(
              controller: _passwordController,
              label: 'Mật khẩu',
              hint: '••••••••',
              prefixIcon: Icons.lock_outline_rounded,
              isPassword: true,
            ),

            const SizedBox(height: 6),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                  );
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Quên mật khẩu?',
                  style: TextStyle(
                    color: Color(0xFFD4A853),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            _isLoading
                ? const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  color: Color(0xFFD4A853),
                  strokeWidth: 2.5,
                ),
              ),
            )
                : _PrimaryButton(
              label: 'Đăng nhập',
              onPressed: _handleEmailLogin,
            ),

            const SizedBox(height: 14),
            const _OrDivider(),
            const SizedBox(height: 14),

            SocialSignInButton(
              label: 'Tiếp tục với Google',
              iconUrl: 'https://www.google.com/favicon.ico',
              onPressed: _isLoading ? () {} : _handleGoogleLogin,
            ),

            const SizedBox(height: 20),
            _RegisterCta(isLoading: _isLoading),
          ],
        ),
        ),
      ),
    );
  }

  // ─── Wide form ────────────────────────────────────────────────────────────
  Widget _buildWideFormContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogoLockup(iconSize: 52, fontSize: 22),
            const SizedBox(height: 32),

            const Text(
              'Chào mừng\ntrở lại',
              style: TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontFamily: 'Georgia',
                fontWeight: FontWeight.w700,
                height: 1.2,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Đăng nhập để tiếp tục hành trình của bạn',
              style: TextStyle(
                color: Colors.white.withOpacity(0.45),
                fontSize: 14,
                letterSpacing: 0.2,
              ),
            ),

            const SizedBox(height: 36),

            if (_errorMessage != null) ...[
              _ErrorBanner(message: _errorMessage!),
              const SizedBox(height: 20),
            ],

            CustomTextField(
              controller: _emailController,
              label: 'Email',
              hint: 'example@email.com',
              prefixIcon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            CustomTextField(
              controller: _passwordController,
              label: 'Mật khẩu',
              hint: '••••••••',
              prefixIcon: Icons.lock_outline_rounded,
              isPassword: true,
            ),

            const SizedBox(height: 10),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                  );
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Quên mật khẩu?',
                  style: TextStyle(
                    color: Color(0xFFD4A853),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            _isLoading
                ? const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  color: Color(0xFFD4A853),
                  strokeWidth: 2.5,
                ),
              ),
            )
                : _PrimaryButton(
              label: 'Đăng nhập',
              onPressed: _handleEmailLogin,
            ),

            const SizedBox(height: 24),
            const _OrDivider(horizontalPadding: 14, fontSize: 13),
            const SizedBox(height: 20),

            SocialSignInButton(
              label: 'Tiếp tục với Google',
              iconUrl: 'https://www.google.com/favicon.ico',
              onPressed: _isLoading ? () {} : _handleGoogleLogin,
            ),

            const SizedBox(height: 36),
            _RegisterCta(isLoading: _isLoading),
          ],
        ),
      ),
    );
  }
}


// ─── Hero Panel ───────────────────────────────────────────────────────────────
class _HeroPanel extends StatelessWidget {
  final bool showTagline;
  const _HeroPanel({super.key, this.showTagline = true});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=1200&q=80',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              Container(color: const Color(0xFF1A1A1A)),
        ),
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x33000000), Color(0xCC000000)],
            ),
          ),
        ),
        Positioned(
          left: 0,
          top: 80,
          bottom: 80,
          width: 3,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Color(0xFFD4A853),
                  Colors.transparent
                ],
              ),
            ),
          ),
        ),
        CustomPaint(painter: _GridPatternPainter()),
        if (showTagline)
          Positioned(
            left: 40,
            right: 40,
            bottom: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: List.generate(
                    5,
                        (_) => const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(Icons.star,
                          color: Color(0xFFD4A853), size: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Đặt phòng\nđẳng cấp.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontFamily: 'Georgia',
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Khách sạn, nhà nghỉ, homestay —\ntất cả trong một ứng dụng.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                    height: 1.6,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─── Grid Pattern Painter ─────────────────────────────────────────────────────
class _GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1;
    const spacing = 60.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
    final arcPaint = Paint()
      ..color = const Color(0xFFD4A853).withOpacity(0.15)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (int i = 1; i <= 3; i++) {
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(size.width, 0),
          width: i * 160.0,
          height: i * 160.0,
        ),
        math.pi / 2,
        math.pi / 2,
        false,
        arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─── Or Divider ───────────────────────────────────────────────────────────────
class _OrDivider extends StatelessWidget {
  final double horizontalPadding;
  final double fontSize;

  const _OrDivider({
    this.horizontalPadding = 12,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child:
            Divider(color: Colors.white.withOpacity(0.12), thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Text(
            'hoặc',
            style: TextStyle(
                color: Colors.white.withOpacity(0.35), fontSize: fontSize),
          ),
        ),
        Expanded(
            child:
            Divider(color: Colors.white.withOpacity(0.12), thickness: 1)),
      ],
    );
  }
}

// ─── Register CTA ─────────────────────────────────────────────────────────────
class _RegisterCta extends StatelessWidget {
  final bool isLoading;
  const _RegisterCta({required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: isLoading
            ? null
            : () => Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const RegisterScreen(),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 400),
          ),
        ),
        child: RichText(
          text: TextSpan(
            text: 'Chưa có tài khoản? ',
            style:
            TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
            children: const [
              TextSpan(
                text: 'Đăng ký ngay',
                style: TextStyle(
                  color: Color(0xFFD4A853),
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationColor: Color(0xFFD4A853),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Primary Button ───────────────────────────────────────────────────────────
class _PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  const _PrimaryButton({required this.label, required this.onPressed});

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFD4A853), Color(0xFFB8892E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4A853).withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.label,
              style: const TextStyle(
                color: Color(0xFF0D0D0D),
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Error Banner ─────────────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Colors.redAccent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  color: Colors.redAccent, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}