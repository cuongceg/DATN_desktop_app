import 'package:flutter/material.dart';
import 'package:flutter_web_rtc/core/constants/app_colors.dart';
import 'package:flutter_web_rtc/core/constants/app_sizes.dart';
import 'package:flutter_web_rtc/core/constants/app_text_styles.dart';
import 'package:flutter_web_rtc/features/auth/presentation/widgets/login_form_widget.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({
    super.key,
    required this.themeMode,
    required this.onToggleTheme,
  });

  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < AppSizes.breakpointCompact;

            if (isCompact) {
              return Column(
                children: [
                  Expanded(
                    flex: 4,
                    child: _BrandPanel(
                      isDark: themeMode == ThemeMode.dark,
                      onToggleTheme: onToggleTheme,
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
                    isDark: themeMode == ThemeMode.dark,
                    onToggleTheme: onToggleTheme,
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: Container(
                    color: Theme.of(context).colorScheme.surface,
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
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.surfaceContainerLow,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.lg,
            vertical: AppSizes.xl,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSizes.formMaxWidth),
            child: Container(
              padding: const EdgeInsets.all(AppSizes.xl),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(AppSizes.radiusXL),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.08),
                    blurRadius: 32,
                    spreadRadius: 0,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.04),
                    blurRadius: 8,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: const LoginFormWidget(),
            ),
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
      padding: const EdgeInsets.all(AppSizes.pageMargin),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.secondary.withValues(alpha: 0.8),
          ],
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
          // Refactored Logo Container with Glassmorphism
          Container(
            width: AppSizes.logoSize,
            height: AppSizes.logoSize,
            decoration: BoxDecoration(
              color: AppColors.glassWhite,
              borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
              border: Border.all(color: AppColors.luminousBorder, width: 1),
            ),
            child: const Icon(
              Icons.auto_stories,
              color: AppColors.white,
              size: AppSizes.iconLg,
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          Text(
            'EduDeaf',
            style: AppTextStyles.displayLarge.copyWith(color: AppColors.white),
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            'A specialized learning environment for the deaf and hard of hearing.',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.white.withValues(alpha: 0.9),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
