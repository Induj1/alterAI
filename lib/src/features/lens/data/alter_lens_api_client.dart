import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/alter_lens_models.dart';

class AlterLensApiClient {
  AlterLensApiClient({
    required String baseUrl,
    http.Client? client,
  })  : _baseUrl = baseUrl.replaceFirst(RegExp(r'/$'), ''),
        _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;

  Future<LensScanResult> analyzeImage({
    required LensScanType scanType,
    required List<int> imageBytes,
    required String filename,
    String userContext = '',
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/v1/alter-lens/analyze'),
    )
      ..fields['scan_type'] = scanType.apiValue
      ..fields['user_context'] = userContext
      ..files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: filename,
        ),
      );

    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AlterLensApiException(
        'Alter Lens returned ${response.statusCode}: ${response.body}',
      );
    }
    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) {
      throw const AlterLensApiException('Alter Lens returned invalid JSON.');
    }
    return LensScanResult.fromJson(body);
  }

  void close() => _client.close();
}

class AlterLensApiException implements Exception {
  const AlterLensApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
