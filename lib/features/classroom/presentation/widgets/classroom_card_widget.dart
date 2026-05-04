import 'dart:ui';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/classroom_entity.dart';

/// Shared base card displaying classroom name, avatar initials, and quick actions.
///
/// [TeacherClassroomCardWidget] and [StudentClassroomCardWidget] compose this
/// widget and add role-specific actions on top.
class ClassroomCardWidget extends StatelessWidget {
  const ClassroomCardWidget({
    super.key,
    required this.classroom,
    required this.onTap,
    this.trailingActions,
  });

  /// The classroom data to display.
  final ClassroomEntity classroom;

  /// Called when the card is tapped (e.g. open classroom channel).
  final VoidCallback onTap;

  /// Optional role-specific actions placed in the top-right corner.
  /// Teachers pass a [PopupMenuButton]; students pass nothing.
  final Widget? trailingActions;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final cardColor = isLight
        ? AppColors.glassWhiteHigh
        : AppColors.surfaceContainer.withValues(alpha: 0.1);
    final initials = _buildInitials(classroom.name);

    final colors = [
      AppColors.primaryContainer,
      AppColors.secondaryContainer,
      AppColors.tertiaryContainer,
      Colors.pink,
      Colors.deepOrange,
    ];
    final color = colors[classroom.name.length % colors.length];

    return Semantics(
      label: 'Lớp học: ${classroom.name}',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: AppSizes.brXL,
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: AppSizes.blurLevel2,
              sigmaY: AppSizes.blurLevel2,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: AppSizes.brXL,
                border: Border.all(
                  color: isLight ? AppColors.luminousBorder : Colors.white.withValues(alpha: 0.1), 
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.withValues(alpha: 0.8),
                            color.withValues(alpha: 0.1),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppSizes.radiusXL),
                        ),
                      ),
                    ),
                  ),
                  if (trailingActions != null)
                    Positioned(
                      top: AppSizes.xl,
                      right: 5.0,
                      child: trailingActions!,
                    ),
                  Padding(
                    padding: const EdgeInsets.all(AppSizes.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: AppSizes.brMedium,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initials,
                            style: AppTextStyles.headlineMedium.copyWith(
                              color: color,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          classroom.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.headlineMedium.copyWith(
                            fontSize: 20,
                            height: 1.3,
                            color: isLight ? AppColors.onSurface : Colors.white,
                          ),
                        ),
                        const SizedBox(height: AppSizes.sm),
                        Text(
                          'ROOM ${classroom.id.substring(0, 3).toUpperCase()} • ${classroom.studentCount} STUDENTS',
                          style: AppTextStyles.labelCaps.copyWith(
                            color: isLight ? AppColors.onSurfaceVariant : AppColors.outlineVariant,
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
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _buildInitials(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (words.length >= 2) {
      final list = words.toList(growable: false);
      return '${list[0][0]}${list[1][0]}'.toUpperCase();
    }
    final compact = name.replaceAll(' ', '').toUpperCase();
    return compact.length >= 2 ? compact.substring(0, 2) : compact;
  }
}
