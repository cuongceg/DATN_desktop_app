import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/meeting_room_provider.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/theme/glass_theme.dart';

class ParticipantsPanel extends StatelessWidget {
  const ParticipantsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      width: 320,
      padding: EdgeInsets.zero,
      child: Consumer<MeetingRoomProvider>(
        builder: (context, provider, _) {
          final parts = provider.participants;
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.white24)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.people_outline),
                    const SizedBox(width: 8),
                    Text('Người tham gia (${parts.length})', 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: parts.length,
                  itemBuilder: (context, index) {
                    final p = parts[index];
                    final isMicOn = p.isMicrophoneEnabled();
                    final isCamOn = p.isCameraEnabled();
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: GlassTheme.accent,
                        child: Text(p.name.isNotEmpty ? p.name[0] : '?'),
                      ),
                      title: Text(p.name),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(isMicOn ? Icons.mic : Icons.mic_off, size: 20, color: isMicOn ? Colors.white : Colors.red),
                          const SizedBox(width: 8),
                          Icon(isCamOn ? Icons.videocam : Icons.videocam_off, size: 20, color: isCamOn ? Colors.white : Colors.red),
                        ],
                      ),
                    );
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
