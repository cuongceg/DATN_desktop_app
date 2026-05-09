import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../providers/meeting_room_provider.dart';
import 'meeting_room_screen.dart';

class JoinScreen extends StatefulWidget {
  final String sessionId;
  final String livekitUrl;
  final String token;
  final String sessionTitle;
  final bool isTeacher;

  const JoinScreen({
    super.key,
    required this.sessionId,
    required this.livekitUrl,
    required this.token,
    this.sessionTitle = 'Phòng học trực tuyến',
    this.isTeacher = false,
  });

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  List<MediaDevice> _audioInputs = [];
  List<MediaDevice> _videoInputs = [];
  StreamSubscription? _subscription;

  bool _busy = false;
  bool _enableVideo = true;
  bool _enableAudio = true;
  LocalAudioTrack? _audioTrack;
  LocalVideoTrack? _videoTrack;

  MediaDevice? _selectedVideoDevice;
  MediaDevice? _selectedAudioDevice;
  VideoParameters _selectedVideoParameters = VideoParametersPresets.h720_169;

  @override
  void initState() {
    super.initState();
    _initStateAsync();
  }

  Future<void> _initStateAsync() async {
    _subscription = Hardware.instance.onDeviceChange.stream.listen(_loadDevices);
    final devices = await Hardware.instance.enumerateDevices();
    await _loadDevices(devices);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _videoTrack?.stop();
    _audioTrack?.stop();
    super.dispose();
  }

  Future<void> _loadDevices(List<MediaDevice> devices) async {
    _audioInputs = devices.where((d) => d.kind == 'audioinput').toList();
    _videoInputs = devices.where((d) => d.kind == 'videoinput').toList();

    if (_selectedAudioDevice != null && !_audioInputs.contains(_selectedAudioDevice)) {
      _selectedAudioDevice = null;
    }
    if (_audioInputs.isEmpty) {
      await _audioTrack?.stop();
      _audioTrack = null;
    }
    if (_selectedVideoDevice != null && !_videoInputs.contains(_selectedVideoDevice)) {
      _selectedVideoDevice = null;
    }
    if (_videoInputs.isEmpty) {
      await _videoTrack?.stop();
      _videoTrack = null;
    }

    if (_enableAudio && _audioInputs.isNotEmpty) {
      if (_selectedAudioDevice == null) {
        _selectedAudioDevice = _audioInputs.first;
        Future.delayed(const Duration(milliseconds: 100), () async {
          if (!mounted) return;
          await _changeLocalAudioTrack();
          if (mounted) setState(() {});
        });
      }
    }

    if (_enableVideo && _videoInputs.isNotEmpty) {
      if (_selectedVideoDevice == null) {
        _selectedVideoDevice = _videoInputs.first;
        Future.delayed(const Duration(milliseconds: 100), () async {
          if (!mounted) return;
          await _changeLocalVideoTrack();
          if (mounted) setState(() {});
        });
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _setEnableVideo(bool value) async {
    _enableVideo = value;
    if (!_enableVideo) {
      await _videoTrack?.stop();
      _videoTrack = null;
      _selectedVideoDevice = null;
    } else {
      if (_selectedVideoDevice == null && _videoInputs.isNotEmpty) {
        _selectedVideoDevice = _videoInputs.first;
      }
      await _changeLocalVideoTrack();
    }
    if (mounted) setState(() {});
  }

  Future<void> _setEnableAudio(bool value) async {
    _enableAudio = value;
    if (!_enableAudio) {
      await _audioTrack?.stop();
      _audioTrack = null;
      _selectedAudioDevice = null;
    } else {
      if (_selectedAudioDevice == null && _audioInputs.isNotEmpty) {
        _selectedAudioDevice = _audioInputs.first;
      }
      await _changeLocalAudioTrack();
    }
    if (mounted) setState(() {});
  }

  Future<void> _changeLocalAudioTrack() async {
    if (!_enableAudio) return;
    if (_audioTrack != null) {
      await _audioTrack!.stop();
      _audioTrack = null;
    }
    if (_selectedAudioDevice != null) {
      _audioTrack = await LocalAudioTrack.create(
        AudioCaptureOptions(deviceId: _selectedAudioDevice!.deviceId),
      );
      await _audioTrack!.start();
    }
  }

  Future<void> _changeLocalVideoTrack() async {
    if (!_enableVideo) return;
    if (_videoTrack != null) {
      await _videoTrack!.stop();
      _videoTrack = null;
    }
    if (_selectedVideoDevice != null) {
      _videoTrack = await LocalVideoTrack.createCameraTrack(
        CameraCaptureOptions(
          deviceId: _selectedVideoDevice!.deviceId,
          params: _selectedVideoParameters,
        ),
      );
      await _videoTrack!.start();
    }
  }

  Future<void> _join(BuildContext context) async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      final provider = MeetingRoomProvider();
      await provider.connect(
        widget.livekitUrl,
        widget.token,
        audioTrack: _audioTrack,
        videoTrack: _videoTrack,
      );
      // Ownership transferred to provider/room
      _audioTrack = null;
      _videoTrack = null;

      if (!context.mounted) return;
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider<MeetingRoomProvider>.value(
            value: provider,
            child: MeetingRoomScreen(
              sessionId: widget.sessionId,
              sessionTitle: widget.sessionTitle,
              isTeacher: widget.isTeacher,
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint('JoinScreen: connect error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi kết nối: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _actionBack(BuildContext context) async {
    await _videoTrack?.stop();
    _videoTrack = null;
    await _audioTrack?.stop();
    _audioTrack = null;
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? GlassTheme.darkBackground : GlassTheme.lightBackground,
      appBar: AppBar(
        title: Text(
          'Chuẩn bị tham gia: ${widget.sessionTitle}',
          style: const TextStyle(fontSize: 16),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _actionBack(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Camera preview
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(GlassTheme.cardRadius),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(GlassTheme.cardRadius),
                          child: _videoTrack != null
                              ? VideoTrackRenderer(
                                  _videoTrack!,
                                  renderMode: VideoRenderMode.auto,
                                )
                              : Center(
                                  child: LayoutBuilder(
                                    builder: (ctx, constraints) => Icon(
                                      Icons.videocam_off,
                                      color: GlassTheme.accent,
                                      size: math.min(
                                            constraints.maxHeight,
                                            constraints.maxWidth,
                                          ) *
                                          0.3,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),

                  // Camera toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Camera:', style: TextStyle(fontWeight: FontWeight.w600)),
                      Switch(
                        value: _enableVideo,
                        onChanged: _setEnableVideo,
                        activeColor: GlassTheme.accent,
                      ),
                    ],
                  ),

                  // Camera device dropdown
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<MediaDevice>(
                        isExpanded: true,
                        hint: Text(
                          _enableVideo ? 'Chọn camera' : 'Camera tắt',
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                        items: _enableVideo
                            ? _videoInputs
                                .map(
                                  (d) => DropdownMenuItem<MediaDevice>(
                                    value: d,
                                    child: Text(
                                      d.label.isNotEmpty ? d.label : 'Camera ${_videoInputs.indexOf(d) + 1}',
                                      style: const TextStyle(fontSize: 14),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList()
                            : [],
                        value: _selectedVideoDevice,
                        onChanged: _enableVideo
                            ? (MediaDevice? value) async {
                                if (value != null) {
                                  _selectedVideoDevice = value;
                                  await _changeLocalVideoTrack();
                                  if (mounted) setState(() {});
                                }
                              }
                            : null,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 14,
                        ),
                        dropdownColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                      ),
                    ),
                  ),

                  // Video resolution dropdown (only when camera on)
                  if (_enableVideo)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<VideoParameters>(
                          isExpanded: true,
                          hint: const Text('Chọn độ phân giải'),
                          items: [
                            VideoParametersPresets.h480_43,
                            VideoParametersPresets.h540_169,
                            VideoParametersPresets.h720_169,
                            VideoParametersPresets.h1080_169,
                          ]
                              .map(
                                (p) => DropdownMenuItem<VideoParameters>(
                                  value: p,
                                  child: Text(
                                    '${p.dimensions.width}x${p.dimensions.height}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              )
                              .toList(),
                          value: _selectedVideoParameters,
                          onChanged: (VideoParameters? value) async {
                            if (value != null) {
                              _selectedVideoParameters = value;
                              await _changeLocalVideoTrack();
                              if (mounted) setState(() {});
                            }
                          },
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 14,
                          ),
                          dropdownColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                        ),
                      ),
                    ),

                  const SizedBox(height: 8),

                  // Mic toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Microphone:', style: TextStyle(fontWeight: FontWeight.w600)),
                      Switch(
                        value: _enableAudio,
                        onChanged: _setEnableAudio,
                        activeColor: GlassTheme.accent,
                      ),
                    ],
                  ),

                  // Mic device dropdown
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<MediaDevice>(
                        isExpanded: true,
                        hint: Text(
                          _enableAudio ? 'Chọn microphone' : 'Microphone tắt',
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                        items: _enableAudio
                            ? _audioInputs
                                .map(
                                  (d) => DropdownMenuItem<MediaDevice>(
                                    value: d,
                                    child: Text(
                                      d.label.isNotEmpty ? d.label : 'Microphone ${_audioInputs.indexOf(d) + 1}',
                                      style: const TextStyle(fontSize: 14),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList()
                            : [],
                        value: _selectedAudioDevice,
                        onChanged: _enableAudio
                            ? (MediaDevice? value) async {
                                if (value != null) {
                                  _selectedAudioDevice = value;
                                  await _changeLocalAudioTrack();
                                  if (mounted) setState(() {});
                                }
                              }
                            : null,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 14,
                        ),
                        dropdownColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                      ),
                    ),
                  ),

                  // Join button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GlassTheme.accent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _busy ? null : () => _join(context),
                    child: _busy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Tham gia',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
