import 'package:flutter/material.dart';

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
      name: 'Lap trinh Python co ban',
      studentCount: 38,
      classCode: 'IT-PY101',
    ),
    Classroom(
      id: 'T02',
      name: 'Cau truc du lieu va giai thuat',
      studentCount: 32,
      classCode: 'IT-DSA201',
    ),
    Classroom(
      id: 'T03',
      name: 'Phat trien ung dung web',
      studentCount: 40,
      classCode: 'IT-WEB301',
    ),
    Classroom(
      id: 'T04',
      name: 'Co so du lieu',
      studentCount: 35,
      classCode: 'IT-DB202',
    ),
    Classroom(
      id: 'T05',
      name: 'Tri tue nhan tao ung dung',
      studentCount: 41,
      classCode: 'IT-AI401',
    ),
    Classroom(
      id: 'T06',
      name: 'Mang may tinh va bao mat',
      studentCount: 33,
      classCode: 'IT-NET303',
    ),
  ];

  final List<Classroom> _studentClasses = const [
    Classroom(
      id: 'S01',
      name: 'Nhap mon khoa hoc du lieu',
      teacherName: 'Thay Nguyen Minh Duc',
      progress: 0.72,
    ),
    Classroom(
      id: 'S02',
      name: 'Lap trinh Java huong doi tuong',
      teacherName: 'Co Le Thu Trang',
      progress: 0.45,
    ),
    Classroom(
      id: 'S03',
      name: 'Phat trien mobile voi Flutter',
      teacherName: 'Thay Pham Quoc Huy',
      progress: 0.83,
    ),
    Classroom(
      id: 'S04',
      name: 'DevOps va CI CD thuc hanh',
      teacherName: 'Thay Tran Anh Tuan',
      progress: 0.31,
    ),
    Classroom(
      id: 'S05',
      name: 'He dieu hanh Linux cho lap trinh vien',
      teacherName: 'Co Doan Ngoc Ha',
      progress: 0.58,
    ),
    Classroom(
      id: 'S06',
      name: 'An toan thong tin can ban',
      teacherName: 'Thay Vu Thanh Son',
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
