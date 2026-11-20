import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'package:flutter_application_1/data/models/task.dart';
import 'package:flutter_application_1/data/repositories/task_repository.dart';

void main() {
  test('task data survives repository restarts and CRUD writes', () async {
    final directory = await Directory.systemTemp.createTemp('taskflow_hive_');
    addTearDown(() async {
      await Hive.close();
      await directory.delete(recursive: true);
    });

    var repository = await TaskRepository.open(directory: directory.path);
    final task = Task(
      id: 'persistent-task',
      title: 'Persist this task',
      description: 'Stored by Hive',
      category: 'Design',
      priority: TaskPriority.high,
      dueDate: DateTime(2026, 11, 24),
      dueTime: const TimeOfDay(hour: 14, minute: 35),
      reminderEnabled: true,
      reminderMinutesBefore: 20,
      recurrenceType: TaskRecurrence.monthly,
      parentTaskId: 'original-occurrence',
      subtasks: const ['Draft', 'Review'],
      createdAt: DateTime(2026, 11, 20, 9),
    );
    await repository.addTask(task);

    await Hive.close();
    repository = await TaskRepository.open(directory: directory.path);
    var savedTask = repository.getAllTasks().singleWhere(
      (saved) => saved.id == task.id,
    );
    expect(savedTask.title, task.title);
    expect(savedTask.dueTime, const TimeOfDay(hour: 14, minute: 35));
    expect(savedTask.reminderEnabled, isTrue);
    expect(savedTask.reminderMinutesBefore, 20);
    expect(savedTask.recurrenceType, TaskRecurrence.monthly);
    expect(savedTask.recurrenceDayOfMonth, 24);
    expect(savedTask.parentTaskId, 'original-occurrence');
    expect(savedTask.subtasks, ['Draft', 'Review']);

    final editedTask = savedTask.copyWith(
      title: 'Edited persistent task',
      description: 'Updated description',
      category: 'Work',
      priority: TaskPriority.low,
    );
    expect(await repository.updateTask(editedTask), isTrue);
    expect(await repository.toggleTaskCompletion(task.id), isTrue);

    await Hive.close();
    repository = await TaskRepository.open(directory: directory.path);
    savedTask = repository.getAllTasks().singleWhere(
      (saved) => saved.id == task.id,
    );
    expect(savedTask.title, 'Edited persistent task');
    expect(savedTask.isCompleted, isTrue);
    expect(savedTask.dueDate, DateTime(2026, 11, 24));
    expect(savedTask.recurrenceType, TaskRecurrence.monthly);
    expect(savedTask.recurrenceDayOfMonth, 24);

    expect(await repository.deleteTask(task.id), isTrue);
    await Hive.close();
    repository = await TaskRepository.open(directory: directory.path);
    expect(
      repository.getAllTasks().any((saved) => saved.id == task.id),
      isFalse,
    );
  });

  test(
    'Hive records without recurrence fields load as non-recurring',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'taskflow_legacy_hive_',
      );
      addTearDown(() async {
        await Hive.close();
        await directory.delete(recursive: true);
      });

      Hive.init(directory.path);
      final tasks = await Hive.openBox<dynamic>('taskflow_tasks');
      final settings = await Hive.openBox<dynamic>('taskflow_settings');
      await settings.put('sample_tasks_seeded', true);
      await tasks.put('legacy-task', {
        'id': 'legacy-task',
        'title': 'Saved before recurrence support',
        'description': '',
        'category': 'Personal',
        'priority': 'medium',
        'dueDate': null,
        'dueTime': null,
        'reminderEnabled': false,
        'reminderMinutesBefore': 15,
        'isCompleted': false,
        'subtasks': <String>[],
        'createdAt': DateTime(2026, 1, 1).toIso8601String(),
      });
      await Hive.close();

      final repository = await TaskRepository.open(directory: directory.path);
      expect(
        repository.getAllTasks().single.recurrenceType,
        TaskRecurrence.none,
      );
      expect(repository.getAllTasks().single.parentTaskId, isNull);
    },
  );
}
