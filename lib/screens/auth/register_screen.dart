import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../DTOs/register_dto.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/app_logo.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();

  int _currentStep = 0; // 0 = thông tin cá nhân, 1 = bảo mật
  String? _errorMessage;
  bool _isLoading = false;

  // Animation controllers
  late final AnimationController _fadeController;
  late final AnimationController _progressController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _progressController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _ageController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _goToStep2() async {
    if (!(_formKey1.currentState?.validate() ?? false)) return;
    setState(() {
      _currentStep = 1;
      _errorMessage = null;
    });
    _fadeController.reset();
    _progressController.animateTo(1.0);
    _fadeController.forward();
  }

  void _backToStep1() {
    setState(() {
      _currentStep = 0;
      _errorMessage = null;
    });
    _fadeController.reset();
    _progressController.animateTo(0.0);
    _fadeController.forward();
  }

  Future<void> _register() async {
    if (!(_formKey2.currentState?.validate() ?? false)) return;

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    final registerDTO = RegisterDTO(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      fullName: _fullNameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      age: int.parse(_ageController.text.trim()),
      bio: _bioController.text.trim(),
    );

    final user = await _authService.registerWithDetails(registerDTO);
    setState(() => _isLoading = false);

    if (user == null) {
      setState(() =>
      _errorMessage = 'Đăng ký thất bại. Email có thể đã được sử dụng.');
    } else {
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _currentStep == 0 ? _buildStep1() : _buildStep2(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header: back button + progress ──────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        children: [
          Row(
            children: [
              // Back button
              _CircleIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: _currentStep == 0
                    ? () => Navigator.pop(context)
                    : _backToStep1,
              ),
              const SizedBox(width: 16),
              // Logo lockup nhỏ gọn
              const AppLogoLockup(iconSize: 32, fontSize: 15),
              const Spacer(),
              // Step indicator text
              Text(
                'Bước ${_currentStep + 1}/2',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          _StepProgressBar(
            progress: _currentStep == 0 ? 0.5 : 1.0,
            controller: _progressController,
          ),
        ],
      ),
    );
  }

  // ─── Step 1: Thông tin cá nhân ────────────────────────────────────────────
  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      child: Form(
        key: _formKey1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StepHeading(
              step: '01',
              title: 'Thông tin\ncá nhân',
              subtitle: 'Cho chúng tôi biết thêm về bạn',
            ),
            const SizedBox(height: 32),

            // Full name
            _FormField(
              controller: _fullNameController,
              label: 'Họ và tên',
              hint: 'Nguyễn Văn A',
              icon: Icons.person_outline_rounded,
              validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Vui lòng nhập họ tên' : null,
            ),
            const SizedBox(height: 16),

            // Phone
            _FormField(
              controller: _phoneController,
              label: 'Số điện thoại',
              hint: '0912 345 678',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Vui lòng nhập số điện thoại' : null,
            ),
            const SizedBox(height: 16),

            // Age
            _FormField(
              controller: _ageController,
              label: 'Tuổi',
              hint: '25',
              icon: Icons.cake_outlined,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Vui lòng nhập tuổi';
                final age = int.tryParse(v);
                if (age == null || age < 1 || age > 150) {
                  return 'Tuổi không hợp lệ';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Address
            _FormField(
              controller: _addressController,
              label: 'Địa chỉ',
              hint: '123 Đường ABC, Hà Nội',
              icon: Icons.location_on_outlined,
              maxLines: 2,
              validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Vui lòng nhập địa chỉ' : null,
            ),
            const SizedBox(height: 16),

            // Bio
            _FormField(
              controller: _bioController,
              label: 'Giới thiệu bản thân',
              hint: 'Tôi thường du lịch vào cuối tuần...',
              icon: Icons.notes_rounded,
              maxLines: 3,
              validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Vui lòng nhập giới thiệu' : null,
            ),

            const SizedBox(height: 36),

            _NextButton(
              label: 'Tiếp theo',
              onPressed: _goToStep2,
              trailingIcon: Icons.arrow_forward_rounded,
            ),

            const SizedBox(height: 20),
            _LoginCta(),
          ],
        ),
      ),
    );
  }

  // ─── Step 2: Bảo mật tài khoản ───────────────────────────────────────────
  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      child: Form(
        key: _formKey2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StepHeading(
              step: '02',
              title: 'Bảo mật\ntài khoản',
              subtitle: 'Thiết lập email & mật khẩu đăng nhập',
            ),
            const SizedBox(height: 32),

            if (_errorMessage != null) ...[
              _ErrorBanner(message: _errorMessage!),
              const SizedBox(height: 20),
            ],

            // Email
            _FormField(
              controller: _emailController,
              label: 'Email',
              hint: 'example@email.com',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Vui lòng nhập email';
                if (!v.contains('@') || !v.contains('.')) {
                  return 'Email không hợp lệ';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Password
            _PasswordFormField(
              controller: _passwordController,
              label: 'Mật khẩu',
              hint: 'Tối thiểu 6 ký tự',
              validator: (v) {
                if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
                if (v.length < 6) return 'Mật khẩu tối thiểu 6 ký tự';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Confirm password
            _PasswordFormField(
              controller: _confirmPasswordController,
              label: 'Xác nhận mật khẩu',
              hint: 'Nhập lại mật khẩu',
              validator: (v) {
                if (v == null || v.isEmpty) return 'Vui lòng xác nhận mật khẩu';
                if (v != _passwordController.text) return 'Mật khẩu không khớp';
                return null;
              },
            ),

            const SizedBox(height: 12),

            // Password strength hint
            _PasswordHint(),

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
                : _NextButton(
              label: 'Tạo tài khoản',
              onPressed: _register,
              trailingIcon: Icons.check_rounded,
            ),

            const SizedBox(height: 20),
            _LoginCta(),
          ],
        ),
      ),
    );
  }
}

// ─── Step Progress Bar ────────────────────────────────────────────────────────
class _StepProgressBar extends StatelessWidget {
  final double progress;
  final AnimationController controller;

  const _StepProgressBar({required this.progress, required this.controller});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Track
            Container(
              height: 2,
              width: double.infinity,
              color: Colors.white.withOpacity(0.10),
            ),
            // Fill — dùng AnimatedContainer để mượt
            AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
              height: 2,
              width: constraints.maxWidth * progress,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE8C06A), Color(0xFFD4A853)],
                ),
              ),
            ),
            // Dot step 1
            Positioned(
              left: constraints.maxWidth * 0.5 - 5,
              top: -4,
              child: _StepDot(active: progress >= 0.5),
            ),
            // Dot step 2
            Positioned(
              right: -5,
              top: -4,
              child: _StepDot(active: progress >= 1.0),
            ),
          ],
        );
      },
    );
  }
}

class _StepDot extends StatelessWidget {
  final bool active;
  const _StepDot({required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? const Color(0xFFD4A853) : Colors.white.withOpacity(0.15),
        boxShadow: active
            ? [
          BoxShadow(
            color: const Color(0xFFD4A853).withOpacity(0.5),
            blurRadius: 6,
            spreadRadius: 1,
          )
        ]
            : null,
      ),
    );
  }
}

// ─── Step Heading ─────────────────────────────────────────────────────────────
class _StepHeading extends StatelessWidget {
  final String step;
  final String title;
  final String subtitle;

  const _StepHeading({
    required this.step,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Big step number — decorative
        Text(
          step,
          style: TextStyle(
            color: const Color(0xFFD4A853).withOpacity(0.15),
            fontSize: 72,
            fontFamily: 'Georgia',
            fontWeight: FontWeight.w700,
            height: 0.9,
          ),
        ),
        const SizedBox(width: 16),
        // Title + subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontFamily: 'Georgia',
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Form Field (text, non-password) ─────────────────────────────────────────
class _FormField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final String? Function(String?)? validator;

  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.maxLines = 1,
    this.validator,
  });

  @override
  State<_FormField> createState() => _FormFieldState();
}

class _FormFieldState extends State<_FormField> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (v) => setState(() => _isFocused = v),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isFocused
                ? const Color(0xFFD4A853)
                : Colors.white.withOpacity(0.12),
            width: _isFocused ? 1.5 : 1,
          ),
          color: Colors.white.withOpacity(_isFocused ? 0.08 : 0.05),
        ),
        child: TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          inputFormatters: widget.inputFormatters,
          maxLines: widget.maxLines,
          validator: widget.validator,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontFamily: 'Georgia',
          ),
          cursorColor: const Color(0xFFD4A853),
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            hintStyle:
            TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 14),
            labelStyle: TextStyle(
              color: _isFocused
                  ? const Color(0xFFD4A853)
                  : Colors.white.withOpacity(0.50),
              fontSize: 13,
              letterSpacing: 0.3,
            ),
            prefixIcon: Icon(
              widget.icon,
              color: _isFocused
                  ? const Color(0xFFD4A853)
                  : Colors.white.withOpacity(0.40),
              size: 20,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: widget.maxLines > 1 ? 14 : 18,
            ),
            errorStyle: const TextStyle(
              color: Color(0xFFFF6B6B),
              fontSize: 12,
              height: 1.2,
            ),
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
          ),
        ),
      ),
    );
  }
}

// ─── Password Form Field (with toggle) ───────────────────────────────────────
class _PasswordFormField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String? Function(String?)? validator;

  const _PasswordFormField({
    required this.controller,
    required this.label,
    required this.hint,
    this.validator,
  });

  @override
  State<_PasswordFormField> createState() => _PasswordFormFieldState();
}

class _PasswordFormFieldState extends State<_PasswordFormField> {
  bool _obscure = true;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (v) => setState(() => _isFocused = v),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isFocused
                ? const Color(0xFFD4A853)
                : Colors.white.withOpacity(0.12),
            width: _isFocused ? 1.5 : 1,
          ),
          color: Colors.white.withOpacity(_isFocused ? 0.08 : 0.05),
        ),
        child: TextFormField(
          controller: widget.controller,
          obscureText: _obscure,
          validator: widget.validator,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontFamily: 'Georgia',
          ),
          cursorColor: const Color(0xFFD4A853),
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            hintStyle:
            TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 14),
            labelStyle: TextStyle(
              color: _isFocused
                  ? const Color(0xFFD4A853)
                  : Colors.white.withOpacity(0.50),
              fontSize: 13,
              letterSpacing: 0.3,
            ),
            prefixIcon: Icon(
              Icons.lock_outline_rounded,
              color: _isFocused
                  ? const Color(0xFFD4A853)
                  : Colors.white.withOpacity(0.40),
              size: 20,
            ),
            suffixIcon: IconButton(
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(
                _obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: Colors.white.withOpacity(0.40),
                size: 20,
              ),
            ),
            border: InputBorder.none,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            errorStyle: const TextStyle(
              color: Color(0xFFFF6B6B),
              fontSize: 12,
              height: 1.2,
            ),
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
          ),
        ),
      ),
    );
  }
}

// ─── Password Hint ────────────────────────────────────────────────────────────
class _PasswordHint extends StatelessWidget {
  const _PasswordHint();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.info_outline_rounded,
          color: Colors.white.withOpacity(0.30),
          size: 14,
        ),
        const SizedBox(width: 6),
        Text(
          'Nên kết hợp chữ, số và ký tự đặc biệt',
          style: TextStyle(
            color: Colors.white.withOpacity(0.30),
            fontSize: 12,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

// ─── Next / Submit Button ─────────────────────────────────────────────────────
class _NextButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData trailingIcon;

  const _NextButton({
    required this.label,
    required this.onPressed,
    required this.trailingIcon,
  });

  @override
  State<_NextButton> createState() => _NextButtonState();
}

class _NextButtonState extends State<_NextButton> {
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.label,
                style: const TextStyle(
                  color: Color(0xFF0D0D0D),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                widget.trailingIcon,
                color: Colors.white,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Circle Icon Button ───────────────────────────────────────────────────────
class _CircleIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  State<_CircleIconButton> createState() => _CircleIconButtonState();
}

class _CircleIconButtonState extends State<_CircleIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.06),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
              width: 1,
            ),
          ),
          child: Icon(
            widget.icon,
            color: Colors.white.withOpacity(0.70),
            size: 20,
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
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Color(0xFFFF6B6B), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  color: Color(0xFFFF6B6B), fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Login CTA ────────────────────────────────────────────────────────────────
class _LoginCta extends StatelessWidget {
  const _LoginCta();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: RichText(
          text: TextSpan(
            text: 'Đã có tài khoản? ',
            style:
            TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 13),
            children: const [
              TextSpan(
                text: 'Đăng nhập',
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