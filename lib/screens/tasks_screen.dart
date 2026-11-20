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
import '../widgets/taskflow_empty_state.dart';

enum _TaskStatus { pending, done }

enum _TaskPriority { high, medium, low }

class _TaskItem {
  _TaskItem(this.task);
  final Task task;
  String get title => task.title;
  String get description => task.description;
  String get category => task.category;
  String get due => _formatTaskDue(task);
  _TaskPriority get priority => switch (task.priority) {
    TaskPriority.high => _TaskPriority.high,
    TaskPriority.medium => _TaskPriority.medium,
    TaskPriority.low => _TaskPriority.low,
  };
  List<String> get subtasks => task.subtasks;
  bool get reminderEnabled => false;
  String get repeat => task.recurrenceType.label;
  int get estimatedMinutes => 30;
  _TaskStatus get status =>
      task.isCompleted ? _TaskStatus.done : _TaskStatus.pending;
}

String _formatTaskDue(Task task) {
  if (task.dueDate == null) return 'No due date';
  final date = task.dueDate!;
  final today = DateUtils.dateOnly(DateTime.now());
  final day = DateUtils.dateOnly(date);
  final dayLabel = day == today
      ? 'Today'
      : day == today.add(const Duration(days: 1))
      ? 'Tomorrow'
      : '${day.month}/${day.day}/${day.year}';
  final dueTime = task.dueTime;
  final time = dueTime == null
      ? ''
      : '${dueTime.hourOfPeriod == 0 ? 12 : dueTime.hourOfPeriod}:${dueTime.minute.toString().padLeft(2, '0')} ${dueTime.period == DayPeriod.am ? 'AM' : 'PM'}';
  return '$dayLabel${time.isEmpty ? '' : ', $time'}';
}

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key, this.onHomeSelected});

  final VoidCallback? onHomeSelected;

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final _searchController = TextEditingController();
  int _selectedStatus = 0;
  String _selectedCategory = 'All Categories';
  int _selectedDestination = 1;

  List<_TaskItem> get _tasks => context
      .watch<TaskProvider>()
      .tasks
      .map(_TaskItem.new)
      .toList(growable: false);

  static const _defaultCategories = [
    'All Categories',
    'Work',
    'Personal',
    'Design',
    'Health',
    'Fitness',
    'Study',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_TaskItem> get _visibleTasks {
    final query = _searchController.text.trim().toLowerCase();
    return _tasks.where((task) {
      final matchesStatus = switch (_selectedStatus) {
        1 => task.status == _TaskStatus.pending,
        2 => task.status == _TaskStatus.done,
        _ => true,
      };
      final matchesCategory =
          _selectedCategory == 'All Categories' ||
          task.category == _selectedCategory;
      final matchesSearch =
          query.isEmpty ||
          task.title.toLowerCase().contains(query) ||
          task.description.toLowerCase().contains(query) ||
          task.category.toLowerCase().contains(query);
      return matchesStatus && matchesCategory && matchesSearch;
    }).toList();
  }

  List<String> get _categories => [
    'All Categories',
    ...<String>{
      ..._defaultCategories.skip(1),
      ..._tasks.map((task) => task.category),
    },
  ];

  int _countForStatus(int status) => _tasks.where((task) {
    return switch (status) {
      1 => task.status == _TaskStatus.pending,
      2 => task.status == _TaskStatus.done,
      _ => true,
    };
  }).length;

  @override
  Widget build(BuildContext context) {
    final visible = _visibleTasks;
    final highPriority = visible
        .where(
          (task) =>
              task.priority == _TaskPriority.high &&
              task.status == _TaskStatus.pending,
        )
        .toList();
    final inProgress = visible
        .where(
          (task) =>
              task.priority != _TaskPriority.high &&
              task.status == _TaskStatus.pending,
        )
        .toList();
    final completed = visible
        .where((task) => task.status == _TaskStatus.done)
        .toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _TasksAppBar(onProfile: _openProfile),
            Expanded(
              child: _selectedDestination == 1
                  ? _buildTaskList(context, highPriority, inProgress, completed)
                  : _OtherDestination(
                      title: _destinationName(_selectedDestination),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: _selectedDestination == 1
          ? FloatingActionButton(
              onPressed: _addTask,
              tooltip: 'Add Task',
              child: const Icon(Icons.add_rounded, size: 32),
            )
          : null,
      bottomNavigationBar: TaskFlowBottomNavigationBar(
        selectedIndex: _selectedDestination,
        onDestinationSelected: _onDestinationSelected,
      ),
    );
  }

  Widget _buildTaskList(
    BuildContext context,
    List<_TaskItem> highPriority,
    List<_TaskItem> inProgress,
    List<_TaskItem> completed,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final hasNoTasks = context.watch<TaskProvider>().totalTasks == 0;
    final hasSearch = _searchController.text.trim().isNotEmpty;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('All Tasks', style: textTheme.headlineMedium),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search tasks, tags, projects...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _searchController.text.isEmpty
                              ? const Icon(Icons.mic_none_rounded)
                              : IconButton(
                                  tooltip: 'Clear search',
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                ),
                          filled: true,
                          fillColor: TaskFlowColors.lavenderContainer,
                          enabledBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(28)),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28),
                            borderSide: const BorderSide(
                              color: TaskFlowColors.primary,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Material(
                      color: const Color(0xFFEFEBFF),
                      shape: const CircleBorder(),
                      child: IconButton(
                        tooltip: 'Filter tasks',
                        onPressed: () => _showMessage(
                          'Use the status and category filters below.',
                        ),
                        icon: const Icon(Icons.tune_rounded),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _StatusSelector(
                  selectedIndex: _selectedStatus,
                  counts: [
                    _countForStatus(0),
                    _countForStatus(1),
                    _countForStatus(2),
                  ],
                  onSelected: (index) =>
                      setState(() => _selectedStatus = index),
                ),
                const SizedBox(height: 12),
                _CategorySelector(
                  categories: _categories,
                  selectedCategory: _selectedCategory,
                  categoryCounts: {
                    for (final category in _categories.skip(1))
                      category: _tasks
                          .where((task) => task.category == category)
                          .length,
                  },
                  onSelected: (category) =>
                      setState(() => _selectedCategory = category),
                ),
                const SizedBox(height: 20),
                const _FocusPeakBanner(),
                const SizedBox(height: 22),
                if (hasNoTasks &&
                    _selectedStatus == 0 &&
                    _selectedCategory == 'All Categories')
                  TaskFlowEmptyState(
                    icon: Icons.add_task_rounded,
                    title: 'No tasks yet',
                    message: 'Add a task to start organizing your day.',
                    actionLabel: 'Add Task',
                    actionIcon: Icons.add_rounded,
                    onAction: _addTask,
                  )
                else if (highPriority.isEmpty &&
                    inProgress.isEmpty &&
                    completed.isEmpty)
                  _filteredEmptyState(hasSearch: hasSearch)
                else ...[
                  _TaskSection(
                    title: 'High Priority',
                    count: highPriority.length,
                    color: const Color(0xFFBA1A1A),
                    tasks: highPriority,
                    onTaskChanged: _setTaskStatus,
                    onEditTask: _editTask,
                    onDeleteTask: _deleteTask,
                  ),
                  const SizedBox(height: 22),
                  _TaskSection(
                    title: 'In Progress',
                    count: inProgress.length,
                    color: const Color(0xFF675DF9),
                    tasks: inProgress,
                    onTaskChanged: _setTaskStatus,
                    onEditTask: _editTask,
                    onDeleteTask: _deleteTask,
                  ),
                  const SizedBox(height: 22),
                  _TaskSection(
                    title: 'Completed',
                    count: completed.length,
                    color: TaskFlowColors.tertiary,
                    tasks: completed,
                    onTaskChanged: _setTaskStatus,
                    onEditTask: _editTask,
                    onDeleteTask: _deleteTask,
                    onClear: completed.isEmpty
                        ? null
                        : () async {
                            final provider = context.read<TaskProvider>();
                            for (final task in completed) {
                              final deleted = await provider.deleteTask(
                                task.task.id,
                              );
                              if (!deleted && mounted) {
                                _showMessage(
                                  provider.errorMessage ??
                                      'Could not delete task. Please try again.',
                                  onRetry: () =>
                                      provider.deleteTask(task.task.id),
                                );
                                break;
                              }
                            }
                          },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _filteredEmptyState({required bool hasSearch}) {
    if (hasSearch) {
      return TaskFlowEmptyState(
        icon: Icons.search_off_rounded,
        title: 'No matching tasks',
        message: 'Try another search or clear it to see your tasks.',
        actionLabel: 'Clear Search & Filters',
        actionIcon: Icons.close_rounded,
        onAction: () => setState(_clearFilters),
      );
    }
    if (_selectedStatus == 2) {
      return TaskFlowEmptyState(
        icon: Icons.task_alt_rounded,
        title: 'No completed tasks yet',
        message: 'Finish a task and it will appear here.',
        actionLabel: 'View Pending Tasks',
        actionIcon: Icons.pending_actions_rounded,
        onAction: () => setState(() => _selectedStatus = 1),
      );
    }
    if (_selectedStatus == 1) {
      return TaskFlowEmptyState(
        icon: Icons.check_circle_outline_rounded,
        title: 'No pending tasks',
        message:
            'You are all caught up. Add another task whenever you are ready.',
        actionLabel: 'Add Task',
        actionIcon: Icons.add_rounded,
        onAction: _addTask,
      );
    }
    return TaskFlowEmptyState(
      icon: Icons.filter_alt_off_rounded,
      title: 'No tasks match these filters',
      message: 'Clear the filters to see your full task list.',
      actionLabel: 'Clear Filters',
      actionIcon: Icons.filter_alt_off_rounded,
      onAction: () => setState(_clearFilters),
    );
  }

  void _clearFilters() {
    _searchController.clear();
    _selectedStatus = 0;
    _selectedCategory = 'All Categories';
  }

  Future<void> _setTaskStatus(_TaskItem task, bool isDone) async {
    final provider = context.read<TaskProvider>();
    final changed = await provider.toggleTaskCompletion(task.task.id);
    if (!changed && mounted) {
      _showMessage(
        provider.errorMessage ?? 'Could not update task. Please try again.',
        onRetry: () => _setTaskStatus(task, isDone),
      );
    }
  }

  Future<void> _editTask(_TaskItem item) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AddTaskScreen(taskToEdit: item.task),
      ),
    );
  }

  Future<void> _deleteTask(_TaskItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('“${item.title}” will be removed.'),
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
      final deleted = await provider.deleteTask(item.task.id);
      if (!deleted && mounted) {
        _showMessage(
          provider.errorMessage ?? 'Could not delete task. Please try again.',
          onRetry: () => _deleteTask(item),
        );
      }
    }
  }

  Future<void> _addTask() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const AddTaskScreen()),
    );
    if (mounted) {
      setState(() {
        _selectedStatus = 0;
        _selectedCategory = 'All Categories';
        _selectedDestination = 1;
      });
    }
  }

  void _onDestinationSelected(int index) {
    if (index == 0) {
      if (widget.onHomeSelected != null) {
        widget.onHomeSelected!();
      } else if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      return;
    }
    if (index == 2) {
      _openCalendar();
      return;
    }
    if (index == 3) {
      _openStatistics();
      return;
    }
    if (index == 4) {
      _openProfile();
      return;
    }
    setState(() => _selectedDestination = index);
  }

  void _openProfile() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ProfileScreen(
          onHomeSelected: () {
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            if (widget.onHomeSelected != null) {
              widget.onHomeSelected!();
            } else if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
          onTasksSelected: () {
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            setState(() => _selectedDestination = 1);
          },
          onCalendarSelected: () {
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            _openCalendar();
          },
          onStatisticsSelected: () {
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            _openStatistics();
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
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            widget.onHomeSelected?.call();
          },
          onTasksSelected: () {
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            setState(() => _selectedDestination = 1);
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
            if (widget.onHomeSelected != null) {
              widget.onHomeSelected!();
            } else if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
          onTasksSelected: () {
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            setState(() => _selectedDestination = 1);
          },
          onCalendarSelected: () {
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            _openCalendar();
          },
        ),
      ),
    );
  }

  String _destinationName(int index) => switch (index) {
    2 => 'Calendar',
    3 => 'Statistics',
    4 => 'Profile',
    _ => 'Tasks',
  };

  void _showMessage(String message, {VoidCallback? onRetry}) {
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
}

class _TasksAppBar extends StatelessWidget {
  const _TasksAppBar({required this.onProfile});

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
                  'Tasks',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: TaskFlowColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('You are all caught up!'),
                behavior: SnackBarBehavior.floating,
              ),
            ),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          GestureDetector(
            onTap: onProfile,
            child: const CircleAvatar(
              radius: 20,
              backgroundColor: Color(0xFFE3DFFF),
              child: Icon(Icons.person_rounded, color: TaskFlowColors.primary),
            ),
          ),
        ],
      ),
    ),
  );
}

class _StatusSelector extends StatelessWidget {
  const _StatusSelector({
    required this.selectedIndex,
    required this.counts,
    required this.onSelected,
  });

  final int selectedIndex;
  final List<int> counts;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    const labels = ['All', 'Pending', 'Done'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: TaskFlowColors.lavenderContainer,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          for (var index = 0; index < labels.length; index++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Material(
                  color: selectedIndex == index
                      ? TaskFlowColors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => onSelected(index),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        '${labels[index]} (${counts[index]})',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: selectedIndex == index
                                  ? Colors.white
                                  : TaskFlowColors.secondaryText,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategorySelector extends StatelessWidget {
  const _CategorySelector({
    required this.categories,
    required this.selectedCategory,
    required this.categoryCounts,
    required this.onSelected,
  });

  final List<String> categories;
  final String selectedCategory;
  final Map<String, int> categoryCounts;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (var index = 0; index < categories.length; index++) ...[
          if (index > 0) const SizedBox(width: 8),
          _CategoryChip(
            category: categories[index],
            count: index == 0 ? null : categoryCounts[categories[index]],
            selected: selectedCategory == categories[index],
            onPressed: () => onSelected(categories[index]),
          ),
        ],
      ],
    ),
  );
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.count,
    required this.selected,
    required this.onPressed,
  });

  final String category;
  final int? count;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = count == null ? category : '$category ($count)';
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => onPressed(),
      avatar: category == 'All Categories'
          ? Icon(
              Icons.apps_rounded,
              size: 17,
              color: selected ? Colors.white : TaskFlowColors.secondaryText,
            )
          : Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: _categoryColor(category),
                shape: BoxShape.circle,
              ),
            ),
      label: Text(label),
      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: selected ? Colors.white : TaskFlowColors.secondaryText,
      ),
      selectedColor: TaskFlowColors.primaryContainer,
      backgroundColor: Colors.white,
      side: BorderSide.none,
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    );
  }

  Color _categoryColor(String category) => switch (category) {
    'Work' => TaskFlowColors.primary,
    'Personal' => TaskFlowColors.primaryContainer,
    'Design' => TaskFlowColors.tertiary,
    _ => const Color(0xFF00855B),
  };
}

class _FocusPeakBanner extends StatelessWidget {
  const _FocusPeakBanner();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFE9E5FF), Color(0xFFF6F2FF)],
      ),
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: TaskFlowColors.mainText.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: Color(0xFFE3DFFF),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.bolt_rounded, color: TaskFlowColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Focus Peak', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 3),
              Text(
                '2 high-priority tasks scheduled for today',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const ShapeDecoration(
            color: Colors.white,
            shape: StadiumBorder(),
          ),
          child: Text(
            '61% done',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: TaskFlowColors.primary),
          ),
        ),
      ],
    ),
  );
}

class _TaskSection extends StatelessWidget {
  const _TaskSection({
    required this.title,
    required this.count,
    required this.color,
    required this.tasks,
    required this.onTaskChanged,
    required this.onEditTask,
    required this.onDeleteTask,
    this.onClear,
  });

  final String title;
  final int count;
  final Color color;
  final List<_TaskItem> tasks;
  final ValueChanged2<_TaskItem, bool> onTaskChanged;
  final ValueChanged<_TaskItem> onEditTask;
  final ValueChanged<_TaskItem> onDeleteTask;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: const ShapeDecoration(
              color: TaskFlowColors.lavenderContainer,
              shape: StadiumBorder(),
            ),
            child: Text(
              '$count',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          const Spacer(),
          if (onClear != null)
            TextButton(onPressed: onClear, child: const Text('Clear'))
          else
            Icon(Icons.more_horiz_rounded, color: TaskFlowColors.secondaryText),
        ],
      ),
      const SizedBox(height: 10),
      if (tasks.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'No tasks here right now.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        )
      else
        for (final task in tasks) ...[
          _TaskCard(
            task: task,
            onChanged: (value) => onTaskChanged(task, value ?? false),
            onEdit: () => onEditTask(task),
            onDelete: () => onDeleteTask(task),
          ),
          if (task != tasks.last) const SizedBox(height: 12),
        ],
    ],
  );
}

typedef ValueChanged2<T, U> = void Function(T value, U secondValue);

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.onChanged,
    required this.onEdit,
    required this.onDelete,
  });

  final _TaskItem task;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isDone = task.status == _TaskStatus.done;
    final priorityColor = switch (task.priority) {
      _TaskPriority.high => const Color(0xFFBA1A1A),
      _TaskPriority.medium => TaskFlowColors.primary,
      _TaskPriority.low => TaskFlowColors.tertiary,
    };
    final priorityBackground = switch (task.priority) {
      _TaskPriority.high => const Color(0xFFFFDAD6),
      _TaskPriority.medium => const Color(0xFFE3DFFF),
      _TaskPriority.low => const Color(0xFFB7F7DF),
    };
    final textTheme = Theme.of(context).textTheme;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDone ? const Color(0xFFF8F5FF) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: TaskFlowColors.mainText.withValues(alpha: 0.035),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 5,
              color: isDone ? TaskFlowColors.tertiary : priorityColor,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 16, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox.adaptive(
                          value: isDone,
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
                                  decoration: isDone
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: isDone
                                      ? TaskFlowColors.outline
                                      : TaskFlowColors.mainText,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                task.description,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: TaskFlowColors.secondaryText,
                                ),
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
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _TaskBadge(
                          icon: isDone
                              ? Icons.check_circle_outline_rounded
                              : switch (task.priority) {
                                  _TaskPriority.high =>
                                    Icons.priority_high_rounded,
                                  _TaskPriority.medium => Icons.tune_rounded,
                                  _TaskPriority.low => Icons.south_rounded,
                                },
                          label: isDone
                              ? 'Done'
                              : switch (task.priority) {
                                  _TaskPriority.high => 'High',
                                  _TaskPriority.medium => 'Medium',
                                  _TaskPriority.low => 'Low',
                                },
                          color: isDone
                              ? TaskFlowColors.tertiary
                              : priorityColor,
                          background: isDone
                              ? const Color(0xFF6FFBBE)
                              : priorityBackground,
                        ),
                        _TaskBadge(
                          icon: Icons.folder_outlined,
                          label: task.category,
                          color: TaskFlowColors.secondaryText,
                          background: const Color(0xFFE9E5FF),
                        ),
                        if (task.task.recurrenceType != TaskRecurrence.none)
                          _TaskBadge(
                            icon: Icons.repeat_rounded,
                            label: task.repeat,
                            color: TaskFlowColors.primary,
                            background: TaskFlowColors.lavenderContainer,
                          ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isDone
                                  ? Icons.done_all_rounded
                                  : task.due.contains('Today')
                                  ? Icons.access_time_rounded
                                  : Icons.calendar_today_outlined,
                              size: 17,
                              color: isDone
                                  ? TaskFlowColors.tertiary
                                  : task.priority == _TaskPriority.high
                                  ? priorityColor
                                  : TaskFlowColors.secondaryText,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              task.due,
                              style: textTheme.labelMedium?.copyWith(
                                color: isDone
                                    ? TaskFlowColors.tertiary
                                    : task.priority == _TaskPriority.high &&
                                          task.due.contains('Today')
                                    ? priorityColor
                                    : TaskFlowColors.secondaryText,
                              ),
                            ),
                          ],
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

class _TaskBadge extends StatelessWidget {
  const _TaskBadge({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(22),
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

class _OtherDestination extends StatelessWidget {
  const _OtherDestination({required this.title});

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
