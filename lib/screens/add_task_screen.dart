import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/models/task.dart';
import '../providers/task_provider.dart';

/// Values returned to the screen that opened the task form.
class TaskDraft {
  TaskDraft({
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.dueDate,
    required this.dueTime,
    required this.reminderEnabled,
    required this.recurrenceType,
    required List<String> subtasks,
    required this.estimatedMinutes,
  }) : subtasks = List.unmodifiable(subtasks);

  final String title;
  final String description;
  final String category;
  final TaskPriority priority;
  final DateTime dueDate;
  final TimeOfDay dueTime;
  final bool reminderEnabled;
  final TaskRecurrence recurrenceType;
  final List<String> subtasks;
  final int estimatedMinutes;
}

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key, this.initialDate, this.taskToEdit});

  final DateTime? initialDate;
  final Task? taskToEdit;

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _subtaskController = TextEditingController();
  final _subtasks = <_Subtask>[];
  final _categories = ['Work', 'Personal', 'Design', 'Fitness', 'Study'];
  String _category = 'Work';
  TaskPriority _priority = TaskPriority.medium;
  DateTime _dueDate = DateUtils.dateOnly(DateTime.now());
  TimeOfDay _dueTime = const TimeOfDay(hour: 15, minute: 30);
  bool _reminderEnabled = true;
  TaskRecurrence _recurrenceType = TaskRecurrence.none;
  int _estimatedMinutes = 45;

  @override
  void initState() {
    super.initState();
    final task = widget.taskToEdit;
    if (task != null) {
      _titleController.text = task.title;
      _descriptionController.text = task.description;
      if (!_categories.contains(task.category)) _categories.add(task.category);
      _category = task.category;
      _priority = task.priority;
      _dueDate = task.dueDate ?? _dueDate;
      _dueTime = task.dueTime ?? _dueTime;
      _reminderEnabled = task.reminderEnabled;
      _recurrenceType = task.recurrenceType;
      _subtasks.addAll(task.subtasks.map(_Subtask.new));
    } else if (widget.initialDate != null) {
      _dueDate = DateUtils.dateOnly(widget.initialDate!);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _subtaskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const _AddTaskAppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Text(
                                widget.taskToEdit == null
                                    ? 'New Task'
                                    : 'Edit Task',
                                style: textTheme.headlineMedium,
                              ),
                              const SizedBox(width: 12),
                              const _DraftBadge(),
                              const Spacer(),
                              IconButton.filledTonal(
                                tooltip: 'Discard draft',
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _TaskDetailsCard(
                            titleController: _titleController,
                            descriptionController: _descriptionController,
                            onAddAttachment: () => _showMessage(
                              'Attachments will be available later.',
                            ),
                          ),
                          const SizedBox(height: 20),
                          _SectionLabel(
                            title: 'Category',
                            trailing: '1 selected',
                          ),
                          const SizedBox(height: 10),
                          _CategoryPicker(
                            categories: _categories,
                            selected: _category,
                            onSelected: (category) => setState(() {
                              _category = category;
                            }),
                            onAddCustom: _addCustomCategory,
                          ),
                          const SizedBox(height: 20),
                          _SectionLabel(title: 'Priority'),
                          const SizedBox(height: 10),
                          _PriorityPicker(
                            selected: _priority,
                            onSelected: (priority) => setState(() {
                              _priority = priority;
                            }),
                          ),
                          const SizedBox(height: 20),
                          const _SectionLabel(title: 'Schedule'),
                          const SizedBox(height: 10),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final dateField = _DateTimeField(
                                icon: Icons.calendar_month_rounded,
                                label: 'Due Date',
                                value: _formatDate(context, _dueDate),
                                onTap: _selectDate,
                              );
                              final timeField = _DateTimeField(
                                icon: Icons.schedule_rounded,
                                label: 'Due Time',
                                value: _dueTime.format(context),
                                onTap: _selectTime,
                              );
                              if (constraints.maxWidth < 390) {
                                return Column(
                                  children: [
                                    dateField,
                                    const SizedBox(height: 10),
                                    timeField,
                                  ],
                                );
                              }
                              return Row(
                                children: [
                                  Expanded(child: dateField),
                                  const SizedBox(width: 12),
                                  Expanded(child: timeField),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          _ReminderRepeatCard(
                            reminderEnabled: _reminderEnabled,
                            onReminderChanged: (value) => setState(() {
                              _reminderEnabled = value;
                            }),
                            recurrenceType: _recurrenceType,
                            onRecurrenceChanged: (value) => setState(() {
                              _recurrenceType = value;
                            }),
                          ),
                          const SizedBox(height: 20),
                          _SectionLabel(
                            title: 'Subtasks',
                            trailing:
                                '${_subtasks.where((item) => item.done).length} of ${_subtasks.length} completed',
                          ),
                          const SizedBox(height: 10),
                          _SubtasksCard(
                            controller: _subtaskController,
                            subtasks: _subtasks,
                            onAdd: _addSubtask,
                            onToggle: (item, value) => setState(() {
                              item.done = value;
                            }),
                            onRemove: (item) => setState(() {
                              _subtasks.remove(item);
                            }),
                          ),
                          const SizedBox(height: 18),
                          _EstimateCard(
                            minutes: _estimatedMinutes,
                            onChanged: (value) => setState(() {
                              _estimatedMinutes = value;
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                color: colors.surface,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _saveTask,
                            icon: const Icon(Icons.check_rounded),
                            label: Text(
                              widget.taskToEdit == null
                                  ? 'Save Task'
                                  : 'Save Changes',
                            ),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(56),
                              backgroundColor: colors.primary,
                              foregroundColor: colors.onPrimary,
                              textStyle: textTheme.titleLarge,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _showMessage(
                            'Save as Template is a UI preview for now.',
                          ),
                          child: Text(
                            'Save as Template',
                            style: textTheme.labelLarge?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateUtils.dateOnly(DateTime.now()),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date != null) setState(() => _dueDate = date);
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(context: context, initialTime: _dueTime);
    if (time != null) setState(() => _dueTime = time);
  }

  void _addSubtask() {
    final title = _subtaskController.text.trim();
    if (title.isEmpty) return;
    setState(() {
      _subtasks.add(_Subtask(title));
      _subtaskController.clear();
    });
  }

  Future<void> _addCustomCategory() async {
    final controller = TextEditingController();
    final category = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Category name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (category == null || category.isEmpty) return;
    setState(() {
      if (!_categories.contains(category)) _categories.add(category);
      _category = category;
    });
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<TaskProvider>();
    final hasNotificationPermission =
        !_reminderEnabled || await provider.requestReminderPermission();
    if (!mounted) return;
    final draft = TaskDraft(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _category,
      priority: _priority,
      dueDate: _dueDate,
      dueTime: _dueTime,
      reminderEnabled: _reminderEnabled,
      recurrenceType: _recurrenceType,
      subtasks: _subtasks.map((item) => item.title).toList(),
      estimatedMinutes: _estimatedMinutes,
    );
    final existingTask = widget.taskToEdit;
    final task = existingTask == null
        ? Task(
            title: draft.title,
            description: draft.description,
            category: draft.category,
            priority: draft.priority,
            dueDate: draft.dueDate,
            dueTime: draft.dueTime,
            reminderEnabled: draft.reminderEnabled,
            reminderMinutesBefore: existingTask?.reminderMinutesBefore ?? 15,
            recurrenceType: draft.recurrenceType,
            recurrenceDayOfMonth: draft.dueDate.day,
            subtasks: draft.subtasks,
          )
        : existingTask.copyWith(
            title: draft.title,
            description: draft.description,
            category: draft.category,
            priority: draft.priority,
            dueDate: draft.dueDate,
            dueTime: draft.dueTime,
            reminderEnabled: draft.reminderEnabled,
            recurrenceType: draft.recurrenceType,
            recurrenceDayOfMonth: draft.dueDate.day,
            subtasks: draft.subtasks,
          );
    final saved = existingTask == null
        ? await provider.addTask(task)
        : await provider.updateTask(task);
    if (!mounted) return;
    if (!saved) {
      _showMessage(
        provider.errorMessage ??
            'We could not save this task. Please try again.',
        onRetry: () => _saveTask(),
      );
      return;
    }
    if (_reminderEnabled && !hasNotificationPermission) {
      _showMessage(
        'Task saved. Allow notifications in device settings to receive reminders.',
      );
    }
    Navigator.of(context).pop(task);
  }

  String _formatDate(BuildContext context, DateTime date) {
    final today = DateUtils.dateOnly(DateTime.now());
    final selected = DateUtils.dateOnly(date);
    if (selected == today) return 'Today, ${_monthDay(date)}';
    if (selected == today.add(const Duration(days: 1))) {
      return 'Tomorrow, ${_monthDay(date)}';
    }
    return MaterialLocalizations.of(context).formatMediumDate(date);
  }

  String _monthDay(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  void _showMessage(String message, {VoidCallback? onRetry}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        action: onRetry == null
            ? null
            : SnackBarAction(label: 'Retry', onPressed: onRetry),
      ),
    );
  }
}

class _Subtask {
  _Subtask(this.title);

  final String title;
  bool done = false;
}

class _AddTaskAppBar extends StatelessWidget {
  const _AddTaskAppBar();

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    elevation: 1,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              Icons.check_rounded,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Add Task',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          IconButton(
            tooltip: 'More options',
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No additional options yet.'),
                behavior: SnackBarBehavior.floating,
              ),
            ),
            icon: const Icon(Icons.more_vert_rounded),
          ),
          CircleAvatar(
            radius: 17,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(
              Icons.person_rounded,
              size: 20,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    ),
  );
}

class _DraftBadge extends StatelessWidget {
  const _DraftBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: ShapeDecoration(
      color: Theme.of(context).colorScheme.primaryContainer,
      shape: StadiumBorder(),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.circle,
          size: 7,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 6),
        Text(
          'Draft',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _TaskDetailsCard extends StatelessWidget {
  const _TaskDetailsCard({
    required this.titleController,
    required this.descriptionController,
    required this.onAddAttachment,
  });

  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final VoidCallback onAddAttachment;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.08),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 7),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_rounded,
                size: 19,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: titleController,
                textCapitalization: TextCapitalization.sentences,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                decoration: const InputDecoration(
                  hintText: 'What needs to be done?',
                  filled: false,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Please enter a task title.'
                    : null,
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 38),
          child: TextFormField(
            controller: descriptionController,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            decoration: const InputDecoration(
              hintText: 'Add notes, checklists, or project details...',
              filled: false,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: onAddAttachment,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.only(left: 38, top: 4),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: Image.asset(
                    'assets/stitch/taskflow/images/scandinavian-desk.jpg',
                    width: 42,
                    height: 42,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TaskFlow 2.0 Sprint Workspace',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      Text(
                        'Connected to Design System Board',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.attach_file_rounded,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              letterSpacing: 1,
            ),
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.primary),
          ),
      ],
    ),
  );
}

class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker({
    required this.categories,
    required this.selected,
    required this.onSelected,
    required this.onAddCustom,
  });

  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;
  final VoidCallback onAddCustom;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (final category in categories) ...[
          _CategoryChip(
            label: category,
            selected: selected == category,
            onTap: () => onSelected(category),
          ),
          const SizedBox(width: 8),
        ],
        ActionChip(
          onPressed: onAddCustom,
          avatar: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Custom'),
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
          side: BorderSide.none,
        ),
      ],
    ),
  );
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ChoiceChip(
    label: Text(label),
    selected: selected,
    onSelected: (_) => onTap(),
    selectedColor: Theme.of(context).colorScheme.primary,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
    labelStyle: TextStyle(
      color: selected
          ? Theme.of(context).colorScheme.onPrimary
          : Theme.of(context).colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w500,
    ),
    side: BorderSide.none,
    shape: const StadiumBorder(),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
  );
}

class _PriorityPicker extends StatelessWidget {
  const _PriorityPicker({required this.selected, required this.onSelected});

  final TaskPriority selected;
  final ValueChanged<TaskPriority> onSelected;

  @override
  Widget build(BuildContext context) {
    const priorities = [
      (TaskPriority.low, 'Low', Color(0xFF006947)),
      (TaskPriority.medium, 'Medium', Color(0xFFFFB900)),
      (TaskPriority.high, 'High', Color(0xFFBA1A1A)),
    ];
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          for (final priority in priorities)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Material(
                  color: selected == priority.$1
                      ? Theme.of(context).colorScheme.surfaceContainerHighest
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: () => onSelected(priority.$1),
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: priority.$3,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            priority.$2,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: selected == priority.$1
                                      ? priority.$3
                                      : Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DateTimeField extends StatelessWidget {
  const _DateTimeField({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surfaceContainerLow,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(value, style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ReminderRepeatCard extends StatelessWidget {
  const _ReminderRepeatCard({
    required this.reminderEnabled,
    required this.onReminderChanged,
    required this.recurrenceType,
    required this.onRecurrenceChanged,
  });

  final bool reminderEnabled;
  final ValueChanged<bool> onReminderChanged;
  final TaskRecurrence recurrenceType;
  final ValueChanged<TaskRecurrence> onRecurrenceChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const _SettingsIcon(icon: Icons.notifications_none_rounded),
          title: Text(
            'Reminder',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: Text(
            reminderEnabled ? '15 minutes before' : 'No reminder',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          trailing: Switch.adaptive(
            value: reminderEnabled,
            onChanged: onReminderChanged,
            activeTrackColor: Theme.of(context).colorScheme.primary,
          ),
        ),
        Divider(height: 1, color: Theme.of(context).dividerColor),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const _SettingsIcon(icon: Icons.repeat_rounded),
          title: Text('Repeat', style: Theme.of(context).textTheme.titleMedium),
          subtitle: Text(
            recurrenceType.label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          trailing: DropdownButton<TaskRecurrence>(
            value: recurrenceType,
            underline: const SizedBox.shrink(),
            borderRadius: BorderRadius.circular(16),
            items: TaskRecurrence.values
                .map(
                  (item) =>
                      DropdownMenuItem(value: item, child: Text(item.label)),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) onRecurrenceChanged(value);
            },
          ),
        ),
      ],
    ),
  );
}

class _SettingsIcon extends StatelessWidget {
  const _SettingsIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(13),
    ),
    child: Icon(icon, color: Theme.of(context).colorScheme.primary),
  );
}

class _SubtasksCard extends StatelessWidget {
  const _SubtasksCard({
    required this.controller,
    required this.subtasks,
    required this.onAdd,
    required this.onToggle,
    required this.onRemove,
  });

  final TextEditingController controller;
  final List<_Subtask> subtasks;
  final VoidCallback onAdd;
  final void Function(_Subtask, bool) onToggle;
  final ValueChanged<_Subtask> onRemove;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      children: [
        for (final subtask in subtasks)
          Row(
            children: [
              Checkbox.adaptive(
                value: subtask.done,
                onChanged: (value) => onToggle(subtask, value ?? false),
                shape: const CircleBorder(),
                activeColor: Theme.of(context).colorScheme.tertiary,
              ),
              Expanded(
                child: Text(
                  subtask.title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    decoration: subtask.done
                        ? TextDecoration.lineThrough
                        : null,
                    color: subtask.done
                        ? Theme.of(context).colorScheme.onSurfaceVariant
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Remove subtask',
                onPressed: () => onRemove(subtask),
                icon: Icon(
                  Icons.close_rounded,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        if (subtasks.isNotEmpty) const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => onAdd(),
                decoration: const InputDecoration(
                  hintText: 'Add a subtask',
                  prefixIcon: Icon(Icons.add_rounded),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              tooltip: 'Add subtask',
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
      ],
    ),
  );
}

class _EstimateCard extends StatelessWidget {
  const _EstimateCard({required this.minutes, required this.onChanged});

  final int minutes;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.auto_awesome_rounded, color: Theme.of(context).colorScheme.onPrimary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Estimated time',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.primary),
              ),
              Text(
                '$minutes min focus block',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        DropdownButton<int>(
          value: minutes,
          underline: const SizedBox.shrink(),
          items: const [15, 30, 45, 60, 90]
              .map(
                (value) =>
                    DropdownMenuItem(value: value, child: Text('$value min')),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ],
    ),
  );
}
