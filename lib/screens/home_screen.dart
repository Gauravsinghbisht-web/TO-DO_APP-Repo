
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/models/task.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/taskflow_bottom_navigation_bar.dart';
import '../widgets/taskflow_empty_state.dart';
import 'add_task_screen.dart';
import 'calendar_screen.dart';
import 'profile_screen.dart';
import 'statistics_screen.dart';
import 'tasks_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  int _selectedTab = 0;
  int _selectedFilter = 0;
  bool _searchOpen = false;

  List<Task> get _tasks => context.watch<TaskProvider>().tasks;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addTask() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const AddTaskScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titles = [
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
            _DashboardAppBar(
              searchOpen: _searchOpen,
              onSearchToggle: () => setState(() {
                _searchOpen = !_searchOpen;
                if (!_searchOpen) _searchController.clear();
              }),
              onNotifications: () => _showInfo('You are all caught up!'),
              onProfile: _openProfile,
            ),
            Expanded(
              child: _selectedTab == 0
                  ? _buildDashboard(context)
                  : _DestinationPlaceholder(
                      title: titles[_selectedTab],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: _selectedTab == 0
          ? FloatingActionButton.extended(
              onPressed: _addTask,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Task'),
              elevation: 5,
            )
          : null,
      bottomNavigationBar: TaskFlowBottomNavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) {
          if (index == 1) {
            _openTasks();
          } else if (index == 2) {
            _openCalendar();
          } else if (index == 3) {
            _openStatistics();
          } else if (index == 4) {
            _openProfile();
          } else {
            setState(() => _selectedTab = index);
          }
        },
      ),
    );
  }

  Widget _buildDashboard(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();

    final filteredTasks = _tasks.where((task) {
      final query = _searchController.text.trim().toLowerCase();

      final matchesSearch = query.isEmpty ||
          task.title.toLowerCase().contains(query) ||
          task.category.toLowerCase().contains(query);

      final matchesFilter = switch (_selectedFilter) {
        1 => task.dueDate != null &&
            DateUtils.isSameDay(
              task.dueDate,
              DateTime.now().add(const Duration(days: 1)),
            ),
        2 => task.priority == TaskPriority.high,
        _ => true,
      };

      return matchesSearch && matchesFilter;
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _GreetingHeader(
                  taskCount: taskProvider.pendingCount,
                  compact: constraints.maxWidth < 360,
                ),
                if (_searchOpen) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search tasks',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                _DailyProgressCard(
                  completedCount: taskProvider.completedCount,
                  pendingCount: taskProvider.pendingCount,
                  totalCount: taskProvider.totalTasks,
                  highPriorityCount: _tasks
                      .where(
                        (task) =>
                            task.priority == TaskPriority.high &&
                            !task.isCompleted,
                      )
                      .length,
                ),
                const SizedBox(height: 20),
                _FilterRow(
                  selectedIndex: _selectedFilter,
                  onSelect: (index) {
                    setState(() => _selectedFilter = index);
                  },
                ),
                const SizedBox(height: 26),
                Row(
                  children: [
                    Text(
                      "Today's Focus",
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(width: 12),
                    _CountBadge(count: taskProvider.pendingCount),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _openTasks,
                      label: const Text('See All'),
                      iconAlignment: IconAlignment.end,
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (filteredTasks.isEmpty)
                  TaskFlowEmptyState(
                    icon: _tasks.isEmpty
                        ? Icons.add_task_rounded
                        : _searchController.text.trim().isNotEmpty
                            ? Icons.search_off_rounded
                            : Icons.filter_alt_off_rounded,
                    title: _tasks.isEmpty
                        ? 'No tasks yet'
                        : _searchController.text.trim().isNotEmpty
                            ? 'No matching tasks'
                            : 'No tasks in this view',
                    message: _tasks.isEmpty
                        ? 'Add a task to start shaping your day.'
                        : _searchController.text.trim().isNotEmpty
                            ? 'Try another search, or clear it to see all tasks.'
                            : 'There are no tasks for the selected filter.',
                    actionLabel: _tasks.isEmpty
                        ? 'Add Task'
                        : _searchController.text.trim().isNotEmpty
                            ? 'Clear Search & Filters'
                            : 'Clear Filter',
                    actionIcon: _tasks.isEmpty
                        ? Icons.add_rounded
                        : Icons.filter_alt_off_rounded,
                    onAction: _tasks.isEmpty
                        ? _addTask
                        : () {
                            _searchController.clear();
                            setState(() => _selectedFilter = 0);
                          },
                  )
                else
                  ...filteredTasks.map(
                    (task) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _TaskCard(
                        task: task,
                        onChanged: (_) => _toggleTask(task),
                        onEdit: () => _editTask(task),
                        onDelete: () => _deleteTask(task),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                const _StreakReminderCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showInfo(String message, {VoidCallback? onRetry}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        action: onRetry == null
            ? null
            : SnackBarAction(
                label: 'Retry',
                onPressed: onRetry,
              ),
      ),
    );
  }

  Future<void> _editTask(Task task) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AddTaskScreen(taskToEdit: task),
      ),
    );
  }

  Future<void> _toggleTask(Task task) async {
    final provider = context.read<TaskProvider>();
    final changed = await provider.toggleTaskCompletion(task.id);

    if (!changed && mounted) {
      _showInfo(
        provider.errorMessage ??
            'Could not update task. Please try again.',
        onRetry: () => _toggleTask(task),
      );
    }
  }

  Future<void> _deleteTask(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('“${task.title}” will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = context.read<TaskProvider>();
      final deleted = await provider.deleteTask(task.id);

      if (!deleted && mounted) {
        _showInfo(
          provider.errorMessage ??
              'Could not delete task. Please try again.',
          onRetry: () => _deleteTask(task),
        );
      }
    }
  }

  void _openTasks() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => TasksScreen(
          onHomeSelected: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
            setState(() => _selectedTab = 0);
          },
        ),
      ),
    );
  }

  void _openCalendar() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CalendarScreen(
          onHomeSelected: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
            setState(() => _selectedTab = 0);
          },
          onTasksSelected: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
            setState(() => _selectedTab = 0);
            _openTasks();
          },
        ),
      ),
    );
  }

  void _openStatistics() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => StatisticsScreen(
          onHomeSelected: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
            setState(() => _selectedTab = 0);
          },
          onTasksSelected: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
            setState(() => _selectedTab = 0);
            _openTasks();
          },
          onCalendarSelected: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
            setState(() => _selectedTab = 0);
            _openCalendar();
          },
        ),
      ),
    );
  }

  void _openProfile() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ProfileScreen(
          onHomeSelected: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
            setState(() => _selectedTab = 0);
          },
          onTasksSelected: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
            setState(() => _selectedTab = 0);
            _openTasks();
          },
          onCalendarSelected: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
            setState(() => _selectedTab = 0);
            _openCalendar();
          },
          onStatisticsSelected: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
            setState(() => _selectedTab = 0);
            _openStatistics();
          },
        ),
      ),
    );
  }
}

class _DashboardAppBar extends StatelessWidget {
  const _DashboardAppBar({
    required this.searchOpen,
    required this.onSearchToggle,
    required this.onNotifications,
    required this.onProfile,
  });

  final bool searchOpen;
  final VoidCallback onSearchToggle;
  final VoidCallback onNotifications;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.check_rounded,
                color: scheme.onPrimary,
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
                          color: scheme.primary,
                        ),
                  ),
                  Text(
                    'Home',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onSearchToggle,
              tooltip: searchOpen ? 'Close search' : 'Search tasks',
              icon: Icon(
                searchOpen ? Icons.close_rounded : Icons.search_rounded,
              ),
            ),
            IconButton(
              onPressed: onNotifications,
              tooltip: 'Notifications',
              icon: const Icon(Icons.notifications_none_rounded),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onProfile,
              child: CircleAvatar(
                radius: 21,
                backgroundColor: scheme.primaryContainer,
                child: ClipOval(
                  child: Image.asset(
                    'assets/stitch/taskflow/images/alexa-profile.jpg',
                    width: 38,
                    height: 38,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Icon(
                      Icons.person_rounded,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({
    required this.taskCount,
    required this.compact,
  });

  final int taskCount;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthProvider>().user;

    final userName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : 'User';

    final hour = DateTime.now().hour;

    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting, $userName! 👋',
                style: (compact
                        ? theme.textTheme.headlineMedium
                        : theme.textTheme.headlineLarge)
                    ?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              Text.rich(
                TextSpan(
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  children: [
                    TextSpan(
                      text:
                          '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}  •  ',
                    ),
                    TextSpan(
                      text: '$taskCount tasks left',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: ' for today'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        const _ProfileAvatar(radius: 28),
      ],
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.radius});

  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: scheme.surfaceContainerHighest,
        backgroundImage: const AssetImage(
          'assets/stitch/taskflow/images/alexa-dashboard.jpg',
        ),
        onBackgroundImageError: (_, _) {},
      ),
    );
  }
}

class _DailyProgressCard extends StatelessWidget {
  const _DailyProgressCard({
    required this.completedCount,
    required this.pendingCount,
    required this.totalCount,
    required this.highPriorityCount,
  });

  final int completedCount;
  final int pendingCount;
  final int totalCount;
  final int highPriorityCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final progress = totalCount == 0
        ? 0.0
        : completedCount / totalCount;

    final percentage = (progress * 100).floor();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DAILY MOMENTUM',
                      style: theme.textTheme.labelSmall?.copyWith(
                        letterSpacing: 1.1,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$percentage% Completed',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$completedCount of $totalCount tasks completed',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 70,
                height: 70,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 7,
                      strokeCap: StrokeCap.round,
                      backgroundColor: scheme.surfaceContainerHighest,
                      color: scheme.primary,
                    ),
                    Icon(
                      Icons.bolt_rounded,
                      color: scheme.primary,
                      size: 26,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  value: '$highPriorityCount',
                  label: 'Priority',
                  icon: Icons.local_fire_department_rounded,
                  iconColor: scheme.error,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  value: '$pendingCount',
                  label: 'Pending',
                  icon: Icons.hourglass_top_rounded,
                  iconColor: scheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  value: '$completedCount',
                  label: 'Done',
                  icon: Icons.check_circle_outline_rounded,
                  iconColor: Colors.green.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.selectedIndex,
    required this.onSelect,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            index: 0,
            selectedIndex: selectedIndex,
            label: 'Today',
            icon: Icons.today_rounded,
            onSelect: onSelect,
          ),
          const SizedBox(width: 10),
          _FilterChip(
            index: 1,
            selectedIndex: selectedIndex,
            label: 'Upcoming',
            icon: Icons.event_repeat_rounded,
            onSelect: onSelect,
          ),
          const SizedBox(width: 10),
          _FilterChip(
            index: 2,
            selectedIndex: selectedIndex,
            label: 'High Priority',
            icon: Icons.flag_outlined,
            onSelect: onSelect,
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.index,
    required this.selectedIndex,
    required this.label,
    required this.icon,
    required this.onSelect,
  });

  final int index;
  final int selectedIndex;
  final String label;
  final IconData icon;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selected = index == selectedIndex;

    return ChoiceChip(
      selected: selected,
      onSelected: (_) => onSelect(index),
      avatar: Icon(
        icon,
        size: 18,
        color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
      ),
      label: Text(label),
      labelStyle: TextStyle(
        color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
        fontWeight: FontWeight.w500,
      ),
      selectedColor: scheme.primary,
      backgroundColor: scheme.surfaceContainer,
      side: BorderSide(
        color: selected
            ? Colors.transparent
            : scheme.outlineVariant.withValues(alpha: 0.4),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 8,
      ),
      shape: const StadiumBorder(),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.onChanged,
    required this.onEdit,
    required this.onDelete,
  });

  final Task task;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final priorityText =
        '${task.priority.name[0].toUpperCase()}${task.priority.name.substring(1)} Priority';

    final priorityColor = switch (task.priority) {
      TaskPriority.high => scheme.error,
      TaskPriority.medium => scheme.primary,
      TaskPriority.low => Colors.green.shade600,
    };

    final time = task.dueTime == null
        ? 'No time set'
        : '${task.dueTime!.hourOfPeriod == 0 ? 12 : task.dueTime!.hourOfPeriod}:${task.dueTime!.minute.toString().padLeft(2, '0')} ${task.dueTime!.period == DayPeriod.am ? 'AM' : 'PM'}';

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 6,
              color: priorityColor,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox.adaptive(
                      value: task.isCompleted,
                      onChanged: onChanged,
                      visualDensity: VisualDensity.compact,
                      activeColor: scheme.primary,
                      shape: const CircleBorder(),
                      side: BorderSide(
                        color: scheme.outline,
                        width: 2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              decoration: task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: task.isCompleted
                                  ? scheme.onSurfaceVariant
                                  : scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _TaskPill(
                                label: priorityText,
                                icon: task.priority == TaskPriority.high
                                    ? Icons.priority_high_rounded
                                    : Icons.flag_outlined,
                                color: priorityColor,
                              ),
                              _TaskPill(
                                label: task.category,
                                icon: Icons.work_outline_rounded,
                                color: scheme.onSurfaceVariant,
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 17,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    time,
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'Task actions',
                      onSelected: (action) {
                        if (action == 'edit') onEdit();
                        if (action == 'delete') onDelete();
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
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

class _TaskPill extends StatelessWidget {
  const _TaskPill({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 5,
      ),
      decoration: ShapeDecoration(
        color: scheme.primaryContainer,
        shape: const StadiumBorder(),
      ),
      child: Text(
        '$count Active',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _StreakReminderCard extends StatelessWidget {
  const _StreakReminderCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.workspace_premium_outlined,
              color: scheme.onSecondaryContainer,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Almost there!',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: scheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Finish 2 more tasks to preserve your 6-day streak.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSecondaryContainer,
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

class _DestinationPlaceholder extends StatelessWidget {
  const _DestinationPlaceholder({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            color: scheme.primary,
            size: 44,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'This section will be available soon.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
