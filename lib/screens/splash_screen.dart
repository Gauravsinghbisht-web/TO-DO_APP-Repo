import 'package:flutter/material.dart';

import '../core/theme/taskflow_theme.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  void _openOnboarding(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const OnboardingScreen(),
      ),
    );
  }

  void _openLogin(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.15),
            radius: 1.05,
            colors: [Color(0xFFF0EDFF), TaskFlowColors.background],
            stops: [0, 0.9],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _ReadyBadge(textStyle: textTheme.labelLarge),
                    FilledButton.tonal(
                      onPressed: () => _openOnboarding(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: TaskFlowColors.surface,
                        foregroundColor: TaskFlowColors.secondaryText,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Get Started'),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: SizedBox(
                        width: double.infinity,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const _TaskFlowMark(),
                            const SizedBox(height: 26),
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Task',
                                    style: textTheme.headlineLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Flow',
                                    style: textTheme.headlineLarge?.copyWith(
                                      color: TaskFlowColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Organize. Focus. Flow.',
                              style: textTheme.titleLarge?.copyWith(
                                color: TaskFlowColors.secondaryText,
                                fontWeight: FontWeight.w400,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 36),
                            const SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: TaskFlowColors.primary,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Syncing offline routines...',
                              style: textTheme.bodyLarge?.copyWith(
                                color: TaskFlowColors.secondaryText,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                _SplashActions(
                  onExplore: () => _openOnboarding(context),
                  onSignIn: () => _openLogin(context),
                ),
                const SizedBox(height: 22),
                Text(
                  'Engineered for seamless productivity',
                  style: textTheme.bodyMedium?.copyWith(
                    color: TaskFlowColors.secondaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  '•  VERSION 2.4.0 (BUILD 182)  •',
                  style: textTheme.labelMedium?.copyWith(
                    color: TaskFlowColors.secondaryText,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReadyBadge extends StatelessWidget {
  const _ReadyBadge({required this.textStyle});

  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: TaskFlowColors.lavenderContainer,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A181445),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: TaskFlowColors.tertiary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'READY TO FLOW',
              style: textStyle?.copyWith(
                color: TaskFlowColors.secondaryText,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskFlowMark extends StatelessWidget {
  const _TaskFlowMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 148,
      height: 142,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              color: TaskFlowColors.surface,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: TaskFlowColors.primary.withValues(alpha: 0.16),
                  blurRadius: 34,
                  spreadRadius: 8,
                  offset: const Offset(0, 12),
                ),
                const BoxShadow(
                  color: Color(0x14181445),
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: TaskFlowColors.lavenderContainer,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 58,
                  color: TaskFlowColors.primary,
                ),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: -2,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: TaskFlowColors.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14181445),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.spa_outlined,
                      size: 18,
                      color: TaskFlowColors.primary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'Flow',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: TaskFlowColors.primary,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashActions extends StatelessWidget {
  const _SplashActions({required this.onExplore, required this.onSignIn});

  final VoidCallback onExplore;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: TaskFlowColors.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10181445),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: onExplore,
              icon: const Icon(Icons.explore_outlined),
              label: const Text('Explore Tour'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton.tonalIcon(
              onPressed: onSignIn,
              icon: const Icon(Icons.login_rounded),
              label: const Text('Sign In'),
              style: FilledButton.styleFrom(
                backgroundColor: TaskFlowColors.lavenderContainer,
                foregroundColor: TaskFlowColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
