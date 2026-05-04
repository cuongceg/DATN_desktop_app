import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../models/class_details.dart';
import '../../../../models/class_member.dart';
import '../../../../models/class_model.dart';
import '../../../../models/user.dart';
import '../../../../services/debounce.dart';

class EditClassNotifier extends ChangeNotifier {
  EditClassNotifier({
    required this.initialClass,
    required this.fetchClassDetails,
    required this.searchUsers,
    required this.addMember,
    required this.removeMember,
    required this.saveClassInfo,
  }) {
    nameController.text = initialClass.name;
    descriptionController.text = initialClass.description ?? '';
    _loadClassDetails();
  }

  final ClassModel initialClass;
  final Future<ClassDetails> Function(String classId) fetchClassDetails;
  final Future<List<User>> Function(String keyword) searchUsers;
  final Future<ClassMember> Function({
    required String classId,
    required String userId,
    String permission,
  })
  addMember;
  final Future<void> Function({required String classId, required String userId})
  removeMember;
  final Future<ClassModel> Function({required String name, String? description})
  saveClassInfo;

  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final searchController = TextEditingController();

  bool isLoading = true;
  bool isSaving = false;
  bool isSearching = false;

  List<ClassMember> existingMembers = [];
  List<User> searchResults = [];

  final Set<String> usersToAdd = {};
  final Set<String> membersToRemove = {};

  bool get hasChanges {
    final newName = nameController.text.trim();
    final newDesc = descriptionController.text.trim();
    if (newName.isNotEmpty && newName != initialClass.name) return true;
    if (newDesc != (initialClass.description ?? '')) return true;
    if (usersToAdd.isNotEmpty) return true;
    if (membersToRemove.isNotEmpty) return true;
    return false;
  }

  String get classCode => initialClass.classCode ?? 'N/A';
  DateTime? get createdAt => initialClass.createdAt;

  Future<void> _loadClassDetails() async {
    isLoading = true;
    notifyListeners();
    try {
      final details = await fetchClassDetails(initialClass.id);
      existingMembers = details.members;
    } catch (e) {
      debugPrint('Error loading class details: $e');
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      searchResults = [];
      isSearching = false;
      notifyListeners();
      return;
    }
    isSearching = true;
    notifyListeners();
    try {
      searchResults = await searchUsers(query.trim());
    } catch (e) {
      debugPrint('Error searching users: $e');
    }
    isSearching = false;
    notifyListeners();
  }

  void toggleAddUser(String userId) {
    if (usersToAdd.contains(userId)) {
      usersToAdd.remove(userId);
    } else {
      usersToAdd.add(userId);
    }
    notifyListeners();
  }

  void toggleRemoveMember(String userId) {
    if (membersToRemove.contains(userId)) {
      membersToRemove.remove(userId);
    } else {
      membersToRemove.add(userId);
    }
    notifyListeners();
  }

  Future<bool> saveChanges() async {
    isSaving = true;
    notifyListeners();
    try {
      final newName = nameController.text.trim();
      final newDesc = descriptionController.text.trim();

      if (newName.isNotEmpty &&
          (newName != initialClass.name ||
              newDesc != initialClass.description)) {
        await saveClassInfo(name: newName, description: newDesc);
      }

      for (final userId in usersToAdd) {
        await addMember(
          classId: initialClass.id,
          userId: userId,
          permission: 'Member',
        );
      }

      for (final userId in membersToRemove) {
        await removeMember(classId: initialClass.id, userId: userId);
      }

      return true;
    } catch (e) {
      debugPrint('Error saving changes: $e');
      isSaving = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    searchController.dispose();
    super.dispose();
  }
}

class EditClassScreen extends StatelessWidget {
  const EditClassScreen({
    super.key,
    required this.initialClass,
    required this.fetchClassDetails,
    required this.searchUsers,
    required this.addMember,
    required this.updateMemberRole,
    required this.removeMember,
    required this.saveClassInfo,
  });

  final ClassModel initialClass;
  final Future<ClassDetails> Function(String classId) fetchClassDetails;
  final Future<List<User>> Function(String keyword) searchUsers;
  final Future<ClassMember> Function({
    required String classId,
    required String userId,
    String permission,
  })
  addMember;
  final Future<ClassMember> Function({
    required String classId,
    required String userId,
    required String role,
  })
  updateMemberRole;
  final Future<void> Function({required String classId, required String userId})
  removeMember;
  final Future<ClassModel> Function({required String name, String? description})
  saveClassInfo;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EditClassNotifier(
        initialClass: initialClass,
        fetchClassDetails: fetchClassDetails,
        searchUsers: searchUsers,
        addMember: addMember,
        removeMember: removeMember,
        saveClassInfo: saveClassInfo,
      ),
      child: const _EditClassScreenView(),
    );
  }
}

class _EditClassScreenView extends StatelessWidget {
  const _EditClassScreenView();

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<EditClassNotifier>();
    final isLight = Theme.of(context).brightness == Brightness.light;
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor = isLight ? const Color(0xFFF8F9FA) : colorScheme.surface;

    return PopScope(
      canPop: !notifier.hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final discard = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Discard Changes?'),
            content: const Text(
              'You have unsaved changes. Are you sure you want to discard them and go back?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error,
                  foregroundColor: Theme.of(ctx).colorScheme.onError,
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Discard'),
              ),
            ],
          ),
        );
        if (discard == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: bgColor,
        body: Column(
          children: [
            // Header
            Container(
              height: 72,
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.xl),
              decoration: BoxDecoration(
                color: isLight
                    ? AppColors.white
                    : colorScheme.surfaceContainerHighest,
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () async {
                      if (notifier.hasChanges) {
                        final discard = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Discard Changes?'),
                            content: const Text(
                              'You have unsaved changes. Are you sure you want to discard them and go back?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: Theme.of(
                                    ctx,
                                  ).colorScheme.error,
                                  foregroundColor: Theme.of(
                                    ctx,
                                  ).colorScheme.onError,
                                ),
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text('Discard'),
                              ),
                            ],
                          ),
                        );
                        if (discard != true) return;
                      }
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    tooltip: 'Back',
                  ),
                  const SizedBox(width: AppSizes.md),
                  Container(
                    width: 1,
                    height: 24,
                    color: AppColors.outlineVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: AppSizes.lg),
                  Text(
                    'Edit Class Information',
                    style: AppTextStyles.headlineMedium.copyWith(fontSize: 20),
                  ),
                  const Spacer(),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: AppSizes.brDefault,
                    ),
                    child: ElevatedButton(
                      onPressed: notifier.isSaving
                          ? null
                          : () async {
                              final success = await notifier.saveChanges();
                              if (success && context.mounted) {
                                Navigator.of(context).pop(true);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppSizes.brDefault,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.xl,
                          vertical: AppSizes.md,
                        ),
                      ),
                      child: notifier.isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Save Changes',
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.xl),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Panel: Class Details
                    Expanded(flex: 1, child: _ClassDetailsPanel()),
                    const SizedBox(width: AppSizes.xl),
                    // Right Panel: Add Students
                    Expanded(flex: 1, child: _AddStudentsPanel()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClassDetailsPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<EditClassNotifier>();
    final isLight = Theme.of(context).brightness == Brightness.light;
    final colorScheme = Theme.of(context).colorScheme;
    final cardColor = isLight
        ? AppColors.white
        : colorScheme.surfaceContainerHighest;

    final c = notifier.createdAt;
    final createdAtStr = c != null
        ? '${c.year}-${c.month.toString().padLeft(2, '0')}-${c.day.toString().padLeft(2, '0')}'
        : 'N/A';

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        boxShadow: isLight
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.all(AppSizes.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Class Details', style: AppTextStyles.headlineMedium),
              const SizedBox(width: AppSizes.sm),
              Icon(Icons.edit_outlined, size: 20, color: AppColors.outline),
            ],
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            'Manage core information for this course module.',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSizes.xl),

          // Class Name Field
          Text('CLASS NAME', style: AppTextStyles.labelCaps),
          const SizedBox(height: AppSizes.sm),
          TextField(
            controller: notifier.nameController,
            decoration: InputDecoration(
              hintText: 'Enter class name',
              filled: true,
              fillColor: isLight ? AppColors.white : colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusDefault),
                borderSide: BorderSide(color: AppColors.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusDefault),
                borderSide: BorderSide(
                  color: AppColors.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.lg),

          // Class Description Field
          Text('CLASS DESCRIPTION', style: AppTextStyles.labelCaps),
          const SizedBox(height: AppSizes.sm),
          TextField(
            controller: notifier.descriptionController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Enter class description',
              filled: true,
              fillColor: isLight
                  ? const Color(0xFFFAFAFA)
                  : colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusDefault),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.lg),

          // Class Code Field
          Text('CLASS CODE', style: AppTextStyles.labelCaps),
          const SizedBox(height: AppSizes.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: AppSizes.md,
            ),
            decoration: BoxDecoration(
              color: isLight ? const Color(0xFFF5F6F8) : colorScheme.surface,
              borderRadius: BorderRadius.circular(AppSizes.radiusDefault),
            ),
            child: Row(
              children: [
                Text(
                  notifier.classCode,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: notifier.classCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Class code copied!')),
                    );
                  },
                  child: Icon(Icons.copy, size: 20, color: AppColors.outline),
                ),
                const SizedBox(width: AppSizes.md),
                Icon(Icons.lock_outline, size: 20, color: AppColors.outline),
              ],
            ),
          ),

          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Last updated: Just now',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.outline,
                ),
              ),
              Text(
                'Created: $createdAtStr',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.outline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddStudentsPanel extends StatefulWidget {
  @override
  State<_AddStudentsPanel> createState() => _AddStudentsPanelState();
}

class _AddStudentsPanelState extends State<_AddStudentsPanel> {
  final _debouncer = Debouncer(milliseconds: 300);

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<EditClassNotifier>();
    final isLight = Theme.of(context).brightness == Brightness.light;
    final colorScheme = Theme.of(context).colorScheme;
    final cardColor = isLight
        ? AppColors.white
        : colorScheme.surfaceContainerHighest;

    final hasSearchQuery = notifier.searchController.text.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        boxShadow: isLight
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.all(AppSizes.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add Students', style: AppTextStyles.headlineMedium),
          const SizedBox(height: AppSizes.xs),
          Text(
            'Enroll new students into the ${notifier.initialClass.name} roster.',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSizes.xl),

          // Search Bar
          TextField(
            controller: notifier.searchController,
            onChanged: (val) {
              _debouncer.run(() {
                notifier.search(val);
              });
            },
            decoration: InputDecoration(
              hintText: 'Search for students by name, email, or ID...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: isLight ? AppColors.white : colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(vertical: AppSizes.md),
              border: OutlineInputBorder(
                borderRadius: AppSizes.brFull,
                borderSide: const BorderSide(color: AppColors.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppSizes.brFull,
                borderSide: BorderSide(
                  color: AppColors.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.xl),

          // List Area
          Expanded(
            child: notifier.isLoading
                ? const Center(child: CircularProgressIndicator())
                : notifier.isSearching
                ? const Center(child: CircularProgressIndicator())
                : hasSearchQuery
                ? _buildSearchResults(context, notifier)
                : _buildExistingMembers(context, notifier),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context, EditClassNotifier notifier) {
    if (notifier.searchResults.isEmpty) {
      return Center(
        child: Text(
          'No students found.',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.outlineVariant,
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: notifier.searchResults.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSizes.md),
      itemBuilder: (context, index) {
        final user = notifier.searchResults[index];
        final isExisting = notifier.existingMembers.any(
          (m) => m.userId == user.id,
        );
        final isPendingAdd = notifier.usersToAdd.contains(user.id);

        return _UserTile(
          name: user.fullName,
          email: user.email,
          idText: user.id.length > 5
              ? user.id.substring(0, 5).toUpperCase()
              : user.id,
          actionLabel: isExisting ? 'Added' : (isPendingAdd ? 'Undo' : 'Add'),
          isActive: !isExisting,
          isPending: isPendingAdd,
          onTap: isExisting ? null : () => notifier.toggleAddUser(user.id),
        );
      },
    );
  }

  Widget _buildExistingMembers(
    BuildContext context,
    EditClassNotifier notifier,
  ) {
    if (notifier.existingMembers.isEmpty) {
      return Center(
        child: Text(
          'No members yet. Search to add students.',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.outlineVariant,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CURRENT ROSTER', style: AppTextStyles.labelCaps),
        const SizedBox(height: AppSizes.md),
        Expanded(
          child: ListView.separated(
            itemCount: notifier.existingMembers.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSizes.md),
            itemBuilder: (context, index) {
              final member = notifier.existingMembers[index];
              final isPendingRemove = notifier.membersToRemove.contains(
                member.userId,
              );

              return _UserTile(
                name: member.fullName,
                email: member.email,
                idText: member.userId.length > 5
                    ? member.userId.substring(0, 5).toUpperCase()
                    : member.userId,
                actionLabel: isPendingRemove ? 'Undo' : 'Remove',
                isActive: true,
                isPending: isPendingRemove,
                isDestructive: !isPendingRemove,
                onTap: () => notifier.toggleRemoveMember(member.userId),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({
    required this.name,
    required this.email,
    required this.idText,
    required this.actionLabel,
    required this.isActive,
    required this.onTap,
    this.isPending = false,
    this.isDestructive = false,
  });

  final String name;
  final String email;
  final String idText;
  final String actionLabel;
  final bool isActive;
  final bool isPending;
  final bool isDestructive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Avatar Initials
    final initials = name.trim().isNotEmpty
        ? name.trim().substring(0, 1).toUpperCase()
        : '?';

    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: colorScheme.primaryContainer,
          child: Text(
            initials,
            style: AppTextStyles.headlineMedium.copyWith(
              fontSize: 20,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        const SizedBox(width: AppSizes.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$email • ID: $idText',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.outline,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSizes.sm),
        OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: isDestructive
                ? colorScheme.error
                : (isPending ? colorScheme.onSurface : colorScheme.primary),
            side: BorderSide(
              color: isDestructive
                  ? colorScheme.error
                  : (isPending
                        ? colorScheme.outline
                        : (isActive
                              ? colorScheme.primary
                              : colorScheme.surfaceContainerHighest)),
            ),
            shape: RoundedRectangleBorder(borderRadius: AppSizes.brFull),
          ),
          child: Text(actionLabel),
        ),
      ],
    );
  }
}
