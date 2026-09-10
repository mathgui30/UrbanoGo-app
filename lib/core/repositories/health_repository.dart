import 'package:urbanogo/core/network/api_client.dart';

class HealthRepository {
  final ApiClient _client;

  HealthRepository(this._client);

  Future<Map<String, dynamic>> checkHealth() async {
    final data = await _client.get('/health');
    return data;
  }
}
