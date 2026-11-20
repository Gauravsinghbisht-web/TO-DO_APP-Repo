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
    this.onRetryStartup,
  });

  final TaskRepository? taskRepository;
  final TaskReminderService? reminderService;
  final Object? startupError;
  final Future<void> Function()? onRetryStartup;

  @override
  Widget build(BuildContext context) {
    if (startupError != null) {
      return MaterialApp(
        title: 'TaskFlow',
        debugShowCheckedModeBanner: false,
        theme: TaskFlowTheme.light,
        home: _StorageErrorScreen(onRetry: onRetryStartup),
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

class _StorageErrorScreen extends StatefulWidget {
  const _StorageErrorScreen({required this.onRetry});

  final Future<void> Function()? onRetry;

  @override
  State<_StorageErrorScreen> createState() => _StorageErrorScreenState();
}

class _StorageErrorScreenState extends State<_StorageErrorScreen> {
  bool _retrying = false;

  Future<void> _retry() async {
    final retry = widget.onRetry;
    if (retry == null || _retrying) return;
    setState(() => _retrying = true);
    await retry();
    if (mounted) setState(() => _retrying = false);
  }

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
              'We couldn’t load your tasks',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Please try again. Your saved tasks have not been removed.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _retrying || widget.onRetry == null ? null : _retry,
              icon: _retrying
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
              label: Text(_retrying ? 'Trying again…' : 'Try Again'),
            ),
          ],
        ),
      ),
    ),
  );
}
