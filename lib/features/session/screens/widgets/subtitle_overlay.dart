import 'package:flutter/material.dart';

/// Displays subtitle text as a semi-transparent pill at the bottom-center of
/// its parent Stack.
///
/// [subtitleText] is managed entirely by the parent — this widget only renders.
/// Opacity is driven by whether [subtitleText] is non-empty; the parent is
/// responsible for clearing it after the auto-clear timer fires.
///
/// NOTE: Subtitles are delivered via LiveKit DataChannel, NOT via video.
/// Teacher's overlay shows local STT output for self-monitoring.
/// Student's overlay shows text received from the teacher's DataChannel publish.
/// These are two independent overlays; screen-share video carries no subtitles.
class SubtitleOverlay extends StatelessWidget {
  final String? subtitleText;

  /// `true` → teacher (local STT output). `false` → student (DataChannel text).
  /// Currently unused for rendering differences but kept for future distinction.
  final bool isTeacher;

  const SubtitleOverlay({
    super.key,
    required this.subtitleText,
    required this.isTeacher,
  });

  @override
  Widget build(BuildContext context) {
    final hasText = subtitleText != null && subtitleText!.isNotEmpty;

    return AnimatedOpacity(
      opacity: hasText ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 400),
      child: IgnorePointer(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 680),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                subtitleText ?? '',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  height: 1.4,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
