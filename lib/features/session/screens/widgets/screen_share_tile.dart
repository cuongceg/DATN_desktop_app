import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:livekit_client/livekit_client.dart';
import '../../../../core/theme/glass_theme.dart';
import '../../../../core/widgets/glass_card.dart';

class ScreenShareTile extends StatefulWidget {
  final VideoTrack track;
  final Future<void> Function() onStop;
  final VoidCallback? onPin;
  final bool isPinned;
  final bool isLocal;
  final String sharerName;

  const ScreenShareTile({
    super.key,
    required this.track,
    required this.onStop,
    this.onPin,
    this.isPinned = false,
    this.isLocal = true,
    this.sharerName = '',
  });

  @override
  State<ScreenShareTile> createState() => _ScreenShareTileState();
}

class _ScreenShareTileState extends State<ScreenShareTile> {
  final RTCVideoRenderer _renderer = RTCVideoRenderer();
  bool _rendererReady = false;

  @override
  void initState() {
    super.initState();
    _initRenderer();
  }

  Future<void> _initRenderer() async {
    await _renderer.initialize();
    _renderer.srcObject = widget.track.mediaStream;
    if (mounted) setState(() => _rendererReady = true);
  }

  @override
  void dispose() {
    _renderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPin,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(GlassTheme.cardRadius),
          border: Border.all(
            color: widget.isPinned ? GlassTheme.accent : Colors.transparent,
            width: 3,
          ),
        ),
        child: GlassCard(
          padding: EdgeInsets.zero,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Video feed ────────────────────────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(GlassTheme.cardRadius),
                child: _rendererReady
                    ? RTCVideoView(
                        _renderer,
                        objectFit: RTCVideoViewObjectFit
                            .RTCVideoViewObjectFitContain,
                      )
                    : const ColoredBox(
                        color: Colors.black87,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: GlassTheme.accent,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
              ),

              // ── Label pill ────────────────────────────────────────────
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.screen_share, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        widget.isLocal
                            ? 'Màn hình của bạn'
                            : (widget.sharerName.isNotEmpty
                                ? 'Màn hình của ${widget.sharerName}'
                                : 'Màn hình'),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Stop button (only shown for local share) ──────────────
              if (widget.isLocal)
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => widget.onStop(),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.stop_screen_share,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),

              // ── Pin indicator ─────────────────────────────────────────
              if (widget.isPinned)
                const Positioned(
                  top: 8,
                  left: 8,
                  child: Icon(
                    Icons.push_pin,
                    color: GlassTheme.accent,
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
