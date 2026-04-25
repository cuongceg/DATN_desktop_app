import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/class_details.dart';
import '../../models/class_member.dart';
import '../../models/class_model.dart';
import '../../models/user.dart';
import '../../services/debounce.dart';

class EditClassScreen extends StatefulWidget {
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
  State<EditClassScreen> createState() => _EditClassScreenState();
}

class _EditClassScreenState extends State<EditClassScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  late final Debouncer _searchDebouncer;

  ClassModel? _classroom;
  List<_EditableMember> _members = const [];
  List<User> _searchResults = const [];

  String _baseName = '';
  String _baseDescription = '';
  Map<String, String> _baseRoleByUserId = const {};
  Map<String, _EditableMember> _baseMemberByUserId = const {};

  final Map<String, String> _roleChangesByUserId = {};
  final Set<String> _removedExistingMemberIds = {};

  User? _selectedUser;
  bool _isInitialLoading = true;
  bool _isSaving = false;
  bool _isSearching = false;
  bool _isSidebarEditing = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialClass.name);
    _descriptionController = TextEditingController(
      text: widget.initialClass.description ?? '',
    );
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    _searchDebouncer = Debouncer(milliseconds: 350);
    _loadClassDetails();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchDebouncer.dispose();
    super.dispose();
  }

  Future<void> _loadClassDetails({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isInitialLoading = true;
      });
    }

    try {
      final details = await widget.fetchClassDetails(widget.initialClass.id);
      if (!mounted) {
        return;
      }
      _applyDetails(details);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted && showLoading) {
        setState(() {
          _isInitialLoading = false;
        });
      }
    }
  }

  void _applyDetails(ClassDetails details) {
    final members = details.members
        .map(
          (member) => _EditableMember(
            userId: member.userId,
            fullName: member.fullName,
            email: member.email,
            permission: _normalizeRole(member.permission),
            isNew: false,
          ),
        )
        .toList(growable: true);

    _classroom = details.classroom;
    _baseName = details.classroom.name.trim();
    _baseDescription = (details.classroom.description ?? '').trim();
    _baseRoleByUserId = {
      for (final member in members) member.userId: member.permission,
    };
    _baseMemberByUserId = {for (final member in members) member.userId: member};

    _roleChangesByUserId.clear();
    _removedExistingMemberIds.clear();
    _members = members;
    _nameController.text = details.classroom.name;
    _descriptionController.text = details.classroom.description ?? '';

    setState(() {});
  }

  bool get _hasClassInfoChanges {
    final currentName = _nameController.text.trim();
    final currentDescription = _descriptionController.text.trim();
    return currentName != _baseName || currentDescription != _baseDescription;
  }

  bool get _hasMemberChanges {
    if (_removedExistingMemberIds.isNotEmpty ||
        _roleChangesByUserId.isNotEmpty) {
      return true;
    }
    return _members.any((member) => member.isNew);
  }

  bool get _hasChanges => _hasClassInfoChanges || _hasMemberChanges;

  Future<void> _searchUsers(String rawQuery) async {
    final query = rawQuery.trim();
    if (query.isEmpty) {
      if (mounted) {
        setState(() {
          _searchResults = const [];
          _selectedUser = null;
          _isSearching = false;
        });
      }
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final users = await widget.searchUsers(query);
      if (!mounted) {
        return;
      }
      setState(() {
        _searchResults = users;
        _isSearching = false;
        if (_selectedUser != null &&
            !users.any((user) => user.id == _selectedUser!.id)) {
          _selectedUser = null;
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _addSelectedMember() {
    final user = _selectedUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a user before adding.')),
      );
      return;
    }

    final existingIndex = _members.indexWhere((item) => item.userId == user.id);
    if (existingIndex >= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This user is already listed.')),
      );
      return;
    }

    final restored = _baseMemberByUserId[user.id];
    setState(() {
      if (restored != null && _removedExistingMemberIds.remove(user.id)) {
        _members = [..._members, restored];
      } else {
        _members = [
          ..._members,
          _EditableMember(
            userId: user.id,
            fullName: user.fullName,
            email: user.email,
            permission: 'Member',
            isNew: true,
          ),
        ];
      }
      _selectedUser = null;
      _searchController.clear();
      _searchResults = const [];
    });
  }

  Future<void> _confirmRemoveMember(_EditableMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member?'),
        content: Text(
          'Are you sure you want to remove ${member.fullName} from this classroom?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    setState(() {
      _members = _members
          .where((item) => item.userId != member.userId)
          .toList();
      _roleChangesByUserId.remove(member.userId);
      if (!member.isNew) {
        _removedExistingMemberIds.add(member.userId);
      }
    });
  }

  void _handlePermissionChange(String userId, String role) {
    final normalized = _normalizeRole(role);
    setState(() {
      _members = _members
          .map(
            (member) => member.userId == userId
                ? member.copyWith(permission: normalized)
                : member,
          )
          .toList(growable: false);

      final isNew = _members
          .firstWhere((member) => member.userId == userId)
          .isNew;
      if (isNew) {
        return;
      }

      final baseRole = _baseRoleByUserId[userId];
      if (baseRole == null || baseRole == normalized) {
        _roleChangesByUserId.remove(userId);
      } else {
        _roleChangesByUserId[userId] = normalized;
      }
    });
  }

  void _cancelSidebarEditing() {
    if (!_isSidebarEditing) {
      return;
    }
    setState(() {
      _isSidebarEditing = false;
      _nameController.text = _classroom?.name ?? _baseName;
      _descriptionController.text = _classroom?.description ?? _baseDescription;
    });
  }

  void _finishSidebarEditing() {
    if (!_isSidebarEditing) {
      return;
    }
    setState(() {
      _isSidebarEditing = false;
    });
  }

  Future<bool> _confirmLeaveIfHasUnsavedChanges() async {
    if (_isSaving) {
      return false;
    }
    if (!_hasChanges) {
      return true;
    }

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text(
          'You have unsaved changes. Do you want to discard them and leave this screen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Stay'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return shouldDiscard == true;
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Class name is required.')));
      return;
    }

    if (!_hasChanges) {
      Navigator.of(context).pop(_classroom ?? widget.initialClass);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final description = _descriptionController.text.trim();
      if (_hasClassInfoChanges) {
        final updated = await widget.saveClassInfo(
          name: name,
          description: description.isEmpty ? null : description,
        );
        _classroom = updated;
      }

      final newMembers = _members.where((member) => member.isNew).toList();
      for (final member in newMembers) {
        await widget.addMember(
          classId: widget.initialClass.id,
          userId: member.userId,
          permission: member.permission,
        );
      }

      final roleChanges = Map<String, String>.from(_roleChangesByUserId);
      for (final entry in roleChanges.entries) {
        await widget.updateMemberRole(
          classId: widget.initialClass.id,
          userId: entry.key,
          role: entry.value,
        );
      }

      for (final userId in _removedExistingMemberIds) {
        await widget.removeMember(
          classId: widget.initialClass.id,
          userId: userId,
        );
      }

      await _loadClassDetails(showLoading: false);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(_classroom ?? widget.initialClass);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Shortcuts(
      shortcuts: {LogicalKeySet(LogicalKeyboardKey.escape): DismissIntent()},
      child: Actions(
        actions: {
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) {
              _cancelSidebarEditing();
              return null;
            },
          ),
        },
        child: WillPopScope(
          onWillPop: _confirmLeaveIfHasUnsavedChanges,
          child: Scaffold(
            appBar: AppBar(title: const Text('Edit Classroom')),
            body: _isInitialLoading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                    child: Column(
                      children: [
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final isCompact = constraints.maxWidth < 1000;
                              final sidebarWidth = (constraints.maxWidth * 0.33)
                                  .clamp(320.0, 460.0);

                              if (isCompact) {
                                return Column(
                                  children: [
                                    _SidebarInfo(
                                      backgroundColor:
                                          scheme.surfaceContainerHighest,
                                      isEditing: _isSidebarEditing,
                                      nameController: _nameController,
                                      descriptionController:
                                          _descriptionController,
                                      onToggleEdit: () {
                                        if (_isSidebarEditing) {
                                          _finishSidebarEditing();
                                          return;
                                        }
                                        setState(() {
                                          _isSidebarEditing = true;
                                        });
                                      },
                                      onCancelEdit: _cancelSidebarEditing,
                                      classCode: _classroom?.classCode,
                                      isCompact: true,
                                    ),
                                    const SizedBox(height: 14),
                                    Expanded(
                                      child: _buildMembersPanel(theme, scheme),
                                    ),
                                  ],
                                );
                              }

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: sidebarWidth,
                                    child: _SidebarInfo(
                                      backgroundColor:
                                          scheme.surfaceContainerHighest,
                                      isEditing: _isSidebarEditing,
                                      nameController: _nameController,
                                      descriptionController:
                                          _descriptionController,
                                      onToggleEdit: () {
                                        if (_isSidebarEditing) {
                                          _finishSidebarEditing();
                                          return;
                                        }
                                        setState(() {
                                          _isSidebarEditing = true;
                                        });
                                      },
                                      onCancelEdit: _cancelSidebarEditing,
                                      classCode: _classroom?.classCode,
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: SizedBox(
                                      height: constraints.maxHeight,
                                      child: _buildMembersPanel(theme, scheme),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            FilledButton.icon(
                              onPressed: (!_hasChanges || _isSaving)
                                  ? null
                                  : _handleSave,
                              icon: _isSaving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.save_outlined),
                              label: Text(
                                _isSaving ? 'Saving...' : 'Save Changes',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildMembersPanel(ThemeData theme, ColorScheme scheme) {
    return Card(
      elevation: 0,
      color: scheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final narrowHeader = constraints.maxWidth < 760;
                if (narrowHeader) {
                  return Column(
                    children: [
                      RawAutocomplete<User>(
                        textEditingController: _searchController,
                        focusNode: _searchFocusNode,
                        displayStringForOption: (user) =>
                            '${user.fullName} - ${user.email}',
                        optionsBuilder: (value) {
                          final query = value.text.trim().toLowerCase();
                          if (query.isEmpty) {
                            return const Iterable<User>.empty();
                          }
                          return _searchResults.where(
                            (user) =>
                                user.fullName.toLowerCase().contains(query) ||
                                user.email.toLowerCase().contains(query),
                          );
                        },
                        onSelected: (user) {
                          setState(() {
                            _selectedUser = user;
                            _searchController.text = user.fullName;
                          });
                        },
                        fieldViewBuilder:
                            (context, controller, focusNode, onFieldSubmitted) {
                              return TextField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: InputDecoration(
                                  hintText: 'Search users by name',
                                  prefixIcon: const Icon(Icons.search),
                                  suffixIcon: _isSearching
                                      ? const Padding(
                                          padding: EdgeInsets.all(12),
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : IconButton(
                                          onPressed: () =>
                                              _searchUsers(controller.text),
                                          icon: const Icon(Icons.arrow_forward),
                                        ),
                                ),
                                onChanged: (value) {
                                  _selectedUser = null;
                                  _searchDebouncer.run(
                                    () => _searchUsers(value),
                                  );
                                },
                                onSubmitted: _searchUsers,
                              );
                            },
                        optionsViewBuilder: (context, onSelected, options) {
                          final optionList = options.toList();
                          if (optionList.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 4,
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: constraints.maxWidth,
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  itemCount: optionList.length > 6
                                      ? 6
                                      : optionList.length,
                                  itemBuilder: (context, index) {
                                    final user = optionList[index];
                                    return ListTile(
                                      leading: const CircleAvatar(
                                        child: Icon(Icons.person_outline),
                                      ),
                                      title: Text(user.fullName),
                                      subtitle: Text(user.email),
                                      onTap: () => onSelected(user),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          onPressed: _selectedUser == null
                              ? null
                              : _addSelectedMember,
                          icon: const Icon(Icons.person_add_alt_1),
                          label: const Text('Add Member'),
                        ),
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: RawAutocomplete<User>(
                        textEditingController: _searchController,
                        focusNode: _searchFocusNode,
                        displayStringForOption: (user) =>
                            '${user.fullName} - ${user.email}',
                        optionsBuilder: (value) {
                          final query = value.text.trim().toLowerCase();
                          if (query.isEmpty) {
                            return const Iterable<User>.empty();
                          }
                          return _searchResults.where(
                            (user) =>
                                user.fullName.toLowerCase().contains(query) ||
                                user.email.toLowerCase().contains(query),
                          );
                        },
                        onSelected: (user) {
                          setState(() {
                            _selectedUser = user;
                            _searchController.text = user.fullName;
                          });
                        },
                        fieldViewBuilder:
                            (context, controller, focusNode, onFieldSubmitted) {
                              return TextField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: InputDecoration(
                                  hintText: 'Search users by name',
                                  prefixIcon: const Icon(Icons.search),
                                  suffixIcon: _isSearching
                                      ? const Padding(
                                          padding: EdgeInsets.all(12),
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : IconButton(
                                          onPressed: () =>
                                              _searchUsers(controller.text),
                                          icon: const Icon(Icons.arrow_forward),
                                        ),
                                ),
                                onChanged: (value) {
                                  _selectedUser = null;
                                  _searchDebouncer.run(
                                    () => _searchUsers(value),
                                  );
                                },
                                onSubmitted: _searchUsers,
                              );
                            },
                        optionsViewBuilder: (context, onSelected, options) {
                          final optionList = options.toList();
                          if (optionList.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 4,
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: 480,
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  itemCount: optionList.length > 6
                                      ? 6
                                      : optionList.length,
                                  itemBuilder: (context, index) {
                                    final user = optionList[index];
                                    return ListTile(
                                      leading: const CircleAvatar(
                                        child: Icon(Icons.person_outline),
                                      ),
                                      title: Text(user.fullName),
                                      subtitle: Text(user.email),
                                      onTap: () => onSelected(user),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _selectedUser == null
                          ? null
                          : _addSelectedMember,
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('Add Member'),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            Expanded(
              child: _members.isEmpty
                  ? Center(
                      child: Text(
                        'No members in this classroom yet.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    )
                  : ListView.separated(
                      itemCount: _members.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final member = _members[index];
                        return _MemberListItem(
                          member: member,
                          onPermissionChanged: (role) =>
                              _handlePermissionChange(member.userId, role),
                          onRemove: () => _confirmRemoveMember(member),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _normalizeRole(String raw) {
    return raw.toLowerCase() == 'owner' ? 'Owner' : 'Member';
  }
}

class _SidebarInfo extends StatelessWidget {
  const _SidebarInfo({
    required this.backgroundColor,
    required this.isEditing,
    required this.nameController,
    required this.descriptionController,
    required this.onToggleEdit,
    required this.onCancelEdit,
    this.classCode,
    this.isCompact = false,
  });

  final Color backgroundColor;
  final bool isEditing;
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final VoidCallback onToggleEdit;
  final VoidCallback onCancelEdit;
  final String? classCode;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Class Information',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: isEditing
                      ? 'Save class info changes'
                      : 'Edit class information',
                  onPressed: onToggleEdit,
                  icon: Icon(
                    isEditing
                        ? Icons.check_circle_outline
                        : Icons.edit_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isEditing) ...[
              Text(
                'Class name',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
              ),
              TextField(
                controller: nameController,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w400,
                ),
                decoration: InputDecoration(
                  hintText: 'Give your class a name',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              Text(
                'Description',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: descriptionController,
                maxLines: 5,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Let members know what this class is about',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.light
                      ? const Color(0xFFF5F5F5)
                      : Colors.grey.shade900,
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: onCancelEdit,
                icon: const Icon(Icons.close),
                label: const Text('Cancel edit (Esc)'),
              ),
            ] else ...[
              Text(
                nameController.text.trim().isEmpty
                    ? 'Untitled Classroom'
                    : nameController.text.trim(),
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                descriptionController.text.trim().isEmpty
                    ? 'No description available.'
                    : descriptionController.text.trim(),
                maxLines: isCompact ? 4 : 6,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyLarge,
              ),
            ],
            const SizedBox(height: 14),
            Text(
              'Team code',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.light
                    ? const Color(0xFFF5F5F5)
                    : Colors.grey.shade900,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      (classCode == null || classCode!.trim().isEmpty)
                          ? 'Unavailable'
                          : classCode!,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Copy team code',
                    onPressed: (classCode == null || classCode!.trim().isEmpty)
                        ? null
                        : () async {
                            await Clipboard.setData(
                              ClipboardData(text: classCode!.trim()),
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Team code copied.'),
                                ),
                              );
                            }
                          },
                    icon: const Icon(Icons.copy_all_outlined),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberListItem extends StatelessWidget {
  const _MemberListItem({
    required this.member,
    required this.onPermissionChanged,
    required this.onRemove,
  });

  final _EditableMember member;
  final ValueChanged<String> onPermissionChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFFE0E0E0),
              child: Icon(Icons.person_outline),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          member.fullName,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (member.isNew)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Chip(
                            label: const Text('New'),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                    ],
                  ),
                  Text(
                    member.email,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 130,
              child: DropdownButtonFormField<String>(
                initialValue: member.permission,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'Owner', child: Text('Owner')),
                  DropdownMenuItem(value: 'Member', child: Text('Member')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    onPermissionChanged(value);
                  }
                },
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              tooltip: 'Remove member',
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline),
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}

class _EditableMember {
  const _EditableMember({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.permission,
    required this.isNew,
  });

  final String userId;
  final String fullName;
  final String email;
  final String permission;
  final bool isNew;

  _EditableMember copyWith({
    String? userId,
    String? fullName,
    String? email,
    String? permission,
    bool? isNew,
  }) {
    return _EditableMember(
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      permission: permission ?? this.permission,
      isNew: isNew ?? this.isNew,
    );
  }
}
