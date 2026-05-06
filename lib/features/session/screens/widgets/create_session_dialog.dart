import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../classroom/domain/entities/classroom_entity.dart';
import '../../../classroom/presentation/controllers/classroom_notifier.dart';
import '../../models/session_model.dart';
import '../../providers/session_provider.dart';

/// Dialog glassmorphism cho phép Teacher tạo hoặc chỉnh sửa một session.
///
/// - **Create mode**: [session] == null — hiển thị dropdown chọn lớp.
/// - **Edit mode**: [session] != null — ẩn dropdown, pre-fill các field.
/// - Nút Delete chỉ hiển thị khi Edit mode và [SessionModel.isEditable].
class CreateSessionDialog extends StatefulWidget {
  /// Truyền [session] để vào Edit mode; null để vào Create mode.
  /// [prefilledDate] pre-fill thời gian khi tap vào calendar cell.
  const CreateSessionDialog({super.key, this.session, this.prefilledDate});

  final SessionModel? session;
  final DateTime? prefilledDate;

  @override
  State<CreateSessionDialog> createState() => _CreateSessionDialogState();
}

class _CreateSessionDialogState extends State<CreateSessionDialog> {
  final TextEditingController _titleController = TextEditingController();
  ClassroomEntity? _selectedClass;
  DateTime? _scheduledAt;
  DateTime? _scheduledEndAt;
  bool _isSaving = false;

  bool get _isEditMode => widget.session != null;

  /// `true` khi cả hai picker đều có giá trị nhưng end <= start.
  bool get _endTimeIsInvalid =>
      _scheduledAt != null &&
      _scheduledEndAt != null &&
      !_scheduledEndAt!.isAfter(_scheduledAt!);

  bool get _canSave =>
      _titleController.text.trim().isNotEmpty &&
      (_isEditMode || _selectedClass != null) &&
      !_endTimeIsInvalid;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _titleController.text = widget.session!.title;
      _scheduledAt = widget.session!.scheduledAt;
      _scheduledEndAt = widget.session!.scheduledEndAt;
    } else {
      _scheduledAt = widget.prefilledDate;
      if (_scheduledAt != null) {
        _scheduledEndAt = _scheduledAt!.add(const Duration(hours: 1));
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  // ── Pickers ───────────────────────────────────────────────────────────────

  Future<void> _pickStartDateTime() async {
    final DateTime initial = _scheduledAt ?? DateTime.now();
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date == null || !mounted) return;

    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;

    setState(() {
      _scheduledAt = DateTime(
        date.year, date.month, date.day, time.hour, time.minute,
      );
      // Auto-fill end time if unset or no longer after new start.
      if (_scheduledEndAt == null ||
          !_scheduledEndAt!.isAfter(_scheduledAt!)) {
        _scheduledEndAt = _scheduledAt!.add(const Duration(hours: 1));
      }
    });
  }

  Future<void> _pickEndDateTime() async {
    final DateTime initial =
        _scheduledEndAt ?? _scheduledAt!.add(const Duration(hours: 1));
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date == null || !mounted) return;

    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;

    setState(() {
      _scheduledEndAt = DateTime(
        date.year, date.month, date.day, time.hour, time.minute,
      );
    });
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _isSaving = true);

    final SessionProvider provider = context.read<SessionProvider>();
    bool success;

    if (_isEditMode) {
      success = await provider.updateSession(
        sessionId: widget.session!.id,
        title: _titleController.text.trim(),
        scheduledAt: _scheduledAt?.toUtc(),
        scheduledEndAt: _scheduledEndAt?.toUtc(),
      );
    } else {
      final SessionModel? created = await provider.createSession(
        _selectedClass!.id,
        _titleController.text.trim(),
        scheduledAt: _scheduledAt?.toUtc(),
        scheduledEndAt: _scheduledEndAt?.toUtc(),
      );
      success = created != null;
    }

    if (!mounted) return;
    setState(() => _isSaving = false);
    if (success) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    setState(() => _isSaving = true);
    final bool ok = await context
        .read<SessionProvider>()
        .deleteSession(widget.session!.id);
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (ok) Navigator.of(context).pop();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final List<ClassroomEntity> classrooms =
        context.watch<ClassroomNotifier>().classrooms;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 480,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.2)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(scheme),
                  const SizedBox(height: 20),
                  if (!_isEditMode) ...[
                    _buildClassDropdown(scheme, classrooms),
                    const SizedBox(height: 16),
                  ],
                  _buildTitleField(scheme),
                  const SizedBox(height: 16),
                  _buildStartTimePicker(scheme),
                  if (_scheduledAt != null) ...[
                    const SizedBox(height: 12),
                    _buildEndTimePicker(scheme),
                  ],
                  const SizedBox(height: 24),
                  _buildActions(scheme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme scheme) {
    return Text(
      _isEditMode ? 'Chỉnh sửa buổi học' : 'Tạo buổi học mới',
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
    );
  }

  Widget _buildClassDropdown(
    ColorScheme scheme,
    List<ClassroomEntity> classrooms,
  ) {
    return Semantics(
      label: 'Chọn lớp học',
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Lớp học',
          filled: true,
          fillColor: scheme.surface.withValues(alpha: 0.5),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
        ),
        child: DropdownButton<ClassroomEntity>(
          value: _selectedClass,
          hint: const Text('Chọn lớp'),
          isExpanded: true,
          underline: const SizedBox.shrink(),
          items: classrooms
              .map(
                (ClassroomEntity c) => DropdownMenuItem<ClassroomEntity>(
                  value: c,
                  child: Text(c.name),
                ),
              )
              .toList(),
          onChanged: (ClassroomEntity? c) =>
              setState(() => _selectedClass = c),
        ),
      ),
    );
  }

  Widget _buildTitleField(ColorScheme scheme) {
    return Semantics(
      label: 'Tiêu đề buổi học',
      child: TextFormField(
        controller: _titleController,
        style: const TextStyle(fontSize: 16),
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: 'Tiêu đề',
          filled: true,
          fillColor: scheme.surface.withValues(alpha: 0.5),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _buildStartTimePicker(ColorScheme scheme) {
    return Semantics(
      label: 'Chọn thời gian bắt đầu',
      button: true,
      child: InkWell(
        onTap: _pickStartDateTime,
        borderRadius: BorderRadius.circular(10),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Thời gian bắt đầu (tuỳ chọn)',
            filled: true,
            fillColor: scheme.surface.withValues(alpha: 0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            suffixIcon: _scheduledAt != null
                ? Semantics(
                    label: 'Xoá thời gian bắt đầu',
                    child: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() {
                        _scheduledAt = null;
                        _scheduledEndAt = null;
                      }),
                    ),
                  )
                : const Icon(Icons.schedule_outlined),
          ),
          child: Text(
            _scheduledAt != null
                ? _formatDateTime(_scheduledAt!)
                : 'Chưa đặt lịch',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 16,
                  color: _scheduledAt != null
                      ? scheme.onSurface
                      : scheme.onSurfaceVariant,
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildEndTimePicker(ColorScheme scheme) {
    return Semantics(
      label: 'Chọn thời gian kết thúc',
      button: true,
      child: InkWell(
        onTap: _pickEndDateTime,
        borderRadius: BorderRadius.circular(10),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Thời gian kết thúc (tuỳ chọn)',
            filled: true,
            fillColor: scheme.surface.withValues(alpha: 0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            errorText: _endTimeIsInvalid
                ? 'Giờ kết thúc phải sau giờ bắt đầu'
                : null,
            suffixIcon: _scheduledEndAt != null
                ? Semantics(
                    label: 'Xoá thời gian kết thúc',
                    child: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () =>
                          setState(() => _scheduledEndAt = null),
                    ),
                  )
                : const Icon(Icons.schedule_outlined),
          ),
          child: Text(
            _scheduledEndAt != null
                ? _formatDateTime(_scheduledEndAt!)
                : 'Chưa đặt',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 16,
                  color: _scheduledEndAt != null
                      ? (_endTimeIsInvalid
                          ? scheme.error
                          : scheme.onSurface)
                      : scheme.onSurfaceVariant,
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildActions(ColorScheme scheme) {
    return Row(
      children: [
        if (_isEditMode && widget.session!.isEditable)
          Semantics(
            label: 'Xoá buổi học này',
            child: TextButton.icon(
              onPressed: _isSaving ? null : _delete,
              icon: Icon(Icons.delete_outline, color: scheme.error),
              label: Text('Xoá', style: TextStyle(color: scheme.error)),
            ),
          ),
        const Spacer(),
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Huỷ'),
        ),
        const SizedBox(width: 8),
        Semantics(
          label: _isEditMode ? 'Lưu thay đổi buổi học' : 'Tạo buổi học mới',
          child: FilledButton(
            onPressed: (_isSaving || !_canSave) ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_isEditMode ? 'Lưu' : 'Tạo'),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    const List<String> weekdays = [
      'Thứ Hai', 'Thứ Ba', 'Thứ Tư',
      'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy', 'Chủ Nhật',
    ];
    final String h = dt.hour.toString().padLeft(2, '0');
    final String m = dt.minute.toString().padLeft(2, '0');
    return '${weekdays[dt.weekday - 1]}, ${dt.day}/${dt.month}/${dt.year} lúc $h:$m';
  }
}
