import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/taskflow_theme.dart';
import '../data/models/task.dart';
import '../providers/task_provider.dart';
import '../widgets/taskflow_bottom_navigation_bar.dart';
import 'add_task_screen.dart';
import 'calendar_screen.dart';
import 'profile_screen.dart';
import 'statistics_screen.dart';
import 'tasks_screen.dart';
import '../widgets/taskflow_empty_state.dart';

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
      MaterialPageRoute<void>(builder: (_) => const AddTaskScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Home', 'Tasks', 'Calendar', 'Statistics', 'Profile'];

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
                  : _DestinationPlaceholder(title: titles[_selectedTab]),
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
    final filteredTasks = _tasks.where((task) {
      final query = _searchController.text.trim().toLowerCase();
      final matchesSearch =
          query.isEmpty ||
          task.title.toLowerCase().contains(query) ||
          task.category.toLowerCase().contains(query);
      final matchesFilter = switch (_selectedFilter) {
        1 =>
          task.dueDate != null &&
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
                  taskCount: context.watch<TaskProvider>().pendingCount,
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
                  completedCount: context.watch<TaskProvider>().completedCount,
                  pendingCount: context.watch<TaskProvider>().pendingCount,
                  totalCount: context.watch<TaskProvider>().totalTasks,
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
                  onSelect: (index) => setState(() => _selectedFilter = index),
                ),
                const SizedBox(height: 26),
                Row(
                  children: [
                    Text(
                      "Today's Focus",
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(width: 12),
                    _CountBadge(
                      count: context.watch<TaskProvider>().pendingCount,
                    ),
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
                        : () => setState(() {
                            _searchController.clear();
                            _selectedFilter = 0;
                          }),
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
            : SnackBarAction(label: 'Retry', onPressed: onRetry),
      ),
    );
  }

  Future<void> _editTask(Task task) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => AddTaskScreen(taskToEdit: task)),
    );
  }

  Future<void> _toggleTask(Task task) async {
    final provider = context.read<TaskProvider>();
    final changed = await provider.toggleTaskCompletion(task.id);
    if (!changed && mounted) {
      _showInfo(
        provider.errorMessage ?? 'Could not update task. Please try again.',
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
      final deleted = await context.read<TaskProvider>().deleteTask(task.id);
      if (!deleted && mounted) {
        _showInfo(
          context.read<TaskProvider>().errorMessage ??
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
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            setState(() => _selectedTab = 0);
          },
          onTasksSelected: () {
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            setState(() => _selectedTab = 0);
            _openTasks();
          },
          onCalendarSelected: () {
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
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
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            setState(() => _selectedTab = 0);
          },
          onTasksSelected: () {
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            setState(() => _selectedTab = 0);
            _openTasks();
          },
          onCalendarSelected: () {
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            setState(() => _selectedTab = 0);
            _openCalendar();
          },
          onStatisticsSelected: () {
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
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
                  'Home',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: TaskFlowColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onSearchToggle,
            tooltip: searchOpen ? 'Close search' : 'Search tasks',
            icon: Icon(searchOpen ? Icons.close_rounded : Icons.search_rounded),
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
              backgroundColor: const Color(0xFFE3DFFF),
              child: ClipOval(
                child: Image.asset(
                  'assets/stitch/taskflow/images/alexa-profile.jpg',
                  width: 38,
                  height: 38,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.person_rounded,
                    color: TaskFlowColors.primary,
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

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({required this.taskCount, required this.compact});

  final int taskCount;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good morning, Alexa! ☀️',
                style:
                    (compact
                            ? textTheme.headlineMedium
                            : textTheme.headlineLarge)
                        ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 5),
              Text.rich(
                TextSpan(
                  style: textTheme.bodyLarge?.copyWith(
                    color: TaskFlowColors.secondaryText,
                  ),
                  children: [
                    const TextSpan(text: 'Tuesday, Oct 24  •  '),
                    TextSpan(
                      text: '$taskCount tasks left',
                      style: const TextStyle(
                        color: TaskFlowColors.primary,
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
        _ProfileAvatar(radius: 28),
      ],
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.radius});

  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(2),
    decoration: const BoxDecoration(
      color: Color(0xFFE3DFFF),
      shape: BoxShape.circle,
    ),
    child: CircleAvatar(
      radius: radius,
      backgroundColor: TaskFlowColors.lavenderContainer,
      backgroundImage: const AssetImage(
        'assets/stitch/taskflow/images/alexa-dashboard.jpg',
      ),
      onBackgroundImageError: (_, _) {},
    ),
  );
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
    final textTheme = Theme.of(context).textTheme;
    final progress = totalCount == 0 ? 0.0 : completedCount / totalCount;
    final percentage = (progress * 100).floor();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEFEBFF),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: TaskFlowColors.primary.withValues(alpha: 0.06),
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
                      style: textTheme.labelSmall?.copyWith(letterSpacing: 1.1),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$percentage% Completed',
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$completedCount of $totalCount tasks completed',
                      style: textTheme.bodyMedium,
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
                      backgroundColor: const Color(0xFFDAD6FF),
                      color: TaskFlowColors.primary,
                    ),
                    const Icon(
                      Icons.bolt_rounded,
                      color: TaskFlowColors.primary,
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
                  iconColor: Color(0xFFB3261E),
                  iconBackground: Color(0xFFFFE4E1),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  value: '$pendingCount',
                  label: 'Pending',
                  icon: Icons.hourglass_top_rounded,
                  iconColor: TaskFlowColors.primary,
                  iconBackground: Color(0xFFE3DFFF),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  value: '$completedCount',
                  label: 'Done',
                  icon: Icons.check_circle_outline_rounded,
                  iconColor: TaskFlowColors.tertiary,
                  iconBackground: Color(0xFFB7F7DF),
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
    required this.iconBackground,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: iconBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: Theme.of(context).textTheme.titleLarge),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall,
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

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.selectedIndex, required this.onSelect});

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
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
    final selected = index == selectedIndex;
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => onSelect(index),
      avatar: Icon(
        icon,
        size: 18,
        color: selected ? Colors.white : TaskFlowColors.secondaryText,
      ),
      label: Text(label),
      labelStyle: TextStyle(
        color: selected ? Colors.white : TaskFlowColors.secondaryText,
        fontWeight: FontWeight.w500,
      ),
      selectedColor: TaskFlowColors.primary,
      backgroundColor: const Color(0xFFEFEBFF),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
    final textTheme = Theme.of(context).textTheme;
    final priorityText =
        '${task.priority.name[0].toUpperCase()}${task.priority.name.substring(1)} Priority';
    final priorityColor = switch (task.priority) {
      TaskPriority.high => const Color(0xFFB3261E),
      TaskPriority.medium => TaskFlowColors.primary,
      TaskPriority.low => TaskFlowColors.tertiary,
    };
    final priorityBackground = switch (task.priority) {
      TaskPriority.high => const Color(0xFFFFE0DD),
      TaskPriority.medium => const Color(0xFFE3DFFF),
      TaskPriority.low => const Color(0xFFB7F7DF),
    };
    final time = task.dueTime == null
        ? 'No time set'
        : '${task.dueTime!.hourOfPeriod == 0 ? 12 : task.dueTime!.hourOfPeriod}:${task.dueTime!.minute.toString().padLeft(2, '0')} ${task.dueTime!.period == DayPeriod.am ? 'AM' : 'PM'}';

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: TaskFlowColors.mainText.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(width: 6, color: priorityColor),
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
                      activeColor: TaskFlowColors.tertiary,
                      shape: const CircleBorder(),
                      side: const BorderSide(
                        color: TaskFlowColors.outlineVariant,
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
                            style: textTheme.titleLarge?.copyWith(
                              decoration: task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: task.isCompleted
                                  ? TaskFlowColors.outline
                                  : TaskFlowColors.mainText,
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
                                    : Icons.menu_rounded,
                                color: priorityColor,
                                background: priorityBackground,
                              ),
                              _TaskPill(
                                label: task.category,
                                icon: Icons.work_outline_rounded,
                                color: TaskFlowColors.secondaryText,
                                background: const Color(0xFFE9E5FF),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.access_time_rounded,
                                    size: 17,
                                    color: TaskFlowColors.secondaryText,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    time,
                                    style: textTheme.labelMedium?.copyWith(
                                      color: TaskFlowColors.secondaryText,
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
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
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
    required this.background,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: background,
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

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: const ShapeDecoration(
      color: Color(0xFFE3DFFF),
      shape: StadiumBorder(),
    ),
    child: Text(
      '$count Active',
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: TaskFlowColors.primary,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _StreakReminderCard extends StatelessWidget {
  const _StreakReminderCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: TaskFlowColors.lavenderContainer,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            color: Color(0xFFE3DFFF),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.workspace_premium_outlined,
            color: TaskFlowColors.primary,
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
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 3),
              Text(
                'Finish 2 more tasks to preserve your 6-day streak.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
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
