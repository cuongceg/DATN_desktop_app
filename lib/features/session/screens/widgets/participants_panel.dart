import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:provider/provider.dart';
import '../../models/session_participant_model.dart';
import '../../providers/meeting_room_provider.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/theme/glass_theme.dart';

class ParticipantsPanel extends StatelessWidget {
  const ParticipantsPanel({super.key});

  Participant? _findLive(String userId, List<Participant> live) {
    try {
      return live.firstWhere((p) => p.identity == userId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      width: 320,
      padding: EdgeInsets.zero,
      child: Consumer<MeetingRoomProvider>(
        builder: (context, provider, _) {
          final apiParts = provider.sessionParticipants;
          final liveParts = provider.participants;
          final useApi = apiParts.isNotEmpty;
          final count = useApi ? apiParts.length : liveParts.length;

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.white24)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.people_outline),
                    const SizedBox(width: 8),
                    Text(
                      'Người tham gia ($count)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      tooltip: 'Làm mới',
                      onPressed: () => provider.fetchSessionParticipants(),
                    ),
                  ],
                ),
              ),
              if (provider.isLoadingParticipants)
                const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: useApi
                    ? ListView.builder(
                        itemCount: apiParts.length,
                        itemBuilder: (context, i) {
                          final ap = apiParts[i];
                          final lp = _findLive(ap.userId, liveParts);
                          return _ApiTile(apiPart: ap, livePart: lp);
                        },
                      )
                    : ListView.builder(
                        itemCount: liveParts.length,
                        itemBuilder: (context, i) {
                          final p = liveParts[i];
                          return _LiveKitTile(participant: p);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ApiTile extends StatelessWidget {
  const _ApiTile({required this.apiPart, required this.livePart});

  final SessionParticipantModel apiPart;
  final Participant? livePart;

  @override
  Widget build(BuildContext context) {
    final isTeacher = apiPart.role == 'teacher';
    final initial =
        apiPart.fullName.isNotEmpty ? apiPart.fullName[0].toUpperCase() : '?';
    final isMicOn = livePart?.isMicrophoneEnabled() ?? false;
    final isCamOn = livePart?.isCameraEnabled() ?? false;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isTeacher ? GlassTheme.accent : Colors.grey.shade700,
        child: Text(initial, style: const TextStyle(color: Colors.white)),
      ),
      title: Text(
        apiPart.fullName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Row(
        children: [
          _RoleBadge(isTeacher: isTeacher),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            size: 10,
            color: apiPart.isOnline ? Colors.greenAccent : Colors.grey,
          ),
          const SizedBox(width: 6),
          if (livePart != null) ...[
            Icon(
              isMicOn ? Icons.mic : Icons.mic_off,
              size: 20,
              color: isMicOn ? Colors.white : Colors.red,
            ),
            const SizedBox(width: 4),
            Icon(
              isCamOn ? Icons.videocam : Icons.videocam_off,
              size: 20,
              color: isCamOn ? Colors.white : Colors.red,
            ),
          ],
        ],
      ),
    );
  }
}

class _LiveKitTile extends StatelessWidget {
  const _LiveKitTile({required this.participant});

  final Participant participant;

  @override
  Widget build(BuildContext context) {
    final isMicOn = participant.isMicrophoneEnabled();
    final isCamOn = participant.isCameraEnabled();
    final initial = participant.name.isNotEmpty ? participant.name[0] : '?';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: GlassTheme.accent,
        child: Text(initial),
      ),
      title: Text(participant.name),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMicOn ? Icons.mic : Icons.mic_off,
            size: 20,
            color: isMicOn ? Colors.white : Colors.red,
          ),
          const SizedBox(width: 8),
          Icon(
            isCamOn ? Icons.videocam : Icons.videocam_off,
            size: 20,
            color: isCamOn ? Colors.white : Colors.red,
          ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.isTeacher});

  final bool isTeacher;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isTeacher
            ? GlassTheme.accent.withValues(alpha: 0.2)
            : Colors.grey.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isTeacher ? GlassTheme.accent : Colors.grey,
          width: 0.5,
        ),
      ),
      child: Text(
        isTeacher ? 'Giáo viên' : 'Học sinh',
        style: TextStyle(
          fontSize: 11,
          color: isTeacher ? GlassTheme.accent : Colors.grey.shade400,
        ),
      ),
    );
  }
}
