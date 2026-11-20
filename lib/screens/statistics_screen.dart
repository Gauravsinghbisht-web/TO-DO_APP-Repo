import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/taskflow_theme.dart';
import '../data/models/task.dart';
import '../providers/task_provider.dart';
import '../widgets/taskflow_bottom_navigation_bar.dart';
import '../widgets/taskflow_empty_state.dart';
import 'add_task_screen.dart';
import 'profile_screen.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({
    super.key,
    this.onHomeSelected,
    this.onTasksSelected,
    this.onCalendarSelected,
  });

  final VoidCallback? onHomeSelected;
  final VoidCallback? onTasksSelected;
  final VoidCallback? onCalendarSelected;

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int _selectedRange = 0;
  int _selectedDestination = 3;

  static const _rangeLabels = ['This Week', 'This Month', 'All Time'];

  _StatisticsSnapshot _snapshotFor(List<Task> allTasks) {
    final now = DateTime.now();
    final start = switch (_selectedRange) {
      0 => DateUtils.dateOnly(now).subtract(Duration(days: now.weekday - 1)),
      1 => DateTime(now.year, now.month),
      _ => DateTime(1),
    };
    final tasks = allTasks
        .where((task) => !task.createdAt.isBefore(start))
        .toList();
    final completed = tasks.where((task) => task.isCompleted).length;
    final pending = tasks.length - completed;
    final activity = List<int>.generate(7, (index) {
      final weekday = index + 1;
      return tasks
          .where(
            (task) => task.isCompleted && task.createdAt.weekday == weekday,
          )
          .length;
    });
    const categoryKeys = ['Work', 'Personal', 'Design', 'Other'];
    final categories = categoryKeys
        .map(
          (key) => tasks.where((task) {
            if (key == 'Other') {
              return !categoryKeys.take(3).contains(task.category);
            }
            return task.category == key;
          }).length,
        )
        .toList();
    return _StatisticsSnapshot(
      completedTasks: completed,
      productivity: tasks.isEmpty
          ? 0
          : (completed * 100 / tasks.length).round(),
      pendingTasks: pending,
      change: 0,
      extraCompletedToday: tasks
          .where(
            (task) =>
                task.isCompleted && DateUtils.isSameDay(task.createdAt, now),
          )
          .length,
      focusStreak: 0,
      activity: activity,
      categories: categories,
      peakPercentage: 0,
      peakStart: '',
      peakEnd: '',
      achievement: completed == 0
          ? 'Your next achievement awaits'
          : 'Task Champion',
      achievementDescription: completed == 0
          ? 'Complete a task to start building your record.'
          : '$completed tasks completed in this date range.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Home', 'Tasks', 'Calendar', 'Statistics', 'Profile'];
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _StatisticsAppBar(
              destination: titles[_selectedDestination],
              onProfile: _openProfile,
            ),
            Expanded(
              child: _selectedDestination == 3
                  ? _buildStatistics(context)
                  : _DestinationPlaceholder(
                      title: titles[_selectedDestination],
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

  Widget _buildStatistics(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final snapshot = _snapshotFor(context.watch<TaskProvider>().tasks);
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Productivity Insights',
                            style: textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Real-time breakdown of your cognitive rhythm',
                            style: textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: 'Export insights',
                      onPressed: () =>
                          _showMessage('Export will be available later.'),
                      icon: const Icon(Icons.ios_share_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _DateRangeSelector(
                  labels: _rangeLabels,
                  selectedIndex: _selectedRange,
                  onSelected: (index) => setState(() => _selectedRange = index),
                ),
                const SizedBox(height: 22),
                if (snapshot.completedTasks + snapshot.pendingTasks == 0)
                  TaskFlowEmptyState(
                    icon: Icons.insights_rounded,
                    title: 'No insights for this period yet',
                    message:
                        'Create a task to see your activity and progress here.',
                    actionLabel: 'Add Task',
                    actionIcon: Icons.add_rounded,
                    onAction: _addTask,
                  )
                else ...[
                  _MetricGrid(
                    snapshot: snapshot,
                    width: (constraints.maxWidth - 40).clamp(0.0, 760.0),
                  ),
                  const SizedBox(height: 22),
                  _ActivityCard(snapshot: snapshot, rangeIndex: _selectedRange),
                  const SizedBox(height: 22),
                  _CategoryDistributionCard(snapshot: snapshot),
                  const SizedBox(height: 22),
                  _PeakFocusCard(snapshot: snapshot),
                  const SizedBox(height: 16),
                  _AchievementCard(snapshot: snapshot),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addTask() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const AddTaskScreen()),
    );
  }

  void _onDestinationSelected(int index) {
    switch (index) {
      case 0:
        if (widget.onHomeSelected != null) {
          widget.onHomeSelected!();
        } else if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          setState(() => _selectedDestination = index);
        }
      case 1:
        if (widget.onTasksSelected != null) {
          widget.onTasksSelected!();
        } else {
          setState(() => _selectedDestination = index);
        }
      case 2:
        if (widget.onCalendarSelected != null) {
          widget.onCalendarSelected!();
        } else {
          setState(() => _selectedDestination = index);
        }
      case 3:
        setState(() => _selectedDestination = 3);
      case 4:
        _openProfile();
    }
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
            if (widget.onCalendarSelected != null) {
              widget.onCalendarSelected!();
            } else {
              setState(() => _selectedDestination = 2);
            }
          },
          onStatisticsSelected: () {
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            setState(() => _selectedDestination = 3);
          },
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

class _StatisticsSnapshot {
  const _StatisticsSnapshot({
    required this.completedTasks,
    required this.productivity,
    required this.pendingTasks,
    required this.change,
    required this.extraCompletedToday,
    required this.focusStreak,
    required this.activity,
    required this.categories,
    required this.peakPercentage,
    required this.peakStart,
    required this.peakEnd,
    required this.achievement,
    required this.achievementDescription,
  });

  final int completedTasks;
  final int productivity;
  final int pendingTasks;
  final int change;
  final int extraCompletedToday;
  final int focusStreak;
  final List<int> activity;
  final List<int> categories;
  final int peakPercentage;
  final String peakStart;
  final String peakEnd;
  final String achievement;
  final String achievementDescription;
}

class _StatisticsAppBar extends StatelessWidget {
  const _StatisticsAppBar({required this.destination, required this.onProfile});

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
            onPressed: () => _showAppBarMessage(
              context,
              'Statistics search will be available later.',
            ),
            icon: const Icon(Icons.search_rounded),
          ),
          IconButton(
            tooltip: 'Notifications',
            onPressed: () =>
                _showAppBarMessage(context, 'You are all caught up!'),
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

void _showAppBarMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
  );
}

class _DateRangeSelector extends StatelessWidget {
  const _DateRangeSelector({
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: const Color(0xFFEFEBFF),
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
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 4,
                    ),
                    child: Text(
                      labels[index],
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
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

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.snapshot, required this.width});

  final _StatisticsSnapshot snapshot;
  final double width;

  @override
  Widget build(BuildContext context) {
    final gap = 12.0;
    final cardWidth = (width - gap) / 2;
    // Narrow cards wrap supporting text. Scale their height with the system
    // text scale so accessibility text sizes have room as well.
    final baseCardHeight = cardWidth < 180 ? 174.0 : 158.0;
    final cardHeight =
        baseCardHeight * MediaQuery.textScalerOf(context).scale(1.0);
    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: [
        SizedBox(
          width: cardWidth,
          height: cardHeight,
          child: _ProductivityMetric(snapshot: snapshot),
        ),
        SizedBox(
          width: cardWidth,
          height: cardHeight,
          child: _CompletedMetric(snapshot: snapshot),
        ),
        SizedBox(
          width: cardWidth,
          height: cardHeight,
          child: _PendingMetric(snapshot: snapshot),
        ),
        SizedBox(
          width: cardWidth,
          height: cardHeight,
          child: _StreakMetric(snapshot: snapshot),
        ),
      ],
    );
  }
}

class _ProductivityMetric extends StatelessWidget {
  const _ProductivityMetric({required this.snapshot});

  final _StatisticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) => _MetricCard(
    background: const Color(0xFFE9E5FF),
    icon: Icons.pie_chart_outline_rounded,
    iconColor: TaskFlowColors.primary,
    topLabel: 'Current',
    topLabelColor: TaskFlowColors.tertiary,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '${snapshot.productivity}%',
          style: Theme.of(
            context,
          ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        Text(
          'Completion Rate',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: TaskFlowColors.secondaryText,
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: snapshot.productivity / 100,
            minHeight: 6,
            backgroundColor: const Color(0xFFDAD6FF),
            color: TaskFlowColors.primary,
          ),
        ),
      ],
    ),
  );
}

class _CompletedMetric extends StatelessWidget {
  const _CompletedMetric({required this.snapshot});

  final _StatisticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) => _MetricCard(
    background: const Color(0xFFEFEBFF),
    icon: Icons.task_alt_rounded,
    iconColor: TaskFlowColors.tertiary,
    topLabel: 'On Track',
    topLabelColor: TaskFlowColors.tertiary,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '${snapshot.completedTasks}',
          style: Theme.of(
            context,
          ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        Text(
          'Tasks Done',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: TaskFlowColors.secondaryText,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(
              Icons.done_all_rounded,
              size: 16,
              color: TaskFlowColors.tertiary,
            ),
            const SizedBox(width: 5),
            Text(
              '${snapshot.extraCompletedToday} created today',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: TaskFlowColors.tertiary),
            ),
          ],
        ),
      ],
    ),
  );
}

class _PendingMetric extends StatelessWidget {
  const _PendingMetric({required this.snapshot});

  final _StatisticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) => _MetricCard(
    background: TaskFlowColors.lavenderContainer,
    icon: Icons.pending_actions_rounded,
    iconColor: TaskFlowColors.secondaryText,
    topLabel: 'Active',
    topLabelColor: TaskFlowColors.secondaryText,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '${snapshot.pendingTasks}',
          style: Theme.of(
            context,
          ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        Text(
          'Pending Tasks',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: TaskFlowColors.secondaryText,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(
              Icons.schedule_rounded,
              size: 16,
              color: TaskFlowColors.secondaryText,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                'See due dates in Calendar',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: TaskFlowColors.secondaryText,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _StreakMetric extends StatelessWidget {
  const _StreakMetric({required this.snapshot});

  final _StatisticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFE3DFFF),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(
              Icons.local_fire_department_rounded,
              color: TaskFlowColors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              'Personal Best',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: TaskFlowColors.primary),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Not tracked',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              'Focus streak',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: TaskFlowColors.secondaryText,
              ),
            ),
          ],
        ),
        Text(
          'Completion time is not recorded',
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: TaskFlowColors.primary),
        ),
      ],
    ),
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.background,
    required this.icon,
    required this.iconColor,
    required this.topLabel,
    required this.topLabelColor,
    required this.child,
  });

  final Color background;
  final IconData icon;
  final Color iconColor;
  final String topLabel;
  final Color topLabelColor;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: TaskFlowColors.mainText.withValues(alpha: 0.035),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.55),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 19, color: iconColor),
            ),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: const ShapeDecoration(
                  color: Color(0xFFB7F7DF),
                  shape: StadiumBorder(),
                ),
                child: Text(
                  topLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: topLabelColor),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(child: child),
      ],
    ),
  );
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.snapshot, required this.rangeIndex});

  final _StatisticsSnapshot snapshot;
  final int rangeIndex;

  @override
  Widget build(BuildContext context) {
    final maxValue = snapshot.activity.reduce((a, b) => a > b ? a : b);
    final bestIndex = snapshot.activity.indexOf(maxValue);
    final bestDay = const [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ][bestIndex];
    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 8,
            children: [
              Text(
                'Activity Timeline',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: const ShapeDecoration(
                  color: Color(0xFFE9E5FF),
                  shape: StadiumBorder(),
                ),
                child: Text(
                  'Best: $bestDay ($maxValue)',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: TaskFlowColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            rangeIndex == 0
                ? 'Completed tasks by weekday this week'
                : rangeIndex == 1
                ? 'Completed tasks by weekday this month'
                : 'Completed tasks by weekday across all time',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: TaskFlowColors.secondaryText,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 220,
            width: double.infinity,
            child: CustomPaint(
              painter: _ActivityChartPainter(
                values: snapshot.activity,
                color: TaskFlowColors.primary,
                mutedColor: const Color(0xFFBDB8FF),
                textColor: TaskFlowColors.secondaryText,
                gridColor: const Color(0xFFE9E5FF),
                textDirection: Directionality.of(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityChartPainter extends CustomPainter {
  const _ActivityChartPainter({
    required this.values,
    required this.color,
    required this.mutedColor,
    required this.textColor,
    required this.gridColor,
    required this.textDirection,
  });

  final List<int> values;
  final Color color;
  final Color mutedColor;
  final Color textColor;
  final Color gridColor;
  final TextDirection textDirection;

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || size.isEmpty) return;
    const left = 28.0;
    const top = 20.0;
    const bottom = 34.0;
    const right = 4.0;
    final plotWidth = size.width - left - right;
    final plotHeight = size.height - top - bottom;
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final axisMax = ((maxValue + 4) ~/ 5) * 5;
    final axis = axisMax == 0 ? 5 : axisMax;
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    final bestValue = maxValue;

    for (var line = 0; line <= 2; line++) {
      final fraction = line / 2;
      final y = top + plotHeight * fraction;
      canvas.drawLine(
        Offset(left, y),
        Offset(size.width - right, y),
        gridPaint,
      );
      final labelValue = (axis * (1 - fraction)).round();
      _drawText(
        canvas,
        '$labelValue',
        Offset(0, y - 7),
        const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        textColor,
        maxWidth: left - 5,
      );
    }

    final slotWidth = plotWidth / values.length;
    final barWidth = slotWidth * 0.52;
    for (var index = 0; index < values.length; index++) {
      final value = values[index];
      final barHeight = plotHeight * value / axis;
      final centerX = left + slotWidth * (index + 0.5);
      final barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          centerX - barWidth / 2,
          top + plotHeight - barHeight,
          barWidth,
          barHeight,
        ),
        const Radius.circular(9),
      );
      canvas.drawRRect(
        barRect,
        Paint()..color = value == bestValue ? color : mutedColor,
      );
      _drawText(
        canvas,
        '$value',
        Offset(centerX - slotWidth / 2, top + plotHeight - barHeight - 20),
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        textColor,
        maxWidth: slotWidth,
        align: TextAlign.center,
      );
      _drawText(
        canvas,
        _days[index],
        Offset(centerX - slotWidth / 2, top + plotHeight + 8),
        TextStyle(
          fontSize: 12,
          fontWeight: value == bestValue ? FontWeight.w700 : FontWeight.w500,
        ),
        value == bestValue ? color : textColor,
        maxWidth: slotWidth,
        align: TextAlign.center,
      );
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    TextStyle style,
    Color color, {
    required double maxWidth,
    TextAlign align = TextAlign.left,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: style.copyWith(color: color, fontFamily: 'Inter'),
      ),
      textDirection: textDirection,
      textAlign: align,
      maxLines: 1,
    )..layout(maxWidth: maxWidth);
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _ActivityChartPainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.color != color ||
      oldDelegate.mutedColor != mutedColor ||
      oldDelegate.textColor != textColor ||
      oldDelegate.gridColor != gridColor;
}

class _CategoryDistributionCard extends StatelessWidget {
  const _CategoryDistributionCard({required this.snapshot});

  final _StatisticsSnapshot snapshot;

  static const _categories = [
    ('Work Projects', Color(0xFF4D41DF)),
    ('Personal & Errands', Color(0xFF006947)),
    ('Design & Creative', Color(0xFF675DF9)),
    ('Health & Habit', Color(0xFFBDB8FF)),
  ];

  @override
  Widget build(BuildContext context) {
    final total = snapshot.categories.fold<int>(0, (sum, count) => sum + count);
    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 6,
            children: [
              Text(
                'Category Distribution',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Text(
                '$total tasks classified',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: TaskFlowColors.secondaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (total > 0)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 12,
                child: Row(
                  children: [
                    for (
                      var index = 0;
                      index < snapshot.categories.length;
                      index++
                    )
                      Expanded(
                        flex: snapshot.categories[index],
                        child: Container(
                          margin: EdgeInsets.only(
                            right: index == snapshot.categories.length - 1
                                ? 0
                                : 2,
                          ),
                          color: _categories[index].$2,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          for (var index = 0; index < _categories.length; index++)
            if (snapshot.categories[index] > 0)
              Padding(
                padding: EdgeInsets.only(
                  bottom: index == _categories.length - 1 ? 0 : 12,
                ),
                child: _CategoryRow(
                  name: _categories[index].$1,
                  color: _categories[index].$2,
                  count: snapshot.categories[index],
                  percent: total == 0
                      ? 0
                      : (snapshot.categories[index] * 100 / total).round(),
                ),
              ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.name,
    required this.color,
    required this.count,
    required this.percent,
  });

  final String name;
  final Color color;
  final int count;
  final int percent;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 10),
      Expanded(child: Text(name, style: Theme.of(context).textTheme.bodyLarge)),
      Text('$count tasks', style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(width: 16),
      SizedBox(
        width: 40,
        child: Text(
          '$percent%',
          textAlign: TextAlign.end,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    ],
  );
}

class _PeakFocusCard extends StatelessWidget {
  const _PeakFocusCard({required this.snapshot});

  final _StatisticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF675DF9), Color(0xFF4D41DF)],
      ),
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: TaskFlowColors.primary.withValues(alpha: 0.24),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Stack(
      children: [
        Positioned(
          right: -6,
          bottom: -10,
          child: Icon(
            Icons.lightbulb_outline_rounded,
            size: 100,
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.psychology_alt_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'PEAK FOCUS WINDOW',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'TaskFlow does not record completion times yet, so a peak focus window cannot be calculated.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.white, height: 1.5),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Deep work scheduling will be available later.',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: TaskFlowColors.primary,
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(horizontal: 18),
              ),
              child: const Text('Schedule Deep Work'),
            ),
          ],
        ),
      ],
    ),
  );
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.snapshot});

  final _StatisticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: TaskFlowColors.lavenderContainer,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Row(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: const BoxDecoration(
            color: Color(0xFF6FFBBE),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.military_tech_rounded,
            color: Color(0xFF006947),
            size: 32,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                snapshot.achievement,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                snapshot.achievementDescription,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded, color: TaskFlowColors.primary),
      ],
    ),
  );
}

class _WhiteCard extends StatelessWidget {
  const _WhiteCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
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
    child: child,
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
