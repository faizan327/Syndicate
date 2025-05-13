import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../generated/l10n.dart';
import '../models/todo_model.dart';
import '../services/todo_service.dart';

class TodoTaskWidget extends StatelessWidget {
  final TodoModel todo;
  const TodoTaskWidget({super.key, required this.todo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final todoService = TodoService();

    return Card(
      color: theme.colorScheme.onBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(7.r), // Scale radius
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h), // Scale padding
        title: Text(
          todo.task,
          style: TextStyle(
            color: const Color(0xffa96d1f),
            fontWeight: FontWeight.bold,
            fontSize: 16.sp, // Scale font size
            decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
          ),
          overflow: TextOverflow.ellipsis, // Prevent overflow on smaller screens
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Due: ${DateFormat.yMMMd().format(todo.dueDate)}',
              style: TextStyle(
                fontSize: 14.sp, // Scale font size
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
            Text(
              '${S.of(context).priority}: ${todo.priority}',
              style: TextStyle(
                fontSize: 14.sp, // Scale font size
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                todo.isCompleted ? Icons.undo : Icons.check,
                color: theme.textTheme.bodyMedium?.color,
                size: 22.w, // Scale icon size
              ),
              onPressed: () {
                todoService.toggleTaskCompletion(todo.docId, !todo.isCompleted);
              },
              padding: EdgeInsets.zero, // Remove extra padding
              constraints: BoxConstraints(maxWidth: 20.w), // Scale constraints
            ),
            IconButton(
              icon: Icon(
                Icons.delete,
                color: Colors.red,
                size: 22.w, // Scale icon size
              ),
              onPressed: () {
                todoService.deleteTodo(todo.docId);
              },
              padding: EdgeInsets.zero, // Remove extra padding
              constraints: BoxConstraints(maxWidth: 20.w), // Scale constraints
            ),
          ],
        ),
      ),
    );
  }
}