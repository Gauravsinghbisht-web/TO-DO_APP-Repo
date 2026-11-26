import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/task.dart';
import '../providers/task_provider.dart';

/// In-app overview of task reminders scheduled on this device.
class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tasks = context
        .watch<TaskProvider>()
        .tasks
        .where(
          (task) =>
              task.reminderEnabled &&
              !task.isCompleted &&
              task.dueDate != null &&
              task.dueTime != null,
        )
        .toList()
      ..sort((a, b) => _dueAt(a).compareTo(_dueAt(b)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: SafeArea(
        child: tasks.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.notifications_off_outlined,
                        size: 48,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No scheduled reminders',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Turn on a reminder and set a due date and time when creating a task.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: tasks.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  final dueAt = _dueAt(task);
                  final reminderAt = dueAt.subtract(
                    Duration(minutes: task.reminderMinutesBefore),
                  );
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: colors.primaryContainer,
                        child: Icon(
                          Icons.notifications_active_outlined,
                          color: colors.onPrimaryContainer,
                        ),
                      ),
                      title: Text(task.title),
                      subtitle: Text(
                        '${_formatDate(reminderAt)} · ${_reminderLabel(task.reminderMinutesBefore)}',
                      ),
                      isThreeLine: false,
                    ),
                  );
                },
              ),
      ),
    );
  }

  static DateTime _dueAt(Task task) {
    final date = task.dueDate!;
    final time = task.dueTime!;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  static String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final dayLabel = day == today
        ? 'Today'
        : day == today.add(const Duration(days: 1))
            ? 'Tomorrow'
            : '${date.day}/${date.month}/${date.year}';
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour < 12 ? 'AM' : 'PM';
    return '$dayLabel at $hour:$minute $period';
  }

  static String _reminderLabel(int minutes) {
    if (minutes == 0) return 'At due time';
    if (minutes < 60) return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} before';
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;
    if (remainder == 0) return '$hours ${hours == 1 ? 'hour' : 'hours'} before';
    return '$hours h $remainder min before';
  }
}
