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
  testWidgets('editing and deleting a task updates shared screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final task = Task(
      id: 'phase13-test-task',
      title: 'Original TaskFlow task',
      description: 'Original description',
      category: 'Work',
      priority: TaskPriority.high,
      dueDate: DateUtils.dateOnly(DateTime.now()),
      dueTime: const TimeOfDay(hour: 10, minute: 0),
      subtasks: const ['First step'],
    );
    final provider = TaskProvider(
      repository: TaskRepository(initialTasks: [task]),
    );

    await tester.pumpWidget(_testApp(provider, const TasksScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Original TaskFlow task'), findsOneWidget);

    final editMenu = find.byTooltip('Task actions').first;
    await tester.ensureVisible(editMenu);
    await tester.tap(editMenu);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).first,
      'Edited TaskFlow task',
    );
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();
    expect(provider.tasks.single.title, 'Edited TaskFlow task');
    expect(provider.tasks.single.id, task.id);
    expect(provider.tasks.single.subtasks, ['First step']);

    await tester.pumpWidget(_testApp(provider, const HomeScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Edited TaskFlow task'), findsOneWidget);

    await tester.pumpWidget(_testApp(provider, const TasksScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Edited TaskFlow task'), findsOneWidget);

    await tester.pumpWidget(_testApp(provider, const CalendarScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Edited TaskFlow task'), findsOneWidget);

    await tester.pumpWidget(_testApp(provider, const StatisticsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Pending Tasks'), findsOneWidget);
    expect(find.text('1'), findsWidgets);

    await tester.pumpWidget(_testApp(provider, const TasksScreen()));
    await tester.pumpAndSettle();
    final deleteMenu = find.byTooltip('Task actions').first;
    await tester.ensureVisible(deleteMenu);
    await tester.tap(deleteMenu);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(provider.tasks, isEmpty);
    expect(find.text('Edited TaskFlow task'), findsNothing);

    await tester.pumpWidget(_testApp(provider, const HomeScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Edited TaskFlow task'), findsNothing);

    await tester.pumpWidget(_testApp(provider, const CalendarScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Edited TaskFlow task'), findsNothing);

    await tester.pumpWidget(_testApp(provider, const StatisticsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Pending Tasks'), findsOneWidget);
    expect(find.text('0'), findsWidgets);
  });
}

Widget _testApp(TaskProvider provider, Widget screen) {
  return ChangeNotifierProvider<TaskProvider>.value(
    value: provider,
    child: MaterialApp(theme: TaskFlowTheme.light, home: screen),
  );
}
