
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/taskflow_theme.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _acceptedTerms = true;

  int get _passwordStrength {
    final password = _passwordController.text;
    if (password.isEmpty) return 0;

    var score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password)) {
      score++;
    }
    if (RegExp(r'\d').hasMatch(password)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) score++;

    return score;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _createAccount() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmController.text;

    if (name.isEmpty) {
      _showMessage('Please enter your full name.');
      return;
    }

    if (email.isEmpty) {
      _showMessage('Please enter your email address.');
      return;
    }

    if (password.isEmpty) {
      _showMessage('Please enter a password.');
      return;
    }

    if (password.length < 6) {
      _showMessage('Password must contain at least 6 characters.');
      return;
    }

    if (password != confirmPassword) {
      _showMessage('Passwords do not match.');
      return;
    }

    if (!_acceptedTerms) {
      _showMessage('Please accept the terms to continue.');
      return;
    }

    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.signUp(
      name: name,
      email: email,
      password: password,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      _showMessage(
        authProvider.errorMessage ??
            'Account creation failed. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final strength = _passwordStrength;
    final isLoading = context.watch<AuthProvider>().isLoading;

    final strengthLabel = switch (strength) {
      0 => 'Not set',
      1 => 'Weak',
      2 => 'Fair',
      3 => 'Good',
      _ => 'Strong',
    };

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: _SignupBrandMark()),
                    const SizedBox(height: 32),
                    Text(
                      'Create Account',
                      style: textTheme.headlineLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start your 14-day free productivity journey.',
                      style: textTheme.bodyLarge?.copyWith(
                        color: TaskFlowColors.secondaryText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 36),
                    Row(
                      children: [
                        Expanded(
                          child: _SocialButton(
                            label: 'Google',
                            icon: const _GoogleGlyph(),
                            onPressed: () => _showMessage(
                              'Google sign-up will be available later.',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SocialButton(
                            label: 'Apple',
                            icon: const Icon(Icons.apple_rounded, size: 23),
                            onPressed: () => _showMessage(
                              'Apple sign-up will be available later.',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    const _DividerLabel(label: 'OR SIGN UP WITH EMAIL'),
                    const SizedBox(height: 24),

                    _FieldLabel(label: 'Full Name'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      enabled: !isLoading,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Alexa Chen',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                    ),

                    const SizedBox(height: 20),
                    _FieldLabel(label: 'Work / Personal Email'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      enabled: !isLoading,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'e.g. alexa.chen@flow.design',
                        prefixIcon: Icon(Icons.mail_outline_rounded),
                      ),
                    ),

                    const SizedBox(height: 20),
                    _FieldLabel(label: 'Password'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      enabled: !isLoading,
                      obscureText: !_showPassword,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Create a strong password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          tooltip: _showPassword
                              ? 'Hide password'
                              : 'Show password',
                          onPressed: () =>
                              setState(() => _showPassword = !_showPassword),
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Security check',
                          style: textTheme.labelSmall?.copyWith(
                            color: TaskFlowColors.outline,
                          ),
                        ),
                        Text(
                          strengthLabel,
                          style: textTheme.labelMedium?.copyWith(
                            color: strength >= 4
                                ? TaskFlowColors.tertiary
                                : TaskFlowColors.secondaryText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(4, (index) {
                        final active = index < strength;

                        return Expanded(
                          child: Container(
                            height: 6,
                            margin: EdgeInsets.only(
                              right: index == 3 ? 0 : 8,
                            ),
                            decoration: BoxDecoration(
                              color: active
                                  ? (index == 3
                                      ? const Color(0xFF4EDEA3)
                                      : TaskFlowColors.primary)
                                  : const Color(0xFFE3DFFF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 20),
                    _FieldLabel(label: 'Confirm Password'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _confirmController,
                      enabled: !isLoading,
                      obscureText: !_showConfirmPassword,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _createAccount(),
                      decoration: InputDecoration(
                        hintText: 'Repeat your password',
                        prefixIcon: const Icon(Icons.lock_reset_rounded),
                        suffixIcon: IconButton(
                          tooltip: _showConfirmPassword
                              ? 'Hide password'
                              : 'Show password',
                          onPressed: () => setState(
                            () => _showConfirmPassword = !_showConfirmPassword,
                          ),
                          icon: Icon(
                            _showConfirmPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox.adaptive(
                          value: _acceptedTerms,
                          onChanged: isLoading
                              ? null
                              : (value) => setState(
                                  () => _acceptedTerms = value ?? false,
                                ),
                          visualDensity: VisualDensity.compact,
                          activeColor: TaskFlowColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 11),
                            child: Text.rich(
                              TextSpan(
                                style: textTheme.bodySmall?.copyWith(
                                  color: TaskFlowColors.secondaryText,
                                ),
                                children: const [
                                  TextSpan(text: 'I agree to the '),
                                  TextSpan(
                                    text: 'Terms of Service',
                                    style: TextStyle(
                                      color: TaskFlowColors.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  TextSpan(text: ' and '),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: TextStyle(
                                      color: TaskFlowColors.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  TextSpan(text: '.'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: isLoading ? null : _createAccount,
                      icon: isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.arrow_forward_rounded),
                      label: Text(
                        isLoading ? 'Creating account...' : 'Create Account',
                      ),
                    ),

                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFEBFF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: TaskFlowColors.tertiary.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.bolt_rounded,
                              color: TaskFlowColors.tertiary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Firebase Authentication Enabled',
                                  style: textTheme.labelLarge,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Your account is securely managed by Firebase.',
                                  style: textTheme.bodySmall,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: isLoading
                              ? null
                              : () => Navigator.of(context).push<void>(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const LoginScreen(),
                                  ),
                                ),
                          child: const Text('Log In'),
                        ),
                      ],
                    ),

                    if (constraints.maxHeight < 620)
                      const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SignupBrandMark extends StatelessWidget {
  const _SignupBrandMark();

  @override
  Widget build(BuildContext context) => Container(
        width: 128,
        height: 128,
        decoration: BoxDecoration(
          color: TaskFlowColors.primary,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: TaskFlowColors.primary.withValues(alpha: 0.22),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Center(
              child: Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 64,
              ),
            ),
            Positioned(
              right: -8,
              top: -8,
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFE3DFFF),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(color: TaskFlowColors.secondaryText),
      );
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final Widget icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: onPressed,
        icon: icon,
        label: Text(label),
        style: OutlinedButton.styleFrom(
          backgroundColor: TaskFlowColors.lavenderContainer,
          side: BorderSide.none,
          foregroundColor: TaskFlowColors.mainText,
        ),
      );
}

class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  @override
  Widget build(BuildContext context) => const Text(
        'G',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Color(0xFF4285F4),
        ),
      );
}

class _DividerLabel extends StatelessWidget {
  const _DividerLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          const Expanded(
            child: Divider(color: TaskFlowColors.outlineVariant),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: TaskFlowColors.outline),
            ),
          ),
          const Expanded(
            child: Divider(color: TaskFlowColors.outlineVariant),
          ),
        ],
      );
}
