import 'dart:async';

import 'package:flutter/material.dart';

import '../models/message_model.dart';
import '../services/session_service.dart';

class ChatProvider extends ChangeNotifier {
  final SessionService _service;
  final String _sessionId;
  final String currentUserId;

  List<MessageModel> messages = [];
  bool isLoading = false;
  bool isSending = false;
  String? errorMessage;

  Timer? _pollTimer;

  ChatProvider({
    required SessionService service,
    required String sessionId,
    required this.currentUserId,
  }) : _service = service,
       _sessionId = sessionId;

  Future<void> loadMessages({bool silent = false}) async {
    if (!silent) {
      isLoading = true;
      notifyListeners();
    }
    try {
      final fetched = await _service.fetchMessages(_sessionId);
      messages = fetched;
      errorMessage = null;
    } catch (e) {
      debugPrint('[ChatProvider] loadMessages error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(String content) async {
    isSending = true;
    errorMessage = null;
    notifyListeners();
    try {
      final msg = await _service.sendMessage(_sessionId, content);
      messages = [...messages, msg];
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      debugPrint('[ChatProvider] sendMessage error: $e');
    } finally {
      isSending = false;
      notifyListeners();
    }
  }

  void startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => loadMessages(silent: true),
    );
  }

  void stopPolling() => _pollTimer?.cancel();

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
