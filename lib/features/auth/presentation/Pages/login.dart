import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/auth_providers.dart';

class Login extends ConsumerStatefulWidget {
  const Login({super.key});

  @override
  ConsumerState<Login> createState() => _LoginState();
}

class _LoginState extends ConsumerState<Login>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLogin = true;
  bool _obscurePassword = true;
  final _passwordFocusNode = FocusNode();
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // ── Design tokens ──────────────────────────────────
  static const _bg = Color(0xFF0F0F1A);
  static const _accent = Color(0xFF7C6FFF);
  static const _accentSoft = Color(0x337C6FFF);
  static const _textPrimary = Color(0xFFF0EFFF);
  static const _textMuted = Color(0xFF8B8AA8);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _animController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _toggleMode() {
    _animController.reset();
    setState(() => _isLogin = !_isLogin);
    _animController.forward();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final authController = ref.read(authControllerProvider.notifier);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final displayName = _nameController.text.trim();

    if (_isLogin) {
      await authController.signIn(email, password);
    } else {
      await authController.signUp(email, password, displayName);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, _) {
          String message = 'Something went wrong';
          if (error is FirebaseAuthException) {
            switch (error.code) {
              case 'user-not-found':
                message = 'No account found for that email';
                break;
              case 'wrong-password':
                message = 'Incorrect password';
                break;
              case 'email-already-in-use':
                message = 'This email is already registered';
                break;
              case 'weak-password':
                message = 'Choose a stronger password';
                break;
              case 'invalid-credential':
                message = 'Invalid email or password';
                break;
              default:
                message = error.message ?? 'Auth error';
            }
          }
          debugPrint('AUTH ERROR: ${error.toString()}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.red.shade800,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      );
    });

    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),

              // ── Brand mark ─────────────────────────
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _accentSoft,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _accent, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.celebration_rounded,
                      color: _accent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'YEM Events',
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 45),

              // ── Headline ───────────────────────────
              FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      _isLogin ? 'Welcome back.' : 'Create your account.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _isLogin
                          ? 'Sign in to manage and discover events.'
                          : 'Join to create, RSVP, and share events.',
                      style: const TextStyle(
                        color: _textMuted,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 44),

              // ── Form ───────────────────────────────
              FadeTransition(
                opacity: _fadeAnim,
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Name field (signup only)
                      if (!_isLogin) ...[
                        _InputField(
                          controller: _nameController,
                          label: 'Full name',
                          icon: Icons.person_outline_rounded,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return 'Enter your name';
                            if (v.trim().length < 2) return 'Name too short';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Email
                      _InputField(
                        controller: _emailController,
                        label: 'Email address',
                        icon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) => _submit(),
                        validator: (v) =>
                            v!.isEmpty ? 'Enter your email' : null,
                      ),
                      const SizedBox(height: 16),

                      // Password
                      _InputField(
                        controller: _passwordController,
                        label: 'Password',
                        icon: Icons.lock_outline_rounded,
                        obscureText: _obscurePassword,
                        focusNode: _passwordFocusNode,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: _textMuted,
                            size: 20,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                        validator: (v) =>
                            v!.length < 6 ? 'At least 6 characters' : null,
                      ),

                      const SizedBox(height: 32),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: authState.isLoading
                            ? Container(
                                decoration: BoxDecoration(
                                  color: _accentSoft,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Center(
                                  child: SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: _accent,
                                    ),
                                  ),
                                ),
                              )
                            : ElevatedButton(
                                onPressed: _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _accent,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  _isLogin ? 'Sign in' : 'Create account',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                      ),

                      const SizedBox(height: 24),

                      // Toggle login/signup
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isLogin
                                ? "Don't have an account?"
                                : 'Already have an account?',
                            style: const TextStyle(
                              color: _textMuted,
                              fontSize: 14,
                            ),
                          ),
                          TextButton(
                            onPressed: _toggleMode,
                            style: TextButton.styleFrom(
                              foregroundColor: _accent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            ),
                            child: Text(
                              _isLogin ? 'Sign up' : 'Sign in',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Event preview strip ────────────────
              _EventPreviewStrip(),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Reusable input field ───────────────────────────────
class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.textInputAction,
    this.focusNode,
    this.validator,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;

  static const _bg = Color(0xFF1A1A2E);
  static const _accent = Color(0xFF7C6FFF);
  static const _textPrimary = Color(0xFFF0EFFF);
  static const _textMuted = Color(0xFF8B8AA8);
  static const _inputBorder = Color(0xFF2E2E4A);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      focusNode: focusNode,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      style: const TextStyle(color: _textPrimary, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _textMuted, fontSize: 14),
        prefixIcon: Icon(icon, color: _textMuted, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: _bg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.shade400),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}

// ── Decorative event preview strip at bottom ───────────
class _EventPreviewStrip extends StatelessWidget {
  final _events = const [
    ('🎵', 'Book Festival', 'Aug 12'),
    ('🎨', 'Art Exhibition', 'Aug 19'),
    ('💼', 'Tech Summit', 'Sep 3'),
    ('🍕', 'Food Fair', 'Sep 14'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            'HAPPENING SOON',
            style: TextStyle(
              color: Color(0xFF8B8AA8),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
        ),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _events.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final (emoji, title, date) = _events[index];
              return Container(
                width: 130,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2E2E4A)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 18)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Color(0xFFF0EFFF),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          date,
                          style: const TextStyle(
                            color: Color(0xFF8B8AA8),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
