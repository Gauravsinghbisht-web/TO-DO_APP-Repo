import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'app.dart';
import 'data/repositories/task_repository.dart';
import 'data/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _launchTaskFlow();
}

Future<void> _launchTaskFlow() async {
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
  } catch (error, stackTrace) {
    debugPrint('TaskFlow could not load local task data: $error\n$stackTrace');
    runApp(TaskFlowApp(startupError: error, onRetryStartup: _retryTaskFlow));
  }
}

Future<void> _retryTaskFlow() async {
  try {
    await Hive.close();
  } catch (error) {
    debugPrint('TaskFlow could not close the previous Hive session: $error');
  }
  await _launchTaskFlow();
}

// Keeps the old MyApp name available for the starter test.
typedef MyApp = TaskFlowApp;
