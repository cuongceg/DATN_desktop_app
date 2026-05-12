import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_sizes.dart';

class SidebarNavigation extends StatelessWidget {
  const SidebarNavigation({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppSizes.blurLevel2,
          sigmaY: AppSizes.blurLevel2,
        ),
        child: Container(
          width: AppSizes.sidebarCollapsed,
          decoration: BoxDecoration(
            color: isLight ? AppColors.glassWhiteHigh : Colors.black.withValues(alpha: 0.2),
            border: Border(
              right: BorderSide(
                color: isLight 
                  ? AppColors.luminousBorder 
                  : Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: AppSizes.brLarge,
                ),
                child: const Icon(Icons.school_rounded, color: Colors.white),
              ),
              const SizedBox(height: 24),
              _NavIcon(
                icon: Icons.notifications_none_outlined,
                selected: selectedIndex == 0,
                tooltip: 'Dashboard',
                onTap: () => onDestinationSelected(0),
              ),
              _NavIcon(
                icon: Icons.class_outlined,
                selected: selectedIndex == 1,
                tooltip: 'Lớp học',
                onTap: () => onDestinationSelected(1),
              ),
              _NavIcon(
                icon: Icons.calendar_month_outlined,
                selected: selectedIndex == 2,
                tooltip: 'Lịch',
                onTap: () => onDestinationSelected(2),
              ),
              _NavIcon(
                icon: Icons.mic_none_outlined,
                selected: selectedIndex == 3,
                tooltip: 'Phụ đề STT',
                onTap: () => onDestinationSelected(3),
              ),
              const Spacer(),
              _NavIcon(
                icon: Icons.settings_outlined,
                selected: selectedIndex == 4,
                tooltip: 'Cài đặt',
                onTap: () => onDestinationSelected(4),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.icon,
    required this.selected,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          borderRadius: AppSizes.brMedium,
          onTap: onTap,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: AppSizes.brMedium,
                ),
                child: Icon(
                  icon,
                  color: selected
                      ? AppColors.primary
                      : Theme.of(context).brightness == Brightness.light
                          ? AppColors.onSurfaceVariant
                          : AppColors.outlineVariant,
                ),
              ),
              if (selected)
                Positioned(
                  left: 0,
                  child: Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: AppSizes.brFull,
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
