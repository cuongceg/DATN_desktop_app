import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../auth/presentation/controllers/auth_notifier.dart';
import '../../models/session_model.dart';
import '../../providers/session_provider.dart';
import 'create_session_dialog.dart';

/// Popup nhỏ hiển thị chi tiết session khi tap vào event trên calendar.
///
/// - **Teacher**: nút Edit, Delete (chỉ khi `scheduled`), Start (chỉ khi `scheduled`).
/// - **Student**: read-only + nút Join chỉ active khi status `ongoing`.
/// - [onJoin] là callback để caller (calendar screen) tự xử lý navigation.
class SessionDetailPopup extends StatefulWidget {
  /// [session] là session cần hiển thị.
  /// [onJoin] được gọi khi student bấm "Tham gia" — caller tự handle navigation.
  /// [onStart] được gọi sau khi teacher start thành công — nhận [SessionModel]
  /// đã updated (có `livekitRoomId`, `startTime`) để caller navigate vào phòng.
  const SessionDetailPopup({
    super.key,
    required this.session,
    this.onJoin,
    this.onStart,
  });

  final SessionModel session;
  final VoidCallback? onJoin;
  final void Function(SessionModel startedSession)? onStart;

  @override
  State<SessionDetailPopup> createState() => _SessionDetailPopupState();
}

class _SessionDetailPopupState extends State<SessionDetailPopup> {
  bool _isProcessing = false;

  Future<void> _startSession() async {
    setState(() => _isProcessing = true);
    final SessionModel? started = await context
        .read<SessionProvider>()
        .startSession(widget.session.id);
    if (!mounted) return;
    Navigator.of(context).pop();
    if (started != null) widget.onStart?.call(started);
  }

  Future<void> _confirmAndDelete() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Xác nhận xoá'),
        content: Text(
          'Bạn có chắc muốn xoá buổi học "${widget.session.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isProcessing = true);
    final bool ok = await context
        .read<SessionProvider>()
        .deleteSession(widget.session.id);
    if (!mounted) return;
    setState(() => _isProcessing = false);
    if (ok) Navigator.of(context).pop();
  }

  void _openEditDialog() {
    Navigator.of(context).pop();
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (_) => CreateSessionDialog(session: widget.session),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isTeacher =
        context.read<AuthNotifier>().currentUser?.role == 'teacher';

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 380,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outline.withOpacity(0.2)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitleRow(scheme),
                  const SizedBox(height: 12),
                  if (widget.session.className != null)
                    _buildInfoRow(
                      scheme,
                      Icons.class_outlined,
                      widget.session.className!,
                    ),
                  if (widget.session.displayTime != null) ...[
                    const SizedBox(height: 6),
                    _buildInfoRow(
                      scheme,
                      Icons.schedule_outlined,
                      _formatDateTime(widget.session.displayTime!),
                    ),
                  ],
                  const SizedBox(height: 20),
                  _buildActions(scheme, isTeacher),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleRow(ColorScheme scheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            widget.session.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
          ),
        ),
        const SizedBox(width: 12),
        _StatusBadge(status: widget.session.status),
      ],
    );
  }

  Widget _buildInfoRow(ColorScheme scheme, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: scheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 16,
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions(ColorScheme scheme, bool isTeacher) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Đóng'),
        ),
        if (isTeacher) ...[
          if (widget.session.isEditable) ...[
            const SizedBox(width: 4),
            Semantics(
              label: 'Xoá buổi học',
              child: IconButton(
                icon: Icon(Icons.delete_outline, color: scheme.error),
                tooltip: 'Xoá buổi học',
                onPressed: _isProcessing ? null : _confirmAndDelete,
              ),
            ),
          ],
          const SizedBox(width: 4),
          Semantics(
            label: 'Chỉnh sửa buổi học',
            child: OutlinedButton.icon(
              onPressed: _isProcessing ? null : _openEditDialog,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Sửa'),
            ),
          ),
          if (widget.session.isEditable) ...[
            const SizedBox(width: 8),
            Semantics(
              label: 'Bắt đầu buổi học',
              child: FilledButton.icon(
                onPressed: _isProcessing ? null : _startSession,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow_rounded),
                label: const Text('Bắt đầu'),
              ),
            ),
          ],
        ],
        if (!isTeacher && widget.session.isOngoing) ...[
          const SizedBox(width: 8),
          Semantics(
            label: 'Tham gia buổi học',
            child: FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onJoin?.call();
              },
              icon: const Icon(Icons.login_rounded),
              label: const Text('Tham gia'),
            ),
          ),
        ],
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

/// Badge hiển thị trạng thái session với màu tương ứng.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final SessionStatus status;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final (String label, Color color) = switch (status) {
      SessionStatus.scheduled => ('Đã lên lịch', scheme.primary),
      SessionStatus.ongoing => ('Đang diễn ra', scheme.secondary),
      SessionStatus.completed => ('Đã kết thúc', scheme.outline),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
