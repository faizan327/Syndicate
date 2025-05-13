import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:syndicate/screen/report/reportedPostsScreen.dart';
import 'package:table_calendar/table_calendar.dart';
import '../main.dart';
import '../todo/models/todo_model.dart';
import '../todo/services/todo_service.dart';
import '../widgets/AuthWrapper.dart';
import 'package:syndicate/todo/screens/todo_dashboard_screen.dart';
import 'package:syndicate/generated/l10n.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syndicate/screen/Saved_Post.dart';
import 'package:syndicate/data/firebase_service/RoleChecker.dart';
import 'package:syndicate/screen/Account/Account_Managment.dart';

enum LanguageOption { english, french }

enum ThemeOption { light, dark, system }

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  LanguageOption _selectedLanguage = LanguageOption.english;
  ThemeOption _selectedTheme = ThemeOption.system;
  String _userRole = 'user';
  final TodoService _todoService = TodoService();
  List<TodoModel> _events = [];
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final FirebaseAuth _auth =
      FirebaseAuth.instance; // Added FirebaseAuth instance

  @override
  void initState() {
    super.initState();
    _loadLanguagePreference();
    _loadThemePreference();
    _checkUserRole();
    _loadEvents();
  }



  void _loadEvents() {
    _todoService.getEvents().listen((events) {
      setState(() {
        _events = events;
      });
    });
  }

  List<TodoModel> _getEventsForDay(DateTime day) {
    return _events.where((event) {
      return event.dueDate.year == day.year &&
          event.dueDate.month == day.month &&
          event.dueDate.day == day.day;
    }).toList();
  }

  void _changeTheme(ThemeOption themeOption) {
    MyApp.of(context)?.updateTheme(themeOption);
  }

  void _loadLanguagePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedLang = prefs.getString('language');
    if (savedLang != null && savedLang == 'fr') {
      setState(() {
        _selectedLanguage = LanguageOption.french;
      });
      MyApp.of(context)?.changeLanguage(Locale('fr'));
    } else {
      setState(() {
        _selectedLanguage = LanguageOption.english;
      });
      MyApp.of(context)?.changeLanguage(Locale('en'));
    }
  }

  void _saveLanguagePreference(LanguageOption lang) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (lang == LanguageOption.french) {
      prefs.setString('language', 'fr');
    } else {
      prefs.setString('language', 'en');
    }
  }

  void _loadThemePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedTheme = prefs.getString('theme');
    if (savedTheme == 'light') {
      setState(() {
        _selectedTheme = ThemeOption.light;
      });
    } else if (savedTheme == 'dark') {
      setState(() {
        _selectedTheme = ThemeOption.dark;
      });
    } else {
      setState(() {
        _selectedTheme = ThemeOption.system;
      });
    }
  }

  void _saveThemePreference(ThemeOption theme) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (theme == ThemeOption.light) {
      prefs.setString('theme', 'light');
    } else if (theme == ThemeOption.dark) {
      prefs.setString('theme', 'dark');
    } else {
      prefs.setString('theme', 'system');
    }
  }

  Future<void> _checkUserRole() async {
    String role = await RoleChecker.checkUserRole();
    setState(() {
      _userRole = role;
    });
  }

  // Method to show edit event dialog
  void _showEditEventDialog(
      BuildContext context, TodoModel event, bool isPublic) {
    final TextEditingController taskController =
        TextEditingController(text: event.task);
    final TextEditingController descriptionController =
        TextEditingController(text: event.description);
    DateTime? dueDate = event.dueDate;
    String priority = event.priority;

    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
              backgroundColor: theme.colorScheme.surface,
              title: Text(
                S.of(context).editEvent,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.headlineSmall?.color,
                ),
              ),
              content: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: taskController,
                        decoration: InputDecoration(
                          labelText: S.of(context).task,
                          labelStyle: TextStyle(
                              color: theme.textTheme.bodyMedium?.color),
                          filled: true,
                          fillColor:
                              theme.colorScheme.surfaceVariant.withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Color(0xffe0993d), width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: S.of(context).description,
                          labelStyle: TextStyle(
                              color: theme.textTheme.bodyMedium?.color),
                          filled: true,
                          fillColor:
                              theme.colorScheme.surfaceVariant.withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Color(0xffe0993d), width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: priority,
                        items: ["Low", "Medium", "High"]
                            .map((p) =>
                                DropdownMenuItem(value: p, child: Text(p)))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            priority = value!;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: S.of(context).priority,
                          labelStyle: TextStyle(
                              color: theme.textTheme.bodyMedium?.color),
                          filled: true,
                          fillColor:
                              theme.colorScheme.surfaceVariant.withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Color(0xffe0993d), width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: dueDate ?? DateTime.now(),
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
                                      foregroundColor: Color(0xffe0993d),
                                    ),
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (pickedDate != null) {
                            setState(() {
                              dueDate = pickedDate;
                            });
                          }
                        },
                        icon: const Icon(Icons.calendar_today,
                            color: Colors.white),
                        label: Text(
                          dueDate != null
                              ? "Due: ${DateFormat.yMMMd().format(dueDate!)}"
                              : "Pick Due Date",
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xffe0993d),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    S.of(context).cancel,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (taskController.text.isNotEmpty && dueDate != null) {
                      final updatedEvent = TodoModel(
                        id: event.id,
                        docId: event.docId,
                        task: taskController.text,
                        description: descriptionController.text,
                        dueDate: dueDate!,
                        priority: priority,
                        isCompleted: event.isCompleted,
                        ownerId: event.ownerId, // Use existing ownerId
                        isPublic: isPublic, // Use the passed isPublic value
                      );
                      if (isPublic) {
                        _todoService.editEvent(event.docId, updatedEvent);
                      } else {
                        _todoService.editPrivateEvent(
                            event.docId, updatedEvent);
                      }
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    S.of(context).save,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.appBarTheme.backgroundColor,
          title: Text(S.of(context).settings),
        ),
        body: ListView(
          children: [


            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              leading: SvgPicture.asset(
                'images/icons/todo.svg',
                color: theme.iconTheme.color ?? Colors.black,
                width: 24.0,
                height: 24.0,
              ),
              title: Text(
                S.of(context).todoList,
                style: const TextStyle(
                    fontSize: 17.0, fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TodoDashboardScreen(),
                  ),
                );
              },
            ),
            Divider(
              color: theme.dividerColor,
              thickness: 0.4,
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                S.of(context).upcomingEvents,
                style: TextStyle(fontSize: 17.0, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                eventLoader: _getEventsForDay,
                calendarStyle: CalendarStyle(
                  markerDecoration: const BoxDecoration(
                    color: Color(0xffe0993d),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: Color(0xffe0993d),
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    if (events.isNotEmpty) {
                      int eventCount = events.length;
                      return Positioned(
                        bottom: 1,
                        child: Container(
                          width: 12.0.w,
                          height: 12.0.h,
                          decoration: BoxDecoration(
                            color: const Color(0xffe0993d),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              eventCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                    return null;
                  },
                ),
              ),
            ),
            if (_selectedDay != null &&
                _getEventsForDay(_selectedDay!).isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Events on ${DateFormat.yMMMd().format(_selectedDay!)}",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    ..._getEventsForDay(_selectedDay!).map((event) => ListTile(
                          title: Text(event.task),
                          subtitle: Text(event.description),
                          trailing: (_userRole == 'admin' ||
                                  (_auth.currentUser!.uid == event.ownerId))
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.blue),
                                      onPressed: () => _showEditEventDialog(
                                        context,
                                        event,
                                        event
                                            .isPublic, // Use isPublic from TodoModel
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title:
                                                Text(S.of(context).deleteEvent),
                                            content: Text(S
                                                .of(context)
                                                .areYouSureDeleteEvent),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child:
                                                    Text(S.of(context).cancel),
                                              ),
                                              ElevatedButton(
                                                onPressed: () {
                                                  if (event.isPublic) {
                                                    _todoService.deleteEvent(
                                                        event.docId);
                                                  } else {
                                                    _todoService
                                                        .deletePrivateEvent(
                                                            event.docId);
                                                  }
                                                  Navigator.pop(context);
                                                },
                                                child: Text(
                                                  S.of(context).delete,
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.red),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                )
                              : null,
                        )),
                  ],
                ),
              ),
            Divider(
              color: theme.dividerColor,
              thickness: 0.4,
            ),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(13, 10, 10, 5),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'images/icons/language.svg',
                    color: theme.iconTheme.color ?? Colors.black,
                    width: 32.0.w,
                    height: 32.0.h,
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    S.of(context).language,
                    style: TextStyle(
                        fontSize: 17.0.sp, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            ListTile(
              subtitle: Column(
                children: [
                  RadioListTile<LanguageOption>(
                    title: Text(S.of(context).english),
                    value: LanguageOption.english,
                    groupValue: _selectedLanguage,
                    onChanged: (LanguageOption? value) {
                      setState(() {
                        _selectedLanguage = value!;
                      });
                      MyApp.of(context)?.changeLanguage(Locale('en'));
                      _saveLanguagePreference(LanguageOption.english);
                    },
                    controlAffinity: ListTileControlAffinity.trailing,
                  ),
                  RadioListTile<LanguageOption>(
                    title: Text(S.of(context).french),
                    value: LanguageOption.french,
                    groupValue: _selectedLanguage,
                    onChanged: (LanguageOption? value) {
                      setState(() {
                        _selectedLanguage = value!;
                      });
                      MyApp.of(context)?.changeLanguage(Locale('fr'));
                      _saveLanguagePreference(LanguageOption.french);
                    },
                    controlAffinity: ListTileControlAffinity.trailing,
                  ),
                ],
              ),
            ),
            Divider(
              color: theme.dividerColor,
              thickness: 0.4,
              height: 5.0.h,
            ),
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              leading: SvgPicture.asset(
                'images/icons/bookmark.svg',
                color: theme.iconTheme.color ?? Colors.black,
                width: 24.0.w,
                height: 24.0.h,
              ),
              title: Text(
                S.of(context).savedPost,
                style:
                    TextStyle(fontSize: 17.0.sp, fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SavedPostsPage(),
                  ),
                );
              },
            ),
            Divider(
              color: theme.dividerColor,
              thickness: 0.4,
              height: 5.0,
            ),
            if (_userRole == 'admin') ...[
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                leading: SvgPicture.asset(
                  'images/icons/spam.svg',
                  color: theme.iconTheme.color ?? Colors.black,
                  width: 25.0.w,
                  height: 25.0.h,
                ),
                title: Text(
                  S.of(context).report,
                  style: const TextStyle(
                      fontSize: 17.0, fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReportedPostsScreen(),
                    ),
                  );
                },
              ),
              Divider(color: theme.dividerColor, thickness: 0.4, height: 5.0.h),
              if (_userRole == 'admin') ...[
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 4.0),
                  leading: SvgPicture.asset(
                    'images/icons/profilefill.svg', // Use an appropriate icon for account management
                    color: theme.iconTheme.color ?? Colors.black,
                    width: 24.0.w,
                    height: 24.0.h,
                  ),
                  title: Text(
                    'Account Management',
                    style: TextStyle(
                        fontSize: 17.0.sp),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AccountManagementScreen(),
                      ),
                    );
                  },
                ),
                Divider(
                  color: theme.dividerColor,
                  thickness: 0.4,
                  height: 5.0.h,
                ),
              ],


            ],

            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(13, 10, 10, 5),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'images/icons/theme.svg',
                    color: theme.iconTheme.color ?? Colors.black,
                    width: 32.0.w,
                    height: 32.0.h,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    S.of(context).theme,
                    style: TextStyle(
                        fontSize: 17.0.sp, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            ListTile(
              subtitle: Column(
                children: [
                  RadioListTile<ThemeOption>(
                    title: Text(S.of(context).lightTheme),
                    value: ThemeOption.light,
                    groupValue: _selectedTheme,
                    onChanged: (ThemeOption? value) {
                      setState(() {
                        _selectedTheme = value!;
                      });
                      _changeTheme(ThemeOption.light);
                      _saveThemePreference(ThemeOption.light);
                    },
                    controlAffinity: ListTileControlAffinity.trailing,
                  ),
                  RadioListTile<ThemeOption>(
                    title: Text(S.of(context).darkTheme),
                    value: ThemeOption.dark,
                    groupValue: _selectedTheme,
                    onChanged: (ThemeOption? value) {
                      setState(() {
                        _selectedTheme = value!;
                      });
                      _changeTheme(ThemeOption.dark);
                      _saveThemePreference(ThemeOption.dark);
                    },
                    controlAffinity: ListTileControlAffinity.trailing,
                  ),
                  RadioListTile<ThemeOption>(
                    title: Text(S.of(context).systemDefault),
                    value: ThemeOption.system,
                    groupValue: _selectedTheme,
                    onChanged: (ThemeOption? value) {
                      setState(() {
                        _selectedTheme = value!;
                      });
                      _changeTheme(ThemeOption.system);
                      _saveThemePreference(ThemeOption.system);
                    },
                    controlAffinity: ListTileControlAffinity.trailing,
                  ),
                ],
              ),
            ),

            Divider(
              color: theme.dividerColor,
              thickness: 0.4,
            ),
            ListTile(
              contentPadding:
              EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              leading: SvgPicture.asset(
                'images/icons/logout.svg',
                color: Colors.red,
                width: 24.0.w,
                height: 24.0.h,
              ),
              title: Text(
                S.of(context).logout,
                style: TextStyle(
                    fontSize: 17.0.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.red),
              ),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                      builder: (context) => const AuthWrapper()),
                      (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        ));
  }
}
