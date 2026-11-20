import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../core/theme/taskflow_theme.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  void _openLogin(BuildContext context) {
    Navigator.of(
      context,
    ).push<void>(MaterialPageRoute<void>(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxHeight < 740;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Column(
                    children: [
                      _OnboardingHeader(onSkip: () => _openLogin(context)),
                      SizedBox(height: isCompact ? 6 : 12),
                      _TaskPreviewHero(height: isCompact ? 276 : 300),
                      const SizedBox(height: 10),
                      const _ProgressIndicators(),
                      const SizedBox(height: 18),
                      const _OnboardingCopy(),
                      const SizedBox(height: 16),
                      const _FeatureChips(),
                      const SizedBox(height: 22),
                      _OnboardingActions(onContinue: () => _openLogin(context)),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OnboardingHeader extends StatelessWidget {
  const _OnboardingHeader({required this.onSkip});

  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      height: 48,
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: TaskFlowColors.primary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: TaskFlowColors.primary.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 20,
              color: TaskFlowColors.surface,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'TaskFlow',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
              color: TaskFlowColors.mainText,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: onSkip,
            style: TextButton.styleFrom(
              backgroundColor: TaskFlowColors.lavenderContainer,
              foregroundColor: TaskFlowColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              shape: const StadiumBorder(),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Skip',
              style: textTheme.labelLarge?.copyWith(
                color: TaskFlowColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskPreviewHero extends StatelessWidget {
  const _TaskPreviewHero({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 18,
            left: 0,
            right: 0,
            child: Center(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  width: 210,
                  height: 210,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0x99C4C0FF),
                        Color(0x99E3DFFF),
                        Color(0x66F6F2FF),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(top: 0, right: 0, child: _StreakCard()),
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 335),
                child: const _FocusTaskCard(),
              ),
            ),
          ),
          const Positioned(left: 0, bottom: 0, child: _FocusScoreBadge()),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: 162,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: TaskFlowColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: TaskFlowColors.primary.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF6FFBBE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              size: 21,
              color: Color(0xFF002113),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Streak',
                  style: textTheme.labelSmall?.copyWith(
                    color: TaskFlowColors.secondaryText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '14 Days 🔥',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
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

class _FocusTaskCard extends StatelessWidget {
  const _FocusTaskCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TaskFlowColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: TaskFlowColors.primary.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: TaskFlowColors.tertiary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Today's Focus Hub",
                  style: textTheme.labelLarge?.copyWith(
                    color: TaskFlowColors.mainText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              _PillLabel(
                text: '3 of 4 Done',
                backgroundColor: const Color(0xFFEFEBFF),
                textStyle: textTheme.labelSmall,
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(top: 12, bottom: 8),
            child: Divider(height: 1, color: Color(0x66E9E5FF)),
          ),
          const _CompletedTaskRow(
            title: 'Design Sprint Planning',
            subtitle: '09:30 AM  •  Team Work',
            trailingIcon: Icons.calendar_today_outlined,
          ),
          const SizedBox(height: 8),
          const _ActiveTaskRow(),
          const SizedBox(height: 8),
          const _CompletedHabitRow(),
        ],
      ),
    );
  }
}

class _CompletedTaskRow extends StatelessWidget {
  const _CompletedTaskRow({
    required this.title,
    required this.subtitle,
    required this.trailingIcon,
  });

  final String title;
  final String subtitle;
  final IconData trailingIcon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: TaskFlowColors.lavenderContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const _TaskCheck(isComplete: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.bodyMedium?.copyWith(
                    color: TaskFlowColors.outline,
                    decoration: TextDecoration.lineThrough,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: textTheme.labelSmall?.copyWith(
                    color: TaskFlowColors.outline,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(trailingIcon, size: 18, color: TaskFlowColors.outlineVariant),
        ],
      ),
    );
  }
}

class _ActiveTaskRow extends StatelessWidget {
  const _ActiveTaskRow();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: TaskFlowColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: TaskFlowColors.primary.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(width: 6, color: TaskFlowColors.primary),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: Row(
                  children: [
                    const _TaskCheck(isComplete: false),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Review Q3 UX Insights',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: TaskFlowColors.mainText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 3,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _PillLabel(
                                text: 'High Priority',
                                backgroundColor: const Color(0xFFE3DFFF),
                                textStyle: textTheme.labelSmall?.copyWith(
                                  color: TaskFlowColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '11:00 AM',
                                style: textTheme.labelMedium?.copyWith(
                                  color: TaskFlowColors.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.flag_rounded,
                      size: 20,
                      color: TaskFlowColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletedHabitRow extends StatelessWidget {
  const _CompletedHabitRow();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: TaskFlowColors.lavenderContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const _TaskCheck(isComplete: true),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Mindful Meditation (15m)',
              style: textTheme.bodyMedium?.copyWith(
                color: TaskFlowColors.outline,
                decoration: TextDecoration.lineThrough,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '+25 XP',
            style: textTheme.labelSmall?.copyWith(
              color: TaskFlowColors.tertiary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskCheck extends StatelessWidget {
  const _TaskCheck({required this.isComplete});

  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    if (isComplete) {
      return Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          color: TaskFlowColors.tertiary,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
      );
    }

    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        color: Color(0xFFE9E5FF),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.radio_button_unchecked_rounded,
        size: 16,
        color: TaskFlowColors.primary,
      ),
    );
  }
}

class _PillLabel extends StatelessWidget {
  const _PillLabel({
    required this.text,
    required this.backgroundColor,
    required this.textStyle,
  });

  final String text;
  final Color backgroundColor;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: textStyle, maxLines: 1),
    );
  }
}

class _FocusScoreBadge extends StatelessWidget {
  const _FocusScoreBadge();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: TaskFlowColors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: TaskFlowColors.primary.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: Color(0xFFE3DFFF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_rounded,
              size: 18,
              color: TaskFlowColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '100% Focus Score',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: TaskFlowColors.mainText,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressIndicators extends StatelessWidget {
  const _ProgressIndicators();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ProgressDot(isActive: true),
        const SizedBox(width: 8),
        _ProgressDot(isActive: false),
        const SizedBox(width: 8),
        _ProgressDot(isActive: false),
      ],
    );
  }
}

class _ProgressDot extends StatelessWidget {
  const _ProgressDot({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: isActive ? 28 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? TaskFlowColors.primary : const Color(0xFFE3DFFF),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

class _OnboardingCopy extends StatelessWidget {
  const _OnboardingCopy();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Text(
            'Master Your Day with\nEffortless Flow',
            style: textTheme.headlineLarge?.copyWith(
              fontSize: 26,
              height: 34 / 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.52,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Prioritize intelligently, organize projects with clarity, and build daily habits that stick.',
            style: textTheme.bodyMedium?.copyWith(
              color: TaskFlowColors.secondaryText,
              height: 22 / 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _FeatureChips extends StatelessWidget {
  const _FeatureChips();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        _FeatureChip(
          icon: Icons.bolt_rounded,
          label: 'Smart Priorities',
          color: TaskFlowColors.primary,
          textStyle: textTheme.labelMedium,
        ),
        _FeatureChip(
          icon: Icons.event_repeat_rounded,
          label: 'Calendar Sync',
          color: TaskFlowColors.secondary,
          textStyle: textTheme.labelMedium,
        ),
        _FeatureChip(
          icon: Icons.insights_rounded,
          label: 'Streak Insights',
          color: TaskFlowColors.tertiary,
          textStyle: textTheme.labelMedium,
        ),
      ],
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.textStyle,
  });

  final IconData icon;
  final String label;
  final Color color;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: TaskFlowColors.lavenderContainer,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A181445),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: textStyle?.copyWith(
              color: TaskFlowColors.mainText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingActions extends StatelessWidget {
  const _OnboardingActions({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton(
            onPressed: onContinue,
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
              shadowColor: TaskFlowColors.primary.withValues(alpha: 0.3),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Get Started',
                  style: textTheme.titleMedium?.copyWith(
                    color: TaskFlowColors.surface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.arrow_forward_rounded, size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: onContinue,
          style: TextButton.styleFrom(
            foregroundColor: TaskFlowColors.secondaryText,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          ),
          child: Text.rich(
            TextSpan(
              text: 'Already have an account? ',
              style: textTheme.labelLarge?.copyWith(
                color: TaskFlowColors.secondaryText,
                fontWeight: FontWeight.w500,
              ),
              children: [
                TextSpan(
                  text: 'Log in',
                  style: textTheme.labelLarge?.copyWith(
                    color: TaskFlowColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
