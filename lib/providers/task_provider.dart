import 'package:flutter/foundation.dart';

import '../data/models/task.dart';
import '../data/repositories/task_repository.dart';
import '../data/services/notification_service.dart';

/// Exposes task changes to Flutter widgets and notifies them when data changes.
class TaskProvider extends ChangeNotifier {
  TaskProvider({TaskRepository? repository, this.reminderService})
    : _repository = repository ?? TaskRepository();

  final TaskRepository _repository;
  final TaskReminderService? reminderService;
  String? _errorMessage;
  String? _notificationError;
  final Set<String> _completionOperations = {};

  String? get errorMessage => _errorMessage;
  String? get notificationError => _notificationError;

  List<Task> get tasks => _repository.getAllTasks();

  List<Task> get completedTasks =>
      tasks.where((task) => task.isCompleted).toList(growable: false);

  List<Task> get pendingTasks =>
      tasks.where((task) => !task.isCompleted).toList(growable: false);

  int get totalTasks => tasks.length;

  int get completedCount => completedTasks.length;

  int get pendingCount => pendingTasks.length;

  Future<bool> addTask(Task task) async {
    try {
      await _repository.addTask(task);
      _errorMessage = null;
      notifyListeners();
      await _syncReminder(task);
      return true;
    } catch (error) {
      debugPrint('TaskFlow failed to save a task: $error');
      _errorMessage = 'We could not save your task. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTask(Task task) async {
    try {
      final updated = await _repository.updateTask(task);
      _errorMessage = updated
          ? null
          : 'That task could not be found. Refresh and try again.';
      if (updated) {
        notifyListeners();
        await _syncReminder(task);
      }
      return updated;
    } catch (error) {
      debugPrint('TaskFlow failed to update a task: $error');
      _errorMessage = 'We could not update your task. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTask(String taskId) async {
    try {
      final deleted = await _repository.deleteTask(taskId);
      _errorMessage = deleted
          ? null
          : 'That task could not be found. Refresh and try again.';
      if (deleted) {
        notifyListeners();
        await _cancelReminder(taskId);
      }
      return deleted;
    } catch (error) {
      debugPrint('TaskFlow failed to delete a task: $error');
      _errorMessage = 'We could not delete your task. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleTaskCompletion(String taskId) async {
    if (!_completionOperations.add(taskId)) return false;
    try {
      final changed = await _repository.toggleTaskCompletion(taskId);
      _errorMessage = changed
          ? null
          : 'That task could not be found. Refresh and try again.';
      if (changed) {
        notifyListeners();
        for (final task in tasks) {
          if (task.id == taskId) {
            await _syncReminder(task);
            if (task.isCompleted &&
                task.recurrenceType != TaskRecurrence.none) {
              await _createNextOccurrence(task);
            }
            break;
          }
        }
      }
      return changed;
    } catch (error) {
      debugPrint('TaskFlow failed to update task status: $error');
      _errorMessage = 'We could not update the task status. Please try again.';
      notifyListeners();
      return false;
    } finally {
      _completionOperations.remove(taskId);
    }
  }

  Future<void> _createNextOccurrence(Task completedTask) async {
    if (tasks.any((task) => task.parentTaskId == completedTask.id)) return;
    final nextDueDate = _nextDueDate(completedTask);
    if (nextDueDate == null) return;

    final nextTask = Task(
      id: '${completedTask.id}_${nextDueDate.millisecondsSinceEpoch}',
      title: completedTask.title,
      description: completedTask.description,
      category: completedTask.category,
      priority: completedTask.priority,
      dueDate: nextDueDate,
      dueTime: completedTask.dueTime,
      reminderEnabled: completedTask.reminderEnabled,
      reminderMinutesBefore: completedTask.reminderMinutesBefore,
      recurrenceType: completedTask.recurrenceType,
      recurrenceDayOfMonth: completedTask.recurrenceDayOfMonth,
      parentTaskId: completedTask.id,
      isCompleted: false,
      subtasks: completedTask.subtasks,
    );
    // addTask persists and publishes the new occurrence, then schedules its
    // reminder through the same service as any manually created task.
    await addTask(nextTask);
  }

  static DateTime? _nextDueDate(Task task) {
    final dueDate = task.dueDate;
    if (dueDate == null) return null;
    return switch (task.recurrenceType) {
      TaskRecurrence.none => null,
      TaskRecurrence.daily => DateTime(
        dueDate.year,
        dueDate.month,
        dueDate.day + 1,
      ),
      TaskRecurrence.weekly => DateTime(
        dueDate.year,
        dueDate.month,
        dueDate.day + 7,
      ),
      TaskRecurrence.monthly => _sameDayNextMonth(
        dueDate,
        task.recurrenceDayOfMonth ?? dueDate.day,
      ),
    };
  }

  static DateTime _sameDayNextMonth(DateTime date, int dayOfMonth) {
    final firstOfNextMonth = DateTime(date.year, date.month + 1, 1);
    final lastDayOfNextMonth = DateTime(
      firstOfNextMonth.year,
      firstOfNextMonth.month + 1,
      0,
    ).day;
    return DateTime(
      firstOfNextMonth.year,
      firstOfNextMonth.month,
      dayOfMonth > lastDayOfNextMonth ? lastDayOfNextMonth : dayOfMonth,
    );
  }

  Future<bool> requestReminderPermission() async {
    final reminderService = this.reminderService;
    if (reminderService == null) return true;
    try {
      return await reminderService.requestPermission();
    } catch (error) {
      debugPrint('TaskFlow failed to check reminder permission: $error');
      _notificationError =
          'Reminder permission could not be checked. Review device settings.';
      notifyListeners();
      return false;
    }
  }

  Future<void> _syncReminder(Task task) async {
    final reminderService = this.reminderService;
    if (reminderService == null) return;
    try {
      if (task.reminderEnabled && !task.isCompleted) {
        await reminderService.scheduleReminder(task);
      } else {
        await reminderService.cancelReminder(task.id);
      }
      _notificationError = null;
    } catch (error) {
      debugPrint('TaskFlow failed to update a task reminder: $error');
      // A notification failure must not undo a successful task write.
      _notificationError =
          'Task saved, but its reminder could not be updated. Check notification settings.';
      notifyListeners();
    }
  }

  Future<void> _cancelReminder(String taskId) async {
    final reminderService = this.reminderService;
    if (reminderService == null) return;
    try {
      await reminderService.cancelReminder(taskId);
      _notificationError = null;
    } catch (error) {
      debugPrint('TaskFlow failed to cancel a task reminder: $error');
      _notificationError =
          'Task deleted, but its reminder could not be cancelled.';
      notifyListeners();
    }
  }
}
