import 'package:flutter/material.dart';

import '../core/theme/taskflow_theme.dart';
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
  bool _darkMode = false;
  bool _notifications = true;
  bool _soundAndHaptics = true;
  bool _calendarSync = true;
  String _defaultPriority = 'Medium';

  @override
  Widget build(BuildContext context) {
    const destinations = ['Home', 'Tasks', 'Calendar', 'Statistics', 'Profile'];
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
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
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
                  darkMode: _darkMode,
                  notifications: _notifications,
                  soundAndHaptics: _soundAndHaptics,
                  defaultPriority: _defaultPriority,
                  onDarkModeChanged: (value) =>
                      setState(() => _darkMode = value),
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
                      backgroundColor: const Color(0xFFFFEBEE),
                      foregroundColor: const Color(0xFFBA1A1A),
                      textStyle: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ),
                if (constraints.maxWidth > 760) const SizedBox(height: 8),
              ],
            ),
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
        icon: const Icon(Icons.logout_rounded, color: Color(0xFFBA1A1A)),
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
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFBA1A1A),
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (shouldLogOut == true && mounted) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil<void>('/login', (route) => false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

class _ProfileAppBar extends StatelessWidget {
  const _ProfileAppBar({required this.destination, required this.onProfile});

  final String destination;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) => Material(
    color: TaskFlowColors.background.withValues(alpha: 0.96),
    elevation: 1,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: TaskFlowColors.primary,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
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
                    color: TaskFlowColors.primary,
                  ),
                ),
                Text(
                  destination,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: TaskFlowColors.secondaryText,
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
            onPressed: () =>
                _showProfileMessage(context, 'You are all caught up!'),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          const SizedBox(width: 2),
          GestureDetector(
            onTap: onProfile,
            child: const CircleAvatar(
              radius: 21,
              backgroundColor: Color(0xFFE3DFFF),
              child: Icon(Icons.person_rounded, color: TaskFlowColors.primary),
            ),
          ),
        ],
      ),
    ),
  );
}

void _showProfileMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
  );
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: TaskFlowColors.mainText.withValues(alpha: 0.05),
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
                  decoration: const BoxDecoration(
                    color: TaskFlowColors.lavenderContainer,
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
                    decoration: const BoxDecoration(
                      color: TaskFlowColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      size: 16,
                      color: Colors.white,
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
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: const ShapeDecoration(
                          color: Color(0xFFE3DFFF),
                          shape: StadiumBorder(),
                        ),
                        child: Text(
                          'PRO',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: TaskFlowColors.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'alexa.chen@flow.design',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(
                        Icons.workspace_premium_outlined,
                        color: TaskFlowColors.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          'TaskFlow Pro • Annual',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: TaskFlowColors.primary),
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            color: TaskFlowColors.lavenderContainer,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Row(
            children: [
              Expanded(
                child: _ProfileMetric(value: '142', label: 'Completed'),
              ),
              Expanded(
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
                  valueColor: TaskFlowColors.tertiary,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ProfileMetric extends StatelessWidget {
  const _ProfileMetric({
    required this.value,
    required this.label,
    this.icon,
    this.valueColor = TaskFlowColors.primary,
  });

  final String value;
  final String label;
  final IconData? icon;
  final Color valueColor;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: valueColor, size: 17),
            const SizedBox(width: 3),
          ],
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      const SizedBox(height: 3),
      Text(
        label,
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: TaskFlowColors.secondaryText),
      ),
    ],
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: TaskFlowColors.secondaryText,
        letterSpacing: 1,
      ),
    ),
  );
}

class _PreferencesCard extends StatelessWidget {
  const _PreferencesCard({
    required this.darkMode,
    required this.notifications,
    required this.soundAndHaptics,
    required this.defaultPriority,
    required this.onDarkModeChanged,
    required this.onNotificationsChanged,
    required this.onSoundChanged,
    required this.onPriorityChanged,
  });

  final bool darkMode;
  final bool notifications;
  final bool soundAndHaptics;
  final String defaultPriority;
  final ValueChanged<bool> onDarkModeChanged;
  final ValueChanged<bool> onNotificationsChanged;
  final ValueChanged<bool> onSoundChanged;
  final ValueChanged<String?> onPriorityChanged;

  @override
  Widget build(BuildContext context) => _SettingsGroup(
    children: [
      _SettingRow(
        icon: Icons.dark_mode_outlined,
        title: 'Dark Mode',
        subtitle: darkMode
            ? 'On • Local preview only'
            : 'Off • Light Lavender theme',
        trailing: Switch.adaptive(
          value: darkMode,
          onChanged: onDarkModeChanged,
          activeTrackColor: TaskFlowColors.primary,
        ),
      ),
      _SettingRow(
        icon: Icons.notifications_active_outlined,
        title: 'Push Notifications',
        subtitle: 'Daily digest & due date alerts',
        trailing: Switch.adaptive(
          value: notifications,
          onChanged: onNotificationsChanged,
          activeTrackColor: TaskFlowColors.primary,
        ),
      ),
      _SettingRow(
        icon: Icons.vibration_rounded,
        title: 'Sound & Haptic',
        subtitle: 'Tactile touch ticks & chimes',
        trailing: Switch.adaptive(
          value: soundAndHaptics,
          onChanged: onSoundChanged,
          activeTrackColor: TaskFlowColors.primary,
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
                (priority) =>
                    DropdownMenuItem(value: priority, child: Text(priority)),
              )
              .toList(),
          onChanged: onPriorityChanged,
        ),
      ),
    ],
  );
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
  Widget build(BuildContext context) => _SettingsGroup(
    children: [
      _SettingRow(
        icon: Icons.calendar_month_outlined,
        iconColor: TaskFlowColors.tertiary,
        iconBackground: const Color(0xFFE0F5ED),
        title: 'Google Calendar Sync',
        subtitle: calendarSync
            ? 'Live bi-directional sync'
            : 'Sync is turned off',
        trailing: Switch.adaptive(
          value: calendarSync,
          onChanged: onCalendarChanged,
          activeTrackColor: TaskFlowColors.primary,
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

class _SupportCard extends StatelessWidget {
  const _SupportCard({required this.onHelp, required this.onPrivacy});

  final VoidCallback onHelp;
  final VoidCallback onPrivacy;

  @override
  Widget build(BuildContext context) => _SettingsGroup(
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

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: TaskFlowColors.mainText.withValues(alpha: 0.035),
          blurRadius: 9,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(children: children),
  );
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.trailing,
    this.iconColor = TaskFlowColors.primary,
    this.iconBackground = TaskFlowColors.lavenderContainer,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget trailing;
  final Color iconColor;
  final Color iconBackground;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(
      children: [
        _SettingIcon(icon: icon, color: iconColor, background: iconBackground),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
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
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _SettingIcon(icon: icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 3),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(trailingIcon, color: TaskFlowColors.secondaryText),
          ],
        ),
      ),
    ),
  );
}

class _SettingIcon extends StatelessWidget {
  const _SettingIcon({
    required this.icon,
    this.color = TaskFlowColors.primary,
    this.background = TaskFlowColors.lavenderContainer,
  });

  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
    width: 42,
    height: 42,
    decoration: BoxDecoration(color: background, shape: BoxShape.circle),
    child: Icon(icon, color: color, size: 21),
  );
}

class _VersionBadge extends StatelessWidget {
  const _VersionBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: const ShapeDecoration(
      color: TaskFlowColors.lavenderContainer,
      shape: StadiumBorder(),
    ),
    child: Text(
      '2.4.0 (Build 182)',
      style: Theme.of(
        context,
      ).textTheme.labelMedium?.copyWith(color: TaskFlowColors.secondaryText),
    ),
  );
}

class _DestinationPlaceholder extends StatelessWidget {
  const _DestinationPlaceholder({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.auto_awesome_outlined,
          color: TaskFlowColors.primary,
          size: 44,
        ),
        const SizedBox(height: 12),
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text(
          'This section will be available soon.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    ),
  );
}
