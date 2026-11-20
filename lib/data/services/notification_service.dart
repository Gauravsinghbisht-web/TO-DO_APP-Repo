import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/task.dart';

/// Notification operations used by TaskProvider.
abstract interface class TaskReminderService {
  Future<bool> requestPermission();
  Future<bool> scheduleReminder(Task task);
  Future<void> cancelReminder(String taskId);
  Future<void> restoreReminders(List<Task> tasks);
}

/// Creates and maintains local reminder notifications for TaskFlow tasks.
class NotificationService implements TaskReminderService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _channelId = 'taskflow_task_reminders';
  static const _channelName = 'Task reminders';
  static const _channelDescription = 'Reminders for your scheduled tasks.';
  static const _payloadPrefix = 'taskflow:';
  static const _timezoneChannel = MethodChannel('taskflow/device_timezone');

  static const _channel = AndroidNotificationChannel(
    _channelId,
    _channelName,
    description: _channelDescription,
    importance: Importance.high,
  );

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    timezone_data.initializeTimeZones();
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final timezoneName = await _timezoneChannel.invokeMethod<String>(
          'getTimeZone',
        );
        if (timezoneName != null) {
          tz.setLocalLocation(tz.getLocation(timezoneName));
        }
      } on PlatformException catch (error) {
        debugPrint('TaskFlow could not read the device timezone: $error');
      }
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      ),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);
    _initialized = true;
  }

  @override
  Future<bool> requestPermission() async {
    if (!_initialized) return false;

    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final granted = await _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission();
        return granted ?? true;
      }
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final granted = await _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true);
        return granted ?? true;
      }
      if (defaultTargetPlatform == TargetPlatform.macOS) {
        final granted = await _plugin
            .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true);
        return granted ?? true;
      }
      return true;
    } catch (error) {
      debugPrint('TaskFlow could not request notification permission: $error');
      return false;
    }
  }

  /// Returns the local reminder instant, or null if the task has no due date
  /// or time from which to calculate one.
  static tz.TZDateTime? reminderTimeFor(Task task) {
    final date = task.dueDate;
    final time = task.dueTime;
    if (date == null || time == null) return null;

    return tz.TZDateTime(
      tz.local,
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    ).subtract(Duration(minutes: task.reminderMinutesBefore));
  }

  /// Uses a stable FNV-1a hash so task IDs map to the same notification ID
  /// across app launches (Dart's regular String.hashCode is not stable).
  static int notificationIdFor(String taskId) {
    var hash = 0x811c9dc5;
    for (final codeUnit in taskId.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash & 0x7fffffff;
  }

  @override
  Future<bool> scheduleReminder(Task task) async {
    _ensureInitialized();
    final id = notificationIdFor(task.id);
    if (!task.reminderEnabled || task.isCompleted) {
      await _plugin.cancel(id: id);
      return false;
    }

    final scheduledTime = reminderTimeFor(task);
    if (scheduledTime == null ||
        !scheduledTime.isAfter(tz.TZDateTime.now(tz.local))) {
      await _plugin.cancel(id: id);
      return false;
    }

    final notificationsEnabled = await _notificationsEnabled();
    if (!notificationsEnabled) return false;

    final offset = task.reminderMinutesBefore;
    final reminderText = offset == 0
        ? 'This task is due now.'
        : 'This task is due in $offset ${offset == 1 ? 'minute' : 'minutes'}.';
    await _plugin.zonedSchedule(
      id: id,
      title: task.title,
      body: reminderText,
      scheduledDate: scheduledTime,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: '$_payloadPrefix${task.id}',
    );
    return true;
  }

  @override
  Future<void> cancelReminder(String taskId) async {
    _ensureInitialized();
    await _plugin.cancel(id: notificationIdFor(taskId));
  }

  /// Removes stale TaskFlow notifications and upserts the notification for
  /// every currently eligible task. Reusing the same ID replaces, rather than
  /// duplicates, an existing scheduled reminder.
  @override
  Future<void> restoreReminders(List<Task> tasks) async {
    _ensureInitialized();
    final validIds = <int>{};
    for (final task in tasks) {
      if (!task.reminderEnabled || task.isCompleted) continue;
      final at = reminderTimeFor(task);
      if (at != null && at.isAfter(tz.TZDateTime.now(tz.local))) {
        validIds.add(notificationIdFor(task.id));
      }
    }

    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending) {
      if (request.payload?.startsWith(_payloadPrefix) == true &&
          !validIds.contains(request.id)) {
        await _plugin.cancel(id: request.id);
      }
    }

    for (final task in tasks) {
      await scheduleReminder(task);
    }
  }

  Future<bool> _notificationsEnabled() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.areNotificationsEnabled() ??
          true;
    }
    return true;
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError('NotificationService.initialize() must run first.');
    }
  }
}
