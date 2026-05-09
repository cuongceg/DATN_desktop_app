import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import '../../../../core/theme/glass_theme.dart';
import '../../../../core/widgets/glass_card.dart';

class ParticipantTile extends StatefulWidget {
  final Participant participant;
  final VoidCallback? onPin;
  final bool isPinned;
  final bool isLoading;

  const ParticipantTile({
    super.key,
    required this.participant,
    this.onPin,
    this.isPinned = false,
    this.isLoading = false,
  });

  @override
  State<ParticipantTile> createState() => _ParticipantTileState();
}

class _ParticipantTileState extends State<ParticipantTile> {
  @override
  void initState() {
    super.initState();
    widget.participant.addListener(_onParticipantChanged);
  }

  @override
  void didUpdateWidget(ParticipantTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.participant != widget.participant) {
      oldWidget.participant.removeListener(_onParticipantChanged);
      widget.participant.addListener(_onParticipantChanged);
    }
  }

  @override
  void dispose() {
    widget.participant.removeListener(_onParticipantChanged);
    super.dispose();
  }

  void _onParticipantChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final isCamEnabled = widget.participant.isCameraEnabled();
    final videoTrack = isCamEnabled
        ? widget.participant.videoTrackPublications
            .where((p) => p.kind == TrackType.VIDEO)
            .firstOrNull
            ?.track as VideoTrack?
        : null;

    final isSpeaking = widget.participant.isSpeaking;
    final isMicOn = widget.participant.isMicrophoneEnabled();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: widget.onPin,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(GlassTheme.cardRadius),
          border: Border.all(
            color: isSpeaking ? GlassTheme.accent : Colors.transparent,
            width: 3,
          ),
        ),
        child: GlassCard(
          padding: EdgeInsets.zero,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (videoTrack != null)
                VideoTrackRenderer(videoTrack)
              else
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1A1A2E)
                        : const Color(0xFFDDE3F5),
                    borderRadius: BorderRadius.circular(GlassTheme.cardRadius),
                  ),
                  child: Center(
                    child: widget.isLoading
                        ? const CircularProgressIndicator(
                            color: GlassTheme.accent,
                          )
                        : CircleAvatar(
                            radius: 40,
                            backgroundColor: GlassTheme.accent,
                            child: Text(
                              widget.participant.name.isNotEmpty
                                  ? widget.participant.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 32,
                                color: Colors.white,
                              ),
                            ),
                          ),
                  ),
                ),
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isMicOn ? Icons.mic : Icons.mic_off,
                        color: isMicOn ? Colors.white : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.participant.name.isNotEmpty
                            ? widget.participant.name
                            : 'Unknown',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              if (widget.isPinned)
                const Positioned(
                  top: 8,
                  right: 8,
                  child: Icon(Icons.push_pin, color: GlassTheme.accent),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
