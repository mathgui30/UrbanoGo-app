import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:urbanogo/core/config/app_config.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic errors;

  ApiException(this.statusCode, this.message, [this.errors]);

  @override
  String toString() => 'Erro $statusCode: $message';
}

class ApiClient {
  final String baseUrl = AppConfig.apiBaseUrl;
  String? _token;

  String? get token => _token;

  void setToken(String token) {
    _token = token;
  }

  Map<String, String> _buildHeaders({bool json = false}) {
    return {
      if (json) 'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  dynamic _processResponse(http.Response response) {
    final body = jsonDecode(response.body);
    final statusCode = body['status_code'] as int;

    if (statusCode >= 400) {
      throw ApiException(statusCode, body['message'], body['data']?['errors']);
    }
    return body['data'];
  }

  Future<dynamic> get(String path) async {
    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: _buildHeaders(),
    );
    return _processResponse(response);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: _buildHeaders(json: body != null),
      body: body != null ? jsonEncode(body) : null,
    );
    return _processResponse(response);
  }

  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    final response = await http.patch(
      Uri.parse('$baseUrl$path'),
      headers: _buildHeaders(json: body != null),
      body: body != null ? jsonEncode(body) : null,
    );
    return _processResponse(response);
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    final response = await http.put(
      Uri.parse('$baseUrl$path'),
      headers: _buildHeaders(json: body != null),
      body: body != null ? jsonEncode(body) : null,
    );
    return _processResponse(response);
  }

  Future<dynamic> delete(String path) async {
    final response = await http.delete(
      Uri.parse('$baseUrl$path'),
      headers: _buildHeaders(),
    );
    return _processResponse(response);
  }
}
