import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../../../../../core/constants/app_sizes.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../models/user.dart';
import '../../../../../services/debounce.dart';
import '../controllers/classroom_notifier.dart';

/// Multi-step dialog for creating a new classroom (teacher only).
///
/// Manages its own state machine:
/// 1. Enter name & description → "Create" button calls [ClassroomNotifier].
/// 2. Loading indicator while waiting for API.
/// 3. Success animation then → Add members step.
/// 4. Autocomplete member search → "Add" / "Skip".
///
/// The dialog pops with no result; callers don't need to handle a return value
/// because [ClassroomNotifier] updates the list internally.
class CreateClassroomDialogWidget extends StatefulWidget {
  const CreateClassroomDialogWidget({
    super.key,
    required this.onSearchUsers,
    required this.onAddMembersToClass,
  });

  /// Searches users by keyword for the add-members step.
  final Future<List<User>> Function(String keyword) onSearchUsers;

  /// Bulk-adds [studentIds] to [classId] after creation.
  final Future<void> Function({
    required String classId,
    required List<String> studentIds,
  })
  onAddMembersToClass;

  @override
  State<CreateClassroomDialogWidget> createState() =>
      _CreateClassroomDialogWidgetState();
}

enum _Step { details, loading, success, addMembers }

class _CreateClassroomDialogWidgetState
    extends State<CreateClassroomDialogWidget> {
  _Step _step = _Step.details;

  Timer? _successTimer;
  int _successToken = 0;

  // Step 1 controllers
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _nameIsValid = false;
  String? _createdClassId;
  String? _createdClassName;

  // Step 3 controllers
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  final _debouncer = Debouncer(milliseconds: 400);
  final List<User> _selectedUsers = [];
  List<User> _searchResults = const [];
  bool _isSearching = false;
  int _searchToken = 0;

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(() {
      final valid = _nameCtrl.text.trim().isNotEmpty;
      if (valid != _nameIsValid) setState(() => _nameIsValid = valid);
    });
  }

  @override
  void dispose() {
    _successTimer?.cancel();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Step 1 → create classroom
  // ---------------------------------------------------------------------------

  Future<void> _handleCreate() async {
    setState(() => _step = _Step.loading);

    try {
      final entity = await context.read<ClassroomNotifier>().createClassroom(
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _createdClassId = entity.id;
        _createdClassName = entity.name;
        _step = _Step.success;
      });

      _scheduleAdvanceToAddMembers();
    } catch (e) {
      if (!mounted) return;
      setState(() => _step = _Step.details);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _scheduleAdvanceToAddMembers() {
    _successTimer?.cancel();
    final token = ++_successToken;
    _successTimer = Timer(const Duration(milliseconds: 2000), () {
      if (!mounted || token != _successToken) return;
      setState(() => _step = _Step.addMembers);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || token != _successToken) return;
        _searchFocus.requestFocus();
      });
    });
  }

  // ---------------------------------------------------------------------------
  // Step 3 → search users
  // ---------------------------------------------------------------------------

  void _onSearchChanged(String value) {
    final keyword = value.trim();
    if (keyword.isEmpty) {
      _searchToken++;
      setState(() {
        _isSearching = false;
        _searchResults = const [];
      });
      return;
    }

    setState(() => _isSearching = true);

    _debouncer.run(() async {
      final token = ++_searchToken;
      try {
        final users = await widget.onSearchUsers(keyword);
        if (!mounted || token != _searchToken) return;
        setState(() {
          _searchResults = users;
          _isSearching = false;
        });
      } catch (_) {
        if (!mounted || token != _searchToken) return;
        setState(() {
          _searchResults = const [];
          _isSearching = false;
        });
      }
    });
  }

  Future<void> _finishWithMembers() async {
    final classId = _createdClassId;
    if (classId != null && _selectedUsers.isNotEmpty) {
      try {
        await widget.onAddMembersToClass(
          classId: classId,
          studentIds: _selectedUsers.map((u) => u.id).toList(growable: false),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Thêm thành viên thất bại: ${e.toString()}')),
        );
      }
    }
    if (mounted) Navigator.of(context).pop();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppSizes.brDefault),
      elevation: 4,
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: switch (_step) {
          _Step.loading => 200,
          _Step.success => 360,
          _ => 480,
        },
        width: 580,
        padding: const EdgeInsets.all(AppSizes.lg),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: _buildCurrentStep(),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case _Step.details:
        return _buildDetailsStep();
      case _Step.loading:
        return _buildLoadingStep();
      case _Step.success:
        return _buildSuccessStep();
      case _Step.addMembers:
        return _buildAddMembersStep();
    }
  }

  // ---- Step 1: Details ----
  Widget _buildDetailsStep() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final inputTheme = theme.inputDecorationTheme;

    return Column(
      key: const ValueKey('details'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Thông tin lớp học',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Semantics(
              label: 'Đóng hộp thoại',
              child: IconButton(
                icon: const Icon(Icons.close, size: 20),
                tooltip: 'Đóng',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Tên lớp học',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        Semantics(
          label: 'Ô nhập tên lớp học',
          textField: true,
          child: TextField(
            controller: _nameCtrl,
            autofocus: true,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Nhập tên lớp học',
              filled: inputTheme.filled,
              fillColor: inputTheme.fillColor,
              contentPadding: const EdgeInsets.all(AppSizes.md),
              border: OutlineInputBorder(
                borderRadius: AppSizes.brSmall,
                borderSide: BorderSide(color: colorScheme.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppSizes.brSmall,
                borderSide: BorderSide(color: colorScheme.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppSizes.brSmall,
                borderSide: BorderSide(color: colorScheme.primary, width: 2),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Mô tả (tùy chọn)',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        Semantics(
          label: 'Ô nhập mô tả lớp học',
          textField: true,
          child: TextField(
            controller: _descCtrl,
            maxLines: 4,
            style: AppTextStyles.bodySmall,
            decoration: InputDecoration(
              hintText: 'Mô tả ngắn về lớp học',
              filled: inputTheme.filled,
              fillColor: inputTheme.fillColor,
              contentPadding: const EdgeInsets.all(AppSizes.md),
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: AppSizes.brSmall,
              ),
            ),
          ),
        ),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.chevron_left, size: 18),
              label: const Text('Hủy'),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.onSurfaceVariant,
              ),
            ),
            Semantics(
              label: 'Tạo lớp học',
              child: FilledButton(
                onPressed: _nameIsValid ? _handleCreate : null,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: AppSizes.brSmall),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
                child: const Text('Tạo lớp'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---- Step 2: Loading ----
  Widget _buildLoadingStep() {
    return const Center(
      key: ValueKey('loading'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          SizedBox(height: 20),
          Text('Đang tạo lớp học...'),
        ],
      ),
    );
  }

  // ---- Step 2.5: Success animation ----
  Widget _buildSuccessStep() {
    final theme = Theme.of(context);

    return Center(
      key: const ValueKey('success'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: 'Hoạt ảnh tạo lớp học thành công',
            image: true,
            child: Lottie.asset(
              'assets/animations/Success.json',
              width: 180,
              height: 180,
              repeat: false,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            'Tạo lớp học thành công',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ---- Step 3: Add members ----
  Widget _buildAddMembersStep() {
    final teamName = _createdClassName ?? '';
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final inputTheme = theme.inputDecorationTheme;

    return Column(
      key: const ValueKey('addMembers'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thêm thành viên vào $teamName',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Text(
          'Nhập tên để tìm kiếm và thêm học sinh vào lớp. Bạn có thể bỏ qua bước này.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: RawAutocomplete<User>(
            focusNode: _searchFocus,
            textEditingController: _searchCtrl,
            displayStringForOption: (u) => u.fullName,
            optionsBuilder: (value) {
              final query = value.text.trim();
              if (query.isEmpty) return const Iterable<User>.empty();
              return _searchResults.where(
                (u) => !_selectedUsers.any((s) => s.id == u.id),
              );
            },
            onSelected: (User user) {
              setState(() => _selectedUsers.add(user));
              _searchCtrl.clear();
              _searchToken++;
              setState(() => _searchResults = const []);
              _searchFocus.requestFocus();
            },
            fieldViewBuilder: (context, ctrl, focus, onSubmit) {
              return SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    color: inputTheme.fillColor,
                    borderRadius: AppSizes.brSmall,
                    border: Border.all(
                      color: focus.hasFocus
                          ? colorScheme.primary
                          : colorScheme.outlineVariant,
                      width: focus.hasFocus ? 2 : 1,
                    ),
                  ),
                  padding: const EdgeInsets.all(AppSizes.md),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ..._selectedUsers.map(
                        (u) => Chip(
                          label: Text(
                            u.fullName,
                            style: const TextStyle(fontSize: 13),
                          ),
                          avatar: const CircleAvatar(
                            backgroundColor: Colors.grey,
                            child: Icon(
                              Icons.person,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () => setState(
                            () =>
                                _selectedUsers.removeWhere((s) => s.id == u.id),
                          ),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 220,
                        child: Semantics(
                          label: 'Ô tìm kiếm học sinh',
                          textField: true,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 44),
                            child: TextField(
                              controller: ctrl,
                              focusNode: focus,
                              onChanged: _onSearchChanged,
                              textAlignVertical: TextAlignVertical.center,
                              style: AppTextStyles.bodyLarge,
                              decoration: const InputDecoration(
                                hintText: 'Tìm kiếm học sinh...',
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              onSubmitted: (_) => onSubmit(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              if (_isSearching) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(4),
                    child: const SizedBox(
                      width: 350,
                      height: 72,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                );
              }
              if (options.isEmpty) return const SizedBox.shrink();
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    width: 350,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final u = options.elementAt(index);
                          return InkWell(
                            onTap: () => onSelected(u),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  const CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.grey,
                                    child: Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        u.fullName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        u.email,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Semantics(
              label: 'Bỏ qua thêm thành viên',
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: Text(
                  'Bỏ qua',
                  style: TextStyle(color: Colors.grey.shade800),
                ),
              ),
            ),
            Semantics(
              label: 'Thêm thành viên đã chọn',
              child: FilledButton(
                onPressed: _selectedUsers.isNotEmpty
                    ? _finishWithMembers
                    : null,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
                child: const Text('Thêm'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
