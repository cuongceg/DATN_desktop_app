import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

class MeetingRoomProvider extends ChangeNotifier {
  Room? room;
  bool isMicOn = true;
  bool isCamOn = true;
  bool isChatOpen = false;
  bool isParticipantsOpen = false;
  List<Participant> participants = [];
  bool _isDisposed = false;
  bool _isDisconnecting = false; // ← THÊM: guard tránh disconnect 2 lần

  Future<void> connect(String url, String token) async {
    room = Room();
    room!.addListener(_onRoomUpdate);
    await room!.connect(url, token);
    await room!.localParticipant?.setCameraEnabled(true);
    await room!.localParticipant?.setMicrophoneEnabled(true);
    _syncParticipants();
    notifyListeners();
  }

  void _onRoomUpdate() {
    if (_isDisconnecting) return; // ← THÊM: bỏ qua update khi đang disconnect
    _syncParticipants();
    notifyListeners();
  }

  void _syncParticipants() {
    participants = [
      if (room?.localParticipant != null) room!.localParticipant!,
      ...room?.remoteParticipants.values ?? [],
    ];
  }

  Future<void> toggleMic() async {
    isMicOn = !isMicOn;
    await room?.localParticipant?.setMicrophoneEnabled(isMicOn);
    notifyListeners();
  }

  Future<void> toggleCam() async {
    isCamOn = !isCamOn;
    await room?.localParticipant?.setCameraEnabled(isCamOn);
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

  Future<void> disconnect() async {
    if (room == null || _isDisconnecting) return; // ← guard
    _isDisconnecting = true;

    final activeRoom = room;

    // ← THAY ĐỔI: removeListener TRƯỚC khi null room
    // để _onRoomUpdate không fire trong lúc đang đóng
    activeRoom?.removeListener(_onRoomUpdate);
    room = null;
    participants = [];

    try {
      // ← THÊM: tắt cam + mic trước khi disconnect
      // giúp LiveKit đóng media track gọn gàng trước khi đóng PeerConnection
      await activeRoom?.localParticipant?.setCameraEnabled(false);
      await activeRoom?.localParticipant?.setMicrophoneEnabled(false);
      await activeRoom?.disconnect();
    } catch (_) {
      // Bỏ qua lỗi platform stream đã bị huỷ
    } finally {
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
    // ← THAY ĐỔI: dùng unawaited pattern thay vì bỏ trống
    // ignore: discarded_futures
    disconnect();
    super.dispose();
  }
}
