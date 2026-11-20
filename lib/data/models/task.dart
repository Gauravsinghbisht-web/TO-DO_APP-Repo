import 'package:flutter/material.dart';

enum TaskPriority { low, medium, high }

/// How often a task should create its next occurrence after completion.
enum TaskRecurrence {
  none('Does not repeat'),
  daily('Every day'),
  weekly('Every week'),
  monthly('Every month');

  const TaskRecurrence(this.label);
  final String label;
  static TaskRecurrence fromName(String? name) => TaskRecurrence.values
      .firstWhere((value) => value.name == name, orElse: () => none);
}

/// A task stored by the shared TaskFlow task repository.
class Task {
  Task({
    String? id,
    required this.title,
    this.description = '',
    this.category = 'Personal',
    this.priority = TaskPriority.medium,
    this.dueDate,
    this.dueTime,
    this.reminderEnabled = false,
    this.reminderMinutesBefore = 15,
    this.recurrenceType = TaskRecurrence.none,
    int? recurrenceDayOfMonth,
    this.parentTaskId,
    this.isCompleted = false,
    List<String> subtasks = const [],
    DateTime? createdAt,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
       recurrenceDayOfMonth = recurrenceDayOfMonth ?? dueDate?.day,
       subtasks = List.unmodifiable(subtasks),
       createdAt = createdAt ?? DateTime.now();

  final String id;
  final String title;
  final String description;
  final String category;
  final TaskPriority priority;
  final DateTime? dueDate;
  final TimeOfDay? dueTime;
  final bool reminderEnabled;
  final int reminderMinutesBefore;
  final TaskRecurrence recurrenceType;
  final int? recurrenceDayOfMonth;
  final String? parentTaskId;
  final bool isCompleted;
  final List<String> subtasks;
  final DateTime createdAt;

  /// Returns a new task with the supplied values changed.
  Task copyWith({
    String? title,
    String? description,
    String? category,
    TaskPriority? priority,
    DateTime? dueDate,
    TimeOfDay? dueTime,
    bool? reminderEnabled,
    int? reminderMinutesBefore,
    TaskRecurrence? recurrenceType,
    int? recurrenceDayOfMonth,
    bool? isCompleted,
    List<String>? subtasks,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderMinutesBefore:
          reminderMinutesBefore ?? this.reminderMinutesBefore,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      recurrenceDayOfMonth: recurrenceDayOfMonth ?? this.recurrenceDayOfMonth,
      parentTaskId: parentTaskId,
      isCompleted: isCompleted ?? this.isCompleted,
      subtasks: subtasks ?? this.subtasks,
      createdAt: createdAt,
    );
  }
}
