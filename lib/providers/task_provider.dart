
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../data/models/task.dart';
import '../data/repositories/task_repository.dart';
import '../data/services/firestore_service.dart';
import '../data/services/notification_service.dart';

/// Exposes task changes and synchronizes local tasks with Firebase.
class TaskProvider extends ChangeNotifier {
  TaskProvider({
    TaskRepository? repository,
    FirestoreService? firestoreService,
    FirebaseAuth? auth,
    this.reminderService,
  }) : _repository = repository ?? TaskRepository(),
       _firestoreService = firestoreService ?? FirestoreService(),
       _auth = auth ?? FirebaseAuth.instance {
    _authSubscription = _auth.authStateChanges().listen((user) {
      unawaited(_handleAuthChange(user));
    });
  }

  final TaskRepository _repository;
  final FirestoreService _firestoreService;
  final FirebaseAuth _auth;
  final TaskReminderService? reminderService;

  StreamSubscription<User?>? _authSubscription;

  String? _errorMessage;
  String? _notificationError;
  String? _cloudSyncError;

  bool _isLoadingCloudTasks = false;

  final Set<String> _completionOperations = {};

  String? get errorMessage => _errorMessage;
  String? get notificationError => _notificationError;
  String? get cloudSyncError => _cloudSyncError;
  bool get isLoadingCloudTasks => _isLoadingCloudTasks;

  List<Task> get tasks => _repository.getAllTasks();

  List<Task> get completedTasks =>
      tasks.where((task) => task.isCompleted).toList(growable: false);

  List<Task> get pendingTasks =>
      tasks.where((task) => !task.isCompleted).toList(growable: false);

  int get totalTasks => tasks.length;
  int get completedCount => completedTasks.length;
  int get pendingCount => pendingTasks.length;

  /// Changes local storage when the Firebase account changes.
  ///
  /// Downloads cloud tasks and merges them with that account's local tasks.
  Future<void> _handleAuthChange(User? user) async {
    final userId = user?.uid;

    _isLoadingCloudTasks = user != null;
    _cloudSyncError = null;

    try {
      await _repository.switchUser(userId);

      // Refresh the UI after changing the active local task storage.
      notifyListeners();

      // A signed-out user uses the guest task box.
      if (user == null) return;

      final cloudTasks = await _firestoreService.fetchTasks();

      // Ignore an old response if the user changed while downloading.
      if (_auth.currentUser?.uid != userId) return;

      final cloudTaskIds = cloudTasks.map((task) => task.id).toSet();

      // Download cloud tasks. Cloud versions take priority for matching IDs.
      for (final cloudTask in cloudTasks) {
        final existingTask = tasks.where(
          (task) => task.id == cloudTask.id,
        );

        if (existingTask.isEmpty) {
          await _repository.addTask(cloudTask);
        } else {
          await _repository.updateTask(cloudTask);
        }
      }

      // Upload account-specific local tasks that aren't in Firestore.
      final localOnlyTasks = tasks
          .where((task) => !cloudTaskIds.contains(task.id))
          .toList(growable: false);

      for (final localTask in localOnlyTasks) {
        if (_auth.currentUser?.uid != userId) return;

        await _firestoreService.addTask(localTask);
      }

      _cloudSyncError = null;

      debugPrint(
        'TaskFlow: Firebase sync completed for user $userId. '
        'Downloaded ${cloudTasks.length} tasks and uploaded '
        '${localOnlyTasks.length} local tasks.',
      );

      notifyListeners();
    } catch (error) {
      debugPrint('TaskFlow failed to load Firebase tasks: $error');

      if (_auth.currentUser?.uid == userId) {
        _cloudSyncError =
            'Could not load your cloud tasks. '
            'Please check your internet connection and try again.';
        notifyListeners();
      }
    } finally {
      _isLoadingCloudTasks = false;
      notifyListeners();
    }
  }

  // Sync changes to Firestore without losing successful local changes.
  Future<void> _syncCloud(Future<void> Function() operation) async {
    if (!_firestoreService.isSignedIn) return;

    try {
      await operation();
      _cloudSyncError = null;
    } catch (error) {
      debugPrint('TaskFlow cloud sync failed: $error');

      _cloudSyncError =
          'Your task is saved locally, but cloud sync failed. '
          'Please check your internet connection.';

      notifyListeners();
    }
  }

  // Add task.
  Future<bool> addTask(Task task) async {
    try {
      await _repository.addTask(task);

      _errorMessage = null;
      notifyListeners();

      await _syncCloud(() => _firestoreService.addTask(task));
      await _syncReminder(task);

      return true;
    } catch (error) {
      debugPrint('TaskFlow failed to save a task: $error');

      _errorMessage = 'We could not save your task. Please try again.';
      notifyListeners();

      return false;
    }
  }

  // Update task.
  Future<bool> updateTask(Task task) async {
    try {
      final updated = await _repository.updateTask(task);

      _errorMessage = updated
          ? null
          : 'That task could not be found. Refresh and try again.';

      if (updated) {
        notifyListeners();

        await _syncCloud(() => _firestoreService.updateTask(task));
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

  // Delete task.
  Future<bool> deleteTask(String taskId) async {
    try {
      final deleted = await _repository.deleteTask(taskId);

      _errorMessage = deleted
          ? null
          : 'That task could not be found. Refresh and try again.';

      if (deleted) {
        notifyListeners();

        await _syncCloud(() => _firestoreService.deleteTask(taskId));
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

  // Toggle task completion.
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
            await _syncCloud(() => _firestoreService.updateTask(task));

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

      _errorMessage =
          'We could not update the task status. Please try again.';
      notifyListeners();

      return false;
    } finally {
      _completionOperations.remove(taskId);
    }
  }

  // Create the next recurring task.
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

  // Request reminder permission.
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

  // Synchronize task reminder.
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

      _notificationError =
          'Task saved, but its reminder could not be updated. '
          'Check notification settings.';

      notifyListeners();
    }
  }

  // Cancel task reminder.
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

  @override
  void dispose() {
    unawaited(_authSubscription?.cancel());
    super.dispose();
  }
}
