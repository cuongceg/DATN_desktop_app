import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:provider/provider.dart';
import '../providers/meeting_room_provider.dart';
import '../providers/session_provider.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/theme/glass_theme.dart';
import '../../stt/services/stt_service.dart';
import 'widgets/participant_grid.dart';
import 'widgets/bottom_toolbar.dart';
import 'widgets/chat_panel.dart';
import 'widgets/participants_panel.dart';
import 'widgets/subtitle_overlay.dart';

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
  // ── Subtitle state ──────────────────────────────────────────────────────────
  String? _subtitleText;
  Timer? _subtitleTimer;
  StreamSubscription<String>? _sttSub;
  bool _isSttOn = false;

  // Student-side DataChannel listener — disposed with this screen.
  EventsListener<RoomEvent>? _dataListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<MeetingRoomProvider>();
      provider.onDisconnected = () {
        if (mounted) {
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      };
      final sessionService = context.read<SessionProvider>().service;
      provider.setSessionContext(widget.sessionId, sessionService);
      provider.fetchSessionParticipants();

      // Student: listen for subtitle text broadcast by teacher via DataChannel.
      // Subtitles are delivered via DataChannel, NOT via video — screen-share
      // video carries no subtitle content.
      if (!widget.isTeacher) {
        final room = provider.room;
        if (room != null) {
          _dataListener = room.createListener();
          _dataListener!.on<DataReceivedEvent>((event) {
            if (event.topic == 'subtitles') {
              _onSubtitleText(utf8.decode(event.data));
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _subtitleTimer?.cancel();
    _sttSub?.cancel();
    _dataListener?.dispose();
    if (_isSttOn) {
      context.read<SttService>().stop();
    }
    super.dispose();
  }

  // ── Shared: update subtitle text and (re)start the 5 s auto-clear timer ────

  void _onSubtitleText(String text) {
    if (!mounted) return;
    _subtitleTimer?.cancel();
    setState(() => _subtitleText = text);
    _subtitleTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _subtitleText = null);
    });
  }

  // ── Teacher: toggle STT on/off and broadcast to students ───────────────────

  Future<void> _toggleStt() async {
    final sttService = context.read<SttService>();
    final provider = context.read<MeetingRoomProvider>();

    if (_isSttOn) {
      await _sttSub?.cancel();
      _sttSub = null;
      await sttService.stop();
      _subtitleTimer?.cancel();
      setState(() {
        _isSttOn = false;
        _subtitleText = null;
      });
      provider.setSttState(false);
    } else {
      _sttSub = sttService.transcriptStream.listen((text) {
        // Show locally for self-monitoring and broadcast to students.
        _onSubtitleText(text);
        final data = Uint8List.fromList(utf8.encode(text));
        provider.room?.localParticipant?.publishData(
          data,
          topic: 'subtitles',
        );
      });
      await sttService.start();
      setState(() => _isSttOn = true);
      provider.setSttState(true);
    }
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
                        child: Stack(
                          children: [
                            Builder(builder: (context) {
                              final isLocalShare =
                                  provider.screenShareTrack != null;
                              final effectiveShare =
                                  provider.screenShareTrack ??
                                      provider.remoteScreenShareTrack;
                              return ParticipantGrid(
                                participants: provider.participants,
                                localParticipantSid:
                                    provider.room?.localParticipant?.sid,
                                isLocalCamStarting:
                                    provider.isCamBusy && provider.isCamOn,
                                screenShareTrack: effectiveShare,
                                isLocalScreenShare: isLocalShare,
                                screenSharerName: isLocalShare
                                    ? ''
                                    : provider.remoteScreenSharerName,
                                onStopScreenShare:
                                    isLocalShare ? _stopScreenShare : null,
                              );
                            }),
                            SubtitleOverlay(
                              subtitleText: _subtitleText,
                              isTeacher: widget.isTeacher,
                            ),
                          ],
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
                  isSttOn: _isSttOn,
                  onToggleStt: widget.isTeacher ? _toggleStt : null,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
