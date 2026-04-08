import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../models/classroom.dart';
import '../models/user_role.dart';
import '../screens/home/home_screen.dart';
import '../screens/login/login_screen.dart';
import '../theme/app_theme.dart';

class EducationDesktopApp extends StatefulWidget {
  const EducationDesktopApp({super.key});

  @override
  State<EducationDesktopApp> createState() => _EducationDesktopAppState();
}

class _EducationDesktopAppState extends State<EducationDesktopApp> {
  ThemeMode _themeMode = ThemeMode.light;
  UserRole? _loggedInRole;

  final List<Classroom> _teacherClasses = const [
    Classroom(
      id: 'T01',
      name: 'Introduction to Python Programming',
      studentCount: 38,
      classCode: 'IT-PY101',
    ),
    Classroom(
      id: 'T02',
      name: 'Data Structures and Algorithms',
      studentCount: 32,
      classCode: 'IT-DSA201',
    ),
    Classroom(
      id: 'T03',
      name: 'Web Application Development',
      studentCount: 40,
      classCode: 'IT-WEB301',
    ),
    Classroom(
      id: 'T04',
      name: 'Database Systems',
      studentCount: 35,
      classCode: 'IT-DB202',
    ),
    Classroom(
      id: 'T05',
      name: 'Applied Artificial Intelligence',
      studentCount: 41,
      classCode: 'IT-AI401',
    ),
    Classroom(
      id: 'T06',
      name: 'Computer Networks and Security',
      studentCount: 33,
      classCode: 'IT-NET303',
    ),
  ];

  final List<Classroom> _studentClasses = const [
    Classroom(
      id: 'S01',
      name: 'Introduction to Data Science',
      teacherName: 'Mr. Nguyen Minh Duc',
      progress: 0.72,
    ),
    Classroom(
      id: 'S02',
      name: 'Object-Oriented Java Programming',
      teacherName: 'Ms. Le Thu Trang',
      progress: 0.45,
    ),
    Classroom(
      id: 'S03',
      name: 'Mobile Development with Flutter',
      teacherName: 'Mr. Pham Quoc Huy',
      progress: 0.83,
    ),
    Classroom(
      id: 'S04',
      name: 'Practical DevOps and CI/CD',
      teacherName: 'Mr. Tran Anh Tuan',
      progress: 0.31,
    ),
    Classroom(
      id: 'S05',
      name: 'Linux for Developers',
      teacherName: 'Ms. Doan Ngoc Ha',
      progress: 0.58,
    ),
    Classroom(
      id: 'S06',
      name: 'Fundamentals of Information Security',
      teacherName: 'Mr. Vu Thanh Son',
      progress: 0.9,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Education Desktop UI',
      themeMode: _themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      home: _loggedInRole == null
          ? LoginScreen(
              themeMode: _themeMode,
              onToggleTheme: _toggleTheme,
              onLogin: (role) {
                setState(() {
                  _loggedInRole = role;
                });
              },
            )
          : HomeScreen(
              isTeacher: _loggedInRole == UserRole.teacher,
              classrooms: _loggedInRole == UserRole.teacher
                  ? _teacherClasses
                  : _studentClasses,
              onLogout: () {
                setState(() {
                  _loggedInRole = null;
                });
              },
              onToggleTheme: _toggleTheme,
            ),
    );
  }

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark
          ? ThemeMode.light
          : ThemeMode.dark;
    });
  }
}
