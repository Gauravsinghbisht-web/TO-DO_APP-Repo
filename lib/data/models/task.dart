import 'package:flutter/material.dart';

/// The priority levels available to a TaskFlow task.
enum TaskPriority { low, medium, high }

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
    this.isCompleted = false,
    List<String> subtasks = const [],
    DateTime? createdAt,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
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
      isCompleted: isCompleted ?? this.isCompleted,
      subtasks: subtasks ?? this.subtasks,
      createdAt: createdAt,
    );
  }
}
