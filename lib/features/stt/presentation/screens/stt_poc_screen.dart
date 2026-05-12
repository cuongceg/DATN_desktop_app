import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/glass_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../services/stt_service.dart';

enum _SttState { loading, idle, recording, stopped }

class SttPocScreen extends StatefulWidget {
  const SttPocScreen({super.key});

  @override
  State<SttPocScreen> createState() => _SttPocScreenState();
}

class _SttPocScreenState extends State<SttPocScreen> {
  late final SttService _service;
  final List<String> _lines = [];
  final ScrollController _scroll = ScrollController();
  StreamSubscription<String>? _sub;
  StreamSubscription<bool>? _vadSub;

  _SttState _state = _SttState.idle;

  // Sub-states while recording (driven by VAD events)
  bool _isSpeaking = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _service = context.read<SttService>();
    if (!_service.isInitialized) {
      // Initialization failed before the app started
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _service.initError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi tải model: ${_service.initError}')),
          );
        }
      });
    }
  }

  Future<void> _start() async {
    if (!_service.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải model: ${_service.initError ?? "không xác định"}')),
      );
      return;
    }
    _sub = _service.transcriptStream.listen(_onText);
    _vadSub = _service.vadStateStream.listen(_onVadState);
    await _service.start();
    if (mounted) setState(() => _state = _SttState.recording);
  }

  Future<void> _stop() async {
    await _service.stop();
    await _sub?.cancel();
    await _vadSub?.cancel();
    _sub = null;
    _vadSub = null;
    if (mounted) {
      setState(() {
        _state = _SttState.stopped;
        _isSpeaking = false;
        _isProcessing = false;
      });
    }
  }

  void _onVadState(bool speaking) {
    if (!mounted) return;
    setState(() {
      // Transition from speaking→silence means we're now processing
      if (!speaking && _isSpeaking) _isProcessing = true;
      if (speaking) _isProcessing = false;
      _isSpeaking = speaking;
    });
  }

  void _onText(String text) {
    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _lines.add(text);
      if (_lines.length > 100) _lines.removeAt(0);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearTranscript() => setState(() => _lines.clear());

  @override
  void dispose() {
    _sub?.cancel();
    _vadSub?.cancel();
    _service.stop(); // stop recording; service lifetime owned by main.dart
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? GlassTheme.darkText : GlassTheme.lightText;
    final subColor = isDark ? GlassTheme.darkSubText : GlassTheme.lightSubText;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Speech-to-Text PoC',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Model: vi-30M-int8',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: subColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Transcript area
            Expanded(
              child: GlassCard(
                padding: const EdgeInsets.all(0),
                child: Column(
                  children: [
                    // Header row with clear button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                      child: Row(
                        children: [
                          Text(
                            'Văn bản nhận dạng',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(color: subColor),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            tooltip: 'Xóa',
                            onPressed:
                                _lines.isEmpty ? null : _clearTranscript,
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: _lines.isEmpty
                          ? Center(
                              child: Text(
                                'Chưa có văn bản nào...',
                                style: TextStyle(color: subColor),
                              ),
                            )
                          : ListView.builder(
                              controller: _scroll,
                              padding: const EdgeInsets.all(16),
                              itemCount: _lines.length,
                              itemBuilder: (_, i) => Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 6),
                                child: Text(
                                  _lines[i],
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Status chip
            Center(
              child: _StatusChip(
                state: _state,
                isSpeaking: _isSpeaking,
                isProcessing: _isProcessing,
              ),
            ),

            const SizedBox(height: 16),

            // Action buttons
            Center(child: _ActionButtons(state: _state, onStart: _start, onStop: _stop, onRestart: _start)),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.state,
    this.isSpeaking = false,
    this.isProcessing = false,
  });

  final _SttState state;
  final bool isSpeaking;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (state) {
      _SttState.loading   => ('Đang tải model...', Colors.orange),
      _SttState.idle      => ('Sẵn sàng nhận dạng', Colors.green),
      _SttState.recording => isSpeaking
          ? ('Đang ghi âm...', Colors.red)
          : isProcessing
              ? ('Đang xử lý...', AppColors.secondary)
              : ('Đang lắng nghe...', AppColors.primary),
      _SttState.stopped   => ('Đã dừng', Colors.grey),
    };

    final showSpinner = state == _SttState.loading ||
        (state == _SttState.recording && (isSpeaking || isProcessing));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showSpinner)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.state,
    required this.onStart,
    required this.onStop,
    required this.onRestart,
  });

  final _SttState state;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      _SttState.loading => const SizedBox.shrink(),
      _SttState.idle => _PrimaryButton(
          icon: Icons.mic,
          label: 'Bắt đầu',
          color: AppColors.primary,
          onPressed: onStart,
        ),
      _SttState.recording => _PrimaryButton(
          icon: Icons.stop,
          label: 'Dừng lại',
          color: Colors.red,
          onPressed: onStop,
        ),
      _SttState.stopped => _PrimaryButton(
          icon: Icons.refresh,
          label: 'Nhận dạng lại',
          color: AppColors.primary,
          onPressed: onRestart,
        ),
    };
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon),
      label: Text(label, style: const TextStyle(fontSize: 16)),
      onPressed: onPressed,
    );
  }
}
