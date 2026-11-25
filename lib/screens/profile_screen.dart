
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/taskflow_bottom_navigation_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    this.onHomeSelected,
    this.onTasksSelected,
    this.onCalendarSelected,
    this.onStatisticsSelected,
  });

  final VoidCallback? onHomeSelected;
  final VoidCallback? onTasksSelected;
  final VoidCallback? onCalendarSelected;
  final VoidCallback? onStatisticsSelected;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedDestination = 4;
  bool _notifications = true;
  bool _soundAndHaptics = true;
  bool _calendarSync = true;
  String _defaultPriority = 'Medium';

  @override
  Widget build(BuildContext context) {
    const destinations = [
      'Home',
      'Tasks',
      'Calendar',
      'Statistics',
      'Profile',
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _ProfileAppBar(
              destination: destinations[_selectedDestination],
              onProfile: () => setState(() => _selectedDestination = 4),
            ),
            Expanded(
              child: _selectedDestination == 4
                  ? _buildProfile(context)
                  : _DestinationPlaceholder(
                      title: destinations[_selectedDestination],
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: TaskFlowBottomNavigationBar(
        selectedIndex: _selectedDestination,
        onDestinationSelected: _onDestinationSelected,
      ),
    );
  }

  Widget _buildProfile(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _ProfileHeroCard(),
              const SizedBox(height: 24),
              const _SectionHeading(title: 'Preferences'),
              const SizedBox(height: 10),
              _PreferencesCard(
                themeMode: themeProvider.themeMode,
                notifications: _notifications,
                soundAndHaptics: _soundAndHaptics,
                defaultPriority: _defaultPriority,
                onThemeChanged: (mode) =>
                    themeProvider.setThemeMode(mode),
                onNotificationsChanged: (value) =>
                    setState(() => _notifications = value),
                onSoundChanged: (value) =>
                    setState(() => _soundAndHaptics = value),
                onPriorityChanged: (value) => setState(() {
                  if (value != null) _defaultPriority = value;
                }),
              ),
              const SizedBox(height: 22),
              const _SectionHeading(title: 'Data & Integrations'),
              const SizedBox(height: 10),
              _IntegrationCard(
                calendarSync: _calendarSync,
                onCalendarChanged: (value) =>
                    setState(() => _calendarSync = value),
                onExport: () =>
                    _showMessage('Task export will be available later.'),
              ),
              const SizedBox(height: 22),
              const _SectionHeading(title: 'Support & About'),
              const SizedBox(height: 10),
              _SupportCard(
                onHelp: () => _showMessage(
                  'Help Center and tutorials will be available later.',
                ),
                onPrivacy: () => _showMessage(
                  'Privacy information will be available later.',
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                height: 64,
                child: FilledButton.icon(
                  onPressed: _confirmLogout,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Log Out of TaskFlow'),
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.errorContainer,
                    foregroundColor:
                        Theme.of(context).colorScheme.onErrorContainer,
                    textStyle: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onDestinationSelected(int index) {
    switch (index) {
      case 0:
        _navigateOrSelect(widget.onHomeSelected, index);
      case 1:
        _navigateOrSelect(widget.onTasksSelected, index);
      case 2:
        _navigateOrSelect(widget.onCalendarSelected, index);
      case 3:
        _navigateOrSelect(widget.onStatisticsSelected, index);
      case 4:
        setState(() => _selectedDestination = 4);
    }
  }

  void _navigateOrSelect(VoidCallback? callback, int index) {
    if (callback != null) {
      callback();
    } else {
      setState(() => _selectedDestination = index);
    }
  }

  Future<void> _confirmLogout() async {
    final shouldLogOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.logout_rounded),
        title: const Text('Log out?'),
        content: const Text(
          'You will return to the sign-in screen. You can sign in again at any time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (shouldLogOut == true && mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil<void>(
        '/login',
        (route) => false,
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _ProfileAppBar extends StatelessWidget {
  const _ProfileAppBar({
    required this.destination,
    required this.onProfile,
  });

  final String destination;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surface,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                Icons.check_rounded,
                color: colors.onPrimaryContainer,
                size: 23,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'TaskFlow',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: colors.primary,
                        ),
                  ),
                  Text(
                    destination,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Search',
              onPressed: () => _showProfileMessage(
                context,
                'Profile search will be available later.',
              ),
              icon: const Icon(Icons.search_rounded),
            ),
            IconButton(
              tooltip: 'Notifications',
              onPressed: () => _showProfileMessage(
                context,
                'You are all caught up!',
              ),
              icon: const Icon(Icons.notifications_none_rounded),
            ),
            const SizedBox(width: 2),
            GestureDetector(
              onTap: onProfile,
              child: CircleAvatar(
                radius: 21,
                backgroundColor: colors.primaryContainer,
                child: Icon(
                  Icons.person_rounded,
                  color: colors.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showProfileMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: const CircleAvatar(
                      radius: 42,
                      backgroundImage: AssetImage(
                        'assets/stitch/taskflow/images/alexa-profile.jpg',
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -1,
                    right: -1,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.edit_rounded,
                        size: 16,
                        color: colors.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          'Alexa Chen',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: ShapeDecoration(
                            color: colors.primaryContainer,
                            shape: const StadiumBorder(),
                          ),
                          child: Text(
                            'PRO',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: colors.onPrimaryContainer),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'alexa.chen@flow.design',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(
                          Icons.workspace_premium_outlined,
                          color: colors.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            'TaskFlow Pro • Annual',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: colors.primary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: colors.surfaceContainer,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: _ProfileMetric(
                    value: '142',
                    label: 'Completed',
                  ),
                ),
                const Expanded(
                  child: _ProfileMetric(
                    value: '12',
                    label: 'Day Streak',
                    icon: Icons.local_fire_department_rounded,
                  ),
                ),
                Expanded(
                  child: _ProfileMetric(
                    value: '98%',
                    label: 'On-time',
                    valueColor: colors.tertiary,
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

class _ProfileMetric extends StatelessWidget {
  const _ProfileMetric({
    required this.value,
    required this.label,
    this.icon,
    this.valueColor,
  });

  final String value;
  final String label;
  final IconData? icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final metricColor = valueColor ?? colors.primary;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: metricColor, size: 17),
              const SizedBox(width: 3),
            ],
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: metricColor,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colors.onSurfaceVariant,
              letterSpacing: 1,
            ),
      ),
    );
  }
}

class _PreferencesCard extends StatelessWidget {
  const _PreferencesCard({
    required this.themeMode,
    required this.notifications,
    required this.soundAndHaptics,
    required this.defaultPriority,
    required this.onThemeChanged,
    required this.onNotificationsChanged,
    required this.onSoundChanged,
    required this.onPriorityChanged,
  });

  final ThemeMode themeMode;
  final bool notifications;
  final bool soundAndHaptics;
  final String defaultPriority;

  final ValueChanged<ThemeMode> onThemeChanged;
  final ValueChanged<bool> onNotificationsChanged;
  final ValueChanged<bool> onSoundChanged;
  final ValueChanged<String?> onPriorityChanged;

  String get themeModeLabel {
    switch (themeMode) {
      case ThemeMode.light:
        return 'Light Mode';
      case ThemeMode.dark:
        return 'Dark Mode';
      case ThemeMode.system:
        return 'System Default';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return _SettingsGroup(
      children: [
        _SettingRow(
          icon: Icons.palette_outlined,
          title: 'Appearance',
          subtitle: themeModeLabel,
          trailing: DropdownButton<ThemeMode>(
            value: themeMode,
            underline: const SizedBox.shrink(),
            borderRadius: BorderRadius.circular(14),
            items: const [
              DropdownMenuItem(
                value: ThemeMode.light,
                child: Text('Light'),
              ),
              DropdownMenuItem(
                value: ThemeMode.dark,
                child: Text('Dark'),
              ),
              DropdownMenuItem(
                value: ThemeMode.system,
                child: Text('System'),
              ),
            ],
            onChanged: (value) {
              if (value != null) onThemeChanged(value);
            },
          ),
        ),
        _SettingRow(
          icon: Icons.notifications_active_outlined,
          title: 'Push Notifications',
          subtitle: 'Daily digest & due date alerts',
          trailing: Switch.adaptive(
            value: notifications,
            onChanged: onNotificationsChanged,
            activeTrackColor: colors.primary,
          ),
        ),
        _SettingRow(
          icon: Icons.vibration_rounded,
          title: 'Sound & Haptic',
          subtitle: 'Tactile touch ticks & chimes',
          trailing: Switch.adaptive(
            value: soundAndHaptics,
            onChanged: onSoundChanged,
            activeTrackColor: colors.primary,
          ),
        ),
        _SettingRow(
          icon: Icons.flag_outlined,
          title: 'Default Priority',
          subtitle: 'Assigned upon fast creation',
          trailing: DropdownButton<String>(
            value: defaultPriority,
            underline: const SizedBox.shrink(),
            borderRadius: BorderRadius.circular(14),
            items: const ['Low', 'Medium', 'High']
                .map(
                  (priority) => DropdownMenuItem(
                    value: priority,
                    child: Text(priority),
                  ),
                )
                .toList(),
            onChanged: onPriorityChanged,
          ),
        ),
      ],
    );
  }
}

class _IntegrationCard extends StatelessWidget {
  const _IntegrationCard({
    required this.calendarSync,
    required this.onCalendarChanged,
    required this.onExport,
  });

  final bool calendarSync;
  final ValueChanged<bool> onCalendarChanged;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return _SettingsGroup(
      children: [
        _SettingRow(
          icon: Icons.calendar_month_outlined,
          iconColor: colors.tertiary,
          iconBackground: colors.surfaceContainerHighest,
          title: 'Google Calendar Sync',
          subtitle: calendarSync
              ? 'Live bi-directional sync'
              : 'Sync is turned off',
          trailing: Switch.adaptive(
            value: calendarSync,
            onChanged: onCalendarChanged,
            activeTrackColor: colors.primary,
          ),
        ),
        _ActionSettingRow(
          icon: Icons.download_rounded,
          title: 'Export Task Archive',
          subtitle: 'Download all tasks as CSV or JSON',
          onTap: onExport,
        ),
      ],
    );
  }
}

class _SupportCard extends StatelessWidget {
  const _SupportCard({
    required this.onHelp,
    required this.onPrivacy,
  });

  final VoidCallback onHelp;
  final VoidCallback onPrivacy;

  @override
  Widget build(BuildContext context) {
    return _SettingsGroup(
      children: [
        _ActionSettingRow(
          icon: Icons.help_outline_rounded,
          title: 'Help Center & Tutorials',
          subtitle: 'Guides, keyboard shortcuts & tips',
          onTap: onHelp,
          trailingIcon: Icons.open_in_new_rounded,
        ),
        _ActionSettingRow(
          icon: Icons.policy_outlined,
          title: 'Terms & Privacy Policy',
          subtitle: 'GDPR compliance & legal terms',
          onTap: onPrivacy,
        ),
        const _SettingRow(
          icon: Icons.info_outline_rounded,
          title: 'App Version',
          trailing: _VersionBadge(),
        ),
      ],
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.035),
            blurRadius: 9,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.trailing,
    this.iconColor,
    this.iconBackground,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget trailing;
  final Color? iconColor;
  final Color? iconBackground;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: Row(
        children: [
          _SettingIcon(
            icon: icon,
            color: iconColor ?? colors.primary,
            background: iconBackground ?? colors.surfaceContainerHighest,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colors.onSurface,
                      ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}

class _ActionSettingRow extends StatelessWidget {
  const _ActionSettingRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailingIcon = Icons.chevron_right_rounded,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final IconData trailingIcon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          child: Row(
            children: [
              _SettingIcon(
                icon: icon,
                color: colors.primary,
                background: colors.surfaceContainerHighest,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: colors.onSurface,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                trailingIcon,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingIcon extends StatelessWidget {
  const _SettingIcon({
    required this.icon,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: color,
        size: 21,
      ),
    );
  }
}

class _VersionBadge extends StatelessWidget {
  const _VersionBadge();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: ShapeDecoration(
        color: colors.surfaceContainerHighest,
        shape: const StadiumBorder(),
      ),
      child: Text(
        '2.4.0 (Build 182)',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
      ),
    );
  }
}

class _DestinationPlaceholder extends StatelessWidget {
  const _DestinationPlaceholder({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            color: colors.primary,
            size: 44,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: colors.onSurface,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'This section will be available soon.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
