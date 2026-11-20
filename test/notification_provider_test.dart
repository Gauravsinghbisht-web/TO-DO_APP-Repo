import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

import 'package:flutter_application_1/data/models/task.dart';
import 'package:flutter_application_1/data/repositories/task_repository.dart';
import 'package:flutter_application_1/data/services/notification_service.dart';
import 'package:flutter_application_1/providers/task_provider.dart';

void main() {
  setUpAll(() {
    timezone_data.initializeTimeZones();
    timezone.setLocalLocation(timezone.getLocation('Asia/Kolkata'));
  });

  test('reminder time is calculated in local time with the saved offset', () {
    final task = _futureReminderTask();
    final dueDateTime = timezone.TZDateTime(
      timezone.local,
      task.dueDate!.year,
      task.dueDate!.month,
      task.dueDate!.day,
      task.dueTime!.hour,
      task.dueTime!.minute,
    );

    expect(
      NotificationService.reminderTimeFor(task),
      dueDateTime.subtract(const Duration(minutes: 10)),
    );
    expect(
      NotificationService.notificationIdFor(task.id),
      NotificationService.notificationIdFor(task.id),
    );
  });

  test(
    'provider schedules, updates, cancels and restores task reminders',
    () async {
      final reminderService = _FakeReminderService();
      final provider = TaskProvider(
        repository: TaskRepository(initialTasks: []),
        reminderService: reminderService,
      );
      final task = _futureReminderTask();

      expect(await provider.addTask(task), isTrue);
      expect(reminderService.scheduledTasks.map((item) => item.id), [task.id]);

      final edited = task.copyWith(title: 'Edited reminder task');
      expect(await provider.updateTask(edited), isTrue);
      expect(reminderService.scheduledTasks.last.title, 'Edited reminder task');

      expect(await provider.toggleTaskCompletion(task.id), isTrue);
      expect(reminderService.cancelledIds.last, task.id);

      expect(await provider.toggleTaskCompletion(task.id), isTrue);
      expect(reminderService.scheduledTasks.last.id, task.id);

      await reminderService.restoreReminders(provider.tasks);
      expect(reminderService.restoredTasks, [task.id]);

      expect(await provider.deleteTask(task.id), isTrue);
      expect(reminderService.cancelledIds.last, task.id);
      expect(provider.tasks, isEmpty);
    },
  );
}

Task _futureReminderTask() {
  final due = DateTime.now().add(const Duration(hours: 1));
  return Task(
    id: 'reminder-test-task',
    title: 'Reminder test task',
    dueDate: DateUtils.dateOnly(due),
    dueTime: TimeOfDay(hour: due.hour, minute: due.minute),
    reminderEnabled: true,
    reminderMinutesBefore: 10,
  );
}

class _FakeReminderService implements TaskReminderService {
  final scheduledTasks = <Task>[];
  final cancelledIds = <String>[];
  final restoredTasks = <String>[];

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<bool> scheduleReminder(Task task) async {
    scheduledTasks.add(task);
    return true;
  }

  @override
  Future<void> cancelReminder(String taskId) async {
    cancelledIds.add(taskId);
  }

  @override
  Future<void> restoreReminders(List<Task> tasks) async {
    restoredTasks.addAll(tasks.map((task) => task.id));
  }
}
