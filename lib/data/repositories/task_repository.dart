import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../models/task.dart';

/// Stores tasks in Hive for normal app use and supports memory data in tests.
class TaskRepository {
  TaskRepository({List<Task>? initialTasks})
    : _box = null,
      _tasks = initialTasks ?? _createSampleTasks();

  TaskRepository._persistent(this._box, this._tasks);

  static const _tasksBoxName = 'taskflow_tasks';
  static const _settingsBoxName = 'taskflow_settings';
  static const _seededKey = 'sample_tasks_seeded';

  final Box<dynamic>? _box;
  final List<Task> _tasks;

  /// Opens Hive and loads saved tasks before the app is shown.
  static Future<TaskRepository> open({String? directory}) async {
    if (directory == null) {
      await Hive.initFlutter();
    } else {
      Hive.init(directory);
    }

    final tasksBox = await Hive.openBox<dynamic>(_tasksBoxName);
    final settingsBox = await Hive.openBox<dynamic>(_settingsBoxName);

    // Seed sample tasks once. If the user later deletes every task, they stay
    // deleted after the next launch.
    if (settingsBox.get(_seededKey) != true) {
      if (tasksBox.isEmpty) {
        final samples = _createSampleTasks();
        await tasksBox.putAll({
          for (final task in samples) task.id: _toMap(task),
        });
      }
      await settingsBox.put(_seededKey, true);
    }

    final tasks = tasksBox.values
        .map((value) => _fromMap(Map<dynamic, dynamic>.from(value as Map)))
        .toList();
    return TaskRepository._persistent(tasksBox, tasks);
  }

  /// Returns a read-only copy of the repository's loaded task cache.
  List<Task> getAllTasks() => List.unmodifiable(_tasks);

  /// Adds a task and prevents the same task ID from being added twice.
  Future<void> addTask(Task task) async {
    if (_tasks.any((savedTask) => savedTask.id == task.id)) {
      throw StateError('A task with ID ${task.id} already exists.');
    }
    await _box?.put(task.id, _toMap(task));
    _tasks.add(task);
  }

  /// Replaces an existing task. Returns false when the task was not found.
  Future<bool> updateTask(Task task) async {
    final index = _tasks.indexWhere((savedTask) => savedTask.id == task.id);
    if (index == -1) return false;

    await _box?.put(task.id, _toMap(task));
    _tasks[index] = task;
    return true;
  }

  /// Removes a task by ID. Returns false when the task was not found.
  Future<bool> deleteTask(String taskId) async {
    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index == -1) return false;

    await _box?.delete(taskId);
    _tasks.removeAt(index);
    return true;
  }

  /// Switches a task between completed and pending.
  Future<bool> toggleTaskCompletion(String taskId) async {
    final task = _tasks.where((item) => item.id == taskId).firstOrNull;
    if (task == null) return false;
    return updateTask(task.copyWith(isCompleted: !task.isCompleted));
  }

  static Map<String, Object?> _toMap(Task task) => {
    'id': task.id,
    'title': task.title,
    'description': task.description,
    'category': task.category,
    'priority': task.priority.name,
    'dueDate': task.dueDate?.toIso8601String(),
    'dueTime': task.dueTime == null
        ? null
        : {'hour': task.dueTime!.hour, 'minute': task.dueTime!.minute},
    'reminderEnabled': task.reminderEnabled,
    'reminderMinutesBefore': task.reminderMinutesBefore,
    'recurrenceType': task.recurrenceType.name,
    'recurrenceDayOfMonth': task.recurrenceDayOfMonth,
    'parentTaskId': task.parentTaskId,
    'isCompleted': task.isCompleted,
    'subtasks': task.subtasks,
    'createdAt': task.createdAt.toIso8601String(),
  };

  static Task _fromMap(Map<dynamic, dynamic> map) {
    final priorityName = map['priority'] as String?;
    final priority = TaskPriority.values.firstWhere(
      (value) => value.name == priorityName,
      orElse: () => TaskPriority.medium,
    );
    final dueTimeMap = map['dueTime'] as Map?;

    final dueDate = map['dueDate'] == null
        ? null
        : DateTime.tryParse(map['dueDate'] as String);
    return Task(
      id: map['id'] as String,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? 'Personal',
      priority: priority,
      dueDate: dueDate,
      dueTime: dueTimeMap == null
          ? null
          : TimeOfDay(
              hour: (dueTimeMap['hour'] as num).toInt(),
              minute: (dueTimeMap['minute'] as num).toInt(),
            ),
      reminderEnabled: map['reminderEnabled'] as bool? ?? false,
      reminderMinutesBefore:
          (map['reminderMinutesBefore'] as num?)?.toInt() ?? 15,
      recurrenceType: TaskRecurrence.fromName(map['recurrenceType'] as String?),
      recurrenceDayOfMonth:
          (map['recurrenceDayOfMonth'] as num?)?.toInt() ?? dueDate?.day,
      parentTaskId: map['parentTaskId'] as String?,
      isCompleted: map['isCompleted'] as bool? ?? false,
      subtasks: (map['subtasks'] as List? ?? const []).cast<String>(),
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  static List<Task> _createSampleTasks() {
    final now = DateTime.now();
    DateTime day(int offset) =>
        DateUtils.dateOnly(now.add(Duration(days: offset)));
    return [
      Task(
        title: 'Finalize Q4 mobile app launch checklist',
        description: 'Review launch readiness and QA staging flags.',
        category: 'Work',
        priority: TaskPriority.high,
        dueDate: day(0),
        dueTime: const TimeOfDay(hour: 16, minute: 0),
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      Task(
        title: 'Client presentation deck rehearsal',
        description: 'Review the value proposition and roadmap slides.',
        category: 'Work',
        priority: TaskPriority.high,
        dueDate: day(1),
        dueTime: const TimeOfDay(hour: 10, minute: 0),
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      Task(
        title: 'Wireframe task analytics reporting module',
        description: 'Draft mockups for productivity charts.',
        category: 'Design',
        priority: TaskPriority.medium,
        dueDate: day(2),
        dueTime: const TimeOfDay(hour: 11, minute: 30),
        createdAt: now,
      ),
      Task(
        title: 'Update quarterly billing invoices',
        description: 'Review the latest account invoices.',
        category: 'Personal',
        priority: TaskPriority.medium,
        dueDate: day(4),
        dueTime: const TimeOfDay(hour: 14, minute: 0),
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      Task(
        title: 'Morning sprint standup',
        description: 'Discuss the engineering migration plan.',
        category: 'Work',
        priority: TaskPriority.medium,
        dueDate: day(0),
        dueTime: const TimeOfDay(hour: 9, minute: 30),
        isCompleted: true,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      Task(
        title: 'Weekly mindfulness and reading',
        description: 'Take a short break for mindfulness and reading.',
        category: 'Health',
        priority: TaskPriority.low,
        dueDate: day(0),
        dueTime: const TimeOfDay(hour: 18, minute: 0),
        createdAt: now.subtract(const Duration(days: 5)),
      ),
    ];
  }
}
