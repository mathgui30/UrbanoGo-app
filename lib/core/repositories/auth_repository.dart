import 'package:urbanogo/core/models/user_model.dart';
import 'package:urbanogo/core/network/api_client.dart';

class AuthRepository {
  final ApiClient _client;

  AuthRepository(this._client);

  Future<Map<String, dynamic>> login(String email, String password) async {
    final data = await _client.post(
      '/auth/login',
      body: {'email': email, 'password': password},
    );

    _client.setToken(data['token']);
    return {'token': data['token'], 'user': UserModel.fromJson(data['user'])};
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> payload) async {
    final data = await _client.post('/auth/register', body: payload);

    _client.setToken(data['token']);
    return {'token': data['token'], 'user': UserModel.fromJson(data['user'])};
  }

  Future<UserModel> getMe() async {
    final data = await _client.get('/auth/me');
    return UserModel.fromJson(data['user']);
  }
}
