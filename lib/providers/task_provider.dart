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
      _errorMessage = 'Could not save task: $error';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTask(Task task) async {
    try {
      final updated = await _repository.updateTask(task);
      _errorMessage = updated ? null : 'Task no longer exists.';
      if (updated) {
        notifyListeners();
        await _syncReminder(task);
      }
      return updated;
    } catch (error) {
      _errorMessage = 'Could not update task: $error';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTask(String taskId) async {
    try {
      final deleted = await _repository.deleteTask(taskId);
      _errorMessage = deleted ? null : 'Task no longer exists.';
      if (deleted) {
        notifyListeners();
        await _cancelReminder(taskId);
      }
      return deleted;
    } catch (error) {
      _errorMessage = 'Could not delete task: $error';
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleTaskCompletion(String taskId) async {
    try {
      final changed = await _repository.toggleTaskCompletion(taskId);
      _errorMessage = changed ? null : 'Task no longer exists.';
      if (changed) {
        notifyListeners();
        for (final task in tasks) {
          if (task.id == taskId) {
            await _syncReminder(task);
            break;
          }
        }
      }
      return changed;
    } catch (error) {
      _errorMessage = 'Could not update task completion: $error';
      notifyListeners();
      return false;
    }
  }

  Future<bool> requestReminderPermission() async {
    final reminderService = this.reminderService;
    if (reminderService == null) return true;
    try {
      return await reminderService.requestPermission();
    } catch (error) {
      _notificationError = 'Could not request notification permission: $error';
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
      // A notification failure must not undo a successful task write.
      _notificationError =
          'Task saved, but its reminder could not be updated: $error';
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
      _notificationError =
          'Task deleted, but its reminder could not be cancelled: $error';
      notifyListeners();
    }
  }
}
