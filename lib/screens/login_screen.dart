
import 'home_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/taskflow_theme.dart';
import '../providers/auth_provider.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _rememberMe = true;
  bool _showPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  // Sign in with Firebase.
 Future<void> _signIn() async {
  final email = _emailController.text.trim();
  final password = _passwordController.text;

  if (email.isEmpty || password.isEmpty) {
    _showMessage('Please enter your email and password.');
    return;
  }

  debugPrint('TASKFLOW: Login button clicked');

  final authProvider = context.read<AuthProvider>();

  debugPrint('TASKFLOW: Calling Firebase sign in');

  final success = await authProvider.signIn(
    email: email,
    password: password,
  );

  debugPrint('TASKFLOW: Login result = $success');
  debugPrint('TASKFLOW: User = ${authProvider.user?.email}');
  debugPrint('TASKFLOW: Error = ${authProvider.errorMessage}');

  if (!mounted) return;

  if (success) {
    debugPrint('TASKFLOW: Login successful. Opening HomeScreen.');

    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const HomeScreen(),
      ),
      (route) => false,
    );
  } else {
    _showMessage(
      authProvider.errorMessage ?? 'Login failed. Please try again.',
    );
  }
}
  // Reset password.
  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showMessage('Please enter your email address first.');
      return;
    }

    final success = await context.read<AuthProvider>().sendPasswordResetEmail(
      email,
    );

    if (!mounted) return;

    if (success) {
      _showMessage('Password reset email sent. Please check your inbox.');
    } else {
      _showMessage(
        context.read<AuthProvider>().errorMessage ??
            'Could not send the reset email.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  children: [
                    const _BrandMark(icon: Icons.bolt_rounded),
                    const SizedBox(height: 24),

                    Text(
                      'Welcome back!',
                      style: textTheme.headlineLarge,
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Log in to continue organizing your workflow with cognitive clarity.',
                      style: textTheme.bodyLarge?.copyWith(
                        color: TaskFlowColors.secondaryText,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 48),

                    Card(
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Work Email', style: textTheme.labelLarge),
                                Text(
                                  'Required',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: TaskFlowColors.outline,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              enabled: !isLoading,
                              decoration: const InputDecoration(
                                hintText: 'alexa.chen@flow.design',
                                prefixIcon: Icon(Icons.alternate_email_rounded),
                              ),
                            ),

                            const SizedBox(height: 20),

                            Text('Password', style: textTheme.labelLarge),

                            const SizedBox(height: 8),

                            TextField(
                              controller: _passwordController,
                              obscureText: !_showPassword,
                              textInputAction: TextInputAction.done,
                              enabled: !isLoading,
                              onSubmitted: (_) => _signIn(),
                              decoration: InputDecoration(
                                hintText: 'Enter your password',
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                ),
                                suffixIcon: IconButton(
                                  tooltip: _showPassword
                                      ? 'Hide password'
                                      : 'Show password',
                                  onPressed: () => setState(
                                    () => _showPassword = !_showPassword,
                                  ),
                                  icon: Icon(
                                    _showPassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),

                            Row(
                              children: [
                                Checkbox.adaptive(
                                  value: _rememberMe,
                                  onChanged: isLoading
                                      ? null
                                      : (value) => setState(
                                          () => _rememberMe = value ?? false,
                                        ),
                                  visualDensity: VisualDensity.compact,
                                  activeColor: TaskFlowColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),

                                Expanded(
                                  child: Text(
                                    'Remember me',
                                    style: textTheme.labelMedium,
                                  ),
                                ),

                                TextButton(
                                  onPressed: isLoading ? null : _resetPassword,
                                  child: const Text('Forgot password?'),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            FilledButton.icon(
                              onPressed: isLoading ? null : _signIn,
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
                                isLoading ? 'Signing in...' : 'Sign In',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    const _DividerLabel(label: 'OR CONTINUE WITH'),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: isLoading
                            ? null
                            : () => _showMessage(
                                'Google sign-in will be available later.',
                              ),
                        icon: const _GoogleGlyph(),
                        label: const Text('Continue with Google'),
                      ),
                    ),

                    const SizedBox(height: 18),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: const ShapeDecoration(
                        color: Color(0xFFEFEBFF),
                        shape: StadiumBorder(),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.circle,
                            size: 9,
                            color: TaskFlowColors.tertiary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Encrypted biometric ready',
                            style: textTheme.labelSmall?.copyWith(
                              color: TaskFlowColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: isLoading
                              ? null
                              : () => Navigator.of(context).push<void>(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const SignupScreen(),
                                  ),
                                ),
                          child: const Text('Create account'),
                        ),
                      ],
                    ),

                    if (constraints.maxHeight < 620) const SizedBox(height: 4),
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

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 80,
    height: 80,
    decoration: BoxDecoration(
      color: TaskFlowColors.primary,
      borderRadius: BorderRadius.circular(24),
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
          child: Icon(Icons.check_rounded, color: Colors.white, size: 44),
        ),
        Positioned(
          right: -8,
          bottom: -8,
          child: Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: Color(0xFF6FFBBE),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF002113)),
          ),
        ),
      ],
    ),
  );
}

class _DividerLabel extends StatelessWidget {
  const _DividerLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(child: Divider(color: TaskFlowColors.outlineVariant)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: TaskFlowColors.outline),
        ),
      ),
      const Expanded(child: Divider(color: TaskFlowColors.outlineVariant)),
    ],
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
