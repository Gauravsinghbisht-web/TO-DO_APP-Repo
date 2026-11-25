
import 'providers/auth_provider.dart' as taskflow_auth;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/taskflow_theme.dart';
import 'data/repositories/task_repository.dart';
import 'data/services/notification_service.dart';
import 'providers/task_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
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

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
        ),
        ChangeNotifierProvider<taskflow_auth.AuthProvider>(
          create: (_) => taskflow_auth.AuthProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => TaskProvider(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'TaskFlow',
            debugShowCheckedModeBanner: false,

            // Light theme
            theme: TaskFlowTheme.light,

            // Dark theme
            darkTheme: TaskFlowTheme.dark,

            // Selected theme mode
            themeMode: themeProvider.themeMode,

            home: const AuthGate(),

            routes: {
              '/login': (_) => const LoginScreen(),
            },
          );
        },
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        debugPrint(
          'TASKFLOW AUTH GATE: '
          'State = ${snapshot.connectionState}, '
          'User = ${snapshot.data?.email}',
        );

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          debugPrint(
            'TASKFLOW AUTH GATE ERROR: ${snapshot.error}',
          );

          return const Scaffold(
            body: Center(
              child: Text('Could not check your login status.'),
            ),
          );
        }

        if (snapshot.data != null) {
          return const HomeScreen();
        }

        return const SplashScreen();
      },
    );
  }
}

class _StorageErrorScreen extends StatefulWidget {
  const _StorageErrorScreen({required this.onRetry});

  final Future<void> Function()? onRetry;

  @override
  State<_StorageErrorScreen> createState() =>
      _StorageErrorScreenState();
}

class _StorageErrorScreenState extends State<_StorageErrorScreen> {
  bool _retrying = false;

  Future<void> _retry() async {
    final retry = widget.onRetry;

    if (retry == null || _retrying) return;

    setState(() => _retrying = true);

    await retry();

    if (mounted) {
      setState(() => _retrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                onPressed:
                    _retrying || widget.onRetry == null ? null : _retry,
                icon: _retrying
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.refresh_rounded),
                label: Text(
                  _retrying ? 'Trying again…' : 'Try Again',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
