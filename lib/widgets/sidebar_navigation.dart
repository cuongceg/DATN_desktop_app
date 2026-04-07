import 'package:flutter/material.dart';

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
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: 88,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.65),
        border: Border(right: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.school_rounded, color: scheme.onPrimary),
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
          const Spacer(),
          _NavIcon(
            icon: Icons.settings_outlined,
            selected: selectedIndex == 3,
            tooltip: 'Cài đặt',
            onTap: () => onDestinationSelected(3),
          ),
          const SizedBox(height: 16),
        ],
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
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: selected ? scheme.primaryContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: selected ? scheme.onPrimaryContainer : scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
