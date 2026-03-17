import 'package:flutter/material.dart';
import 'package:flutter_web_rtc/models/chat_message.dart';
import 'package:flutter_web_rtc/services/debounce.dart';
import 'package:flutter_web_rtc/services/gemini_chat.dart';
import 'package:flutter/services.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:math';

void main() => runApp(
  const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: LiveTranscriptViewer(),
  ),
);

class LiveTranscriptViewer extends StatefulWidget {
  const LiveTranscriptViewer({super.key});

  @override
  State<LiveTranscriptViewer> createState() => _LiveTranscriptViewerState();
}

class _LiveTranscriptViewerState extends State<LiveTranscriptViewer> {
  final GeminiChatService _geminiService = GeminiChatService();
  final FocusNode _chatInputFocusNode = FocusNode();
  final ScrollController _chatScrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isSendingMessage = false;
  final _channel = WebSocketChannel.connect(
    Uri.parse('ws://localhost:8000/ws/stt'),
  );
  bool isChatOpen = false;
  bool isHoveringSTT = false;
  final TextEditingController _chatController = TextEditingController();
  String transcriptBuffer = "";
  String highlightedText = "";
  String recentContext = "";
  String frozenDisplayTranscript = "";
  final int maxDisplayLength = 150;
  int currentStartIndex = 0;
  int frozenStartIndex = 0;
  bool get isUIFrozen => isHoveringSTT;
  final _debouncer = Debouncer(milliseconds: 500);
  List<String> _suggestions = [];
  List<String> _mentionSuggestions = [];
  bool _isLoadingSuggestions = false;
  bool _isChatbotQuestion = false;
  static const String _chatbotName = 'deai';

  @override
  void initState() {
    super.initState();
    _channel.stream.listen((data) {
      setState(() {
        transcriptBuffer += data.toString();
      });
    });
  }

  @override
  void dispose() {
    _chatInputFocusNode.dispose();
    _chatScrollController.dispose();
    _chatController.dispose();
    _channel.sink.close();
    super.dispose();
  }

  void _handleSelectionChanged(
    TextSelection selection,
    SelectionChangedCause? cause,
  ) {
    if (selection.isCollapsed) {
      // Nếu click ra ngoài (hủy bôi đen), xóa highlight
      setState(() {
        highlightedText = "";
        recentContext = "";
      });
      return;
    }

    int localStart = min(selection.baseOffset, selection.extentOffset);
    int localEnd = max(selection.baseOffset, selection.extentOffset);

    int globalStart = frozenStartIndex + localStart;
    int globalEnd = frozenStartIndex + localEnd;

    if (globalStart < 0 || globalEnd > transcriptBuffer.length) return;

    String selected = transcriptBuffer.substring(globalStart, globalEnd);
    int contextStart = max(0, globalStart - 200);
    String context = transcriptBuffer.substring(
      contextStart,
      transcriptBuffer.length,
    );

    setState(() {
      highlightedText = selected;
      recentContext = context;
    });
  }

  void _updateMentionSuggestions(String text) {
    final mentionMatch = RegExp(r'(^|\s)@([a-zA-Z0-9_]*)$').firstMatch(text);

    if (mentionMatch == null) {
      if (_mentionSuggestions.isNotEmpty) {
        setState(() {
          _mentionSuggestions = [];
        });
      }
      return;
    }

    final query = (mentionMatch.group(2) ?? '').toLowerCase();
    final mention = '@$_chatbotName';
    final matches = _chatbotName.startsWith(query) ? [mention] : <String>[];

    setState(() {
      _mentionSuggestions = matches;
    });
  }

  void _applyMentionSuggestion(String mention) {
    final text = _chatController.text;
    final mentionMatch = RegExp(r'(^|\s)@[a-zA-Z0-9_]*$').firstMatch(text);
    if (mentionMatch == null) return;

    final leadingSpace = mentionMatch.group(1) ?? '';
    final updatedText = text.replaceRange(
      mentionMatch.start,
      mentionMatch.end,
      '$leadingSpace$mention ',
    );

    setState(() {
      _chatController.text = updatedText;
      _chatController.selection = TextSelection.fromPosition(
        TextPosition(offset: updatedText.length),
      );
      _mentionSuggestions = [];
      _isChatbotQuestion = updatedText.contains('@$_chatbotName');
    });
  }

  @override
  Widget build(BuildContext context) {
    const double chatWindowWidth = 320;
    int liveStartIndex = max(0, transcriptBuffer.length - maxDisplayLength);
    String liveTranscript = transcriptBuffer.substring(liveStartIndex);

    String textToDisplay = isUIFrozen
        ? frozenDisplayTranscript
        : liveTranscript;

    if (!isUIFrozen) {
      frozenDisplayTranscript = liveTranscript;
      frozenStartIndex = liveStartIndex;
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
            ),
          ),

          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            bottom: 30,
            left: 20,
            right: isChatOpen ? chatWindowWidth + 20 : 20,
            child: Center(
              child: MouseRegion(
                onEnter: (_) {
                  setState(() {
                    isHoveringSTT = true;
                    frozenDisplayTranscript = liveTranscript;
                    frozenStartIndex = liveStartIndex;
                  });
                },
                onExit: (_) {
                  setState(() {
                    isHoveringSTT = false;
                  });
                },
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isUIFrozen
                          ? Colors.blue.withOpacity(0.5)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: SelectableText(
                    textToDisplay,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                    onSelectionChanged: _handleSelectionChanged,
                  ),
                ),
              ),
            ),
          ),

          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            top: 50,
            bottom: 0,
            right: isChatOpen ? 0 : -chatWindowWidth,
            width: chatWindowWidth,
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey[100],
                    child: const Row(
                      children: [
                        Icon(Icons.chat_bubble_outline),
                        SizedBox(width: 8),
                        Text(
                          "Meeting Chat",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: Column(
                      children: [
                        if (highlightedText.isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "Đang hỏi về: '$highlightedText'",
                              style: const TextStyle(
                                color: Colors.blue,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        Expanded(
                          child: ListView.builder(
                            controller: _chatScrollController,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            itemCount:
                                _messages.length + (_isSendingMessage ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index >= _messages.length) {
                                return Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      "deai đang trả lời...",
                                      style: TextStyle(color: Colors.black54),
                                    ),
                                  ),
                                );
                              }
                              return _buildMessageBubble(_messages[index]);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_isLoadingSuggestions)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: LinearProgressIndicator(),
                    ),

                  if (_mentionSuggestions.isNotEmpty)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(color: Colors.grey[200]!),
                        ),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _mentionSuggestions.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            dense: true,
                            leading: const Icon(
                              Icons.alternate_email,
                              color: Colors.blue,
                              size: 18,
                            ),
                            title: Text(_mentionSuggestions[index]),
                            subtitle: const Text('Dùng để hỏi chatbot'),
                            onTap: () {
                              _applyMentionSuggestion(
                                _mentionSuggestions[index],
                              );
                            },
                          );
                        },
                      ),
                    ),

                  if (!_isLoadingSuggestions && _suggestions.isNotEmpty)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 150),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(color: Colors.grey[200]!),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _suggestions.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            dense: true,
                            leading: const Icon(
                              Icons.auto_awesome,
                              color: Colors.purple,
                              size: 18,
                            ), // Icon AI
                            title: Text(_suggestions[index]),
                            onTap: () {
                              setState(() {
                                _chatController.text = _suggestions[index];
                                _suggestions = [];
                              });
                              _chatController.selection =
                                  TextSelection.fromPosition(
                                    TextPosition(
                                      offset: _chatController.text.length,
                                    ),
                                  );
                            },
                          );
                        },
                      ),
                    ),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Colors.grey[300]!)),
                    ),
                    child: Focus(
                      focusNode: _chatInputFocusNode,
                      onKeyEvent: (node, event) {
                        final isEnter =
                            event.logicalKey == LogicalKeyboardKey.enter;
                        final isShiftPressed =
                            HardwareKeyboard.instance.isShiftPressed;

                        if (event is KeyDownEvent &&
                            isEnter &&
                            !isShiftPressed) {
                          _sendCurrentMessage();
                          return KeyEventResult.handled;
                        }

                        return KeyEventResult.ignored;
                      },
                      child: TextField(
                        controller: _chatController,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          hintText: "Nhập câu hỏi...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.send, color: Colors.blue),
                            onPressed: _sendCurrentMessage,
                          ),
                        ),
                        onChanged: (text) {
                          _updateMentionSuggestions(text);

                          final isChatbotQuestion = text.contains(
                            '@$_chatbotName',
                          );
                          if (_isChatbotQuestion != isChatbotQuestion) {
                            setState(() {
                              _isChatbotQuestion = isChatbotQuestion;
                            });
                          }

                          if (text.trim().isEmpty) {
                            setState(() {
                              _suggestions = [];
                              _isLoadingSuggestions = false;
                            });
                            return;
                          }

                          if (_isChatbotQuestion) {
                            setState(() {
                              _suggestions = [];
                              _isLoadingSuggestions = false;
                            });
                            return;
                          }

                          setState(() {
                            _isLoadingSuggestions = true;
                          });

                          _debouncer.run(() async {
                            final results = await _geminiService
                                .getQuestionsFromGemini(
                                  recentContext,
                                  highlightedText,
                                  _chatController.text,
                                );
                            setState(() {
                              _suggestions = results;
                              _isLoadingSuggestions = false;
                            });
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.end, // Canh phải cho các icon
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.people_alt_outlined,
                      color: Colors.white,
                    ),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(
                      isChatOpen
                          ? Icons.chat_bubble
                          : Icons.chat_bubble_outline,
                      color: isChatOpen ? Colors.blue : Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        isChatOpen = !isChatOpen;
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_horiz, color: Colors.white),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () {},
                    child: const Text(
                      "Leave",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendCurrentMessage() async {
    final rawInput = _chatController.text.trim();
    if (rawInput.isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(
          sender: MessageSender.user,
          text: rawInput,
          createdAt: DateTime.now(),
        ),
      );
      _chatController.clear();
      _suggestions = [];
      _mentionSuggestions = [];
      _isChatbotQuestion = false;
    });
    _scrollToBottom();

    final isForDeai = _geminiService.isDeaiMentionQuestion(rawInput);
    if (!isForDeai) return;

    setState(() {
      _isSendingMessage = true;
    });

    final answer = await _geminiService.getAnswerForDeai(
      rawInput: rawInput,
      context: recentContext,
      highlight: highlightedText,
    );

    if (!mounted) return;

    setState(() {
      _isSendingMessage = false;
      _messages.add(
        ChatMessage(
          sender: MessageSender.deai,
          text: answer,
          createdAt: DateTime.now(),
        ),
      );
    });
    _scrollToBottom();
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.sender == MessageSender.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 240),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isUser ? 12 : 2),
            bottomRight: Radius.circular(isUser ? 2 : 12),
          ),
        ),
        child: Text(
          msg.text,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}
