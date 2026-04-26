import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_web_rtc/core/constants/app_colors.dart';
import 'package:flutter_web_rtc/core/constants/app_sizes.dart';
import 'package:flutter_web_rtc/core/constants/app_text_styles.dart';
import 'package:flutter_web_rtc/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:flutter_web_rtc/features/auth/presentation/controllers/auth_notifier.dart';
import 'package:flutter_web_rtc/models/user_role.dart';

/// Classifies [AuthException] into a human-readable message.
String _classifyError(Object error) {
  if (error is AuthException) {
    final code = error.statusCode;
    if (code == 401 || code == 403) {
      return 'Wrong email or password. Please try again.';
    }
    if (code != null && code >= 500) {
      return 'Server error. Please wait a moment and try again.';
    }
    return error.message;
  }
  final msg = error.toString();
  if (msg.toLowerCase().contains('network') ||
      msg.toLowerCase().contains('socket') ||
      msg.toLowerCase().contains('connection')) {
    return 'Cannot connect to the server. Check your internet connection.';
  }
  return 'An unexpected error occurred. Please try again.';
}

/// Regular expression for basic email validation.
final RegExp _emailRegex = RegExp(
  r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
);

class LoginFormWidget extends StatefulWidget {
  const LoginFormWidget({super.key});

  @override
  State<LoginFormWidget> createState() => _LoginFormWidgetState();
}

class _LoginFormWidgetState extends State<LoginFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  UserRole _selectedRole = UserRole.teacher;
  bool _obscurePassword = true;

  /// Null = no error, non-null = message to show in error banner.
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() => _errorMessage = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    try {
      await context.read<AuthNotifier>().signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        selectedRole: _selectedRole,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = _classifyError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthNotifier>().isLoading;
    final colorScheme = Theme.of(context).colorScheme;
    final fieldFill = colorScheme.surfaceContainerHighest;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Title ──────────────────────────────────────────
          Text(
            'EduDeaf',
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            'Welcome back! Please login to your account.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSizes.xl),

          // ── Role Selector ──────────────────────────────────
          _RoleSelector(
            selected: _selectedRole,
            onChanged: (role) => setState(() {
              _selectedRole = role;
              _errorMessage = null;
            }),
          ),
          const SizedBox(height: AppSizes.lg),

          // ── Error Banner ───────────────────────────────────
          if (_errorMessage != null) ...[
            _ErrorBanner(message: _errorMessage!),
            const SizedBox(height: AppSizes.md),
          ],

          // ── Email Field ────────────────────────────────────
          _FieldLabel(label: 'Email/Username'),
          const SizedBox(height: AppSizes.xs),
          Semantics(
            label: 'Email đăng nhập',
            textField: true,
            child: TextFormField(
              controller: _emailController,
              decoration: _fieldDecoration(
                context: context,
                fillColor: fieldFill,
                hintText: 'Enter your email or username',
                prefixIcon: Icons.person_outline,
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() => _errorMessage = null),
              validator: (value) {
                final trimmed = value?.trim() ?? '';
                if (trimmed.isEmpty) return 'Email is required.';
                if (!_emailRegex.hasMatch(trimmed)) {
                  return 'Please enter a valid email address.';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: AppSizes.md),

          // ── Password Field ─────────────────────────────────
          _FieldLabel(label: 'Password'),
          const SizedBox(height: AppSizes.xs),
          Semantics(
            label: 'Mật khẩu',
            textField: true,
            child: TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: _fieldDecoration(
                context: context,
                fillColor: fieldFill,
                hintText: 'Enter your password',
                prefixIcon: Icons.lock_outline,
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  tooltip:
                      _obscurePassword ? 'Show password' : 'Hide password',
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              onChanged: (_) => setState(() => _errorMessage = null),
              onFieldSubmitted: (_) => _handleLogin(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password is required.';
                }
                return null;
              },
            ),
          ),

          // ── Forgot Password ────────────────────────────────
          Align(
            alignment: Alignment.centerRight,
            child: Semantics(
              label: 'Quên mật khẩu',
              button: true,
              child: TextButton(
                onPressed: () {
                  // TODO: FEATURE-forgot-password
                },
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.onSurfaceVariant,
                  textStyle: AppTextStyles.bodySmall,
                ),
                child: const Text('Forgot Password?'),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.sm),

          // ── Login Button (gradient) ────────────────────────
          Semantics(
            label: 'Nút đăng nhập',
            button: true,
            child: _GradientButton(
              onPressed: isLoading ? null : _handleLogin,
              isLoading: isLoading,
              label: 'Login',
            ),
          ),
          const SizedBox(height: AppSizes.lg),

          // ── Divider ────────────────────────────────────────
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
                child: Text('Or', style: AppTextStyles.bodySmall),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: AppSizes.lg),

          // ── Join Meeting ───────────────────────────────────
          SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary, width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusDefault),
                ),
              ),
              child: const Text('Join a meeting'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helper: builds a consistent filled InputDecoration ──────────────────────

InputDecoration _fieldDecoration({
  required BuildContext context,
  required Color fillColor,
  required String hintText,
  required IconData prefixIcon,
  Widget? suffixIcon,
}) {
  final colorScheme = Theme.of(context).colorScheme;
  return InputDecoration(
    filled: true,
    fillColor: fillColor,
    hintText: hintText,
    hintStyle: AppTextStyles.bodyLarge.copyWith(
      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
    ),
    prefixIcon: Icon(prefixIcon, color: colorScheme.onSurfaceVariant),
    suffixIcon: suffixIcon,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSizes.md,
      vertical: AppSizes.md,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusDefault),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusDefault),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusDefault),
      borderSide: BorderSide(color: AppColors.primary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusDefault),
      borderSide: BorderSide(color: colorScheme.error, width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusDefault),
      borderSide: BorderSide(color: colorScheme.error, width: 1.5),
    ),
  );
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

/// Small label sitting above each form field.
class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.bodySmall.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// Pill-shaped role selector matching the reference design.
class _RoleSelector extends StatelessWidget {
  const _RoleSelector({required this.selected, required this.onChanged});

  final UserRole selected;
  final ValueChanged<UserRole> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<UserRole>(
      segments: const [
        ButtonSegment<UserRole>(
          value: UserRole.teacher,
          label: Text('Professor'),
        ),
        ButtonSegment<UserRole>(
          value: UserRole.student,
          label: Text('Student'),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (s) => onChanged(s.first),
      showSelectedIcon: false,
      expandedInsets: EdgeInsets.zero,
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: AppColors.white,
        selectedForegroundColor: AppColors.primary,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
        textStyle: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        ),
      ),
    );
  }
}

/// Full-width button with a blue → purple gradient and pill shape.
class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.onPressed,
    required this.isLoading,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: onPressed == null
            ? null
            : const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
        color: onPressed == null
            ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12)
            : null,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      ),
      child: SizedBox(
        height: 52,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.onPrimary,
                      ),
                    )
                  : Text(
                      label,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: onPressed == null
                            ? Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.38)
                            : AppColors.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A styled inline error banner.
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppSizes.radiusDefault),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: colorScheme.onErrorContainer,
            size: AppSizes.iconMd,
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
