import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import '../../../../core/theme/glass_theme.dart';
import '../../../../core/widgets/glass_card.dart';

class ParticipantTile extends StatelessWidget {
  final Participant participant;
  final VoidCallback? onPin;
  final bool isPinned;

  const ParticipantTile({
    super.key, 
    required this.participant,
    this.onPin,
    this.isPinned = false,
  });

  @override
  Widget build(BuildContext context) {
    final videoTrack = participant.videoTrackPublications
        .where((p) => p.kind == TrackType.VIDEO)
        .firstOrNull?.track as VideoTrack?;
    
    final isSpeaking = participant.isSpeaking;
    final isMicOn = participant.isMicrophoneEnabled();

    return GestureDetector(
      onTap: onPin,
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
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: GlassTheme.accent,
                    child: Text(
                      participant.name.isNotEmpty ? participant.name[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 32, color: Colors.white),
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
                        participant.name.isNotEmpty ? participant.name : 'Unknown',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              if (isPinned)
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
