import 'package:flutter/material.dart';

import '../../models/user_role.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.onLogin,
    required this.themeMode,
    required this.onToggleTheme,
  });

  final ValueChanged<UserRole> onLogin;
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  UserRole _selectedRole = UserRole.teacher;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 980;

            if (isCompact) {
              return Column(
                children: [
                  Expanded(
                    flex: 4,
                    child: _BrandPanel(
                      isDark: widget.themeMode == ThemeMode.dark,
                      onToggleTheme: widget.onToggleTheme,
                    ),
                  ),
                  Expanded(flex: 6, child: _buildFormPanel(context)),
                ],
              );
            }

            return Row(
              children: [
                Expanded(
                  flex: 4,
                  child: _BrandPanel(
                    isDark: widget.themeMode == ThemeMode.dark,
                    onToggleTheme: widget.onToggleTheme,
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: Container(
                    color: scheme.surface,
                    child: _buildFormPanel(context),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFormPanel(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Đăng nhập hệ thống học tập',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Vui lòng chọn vai trò và đăng nhập để tiếp tục.',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              SegmentedButton<UserRole>(
                segments: const [
                  ButtonSegment<UserRole>(
                    value: UserRole.teacher,
                    label: Text('Giáo viên'),
                    icon: Icon(Icons.co_present_outlined),
                  ),
                  ButtonSegment<UserRole>(
                    value: UserRole.student,
                    label: Text('Học sinh'),
                    icon: Icon(Icons.school_outlined),
                  ),
                ],
                selected: {_selectedRole},
                onSelectionChanged: (selection) {
                  setState(() {
                    _selectedRole = selection.first;
                  });
                },
                showSelectedIcon: false,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'teacher@school.edu',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Mật khẩu'),
              ),
              const SizedBox(height: 20),

              // Nút Đăng nhập chính
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: () => widget.onLogin(_selectedRole),
                  child: const Text('Đăng nhập'),
                ),
              ),
              const SizedBox(height: 20),

              // Cụm chữ "Hoặc"
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text('Hoặc', style: textTheme.bodySmall),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 20),

              // Nút Join a meeting mới
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: () {
                    // TODO: Thêm logic chuyển sang màn hình tham gia cuộc họp bằng mã
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white, // Nền trắng theo yêu cầu
                    foregroundColor:
                        colorScheme.primary, // Chữ cùng màu với viền
                    side: BorderSide(
                      color: colorScheme.primary,
                      width: 1.5,
                    ), // Viền cùng màu nút Đăng nhập
                  ),
                  child: const Text(
                    'Join a meeting',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel({required this.isDark, required this.onToggleTheme});

  final bool isDark;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F4C81), Color(0xFF2B579A), Color(0xFF4C7FBF)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: IconButton.filledTonal(
              onPressed: onToggleTheme,
              icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
              tooltip: 'Chuyển giao diện',
            ),
          ),
          const Spacer(),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white30),
            ),
            child: const Icon(
              Icons.auto_stories,
              color: Colors.white,
              size: 44,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Edu Teams Desktop',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 30,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Nền tảng học tập trực tuyến cho giáo viên và học sinh.',
            style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
