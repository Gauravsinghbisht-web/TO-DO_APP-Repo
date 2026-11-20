import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/taskflow_theme.dart';
import 'data/repositories/task_repository.dart';
import 'data/services/notification_service.dart';
import 'providers/task_provider.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';

class TaskFlowApp extends StatelessWidget {
  const TaskFlowApp({
    super.key,
    this.taskRepository,
    this.reminderService,
    this.startupError,
  });

  final TaskRepository? taskRepository;
  final TaskReminderService? reminderService;
  final Object? startupError;

  @override
  Widget build(BuildContext context) {
    if (startupError != null) {
      return MaterialApp(
        title: 'TaskFlow',
        debugShowCheckedModeBanner: false,
        theme: TaskFlowTheme.light,
        home: _StorageErrorScreen(error: startupError.toString()),
      );
    }

    return ChangeNotifierProvider<TaskProvider>(
      create: (_) => TaskProvider(
        repository: taskRepository,
        reminderService: reminderService,
      ),
      child: MaterialApp(
        title: 'TaskFlow',
        debugShowCheckedModeBanner: false,
        theme: TaskFlowTheme.light,
        home: const SplashScreen(),
        routes: {'/login': (_) => const LoginScreen()},
      ),
    );
  }
}

class _StorageErrorScreen extends StatelessWidget {
  const _StorageErrorScreen({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.storage_rounded, size: 48),
            const SizedBox(height: 16),
            Text(
              'TaskFlow could not open local task storage.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center),
          ],
        ),
      ),
    ),
  );
}
