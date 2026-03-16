import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';

class GeminiChatService {
  final model = GenerativeModel(
    model: 'gemini-2.5-flash',
    apiKey: 'YOUR_API_KEY_HERE', 
    generationConfig: GenerationConfig(
      responseMimeType: 'application/json', 
      temperature:
          0.3, 
    ),
  );

  Future<List<String>> getQuestionsFromGemini(
    String context,
    String highlight,
    String prefix,
  ) async {
    if (prefix.trim().isEmpty) return [];

    final prompt =
        '''
Bạn là AI hỗ trợ học sinh khiếm thính đặt câu hỏi kỹ thuật cho giáo viên trong lúc nghe giảng.
Dựa vào ngữ cảnh bài giảng, phần text học sinh bôi đen và những chữ họ đang gõ dở, hãy dự đoán và hoàn thiện 3 câu hỏi ngắn gọn, tự nhiên.

INPUT:
- Ngữ cảnh: "$context"
- Bôi đen: "$highlight"
- Đang gõ: "$prefix"

OUTPUT REQUIREMENTS:
- Bắt buộc trả về một mảng JSON chứa đúng 3 chuỗi (string).
- Không giải thích, không dùng markdown.
- Câu hỏi phải bắt đầu bằng hoặc bao hàm ý nghĩa của từ đang gõ ("$prefix").
''';

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      print("Gemini response: ${response.text}");
      if (response.text != null) {
        List<dynamic> parsedJson = jsonDecode(response.text!);
        return parsedJson.map((e) => e.toString()).toList();
      }
    } catch (e) {
      print("Lỗi gọi Gemini: $e");
    }
    return [];
  }
}
