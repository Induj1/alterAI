import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/errors/alter_service_exception.dart';

/// Direct OpenAI BYOK — no cloud proxy. User must supply their key in Settings.
class OpenAIService {
  OpenAIService({this.byokKey});

  final String? byokKey;

  bool get _hasByok => byokKey != null && byokKey!.isNotEmpty;

  Future<String> chat({
    required List<Map<String, dynamic>> messages,
    String model = 'gpt-4o-mini',
    double temperature = 0.7,
    int maxTokens = 1200,
    bool jsonMode = false,
  }) async {
    if (!_hasByok) {
      throw const AlterServiceException(
        'Add your OpenAI key in Settings to use Cloud AI.',
        kind: ServiceErrorKind.notConfigured,
      );
    }
    return _directChat(
      messages: messages,
      model: model,
      temperature: temperature,
      maxTokens: maxTokens,
      jsonMode: jsonMode,
    );
  }

  /// Agent function-calling. Returns { content: String, tool_calls: List? }.
  Future<Map<String, dynamic>> chatWithTools({
    required List<Map<String, dynamic>> messages,
    required List<Map<String, dynamic>> tools,
    String model = 'gpt-4o-mini',
    double temperature = 0.4,
    int maxTokens = 900,
  }) async {
    if (!_hasByok) {
      throw const AlterServiceException(
        'Add your OpenAI key in Settings to use Cloud AI.',
        kind: ServiceErrorKind.notConfigured,
      );
    }
    return _directTools(messages, tools, model, temperature, maxTokens);
  }

  Future<Map<String, dynamic>> _directTools(
    List<Map<String, dynamic>> messages,
    List<Map<String, dynamic>> tools,
    String model,
    double temperature,
    int maxTokens,
  ) async {
    final res = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $byokKey',
      },
      body: jsonEncode({
        'model': model,
        'messages': messages,
        'temperature': temperature,
        'max_tokens': maxTokens,
        'tools': tools,
        'tool_choice': 'auto',
      }),
    );
    final decoded = jsonDecode(res.body);
    if (res.statusCode != 200) {
      throw AlterServiceException(
        'OpenAI direct error',
        kind: _openAiKindForStatus(res.statusCode),
        statusCode: res.statusCode,
      );
    }
    final msg = ((decoded as Map)['choices'] as List).first['message'] as Map;
    return {'content': msg['content'] ?? '', 'tool_calls': msg['tool_calls']};
  }

  Future<String> _directChat({
    required List<Map<String, dynamic>> messages,
    required String model,
    required double temperature,
    required int maxTokens,
    required bool jsonMode,
  }) async {
    final res = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $byokKey',
      },
      body: jsonEncode({
        'model': model,
        'messages': messages,
        'temperature': temperature,
        'max_tokens': maxTokens,
        if (jsonMode) 'response_format': {'type': 'json_object'},
      }),
    );

    final decoded = jsonDecode(res.body);
    if (res.statusCode != 200) {
      throw AlterServiceException(
        'OpenAI direct error',
        kind: _openAiKindForStatus(res.statusCode),
        statusCode: res.statusCode,
      );
    }
    final choices = (decoded as Map)['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw const FormatException('OpenAI returned no choices.');
    }
    return ((choices.first as Map)['message'] as Map)['content'] as String;
  }

  void dispose() {}
}

ServiceErrorKind _openAiKindForStatus(int code) {
  if (code == 401 || code == 403) return ServiceErrorKind.auth;
  if (code == 404) return ServiceErrorKind.notFound;
  if (code == 429) return ServiceErrorKind.quota;
  if (code >= 500) return ServiceErrorKind.server;
  return ServiceErrorKind.unknown;
}
