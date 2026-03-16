import 'package:flutter/material.dart';
import 'package:flutter_web_rtc/services/debounce.dart';
import 'package:flutter_web_rtc/services/gemini_chat.dart';
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
  bool _isLoadingSuggestions = false;

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
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (highlightedText.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(8),
                            margin: const EdgeInsets.only(bottom: 10),
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
                      ],
                    ),
                  ),

                  if (_isLoadingSuggestions)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: LinearProgressIndicator(), 
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
                              // Khi chọn gợi ý, điền vào ô text và xóa list gợi ý
                              setState(() {
                                _chatController.text = _suggestions[index];
                                _suggestions = [];
                              });
                              // Di chuyển con trỏ về cuối câu
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
                    child: TextField(
                      controller: _chatController,
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
                          onPressed: () {},
                        ),
                      ),
                      onChanged: (text) {
                        if (text.trim().isEmpty) {
                          setState(() {
                            _suggestions = [];
                            _isLoadingSuggestions = false;
                          });
                          return;
                        }

                        // Bật loading để user biết app đang nghĩ
                        setState(() {
                          _isLoadingSuggestions = true;
                        });

                        // Chạy Debouncer: Dừng gõ 500ms mới gọi hàm
                        _debouncer.run(() async {
                          final results = await GeminiChatService()
                              .getQuestionsFromGemini(
                                recentContext,
                                highlightedText,
                                text,
                              );

                          setState(() {
                            _suggestions = results;
                            _isLoadingSuggestions = false;
                          });
                        });
                      },
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
}
