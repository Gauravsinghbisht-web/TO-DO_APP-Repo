
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/task.dart';
import '../providers/task_provider.dart';
import '../widgets/taskflow_bottom_navigation_bar.dart';
import 'add_task_screen.dart';
import 'profile_screen.dart';
import 'statistics_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, this.onHomeSelected, this.onTasksSelected});

  final VoidCallback? onHomeSelected;
  final VoidCallback? onTasksSelected;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _displayedMonth;
  late DateTime _selectedDate;
  int _selectedDestination = 2;

  List<_CalendarTask> get _tasks => context
      .watch<TaskProvider>()
      .tasks
      .where((task) => task.dueDate != null)
      .map(_CalendarTask.fromTask)
      .toList(growable: false);

  @override
  void initState() {
    super.initState();
    final today = DateUtils.dateOnly(DateTime.now());
    _selectedDate = today;
    _displayedMonth = DateTime(today.year, today.month);
  }

  List<_CalendarTask> get _selectedDateTasks =>
      _tasks
          .where((task) => DateUtils.isSameDay(task.date, _selectedDate))
          .toList()
        ..sort(
          (a, b) => _minutesFromMidnight(
            a.start,
          ).compareTo(_minutesFromMidnight(b.start)),
        );

  int get _totalMinutes => _selectedDateTasks.fold<int>(
    0,
    (total, task) => total + task.durationMinutes,
  );

  @override
  Widget build(BuildContext context) {
    final tasksForDate = _selectedDateTasks;
    final destinationTitles = [
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
            _CalendarAppBar(
              destination: destinationTitles[_selectedDestination],
              onProfile: _openProfile,
            ),
            Expanded(
              child: _selectedDestination == 2
                  ? _buildCalendar(context, tasksForDate)
                  : _OtherDestination(
                      title: destinationTitles[_selectedDestination],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: _selectedDestination == 2
          ? FloatingActionButton.extended(
              onPressed: _addTask,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Task'),
              elevation: 5,
            )
          : null,
      bottomNavigationBar: TaskFlowBottomNavigationBar(
        selectedIndex: _selectedDestination,
        onDestinationSelected: _onDestinationSelected,
      ),
    );
  }

  Widget _buildCalendar(
    BuildContext context,
    List<_CalendarTask> tasksForDate,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 112),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 780),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _MonthCalendarCard(
                  displayedMonth: _displayedMonth,
                  selectedDate: _selectedDate,
                  tasks: _tasks,
                  compact: constraints.maxWidth < 400,
                  onPreviousMonth: () => _changeMonth(-1),
                  onNextMonth: () => _changeMonth(1),
                  onToday: _selectToday,
                  onSelectDate: _selectDate,
                ),
                const SizedBox(height: 24),
                _SelectedDayHeading(
                  date: _selectedDate,
                  taskCount: tasksForDate.length,
                  totalMinutes: _totalMinutes,
                ),
                const SizedBox(height: 14),
                if (tasksForDate.isEmpty)
                  _NoScheduledTasks(onAddTask: _addTask)
                else
                  for (final task in tasksForDate) ...[
                    _ScheduledTaskCard(task: task),
                    if (task != tasksForDate.last) const SizedBox(height: 12),
                  ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _changeMonth(int offset) {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + offset,
      );
      final lastDay = DateUtils.getDaysInMonth(
        _displayedMonth.year,
        _displayedMonth.month,
      );
      final day = _selectedDate.day.clamp(1, lastDay);
      _selectedDate = DateTime(
        _displayedMonth.year,
        _displayedMonth.month,
        day,
      );
    });
  }

  void _selectToday() {
    final today = DateUtils.dateOnly(DateTime.now());
    setState(() {
      _selectedDate = today;
      _displayedMonth = DateTime(today.year, today.month);
    });
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = DateUtils.dateOnly(date);
      _displayedMonth = DateTime(date.year, date.month);
    });
  }

  Future<void> _addTask() async {
    final task = await Navigator.of(context).push<Task>(
      MaterialPageRoute<Task>(
        builder: (_) => AddTaskScreen(initialDate: _selectedDate),
      ),
    );
    if (task == null || !mounted) return;
    setState(() {
      _selectedDate = DateUtils.dateOnly(task.dueDate ?? DateTime.now());
      _displayedMonth = DateTime(_selectedDate.year, _selectedDate.month);
    });
  }

  void _onDestinationSelected(int index) {
    if (index == 0 && widget.onHomeSelected != null) {
      widget.onHomeSelected!();
      return;
    }
    if (index == 1 && widget.onTasksSelected != null) {
      widget.onTasksSelected!();
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
    if (index == _selectedDestination) return;
    setState(() => _selectedDestination = index);
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
            if (widget.onTasksSelected != null) {
              widget.onTasksSelected!();
            } else {
              setState(() => _selectedDestination = 1);
            }
          },
          onCalendarSelected: () {
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            setState(() => _selectedDestination = 2);
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
            if (widget.onHomeSelected != null) {
              widget.onHomeSelected!();
            } else if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
          onTasksSelected: () {
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            if (widget.onTasksSelected != null) {
              widget.onTasksSelected!();
            } else {
              setState(() => _selectedDestination = 1);
            }
          },
          onCalendarSelected: () {
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            setState(() => _selectedDestination = 2);
          },
          onStatisticsSelected: () {
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            _openStatistics();
          },
        ),
      ),
    );
  }
}

class _CalendarTask {
  _CalendarTask({
    required this.title,
    this.description = '',
    required this.category,
    this.tag = '',
    this.isHighPriority = false,
    required this.detail,
    required this.date,
    required this.start,
    required this.duration,
  });

  final String title;
  final String description;
  final String category;
  final String tag;
  final bool isHighPriority;
  final String detail;
  final DateTime date;
  final TimeOfDay start;
  final int duration;

  int get durationMinutes => duration;

  factory _CalendarTask.fromTask(Task task) => _CalendarTask(
    title: task.title,
    description: task.description,
    category: task.category,
    tag: task.subtasks.isEmpty ? '' : '${task.subtasks.length} subtasks',
    isHighPriority: task.priority == TaskPriority.high,
    detail: '',
    date: task.dueDate!,
    start: task.dueTime ?? const TimeOfDay(hour: 9, minute: 0),
    duration: 30,
  );
}

int _minutesFromMidnight(TimeOfDay time) => time.hour * 60 + time.minute;

class _CalendarAppBar extends StatelessWidget {
  const _CalendarAppBar({required this.destination, required this.onProfile});

  final String destination;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surface,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                Icons.check_rounded,
                color: colors.onPrimary,
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
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Calendar search will be available later.'),
                  behavior: SnackBarBehavior.floating,
                ),
              ),
              icon: const Icon(Icons.search_rounded),
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

class _MonthCalendarCard extends StatelessWidget {
  const _MonthCalendarCard({
    required this.displayedMonth,
    required this.selectedDate,
    required this.tasks,
    required this.compact,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onToday,
    required this.onSelectDate,
  });

  final DateTime displayedMonth;
  final DateTime selectedDate;
  final List<_CalendarTask> tasks;
  final bool compact;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onToday;
  final ValueChanged<DateTime> onSelectDate;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final firstDay = DateTime(displayedMonth.year, displayedMonth.month);
    final mondayOffset = (firstDay.weekday + 6) % 7;
    final gridStart = firstDay.subtract(Duration(days: mondayOffset));
    final daysInMonth = DateUtils.getDaysInMonth(
      displayedMonth.year,
      displayedMonth.month,
    );
    final weekCount = (mondayOffset + daysInMonth + 6) ~/ 7;
    final monthName = MaterialLocalizations.of(
      context,
    ).formatMonthYear(firstDay);
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  monthName,
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (!compact)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: ShapeDecoration(
                    color: colors.primaryContainer,
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    'Autumn Sprint',
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ),
              TextButton(onPressed: onToday, child: const Text('Today')),
              IconButton(
                tooltip: 'Previous month',
                visualDensity: VisualDensity.compact,
                onPressed: onPreviousMonth,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              IconButton(
                tooltip: 'Next month',
                visualDensity: VisualDensity.compact,
                onPressed: onNextMonth,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const _WeekHeader(),
          const SizedBox(height: 8),
          for (var week = 0; week < weekCount; week++)
            Row(
              children: [
                for (var day = 0; day < 7; day++)
                  Expanded(
                    child: _CalendarDayCell(
                      date: gridStart.add(Duration(days: week * 7 + day)),
                      displayedMonth: displayedMonth,
                      selectedDate: selectedDate,
                      tasks: tasks,
                      onTap: onSelectDate,
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 14),
          const _CalendarLegend(),
        ],
      ),
    );
  }
}

class _WeekHeader extends StatelessWidget {
  const _WeekHeader();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Row(
      children: [
        for (final day in days)
          Expanded(
            child: Center(
              child: Text(
                day,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.date,
    required this.displayedMonth,
    required this.selectedDate,
    required this.tasks,
    required this.onTap,
  });

  final DateTime date;
  final DateTime displayedMonth;
  final DateTime selectedDate;
  final List<_CalendarTask> tasks;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final selected = DateUtils.isSameDay(date, selectedDate);
    final today = DateUtils.isSameDay(date, DateTime.now());
    final currentMonth =
        date.month == displayedMonth.month && date.year == displayedMonth.year;
    final taskColors = tasks
        .where((task) => DateUtils.isSameDay(task.date, date))
        .map((task) => _taskColor(task, colors))
        .toSet()
        .take(3)
        .toList();

    return SizedBox(
      height: 47,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => onTap(date),
        child: Center(
          child: Container(
            width: 40,
            height: 44,
            decoration: BoxDecoration(
              color: selected ? colors.primary : Colors.transparent,
              shape: BoxShape.circle,
              border: today && !selected
                  ? Border.all(color: colors.primary, width: 1.5)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${date.day}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: selected
                        ? colors.onPrimary
                        : currentMonth
                        ? colors.onSurface
                        : colors.onSurface.withValues(alpha: 0.38),
                    fontWeight: selected || today ? FontWeight.w700 : null,
                  ),
                ),
                const SizedBox(height: 3),
                SizedBox(
                  height: 5,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final color in taskColors)
                        Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: selected
                                ? colors.onPrimary.withValues(alpha: 0.9)
                                : color,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CalendarLegend extends StatelessWidget {
  const _CalendarLegend();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 18,
        runSpacing: 8,
        children: [
          _LegendItem(label: 'Work', color: colors.primary),
          _LegendItem(label: 'High Priority', color: colors.error),
          _LegendItem(label: 'Wellness', color: colors.tertiary),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _SelectedDayHeading extends StatelessWidget {
  const _SelectedDayHeading({
    required this.date,
    required this.taskCount,
    required this.totalMinutes,
  });

  final DateTime date;
  final int taskCount;
  final int totalMinutes;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final localizations = MaterialLocalizations.of(context);
    final totalHours = totalMinutes ~/ 60;
    final remainingMinutes = totalMinutes % 60;
    final totalLabel = totalHours == 0
        ? '${remainingMinutes}m total'
        : remainingMinutes == 0
        ? '${totalHours}h total'
        : '${totalHours}h ${remainingMinutes}m total';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 6,
          children: [
            Text(
              'Tasks for ${localizations.formatFullDate(date)}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            if (taskCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: ShapeDecoration(
                  color: colors.primaryContainer,
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  totalLabel,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.onPrimaryContainer,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '$taskCount scheduled ${taskCount == 1 ? 'activity' : 'activities'} ${DateUtils.isSameDay(date, DateTime.now()) ? 'today' : 'on this date'}',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ScheduledTaskCard extends StatelessWidget {
  const _ScheduledTaskCard({required this.task});

  final _CalendarTask task;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = _taskColor(task, colors);
    final priority = task.isHighPriority;
    final endTime = _addMinutes(task.start, task.durationMinutes);
    final textTheme = Theme.of(context).textTheme;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(width: 6, color: color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: priority
                                ? colors.errorContainer
                                : colors.primaryContainer,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            priority
                                ? 'HIGH PRIORITY'
                                : task.category.toUpperCase(),
                            style: textTheme.labelSmall?.copyWith(
                              color: priority
                                  ? colors.onErrorContainer
                                  : colors.onPrimaryContainer,
                            ),
                          ),
                        ),
                        if (task.tag.isNotEmpty)
                          Text(
                            task.tag,
                            style: textTheme.labelMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Text(task.title, style: textTheme.titleLarge),
                    if (task.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.description,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 18,
                              color: color,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${task.start.format(context)} – ${endTime.format(context)}',
                              style: textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: CircleAvatar(
                radius: 22,
                backgroundColor: colors.primaryContainer,
                child: Icon(
                  Icons.check_rounded,
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

class _NoScheduledTasks extends StatelessWidget {
  const _NoScheduledTasks({required this.onAddTask});

  final VoidCallback onAddTask;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_available_rounded,
            color: colors.primary,
            size: 36,
          ),
          const SizedBox(height: 8),
          Text(
            'Nothing scheduled',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Enjoy the open space or add a task for this day.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: onAddTask,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Task'),
          ),
        ],
      ),
    );
  }
}

class _OtherDestination extends StatelessWidget {
  const _OtherDestination({required this.title});

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
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
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

Color _taskColor(_CalendarTask task, ColorScheme colors) =>
    task.isHighPriority
    ? colors.error
    : switch (task.category) {
        'Wellness' => colors.tertiary,
        'Design' || 'Meeting' => colors.primaryContainer,
        _ => colors.primary,
      };

TimeOfDay _addMinutes(TimeOfDay time, int minutes) {
  final total = (time.hour * 60 + time.minute + minutes) % (24 * 60);
  return TimeOfDay(hour: total ~/ 60, minute: total % 60);
}
