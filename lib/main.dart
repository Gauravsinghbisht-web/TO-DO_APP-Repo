import 'package:flutter/material.dart';

import 'app.dart';
import 'data/repositories/task_repository.dart';
import 'data/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final taskRepository = await TaskRepository.open();
    final notificationService = NotificationService();
    try {
      await notificationService.initialize();
      await notificationService.restoreReminders(taskRepository.getAllTasks());
    } catch (error) {
      debugPrint('Task reminders could not be restored: $error');
    }
    runApp(
      TaskFlowApp(
        taskRepository: taskRepository,
        reminderService: notificationService,
      ),
    );
  } catch (error) {
    runApp(TaskFlowApp(startupError: error));
  }
}

// Keeps the old MyApp name available for the starter test.
typedef MyApp = TaskFlowApp;
