import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../models/user.dart';
import '../services/debounce.dart';

// Khai báo các bước của Dialog
enum CreateStep { details, loading, success, addMembers }

class CreateClassDialog extends StatefulWidget {
  const CreateClassDialog({super.key, required this.onSearchUsers});

  final Future<List<User>> Function(String keyword) onSearchUsers;

  @override
  State<CreateClassDialog> createState() => _CreateClassDialogState();
}

class _CreateClassDialogState extends State<CreateClassDialog> {
  // Trạng thái hiện tại
  CreateStep _currentStep = CreateStep.details;

  // Controllers cho Bước 1
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isCreateEnabled = false;

  // Controllers & State cho Bước 3
  final _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final Debouncer _searchDebouncer = Debouncer(milliseconds: 500);
  final List<User> _selectedUsers = [];
  List<User> _searchResults = const [];
  bool _isSearchingUsers = false;
  int _searchToken = 0;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() {
      final text = _nameController.text.trim();
      if (text.isNotEmpty != _isCreateEnabled) {
        setState(() => _isCreateEnabled = text.isNotEmpty);
      }
    });
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

  void _onSearchChanged(String value) {
    final keyword = value.trim();
    if (keyword.isEmpty) {
      _searchToken++;
      setState(() {
        _isSearchingUsers = false;
        _searchResults = const [];
      });
      return;
    }

    setState(() => _isSearchingUsers = true);

    _searchDebouncer.run(() async {
      final currentToken = ++_searchToken;
      final currentKeyword = keyword;

      try {
        final users = await widget.onSearchUsers(currentKeyword);
        if (!mounted || currentToken != _searchToken) {
          return;
        }

        if (_searchController.text.trim() != currentKeyword) {
          return;
        }

        setState(() {
          _searchResults = users;
          _isSearchingUsers = false;
        });
      } catch (_) {
        if (!mounted || currentToken != _searchToken) {
          return;
        }
        setState(() {
          _searchResults = const [];
          _isSearchingUsers = false;
        });
      }
    });
  }

  // --- LOGIC CHUYỂN BƯỚC ---
  Future<void> _handleCreateTeam() async {
    setState(() => _currentStep = CreateStep.loading);

    // Giả lập gọi API tạo team mất 1.5 giây
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    setState(() => _currentStep = CreateStep.success);

    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // Chuyển sang bước Add Members
    setState(() => _currentStep = CreateStep.addMembers);
  }

  void _finishAndClose() {
    // Trả về dữ liệu cuối cùng khi hoàn thành hoặc skip
    Navigator.of(context).pop({
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'members': _selectedUsers,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 4,
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        // Điều chỉnh chiều cao tùy theo bước để UI mượt hơn
        height: _currentStep == CreateStep.loading ? 400 : 480,
        width: 580,
        padding: const EdgeInsets.all(28.0),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          // Render UI dựa trên trạng thái
          child: _buildCurrentStepWidget(),
        ),
      ),
    );
  }

  Widget _buildCurrentStepWidget() {
    switch (_currentStep) {
      case CreateStep.details:
        return _buildStep1Details();
      case CreateStep.loading:
        return _buildStep2Loading();
      case CreateStep.success:
        return _buildStep3Success();
      case CreateStep.addMembers:
        return _buildStep4AddMembers();
    }
  }

  // ==========================================
  // BƯỚC 1: NHẬP THÔNG TIN (UI cũ)
  // ==========================================
  Widget _buildStep1Details() {
    return Column(
      key: const ValueKey('step1'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Some quick details about your private team',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              splashRadius: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Text(
          'Team name',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
        ),
        TextField(
          controller: _nameController,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w400),
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Give your team a name',
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
        ),
        const SizedBox(height: 24),
        Text(
          'Description',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _descriptionController,
          maxLines: 4,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Let people know what this team is all about',
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
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.chevron_left, size: 18),
              label: const Text('Back'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
              ),
            ),
            FilledButton(
              onPressed: _isCreateEnabled ? _handleCreateTeam : null,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
              child: const Text('Create'),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // BƯỚC 2: MÀN HÌNH LOADING TRUNG GIAN
  // ==========================================
  Widget _buildStep2Loading() {
    return Center(
      key: const ValueKey('step2'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Creating the team...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3Success() {
    return Center(
      key: const ValueKey('step3'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 180,
            height: 180,
            child: Lottie.asset(
              'assets/animations/Success.json',
              repeat: false,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Team created successfully!',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // BƯỚC 4: THÊM THÀNH VIÊN
  // ==========================================
  Widget _buildStep4AddMembers() {
    final teamName = _nameController.text.trim();

    return Column(
      key: const ValueKey('step4'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add members to $teamName',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Start typing a name, distribution list, or security group to add to your team. You can also add people outside your organization as guests by typing their email addresses.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade700,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),

        // Autocomplete Custom Field
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: RawAutocomplete<User>(
                focusNode: _searchFocusNode,
                textEditingController: _searchController,
                displayStringForOption: (user) => user.fullName,
                optionsBuilder: (TextEditingValue textEditingValue) {
                  final query = textEditingValue.text.trim();
                  if (query.isEmpty) {
                    return const Iterable<User>.empty();
                  }
                  return _searchResults.where((user) {
                    final notSelected = !_selectedUsers.any(
                      (u) => u.id == user.id,
                    );
                    return notSelected;
                  });
                },
                onSelected: (User selection) {
                  setState(() {
                    _selectedUsers.add(selection);
                  });
                  _searchController.clear();
                  _searchToken++;
                  setState(() {
                    _searchResults = const [];
                  });
                  _searchFocusNode.requestFocus();
                },
                fieldViewBuilder:
                    (
                      context,
                      textEditingController,
                      focusNode,
                      onFieldSubmitted,
                    ) {
                      return Container(
                        padding: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: focusNode.hasFocus
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey.shade400,
                              width: focusNode.hasFocus ? 2 : 1,
                            ),
                          ),
                        ),
                        child: Wrap(
                          spacing: 8.0,
                          runSpacing: 4.0,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            // Hiển thị các Chip cho user đã chọn
                            ..._selectedUsers.map(
                              (user) => Chip(
                                label: Text(
                                  user.fullName,
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
                                onDeleted: () {
                                  setState(
                                    () => _selectedUsers.removeWhere(
                                      (u) => u.id == user.id,
                                    ),
                                  );
                                },
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: Colors.grey.shade300),
                                ),
                              ),
                            ),
                            // Ô nhập liệu
                            SizedBox(
                              width: 200, // Chiều rộng tối thiểu cho ô nhập
                              child: TextField(
                                controller: textEditingController,
                                focusNode: focusNode,
                                onChanged: _onSearchChanged,
                                decoration: const InputDecoration(
                                  hintText: 'Start typing a name or group',
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                ),
                                onSubmitted: (String value) =>
                                    onFieldSubmitted(),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                // Build giao diện dropdown (Overlay)
                optionsViewBuilder: (context, onSelected, options) {
                  if (_isSearchingUsers) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
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

                  if (options.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Container(
                        width: 350,
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (BuildContext context, int index) {
                            final User option = options.elementAt(index);
                            return InkWell(
                              onTap: () => onSelected(option),
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
                                          option.fullName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          option.email,
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
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            ListenableBuilder(
              listenable: _searchController,
              builder: (context, child) {
                final canAdd = _selectedUsers.isNotEmpty;
                return FilledButton(
                  onPressed: canAdd ? _finishAndClose : null,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                  child: const Text('Add'),
                );
              },
            ),
          ],
        ),

        const Spacer(),
        // Footer: Skip button
        Align(
          alignment: Alignment.bottomRight,
          child: OutlinedButton(
            onPressed: _finishAndClose,
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: Text('Skip', style: TextStyle(color: Colors.grey.shade800)),
          ),
        ),
      ],
    );
  }
}
