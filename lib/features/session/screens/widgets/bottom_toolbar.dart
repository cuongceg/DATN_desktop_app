import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:livekit_client/livekit_client.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';
import '../../providers/meeting_room_provider.dart';
import '../../providers/session_provider.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/theme/glass_theme.dart';

class BottomToolbar extends StatelessWidget {
  /// ID của session đang diễn ra — cần để gọi API end session.
  final String sessionId;

  /// `true` nếu người dùng là giáo viên → hiện thêm tùy chọn "Kết thúc buổi học".
  final bool isTeacher;

  /// Whether STT subtitle broadcast is currently active (teacher only).
  final bool isSttOn;

  /// Callback to toggle STT on/off. Only provided for teacher; null for student.
  final VoidCallback? onToggleStt;

  const BottomToolbar({
    super.key,
    required this.sessionId,
    required this.isTeacher,
    this.isSttOn = false,
    this.onToggleStt,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<MeetingRoomProvider>(
      builder: (context, provider, _) => GlassCard(
        borderRadius: GlassTheme.panelRadius,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isTeacher) ...[
              _ToolbarButton(
                icon: isSttOn ? Icons.mic : Icons.mic_off,
                label: isSttOn ? 'Tắt micro' : 'Bật micro ',
                onTap: onToggleStt ?? () {},
                isActive: isSttOn,
                activeColor: Colors.red,
              ),
              const SizedBox(width: 16),
            ],
            _ToolbarButton(
              icon: provider.isCamOn ? Icons.videocam : Icons.videocam_off,
              label: provider.isCamOn ? 'Tắt Cam' : 'Bật Cam',
              onTap: provider.toggleCam,
              isActive: provider.isCamOn,
              inactiveColor: Colors.red,
            ),
            const SizedBox(width: 16),
            _ToolbarButton(
              icon: provider.isScreenShareOn
                  ? Icons.stop_screen_share
                  : Icons.screen_share,
              label: provider.isScreenShareOn
                  ? 'Dừng chia sẻ'
                  : 'Chia sẻ màn hình',
              onTap: provider.isScreenShareOn
                  ? () => _disableScreenShare(context, provider)
                  : () => _handleScreenShare(context, provider),
              isActive: provider.isScreenShareOn,
              activeColor: GlassTheme.accent,
            ),
            const SizedBox(width: 16),
            _ToolbarButton(
              icon: Icons.chat_bubble_outline,
              label: 'Chat',
              onTap: provider.toggleChat,
              isActive: provider.isChatOpen,
              activeColor: GlassTheme.accent,
            ),
            const SizedBox(width: 16),
            _ToolbarButton(
              icon: Icons.people_outline,
              label: 'Người tham gia',
              onTap: provider.toggleParticipants,
              isActive: provider.isParticipantsOpen,
              activeColor: GlassTheme.accent,
            ),
            const SizedBox(width: 24),
            // Nút End Call — phân biệt teacher / student
            if (isTeacher)
              _TeacherEndCallButton(sessionId: sessionId, provider: provider)
            else
              _StudentLeaveButton(provider: provider),
          ],
        ),
      ),
    );
  }
}

Future<void> _handleScreenShare(
  BuildContext context,
  MeetingRoomProvider provider,
) async {
  if (provider.room?.localParticipant == null) return;

  // ── Wayland-only guard (Linux only) ────────────────────────────────────────
  if (!kIsWeb && Platform.isLinux) {
    final waylandDisplay = Platform.environment['WAYLAND_DISPLAY'];
    final x11Display = Platform.environment['DISPLAY'];
    if (waylandDisplay != null && x11Display == null) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Cảnh báo Wayland'),
          content: const Text(
            'Bạn đang chạy trên Wayland thuần túy (không có X11).\n'
            'Chia sẻ màn hình có thể không hoạt động hoặc '
            'hiển thị màn hình trống.\n\n'
            'Bạn có muốn thử không?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Huỷ'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Thử'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }
  }

  // ── Source picker + capture ─────────────────────────────────────────────────
  try {
    if (lkPlatformIsDesktop()) {
      final source = await showDialog<DesktopCapturerSource>(
        context: context,
        builder: (ctx) => ScreenSelectDialog(),
      );
      if (source == null) return;
      final track = await LocalVideoTrack.createScreenShareTrack(
        ScreenShareCaptureOptions(sourceId: source.id, maxFrameRate: 15.0),
      );
      await provider.room!.localParticipant!.publishVideoTrack(track);
      provider.startScreenShare(track);
    } else {
      await provider.room!.localParticipant!.setScreenShareEnabled(
        true,
        captureScreenAudio: true,
      );
    }
  } on PlatformException catch (e) {
    debugPrint('Screen share PlatformException: ${e.code} — ${e.message}');
    if (context.mounted) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Lỗi chia sẻ màn hình'),
          content: Text(
            'Không thể chia sẻ màn hình.\n'
            'Lỗi: ${e.message ?? e.code}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  } catch (e) {
    debugPrint('Screen share error: $e');
  }
}

Future<void> _disableScreenShare(
  BuildContext context,
  MeetingRoomProvider provider,
) async {
  try {
    await provider.room?.localParticipant?.setScreenShareEnabled(false);
  } catch (e) {
    debugPrint('Disable screen share error: $e');
  }
  await provider.stopScreenShare();
}

// ─── Teacher: 2 lựa chọn qua dialog ────────────────────────────────────────

class _TeacherEndCallButton extends StatelessWidget {
  final String sessionId;
  final MeetingRoomProvider provider;

  const _TeacherEndCallButton({
    required this.sessionId,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
      icon: const Icon(Icons.call_end, color: Colors.white),
      label: const Text('Kết thúc', style: TextStyle(color: Colors.white)),
      onPressed: () => _showTeacherDialog(context),
    );
  }

  void _showTeacherDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kết thúc buổi học'),
        content: const Text(
          'Bạn muốn rời phòng hay kết thúc hoàn toàn buổi học?\n\n'
          '• Rời phòng: Bạn thoát ra, buổi học vẫn đang diễn ra.\n'
          '• Kết thúc buổi học: Toàn bộ phòng bị đóng lại.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Huỷ'),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.exit_to_app),
            label: const Text('Rời phòng'),
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.disconnect();
              if (context.mounted) Navigator.pop(context);
            },
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            icon: const Icon(Icons.stop_circle_outlined, color: Colors.white),
            label: const Text(
              'Kết thúc buổi học',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _endSessionAndLeave(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _endSessionAndLeave(BuildContext context) async {
    try {
      // 1. Gọi PATCH /api/sessions/:id/end
      await context.read<SessionProvider>().endSession(sessionId);
    } catch (e) {
      // Vẫn tiếp tục disconnect dù API lỗi, tránh user bị kẹt
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cảnh báo: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }

    // 2. Disconnect khỏi LiveKit
    await provider.disconnect();

    // 3. Navigate về màn hình trước
    if (context.mounted) Navigator.pop(context);
  }
}

// ─── Student: chỉ Rời phòng ────────────────────────────────────────────────

class _StudentLeaveButton extends StatelessWidget {
  final MeetingRoomProvider provider;

  const _StudentLeaveButton({required this.provider});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
      icon: const Icon(Icons.call_end, color: Colors.white),
      label: const Text('Rời phòng', style: TextStyle(color: Colors.white)),
      onPressed: () => _confirmLeave(context),
    );
  }

  void _confirmLeave(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rời khỏi buổi học?'),
        content: const Text(
          'Bạn sẽ thoát khỏi phòng. Buổi học vẫn tiếp tục diễn ra.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.disconnect();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text(
              'Rời phòng',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared toolbar button ──────────────────────────────────────────────────

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;
  final Color? activeColor;
  final Color inactiveColor;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isActive,
    this.activeColor,
    this.inactiveColor = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    final Color color;
    if (isActive) {
      color =
          activeColor ??
          (Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black87);
    } else {
      color = inactiveColor;
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
