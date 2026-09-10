import 'package:urbanogo/core/models/driver_model.dart';
import 'package:urbanogo/core/network/api_client.dart';

class DriverRepository {
  final ApiClient _client;

  DriverRepository(this._client);

  Future<DriverModel> createProfile(Map<String, dynamic> payload) async {
    final data = await _client.post('/drivers/me', body: payload);
    return DriverModel.fromJson(data['driver']);
  }

  Future<DriverModel> getMe() async {
    final data = await _client.get('/drivers/me');
    return DriverModel.fromJson(data['driver']);
  }

  Future<DriverModel> updateProfile(Map<String, dynamic> payload) async {
    final data = await _client.patch('/drivers/me', body: payload);
    return DriverModel.fromJson(data['driver']);
  }

  Future<bool> updateAvailability(bool isOnline) async {
    final data = await _client.put(
      '/drivers/me/availability',
      body: {'is_online': isOnline},
    );
    return data['is_online'] as bool;
  }
}
