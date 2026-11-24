
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/task.dart';

class FirestoreService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirestoreService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  // Check whether a user is logged in.
  bool get isSignedIn => _auth.currentUser != null;

  // Get the currently logged-in user's UID.
  String get _userId {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in.');
    }

    return user.uid;
  }

  // Reference to the current user's document.
  DocumentReference<Map<String, dynamic>> get _userDocument {
    return _firestore.collection('users').doc(_userId);
  }

  // Reference to the current user's tasks collection.
  CollectionReference<Map<String, dynamic>> get userTasks {
    return _userDocument.collection('tasks');
  }

  // Save or update the user's Firestore profile.
  Future<void> saveUserProfile({
    required String name,
    required String email,
  }) async {
    final profile = await _userDocument.get();

    await _userDocument.set({
      'name': name,
      'email': email,
      if (!profile.exists) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Get the current user's profile.
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserProfile() {
    return _userDocument.get();
  }

  // Convert Task into Firestore-compatible data.
  Map<String, dynamic> _taskToMap(Task task) {
    return {
      'id': task.id,
      'title': task.title,
      'description': task.description,
      'category': task.category,
      'priority': task.priority.name,
      'dueDate': task.dueDate == null
          ? null
          : Timestamp.fromDate(task.dueDate!),
      'dueTime': task.dueTime == null
          ? null
          : {
              'hour': task.dueTime!.hour,
              'minute': task.dueTime!.minute,
            },
      'reminderEnabled': task.reminderEnabled,
      'reminderMinutesBefore': task.reminderMinutesBefore,
      'recurrenceType': task.recurrenceType.name,
      'recurrenceDayOfMonth': task.recurrenceDayOfMonth,
      'parentTaskId': task.parentTaskId,
      'isCompleted': task.isCompleted,
      'subtasks': task.subtasks,
      'createdAt': Timestamp.fromDate(task.createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // Convert Firestore document into a Task object.
  Task _taskFromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data()!;

    final priorityName = data['priority'] as String?;

    final priority = TaskPriority.values.firstWhere(
      (value) => value.name == priorityName,
      orElse: () => TaskPriority.medium,
    );

    final dueTimeData = data['dueTime'] as Map<String, dynamic>?;

    final dueDateData = data['dueDate'];

    final dueDate = dueDateData is Timestamp
        ? dueDateData.toDate()
        : dueDateData is DateTime
            ? dueDateData
            : null;

    final createdAtData = data['createdAt'];

    final createdAt = createdAtData is Timestamp
        ? createdAtData.toDate()
        : createdAtData is DateTime
            ? createdAtData
            : DateTime.now();

    return Task(
      id: document.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      category: data['category'] as String? ?? 'Personal',
      priority: priority,
      dueDate: dueDate,
      dueTime: dueTimeData == null
          ? null
          : TimeOfDay(
              hour: (dueTimeData['hour'] as num).toInt(),
              minute: (dueTimeData['minute'] as num).toInt(),
            ),
      reminderEnabled: data['reminderEnabled'] as bool? ?? false,
      reminderMinutesBefore:
          (data['reminderMinutesBefore'] as num?)?.toInt() ?? 15,
      recurrenceType: TaskRecurrence.fromName(
        data['recurrenceType'] as String?,
      ),
      recurrenceDayOfMonth:
          (data['recurrenceDayOfMonth'] as num?)?.toInt(),
      parentTaskId: data['parentTaskId'] as String?,
      isCompleted: data['isCompleted'] as bool? ?? false,
      subtasks: (data['subtasks'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
      createdAt: createdAt,
    );
  }

  // Add a task to Firestore.
  Future<void> addTask(Task task) async {
    await userTasks.doc(task.id).set(_taskToMap(task));
  }

  // Update a task in Firestore.
  Future<void> updateTask(Task task) async {
    await userTasks.doc(task.id).set(
      _taskToMap(task),
      SetOptions(merge: true),
    );
  }

  // Delete a task from Firestore.
  Future<void> deleteTask(String taskId) async {
    await userTasks.doc(taskId).delete();
  }

  // Fetch all tasks belonging to the current user.
  Future<List<Task>> fetchTasks() async {
    final snapshot = await userTasks.get();

    return snapshot.docs.map(_taskFromDocument).toList();
  }
}
