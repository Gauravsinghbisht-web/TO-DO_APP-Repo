import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:flutter_application_1/core/theme/taskflow_theme.dart';
import 'package:flutter_application_1/data/models/task.dart';
import 'package:flutter_application_1/data/repositories/task_repository.dart';
import 'package:flutter_application_1/providers/task_provider.dart';
import 'package:flutter_application_1/screens/calendar_screen.dart';
import 'package:flutter_application_1/screens/home_screen.dart';
import 'package:flutter_application_1/screens/statistics_screen.dart';
import 'package:flutter_application_1/screens/tasks_screen.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('home gives an add action when no tasks exist', (tester) async {
    _setLargeViewport(tester);
    await tester.pumpWidget(_withTasks(const HomeScreen(), []));

    expect(find.text('No tasks yet'), findsOneWidget);
    expect(find.text('Add Task'), findsWidgets);
  });

  testWidgets('tasks screen explains empty, completed and pending lists', (
    tester,
  ) async {
    _setLargeViewport(tester);
    await tester.pumpWidget(_withTasks(const TasksScreen(), []));
    expect(find.text('No tasks yet'), findsOneWidget);

    await tester.tap(find.text('Done (0)'));
    await tester.pumpAndSettle();
    expect(find.text('No completed tasks yet'), findsOneWidget);

    await tester.tap(find.text('View Pending Tasks'));
    await tester.pumpAndSettle();
    expect(find.text('No pending tasks'), findsOneWidget);
  });

  testWidgets('tasks screen offers clear search when there are no results', (
    tester,
  ) async {
    _setLargeViewport(tester);
    final task = Task(title: 'Prepare project notes');
    await tester.pumpWidget(_withTasks(const TasksScreen(), [task]));
    await tester.enterText(find.byType(TextField).first, 'not in this list');
    await tester.pumpAndSettle();

    expect(find.text('No matching tasks'), findsOneWidget);
    await tester.tap(find.text('Clear Search & Filters'));
    await tester.pumpAndSettle();
    expect(find.text(task.title), findsOneWidget);
  });

  testWidgets('calendar empty date offers to add a task', (tester) async {
    _setLargeViewport(tester);
    await tester.pumpWidget(_withTasks(const CalendarScreen(), []));

    expect(find.text('Nothing scheduled'), findsOneWidget);
    expect(find.text('Add Task'), findsWidgets);
  });

  testWidgets('statistics explains an empty date range', (tester) async {
    _setLargeViewport(tester);
    await tester.pumpWidget(_withTasks(const StatisticsScreen(), []));

    expect(find.text('No insights for this period yet'), findsOneWidget);
    expect(find.text('Add Task'), findsOneWidget);
  });
}

void _setLargeViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _withTasks(Widget screen, List<Task> tasks) {
  return ChangeNotifierProvider<TaskProvider>(
    create: (_) =>
        TaskProvider(repository: TaskRepository(initialTasks: tasks)),
    child: MaterialApp(theme: TaskFlowTheme.light, home: screen),
  );
}
