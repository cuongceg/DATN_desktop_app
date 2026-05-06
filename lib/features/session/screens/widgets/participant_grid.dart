import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'participant_tile.dart';

class ParticipantGrid extends StatefulWidget {
  final List<Participant> participants;

  const ParticipantGrid({super.key, required this.participants});

  @override
  State<ParticipantGrid> createState() => _ParticipantGridState();
}

class _ParticipantGridState extends State<ParticipantGrid> {
  Participant? pinnedParticipant;

  @override
  Widget build(BuildContext context) {
    if (widget.participants.isEmpty) {
      return const Center(child: Text('Đang đợi người tham gia...'));
    }

    // Nếu có người được ghim, hiển thị layout to nhỏ
    if (pinnedParticipant != null && widget.participants.contains(pinnedParticipant)) {
      final others = widget.participants.where((p) => p != pinnedParticipant).toList();
      return Row(
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ParticipantTile(
                participant: pinnedParticipant!,
                isPinned: true,
                onPin: () => setState(() => pinnedParticipant = null),
              ),
            ),
          ),
          if (others.isNotEmpty)
            Expanded(
              flex: 1,
              child: ListView.builder(
                itemCount: others.length,
                itemBuilder: (context, index) {
                  return AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ParticipantTile(
                        participant: others[index],
                        onPin: () => setState(() => pinnedParticipant = others[index]),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      );
    }

    // Tự động chia cột
    int crossAxisCount = 1;
    if (widget.participants.length == 2) crossAxisCount = 2;
    if (widget.participants.length >= 3) crossAxisCount = 3;

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 16 / 9,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: widget.participants.length,
      itemBuilder: (context, index) {
        final p = widget.participants[index];
        return ParticipantTile(
          participant: p,
          onPin: () => setState(() => pinnedParticipant = p),
        );
      },
    );
  }
}
