import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:provider/provider.dart';
import '../../models/session_participant_model.dart';
import '../../providers/meeting_room_provider.dart';
import 'participant_tile.dart';
import 'screen_share_tile.dart';

class ParticipantGrid extends StatefulWidget {
  final List<Participant> participants;
  final String? localParticipantSid;
  final bool isLocalCamStarting;
  final VideoTrack? screenShareTrack;
  final bool isLocalScreenShare;
  final String screenSharerName;
  final Future<void> Function()? onStopScreenShare;

  const ParticipantGrid({
    super.key,
    required this.participants,
    this.localParticipantSid,
    this.isLocalCamStarting = false,
    this.screenShareTrack,
    this.isLocalScreenShare = true,
    this.screenSharerName = '',
    this.onStopScreenShare,
  });

  @override
  State<ParticipantGrid> createState() => _ParticipantGridState();
}

class _ParticipantGridState extends State<ParticipantGrid> {
  Participant? pinnedParticipant;

  @override
  void didUpdateWidget(ParticipantGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Pinned participant left → clear their pin
    if (pinnedParticipant != null &&
        !widget.participants.contains(pinnedParticipant)) {
      pinnedParticipant = null;
    }
  }

  bool _isLocalCamStarting(Participant p) =>
      widget.isLocalCamStarting &&
      widget.localParticipantSid != null &&
      p.sid == widget.localParticipantSid;

  void _pinParticipant(Participant p) => setState(() {
        pinnedParticipant = p;
      });

  void _unpin() => setState(() {
        pinnedParticipant = null;
      });

  Widget _screenShareTile() => ScreenShareTile(
        track: widget.screenShareTrack!,
        onStop: widget.onStopScreenShare ?? () async {},
        isPinned: false,
        onPin: null,
        isLocal: widget.isLocalScreenShare,
        sharerName: widget.screenSharerName,
      );


  String _resolveName(Participant p, List<SessionParticipantModel> apiParts) {
    try {
      return apiParts.firstWhere((a) => a.userId == p.identity).fullName;
    } catch (_) {
      return p.name.isNotEmpty ? p.name : 'Unknown';
    }
  }

  Widget _participantTile(
    Participant p, {
    bool isPinned = false,
    List<SessionParticipantModel> apiParts = const [],
  }) =>
      ParticipantTile(
        participant: p,
        isPinned: isPinned,
        isLoading: _isLocalCamStarting(p),
        onPin: isPinned ? _unpin : () => _pinParticipant(p),
        displayName: _resolveName(p, apiParts),
      );

  Widget _buildParticipantGrid(
    List<Participant> participants, {
    required bool isSideBar,
    List<SessionParticipantModel> apiParts = const [],
  }) {
    final int totalItems = participants.length;
    int displayCount = totalItems;
    bool hasOverflow = false;

    if (totalItems > 16) {
      displayCount = 15;
      hasOverflow = true;
    }

    final int gridItemsCount = hasOverflow ? 16 : displayCount;

    int crossAxisCount = 1;
    if (isSideBar) {
      crossAxisCount = gridItemsCount > 4 ? 2 : 1;
    } else {
      if (gridItemsCount == 2) {
        crossAxisCount = 2;
      } else if (gridItemsCount == 3) {
        crossAxisCount = 3;
      } else if (gridItemsCount == 4) {
        crossAxisCount = 2;
      } else if (gridItemsCount >= 5 && gridItemsCount <= 9) {
        crossAxisCount = 3;
      } else if (gridItemsCount >= 10) {
        crossAxisCount = 4;
      }
    }

    final int rowCount = (gridItemsCount / crossAxisCount).ceil();

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        final tileHeight =
            ((constraints.maxHeight - 16 - spacing * (rowCount - 1)) / rowCount)
                .clamp(50.0, double.infinity);

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisExtent: tileHeight,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
          ),
          itemCount: gridItemsCount,
          itemBuilder: (_, i) {
            if (hasOverflow && i == 15) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  '+${totalItems - 15} người',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              );
            }
            return _participantTile(participants[i], apiParts: apiParts);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final apiParts =
        context.read<MeetingRoomProvider>().sessionParticipants;
    final hasScreenShare = widget.screenShareTrack != null;

    if (widget.participants.isEmpty && !hasScreenShare) {
      return const Center(child: Text('Đang đợi người tham gia...'));
    }

    // ── Screen share active ───────────────────────────────────────────────────
    if (hasScreenShare) {
      return Row(
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: _screenShareTile(),
            ),
          ),
          if (widget.participants.isNotEmpty)
            Expanded(
              flex: 1,
              child: _buildParticipantGrid(
                widget.participants,
                isSideBar: true,
                apiParts: apiParts,
              ),
            ),
        ],
      );
    }

    // ── Participant pinned ────────────────────────────────────────────────────
    if (pinnedParticipant != null &&
        widget.participants.contains(pinnedParticipant)) {
      final others =
          widget.participants.where((p) => p != pinnedParticipant).toList();

      return Row(
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: _participantTile(
                pinnedParticipant!,
                isPinned: true,
                apiParts: apiParts,
              ),
            ),
          ),
          if (others.isNotEmpty)
            Expanded(
              flex: 1,
              child: _buildParticipantGrid(
                others,
                isSideBar: true,
                apiParts: apiParts,
              ),
            ),
        ],
      );
    }

    // ── Auto grid (nothing pinned) ────────────────────────────────────────────
    return _buildParticipantGrid(
      widget.participants,
      isSideBar: false,
      apiParts: apiParts,
    );
  }
}
