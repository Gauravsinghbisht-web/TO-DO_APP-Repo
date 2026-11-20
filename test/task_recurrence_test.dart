import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/data/models/task.dart';
import 'package:flutter_application_1/data/repositories/task_repository.dart';
import 'package:flutter_application_1/data/services/notification_service.dart';
import 'package:flutter_application_1/providers/task_provider.dart';

void main() {
  group('recurring tasks', () {
    test(
      'daily, weekly and monthly recurrence create the right next date',
      () async {
        final start = DateTime(2026, 1, 31);
        final repository = TaskRepository(initialTasks: []);
        final reminders = _FakeReminderService();
        final provider = TaskProvider(
          repository: repository,
          reminderService: reminders,
        );

        for (final expectation in [
          (TaskRecurrence.daily, DateTime(2026, 2, 1)),
          (TaskRecurrence.weekly, DateTime(2026, 2, 7)),
          (TaskRecurrence.monthly, DateTime(2026, 2, 28)),
        ]) {
          final task = _task(
            id: 'repeat-${expectation.$1.name}',
            dueDate: start,
            recurrenceType: expectation.$1,
          );
          expect(await provider.addTask(task), isTrue);
          expect(await provider.toggleTaskCompletion(task.id), isTrue);

          final occurrence = provider.tasks.singleWhere(
            (item) => item.parentTaskId == task.id,
          );
          expect(occurrence.dueDate, expectation.$2);
          expect(occurrence.recurrenceType, expectation.$1);
          if (expectation.$1 == TaskRecurrence.monthly) {
            await provider.toggleTaskCompletion(occurrence.id);
            final marchOccurrence = provider.tasks.singleWhere(
              (item) => item.parentTaskId == occurrence.id,
            );
            expect(marchOccurrence.dueDate, DateTime(2026, 3, 31));
          }
        }
      },
    );

    test(
      'completion creates one pending occurrence and preserves fields',
      () async {
        final reminders = _FakeReminderService();
        final provider = TaskProvider(
          repository: TaskRepository(initialTasks: []),
          reminderService: reminders,
        );
        final task = _task(
          id: 'daily-source',
          dueDate: DateTime(2026, 4, 2),
          recurrenceType: TaskRecurrence.daily,
        );

        expect(await provider.addTask(task), isTrue);
        expect(await provider.toggleTaskCompletion(task.id), isTrue);
        final occurrence = provider.tasks.singleWhere(
          (item) => item.parentTaskId == task.id,
        );

        expect(occurrence.id, isNot(task.id));
        expect(occurrence.isCompleted, isFalse);
        expect(occurrence.title, task.title);
        expect(occurrence.description, task.description);
        expect(occurrence.category, task.category);
        expect(occurrence.priority, task.priority);
        expect(occurrence.dueTime, task.dueTime);
        expect(occurrence.reminderEnabled, task.reminderEnabled);
        expect(occurrence.reminderMinutesBefore, task.reminderMinutesBefore);
        expect(occurrence.subtasks, task.subtasks);
        expect(reminders.cancelledIds, contains(task.id));
        expect(
          reminders.scheduledTasks.map((item) => item.id),
          contains(occurrence.id),
        );
      },
    );

    test(
      're-completing a reopened occurrence does not duplicate its child',
      () async {
        final provider = TaskProvider(
          repository: TaskRepository(initialTasks: []),
        );
        final task = _task(
          id: 'idempotent-source',
          dueDate: DateTime(2026, 5, 1),
          recurrenceType: TaskRecurrence.weekly,
        );
        await provider.addTask(task);

        await provider.toggleTaskCompletion(task.id);
        await provider.toggleTaskCompletion(task.id); // Reopened as pending.
        expect(
          provider.tasks.where((item) => item.parentTaskId == task.id),
          hasLength(1),
        );
        await provider.toggleTaskCompletion(task.id);
        expect(
          provider.tasks.where((item) => item.parentTaskId == task.id),
          hasLength(1),
        );
      },
    );

    test(
      'deleting an occurrence cancels only that occurrence reminder',
      () async {
        final reminders = _FakeReminderService();
        final provider = TaskProvider(
          repository: TaskRepository(initialTasks: []),
          reminderService: reminders,
        );
        final original = _task(
          id: 'delete-parent',
          dueDate: DateTime(2026, 6, 1),
          recurrenceType: TaskRecurrence.daily,
        );
        await provider.addTask(original);
        await provider.toggleTaskCompletion(original.id);
        final occurrence = provider.tasks.singleWhere(
          (item) => item.parentTaskId == original.id,
        );

        expect(await provider.deleteTask(occurrence.id), isTrue);
        expect(reminders.cancelledIds.last, occurrence.id);
        expect(provider.tasks.map((item) => item.id), contains(original.id));
        expect(
          provider.tasks.where((item) => item.parentTaskId == original.id),
          isEmpty,
        );
      },
    );

    test('editing recurrence settings updates the existing task', () async {
      final provider = TaskProvider(
        repository: TaskRepository(initialTasks: []),
      );
      final task = _task(
        id: 'editable-recurrence',
        dueDate: DateTime(2026, 7, 4),
      );
      await provider.addTask(task);

      final edited = task.copyWith(recurrenceType: TaskRecurrence.monthly);
      expect(await provider.updateTask(edited), isTrue);
      expect(provider.tasks.single.recurrenceType, TaskRecurrence.monthly);
    });

    test('non-recurring tasks do not create another occurrence', () async {
      final provider = TaskProvider(
        repository: TaskRepository(initialTasks: []),
      );
      final task = _task(id: 'one-off-task', dueDate: DateTime(2026, 8, 10));
      await provider.addTask(task);

      await provider.toggleTaskCompletion(task.id);

      expect(provider.tasks, hasLength(1));
      expect(provider.tasks.single.isCompleted, isTrue);
    });
  });
}

Task _task({
  required String id,
  required DateTime dueDate,
  TaskRecurrence recurrenceType = TaskRecurrence.none,
}) => Task(
  id: id,
  title: 'Prepare weekly project report',
  description: 'Summarize progress and open questions.',
  category: 'Work',
  priority: TaskPriority.high,
  dueDate: dueDate,
  dueTime: const TimeOfDay(hour: 10, minute: 30),
  reminderEnabled: true,
  reminderMinutesBefore: 15,
  recurrenceType: recurrenceType,
  subtasks: const ['Collect updates', 'Review draft'],
);

class _FakeReminderService implements TaskReminderService {
  final scheduledTasks = <Task>[];
  final cancelledIds = <String>[];

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
  Future<void> restoreReminders(List<Task> tasks) async {}
}
