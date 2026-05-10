import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import '../models/session_participant_model.dart';
import '../services/session_service.dart';

class MeetingRoomProvider extends ChangeNotifier {
  Room? room;
  bool isMicOn = false;
  bool isCamOn = false;
  bool isCamBusy = false;
  bool isChatOpen = false;
  bool isParticipantsOpen = false;
  bool isScreenShareOn = false;
  LocalVideoTrack? screenShareTrack;
  List<Participant> participants = [];
  List<SessionParticipantModel> sessionParticipants = [];
  bool isLoadingParticipants = false;
  bool _isDisposed = false;
  bool _isDisconnecting = false;

  String? _sessionId;
  SessionService? _sessionService;

  EventsListener<RoomEvent>? _listener;

  /// Called when the room is disconnected (e.g. server kicked).
  void Function()? onDisconnected;

  Future<void> connect(
    String url,
    String token, {
    bool enableCamera = true,
    bool enableMic = true,
    LocalAudioTrack? audioTrack,
    LocalVideoTrack? videoTrack,
  }) async {
    room = Room(
      roomOptions: RoomOptions(
        adaptiveStream: true,
        dynacast: true,
        defaultCameraCaptureOptions: const CameraCaptureOptions(
          maxFrameRate: 30,
          params: VideoParameters(
            dimensions: VideoDimensions(1280, 720),
          ),
        ),
        defaultVideoPublishOptions: const VideoPublishOptions(
          simulcast: true,
        ),
      ),
    );

    _listener = room!.createListener();
    room!.addListener(_onRoomUpdate);
    _setupListeners();

    await room!.prepareConnection(url, token);

    if (audioTrack != null || videoTrack != null) {
      isCamOn = videoTrack != null;
      isMicOn = audioTrack != null;
      await room!.connect(
        url,
        token,
        fastConnectOptions: FastConnectOptions(
          microphone: TrackOption(track: audioTrack),
          camera: TrackOption(track: videoTrack),
        ),
      );
    } else {
      isCamOn = enableCamera;
      isMicOn = enableMic;
      await room!.connect(url, token);
      await room!.localParticipant?.setCameraEnabled(enableCamera);
      await room!.localParticipant?.setMicrophoneEnabled(enableMic);
    }

    _syncParticipants();
    notifyListeners();
  }

  void _setupListeners() {
    _listener!
      ..on<RoomDisconnectedEvent>((event) {
        debugPrint('[MeetingRoom] disconnected: ${event.reason}');
        onDisconnected?.call();
      })
      ..on<ParticipantConnectedEvent>((_) => fetchSessionParticipants())
      ..on<ParticipantDisconnectedEvent>((_) => fetchSessionParticipants());
  }

  void _onRoomUpdate() {
    if (_isDisconnecting) return;
    _syncParticipants();
    notifyListeners();
  }

  void _syncParticipants() {
    final remotes = room?.remoteParticipants.values.toList() ?? [];

    remotes.sort((a, b) {
      // Speaking first (louder first)
      if (a.isSpeaking != b.isSpeaking) {
        return b.isSpeaking ? 1 : -1;
      }
      if (a.isSpeaking && b.isSpeaking) {
        final aLevel = a.audioLevel;
        final bLevel = b.audioLevel;
        if (aLevel != bLevel) return bLevel.compareTo(aLevel);
      }
      // More recently spoke first
      final aSpoke = a.lastSpokeAt;
      final bSpoke = b.lastSpokeAt;
      if (aSpoke != null && bSpoke != null && aSpoke != bSpoke) {
        return bSpoke.compareTo(aSpoke);
      }
      if (aSpoke != null && bSpoke == null) return -1;
      if (aSpoke == null && bSpoke != null) return 1;
      // Has video first
      final aHasVideo = a.isCameraEnabled();
      final bHasVideo = b.isCameraEnabled();
      if (aHasVideo != bHasVideo) return bHasVideo ? 1 : -1;
      // Joined earlier first
      return a.joinedAt.compareTo(b.joinedAt);
    });

    participants = [
      if (room?.localParticipant != null) room!.localParticipant!,
      ...remotes,
    ];
  }

  Future<void> toggleMic() async {
    isMicOn = !isMicOn;
    notifyListeners();
    await room?.localParticipant?.setMicrophoneEnabled(isMicOn);
  }

  Future<void> toggleCam() async {
    if (isCamBusy) return;
    isCamBusy = true;
    isCamOn = !isCamOn;
    notifyListeners();
    await room?.localParticipant?.setCameraEnabled(isCamOn);
    isCamBusy = false;
    notifyListeners();
  }

  void toggleChat() {
    isChatOpen = !isChatOpen;
    if (isChatOpen) isParticipantsOpen = false;
    notifyListeners();
  }

  void toggleParticipants() {
    isParticipantsOpen = !isParticipantsOpen;
    if (isParticipantsOpen) isChatOpen = false;
    notifyListeners();
  }

  void setSessionContext(String sessionId, SessionService service) {
    _sessionId = sessionId;
    _sessionService = service;
  }

  Future<void> fetchSessionParticipants() async {
    if (_sessionId == null || _sessionService == null) return;
    isLoadingParticipants = true;
    notifyListeners();
    try {
      sessionParticipants = await _sessionService!.getParticipants(_sessionId!);
    } catch (e) {
      debugPrint('[MeetingRoom] fetchSessionParticipants error: $e');
    } finally {
      isLoadingParticipants = false;
      notifyListeners();
    }
  }

  void startScreenShare(LocalVideoTrack track) {
    screenShareTrack = track;
    isScreenShareOn = true;
    notifyListeners();
  }

  Future<void> stopScreenShare() async {
    isScreenShareOn = false;
    final t = screenShareTrack;
    screenShareTrack = null;
    notifyListeners();
    await t?.stop();
  }

  Future<void> disconnect() async {
    if (room == null || _isDisconnecting) return;
    _isDisconnecting = true;

    final sid = _sessionId;
    final svc = _sessionService;
    if (sid != null && svc != null) {
      svc.leaveSession(sid).catchError((e) {
        debugPrint('[MeetingRoom] leaveSession error (suppressed): $e');
      });
    }

    final activeRoom = room;
    final activeListener = _listener;

    activeRoom?.removeListener(_onRoomUpdate);
    room = null;
    _listener = null;
    participants = [];

    try {
      await activeListener?.dispose();
    } catch (_) {}

    try {
      await activeRoom?.disconnect();
    } catch (e) {
      debugPrint('[MeetingRoom] disconnect error (suppressed): $e');
    } finally {
      try {
        activeRoom?.dispose();
      } catch (_) {}
      _isDisconnecting = false;
      notifyListeners();
    }
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    disconnect();
    super.dispose();
  }
}
