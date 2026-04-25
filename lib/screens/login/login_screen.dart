import 'package:flutter/material.dart';

import '../../models/user_role.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.onLogin,
    required this.themeMode,
    required this.onToggleTheme,
  });

  final Future<void> Function({
    required String email,
    required String password,
    required UserRole selectedRole,
  })
  onLogin;
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  UserRole _selectedRole = UserRole.teacher;
  bool _obscurePassword = true;
  bool _isLoading = false;

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

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email and password are required.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.onLogin(
        email: email,
        password: password,
        selectedRole: _selectedRole,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildFormPanel(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Sign in to the learning system',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please choose your role and sign in to continue.',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              SegmentedButton<UserRole>(
                segments: const [
                  ButtonSegment<UserRole>(
                    value: UserRole.teacher,
                    label: Text('Teacher'),
                    icon: Icon(Icons.co_present_outlined),
                  ),
                  ButtonSegment<UserRole>(
                    value: UserRole.student,
                    label: Text('Student'),
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
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    tooltip: _obscurePassword
                        ? 'Show password'
                        : 'Hide password',
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Primary sign-in button
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Sign in'),
                ),
              ),
              const SizedBox(height: 20),

              // "Or" separator
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text('Or', style: textTheme.bodySmall),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 20),

              // Join meeting button
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surface, // White background as requested
                    foregroundColor: Theme.of(
                      context,
                    ).colorScheme.primary, // Text color matches border
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1.5,
                    ), // Border color matches the sign-in button
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
              tooltip: 'Toggle theme',
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
            'An online learning platform for teachers and students.',
            style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
