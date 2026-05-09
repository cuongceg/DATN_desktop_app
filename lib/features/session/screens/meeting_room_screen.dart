import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/meeting_room_provider.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/theme/glass_theme.dart';
import 'widgets/participant_grid.dart';
import 'widgets/bottom_toolbar.dart';
import 'widgets/chat_panel.dart';
import 'widgets/participants_panel.dart';

class MeetingRoomScreen extends StatefulWidget {
  final String sessionId;
  final String sessionTitle;
  final bool isTeacher;

  const MeetingRoomScreen({
    super.key,
    required this.sessionId,
    this.sessionTitle = 'Phòng học trực tuyến',
    this.isTeacher = false,
  });

  @override
  State<MeetingRoomScreen> createState() => _MeetingRoomScreenState();
}

class _MeetingRoomScreenState extends State<MeetingRoomScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MeetingRoomProvider>().onDisconnected = () {
        if (mounted) {
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      };
    });
  }

  Future<void> _stopScreenShare() async {
    final p = context.read<MeetingRoomProvider>();
    try {
      await p.room?.localParticipant?.setScreenShareEnabled(false);
    } catch (e) {
      debugPrint('[MeetingRoom] stopScreenShare setScreenShareEnabled: $e');
    }
    await p.stopScreenShare();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? GlassTheme.darkBackground
          : GlassTheme.lightBackground,
      body: Consumer<MeetingRoomProvider>(
        builder: (context, provider, _) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                GlassCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.school, color: GlassTheme.accent),
                      const SizedBox(width: 8),
                      Text(
                        widget.sessionTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.circle, color: Colors.red, size: 12),
                            SizedBox(width: 4),
                            Text(
                              'REC',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '${provider.participants.length} người',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: ParticipantGrid(
                          participants: provider.participants,
                          localParticipantSid:
                              provider.room?.localParticipant?.sid,
                          isLocalCamStarting:
                              provider.isCamBusy && provider.isCamOn,
                          screenShareTrack: provider.screenShareTrack,
                          onStopScreenShare: _stopScreenShare,
                        ),
                      ),
                      if (provider.isChatOpen) ...[
                        const SizedBox(width: 16),
                        ChatPanel(sessionId: widget.sessionId),
                      ],
                      if (provider.isParticipantsOpen) ...[
                        const SizedBox(width: 16),
                        const ParticipantsPanel(),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                BottomToolbar(
                  sessionId: widget.sessionId,
                  isTeacher: widget.isTeacher,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
