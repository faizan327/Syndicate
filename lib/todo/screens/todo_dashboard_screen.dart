import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:syndicate/data/firebase_service/firestor.dart';
import 'package:syndicate/generated/l10n.dart';
import '../../data/firebase_service/RoleChecker.dart';
import '../../data/model/usermodel.dart';
import '../services/todo_service.dart';
import '../models/todo_model.dart';
import '../widgets/todo_task_widget.dart';

class TodoDashboardScreen extends StatefulWidget {
  const TodoDashboardScreen({super.key});

  @override
  _TodoDashboardScreenState createState() => _TodoDashboardScreenState();
}

class _TodoDashboardScreenState extends State<TodoDashboardScreen>
    with SingleTickerProviderStateMixin {
  final TodoService todoService = TodoService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _searchQuery = '';
  String _selectedPriority = 'All';
  late TabController _tabController;
  String _userRole = 'user'; // Default role

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _checkUserRole(); // Check user role on initialization
  }

  // Check user role
  Future<void> _checkUserRole() async {
    String role = await RoleChecker.checkUserRole();
    setState(() {
      _userRole = role;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: theme.appBarTheme.backgroundColor,
        toolbarHeight: 90.h, // Scale height
        flexibleSpace: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
              15.w, 40.h, 10.w, 5.h), // Scale padding
          child: FutureBuilder<Usermodel>(
            future: Firebase_Firestor().getUser(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox(); // Return empty if no data
              }
              final user = snapshot.data!;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 23.w, // Scale radius
                        backgroundImage:
                        CachedNetworkImageProvider(user.profile),
                      ),
                      SizedBox(width: 10.w), // Scale spacing
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${S.of(context).hello}, ${user.username}!',
                            style: TextStyle(
                              fontSize: 15.sp, // Scale font size
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                          Text(
                            S.of(context).taskManager,
                            style: TextStyle(
                              fontSize: 13.sp, // Scale font size
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      _showAddTaskBottomSheet(context); // Correct
                    },
                    icon: Icon(
                      Icons.add,
                      size: 18.w, // Scale icon size
                      color: Colors.white,
                    ),
                    label: Text(
                      S.of(context).newTask,
                      style: TextStyle(fontSize: 14.sp), // Scale font size
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                          horizontal: 12.w, vertical: 8.h), // Scale padding
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(8.r), // Scale radius
                      ),
                      backgroundColor: const Color(0xffe0993d),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(
            13.w, 6.h, 13.w, 6.h), // Scale padding
        child: Column(
          children: [
            Expanded(
              flex: 1,
              child: Card(
                color: theme.colorScheme.onBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r), // Scale radius
                ),
                child: Padding(
                  padding: EdgeInsets.all(10.w), // Scale padding
                  child: Column(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            // Pie Chart and Filters
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: EdgeInsets.all(20.w), // Scale padding
                                child: Row(
                                  children: [
                                    // Pie Chart
                                    Expanded(
                                      flex: 1,
                                      child: StreamBuilder<List<TodoModel>>(
                                        stream: todoService.getTodos(),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return Center(
                                              child: CircularProgressIndicator(
                                                strokeWidth:
                                                4.w, // Scale stroke width
                                              ),
                                            );
                                          }

                                          if (snapshot.hasError) {
                                            return Center(
                                              child: Text(
                                                'Error: ${snapshot.error}',
                                                style: TextStyle(
                                                    fontSize: 14
                                                        .sp), // Scale font size
                                              ),
                                            );
                                          }

                                          if (!snapshot.hasData ||
                                              snapshot.data!.isEmpty) {
                                            return Center(
                                              child: Text(
                                                S.of(context).noTasksYet,
                                                style: TextStyle(
                                                    fontSize: 14
                                                        .sp), // Scale font size
                                              ),
                                            );
                                          }

                                          final todos = snapshot.data!;
                                          final completedTasks = todos
                                              .where((todo) => todo.isCompleted)
                                              .toList();
                                          final pendingTasks = todos
                                              .where(
                                                  (todo) => !todo.isCompleted)
                                              .toList();

                                          return PieChart(
                                            PieChartData(
                                              sections: [
                                                PieChartSectionData(
                                                  value: completedTasks.length
                                                      .toDouble(),
                                                  title:
                                                  '${completedTasks.length}',
                                                  titleStyle: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 13
                                                        .sp, // Scale font size
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  color:
                                                  const Color(0xffa96d1f),
                                                  radius: 25.w, // Scale radius
                                                ),
                                                PieChartSectionData(
                                                  value: pendingTasks.length
                                                      .toDouble(),
                                                  title:
                                                  '${pendingTasks.length}',
                                                  titleStyle: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 13
                                                        .sp, // Scale font size
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  color: Colors.black,
                                                  radius: 25.w, // Scale radius
                                                ),
                                              ],
                                              centerSpaceRadius: 27
                                                  .w, // Scale center space radius
                                              borderData:
                                              FlBorderData(show: false),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    SizedBox(width: 15.w), // Scale spacing
                                    // Completed and Pending Task Numbers
                                    Expanded(
                                      flex: 1,
                                      child: Column(
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          StreamBuilder<List<TodoModel>>(
                                            stream: todoService.getTodos(),
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState ==
                                                  ConnectionState.waiting) {
                                                return Text(
                                                  S.of(context).loading,
                                                  style: TextStyle(
                                                      fontSize: 14
                                                          .sp), // Scale font size
                                                );
                                              }

                                              if (snapshot.hasError) {
                                                return Text(
                                                  'Error: ${snapshot.error}',
                                                  style: TextStyle(
                                                      fontSize: 14
                                                          .sp), // Scale font size
                                                );
                                              }

                                              if (!snapshot.hasData ||
                                                  snapshot.data!.isEmpty) {
                                                return Text(
                                                  S.of(context).noTasksYet,
                                                  style: TextStyle(
                                                      fontSize: 14
                                                          .sp), // Scale font size
                                                );
                                              }

                                              final todos = snapshot.data!;
                                              final completedTasks = todos
                                                  .where((todo) =>
                                              todo.isCompleted)
                                                  .toList();
                                              final pendingTasks = todos
                                                  .where((todo) =>
                                              !todo.isCompleted)
                                                  .toList();

                                              return Column(
                                                crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '${S.of(context).completed}: ${completedTasks.length}',
                                                    style: TextStyle(
                                                      fontSize: 14
                                                          .sp, // Scale font size
                                                      fontWeight:
                                                      FontWeight.bold,
                                                      color: const Color(
                                                          0xffa96d1f),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                      height:
                                                      4.h), // Scale spacing
                                                  Text(
                                                    '${S.of(context).pending}: ${pendingTasks.length}',
                                                    style: TextStyle(
                                                      fontSize: 14
                                                          .sp, // Scale font size
                                                      fontWeight:
                                                      FontWeight.bold,
                                                      color: theme.textTheme
                                                          .displayLarge?.color,
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.h), // Scale spacing
            // Tabs
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: S.of(context).all),
                Tab(text: S.of(context).high),
                Tab(text: S.of(context).medium),
                Tab(text: S.of(context).low),
              ],
              indicatorColor: const Color(0xffa96d1f),
              labelColor: theme.textTheme.bodyLarge?.color,
              unselectedLabelColor: theme.textTheme.bodyMedium?.color,
              labelStyle: TextStyle(fontSize: 16.sp), // Scale font size
              unselectedLabelStyle:
              TextStyle(fontSize: 14.sp), // Scale font size
            ),
            Expanded(
              flex: 3,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTaskList('All'),
                  _buildTaskList('High'),
                  _buildTaskList('Medium'),
                  _buildTaskList('Low'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList(String priority) {
    final theme = Theme.of(context);
    return StreamBuilder<List<TodoModel>>(
      stream: todoService.getTodos(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              strokeWidth: 4.w, // Scale stroke width
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: TextStyle(fontSize: 14.sp), // Scale font size
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              S.of(context).noTasksYet,
              style: TextStyle(fontSize: 14.sp), // Scale font size
            ),
          );
        }

        final todos = snapshot.data!;
        final filteredTodos = todos.where((todo) {
          final matchesSearch = todo.task.toLowerCase().contains(_searchQuery);
          final matchesPriority =
              priority == 'All' || todo.priority == priority;
          return matchesSearch && matchesPriority;
        }).toList();

        return ListView.builder(
          itemCount: filteredTodos.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 4.h), // Scale padding
              child: TodoTaskWidget(todo: filteredTodos[index]),
            );
          },
        );
      },
    );
  }

  final TodoService _todoService = TodoService();

  void _showAddTaskBottomSheet(BuildContext context) {
    final TextEditingController taskController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    DateTime? dueDate;
    String priority = 'Low';
    String eventOption = 'None'; // Default event option

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(top: Radius.circular(24.r)), // Scale radius
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          color: theme.colorScheme.onPrimary,
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                left: 16.w,
                right: 16.w,
                top: 24.h,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16.h,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 60.w, // Scale width
                      height: 5.h, // Scale height
                      decoration: BoxDecoration(
                        color: const Color(0xffe0993d),
                        borderRadius:
                        BorderRadius.circular(12.r), // Scale radius
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h), // Scale spacing
                  Text(
                    S.of(context).addNewTask,
                    style: TextStyle(
                      fontSize: 20.sp, // Scale font size
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  SizedBox(height: 16.h), // Scale spacing
                  TextField(
                    controller: taskController,
                    decoration: InputDecoration(
                      labelText: S.of(context).task,
                      labelStyle: TextStyle(fontSize: 16.sp), // Scale font size
                      border: OutlineInputBorder(
                        borderRadius:
                        BorderRadius.circular(12.r), // Scale radius
                        borderSide: const BorderSide(color: Color(0xffa96d1f)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                        BorderRadius.circular(12.r), // Scale radius
                        borderSide: const BorderSide(
                            color: Color(0xffa96d1f), width: 1),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.onBackground,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 14.h), // Scale padding
                    ),
                    style: TextStyle(fontSize: 16.sp), // Scale font size
                  ),
                  SizedBox(height: 16.h), // Scale spacing
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: S.of(context).description,
                      labelStyle: TextStyle(fontSize: 16.sp), // Scale font size
                      border: OutlineInputBorder(
                        borderRadius:
                        BorderRadius.circular(12.r), // Scale radius
                        borderSide: BorderSide(color: theme.dividerColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                        BorderRadius.circular(12.r), // Scale radius
                        borderSide: const BorderSide(
                            color: Color(0xffa96d1f), width: 1),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.onBackground,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 14.h), // Scale padding
                    ),
                    style: TextStyle(fontSize: 16.sp), // Scale font size
                  ),
                  SizedBox(height: 16.h), // Scale spacing
                  DropdownButtonFormField(
                    value: priority,
                    items: ["Low", "Medium", "High"]
                        .map(
                          (p) => DropdownMenuItem(
                        value: p,
                        child: Text(
                          p,
                          style:
                          TextStyle(fontSize: 16.sp), // Scale font size
                        ),
                      ),
                    )
                        .toList(),
                    onChanged: (value) {
                      priority = value!;
                    },
                    decoration: InputDecoration(
                      labelText: S.of(context).priority,
                      labelStyle: TextStyle(fontSize: 16.sp), // Scale font size
                      border: OutlineInputBorder(
                        borderRadius:
                        BorderRadius.circular(12.r), // Scale radius
                        borderSide: const BorderSide(color: Color(0xffa96d1f)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                        BorderRadius.circular(12.r), // Scale radius
                        borderSide: const BorderSide(
                            color: Color(0xffa96d1f), width: 1),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.onBackground,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 14.h), // Scale padding
                    ),
                  ),
                  SizedBox(height: 16.h), // Scale spacing
                  // Show event dropdown only for admins
                  DropdownButtonFormField(
                    value: eventOption,
                    items: ["None", "Event"]
                        .map(
                          (e) => DropdownMenuItem(
                        value: e,
                        child: Text(
                          e,
                          style:
                          TextStyle(fontSize: 16.sp), // Scale font size
                        ),
                      ),
                    )
                        .toList(),
                    onChanged: (value) {
                      eventOption = value!;
                    },
                    decoration: InputDecoration(
                      labelText: "Event",
                      labelStyle: TextStyle(fontSize: 16.sp), // Scale font size
                      border: OutlineInputBorder(
                        borderRadius:
                        BorderRadius.circular(12.r), // Scale radius
                        borderSide: const BorderSide(color: Color(0xffa96d1f)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                        BorderRadius.circular(12.r), // Scale radius
                        borderSide: const BorderSide(
                            color: Color(0xffa96d1f), width: 1),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.onBackground,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 14.h), // Scale padding
                    ),
                  ),
                  SizedBox(height: 16.h), // Scale spacing
                  ElevatedButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Color(0xffe0993d),
                                onPrimary: Colors.white,
                                onSurface: Colors.black,
                              ),
                              textButtonTheme: TextButtonThemeData(
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xffe0993d),
                                ),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (date != null) {
                        dueDate = date;
                        setState(() {});
                      }
                    },
                    icon: Icon(
                      Icons.calendar_today,
                      color: Colors.white,
                      size: 20.w, // Scale icon size
                    ),
                    label: Text(
                      dueDate == null
                          ? S.of(context).pickDueDate
                          : '${S.of(context).dueDate}: ${dueDate!.toLocal()}'
                          .split(' ')[0],
                      style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold), // Scale font size
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xffe0993d),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                          vertical: 14.h, horizontal: 20.w), // Scale padding
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(12.r), // Scale radius
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h), // Scale spacing
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final task = taskController.text.trim();
                        final description = descriptionController.text.trim();

                        if (task.isNotEmpty && dueDate != null) {
                          final newTodo = TodoModel(
                            id: DateTime.now().toString(),
                            task: task,
                            description: description,
                            dueDate: dueDate!,
                            priority: priority,
                            ownerId: _auth.currentUser!.uid,
                            isPublic:
                            _userRole == 'admin' && eventOption == "Event",
                          );
                          todoService.addTodo(newTodo);

                          // Handle event addition based on role
                          if (eventOption == "Event") {
                            if (_userRole == 'admin') {
                              todoService.addPublicEvent(
                                  newTodo); // Public event for admins
                            } else {
                              todoService.addPrivateEvent(
                                  newTodo); // Private event for users
                            }
                          }

                          Navigator.of(context).pop();
                        }
                      },
                      child: Text(
                        S.of(context).addNewTask,
                        style: TextStyle(
                          fontSize: 16.sp, // Scale font size
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                            vertical: 14.h), // Scale padding
                        shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(12.r), // Scale radius
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}