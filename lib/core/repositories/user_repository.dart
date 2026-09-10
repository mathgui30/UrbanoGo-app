import 'package:urbanogo/core/models/user_model.dart';
import 'package:urbanogo/core/models/rating_model.dart';
import 'package:urbanogo/core/models/trust_score_model.dart';
import 'package:urbanogo/core/network/api_client.dart';

class UserRepository {
  final ApiClient _client;

  UserRepository(this._client);

  Future<UserModel> updateProfile({String? name, String? phone}) async {
    final payload = <String, dynamic>{};
    if (name != null) payload['name'] = name;
    if (phone != null) payload['phone'] = phone;

    final data = await _client.patch('/users/me', body: payload);
    return UserModel.fromJson(data['user']);
  }

  Future<void> deleteAccount() async {
    await _client.delete('/users/me');
  }

  Future<Map<String, dynamic>> getRatings(
    String userId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    final data = await _client.get(
      '/users/$userId/ratings?page=$page&page_size=$pageSize',
    );

    return {
      'items': (data['items'] as List)
          .map((item) => RatingModel.fromJson(item))
          .toList(),
      'page': data['page'],
      'page_size': data['page_size'],
      'total': data['total'],
    };
  }

  Future<TrustScoreModel> getTrustScore(String userId) async {
    final data = await _client.get('/users/$userId/trust-score');
    return TrustScoreModel.fromJson(data['trust_score']);
  }
}
