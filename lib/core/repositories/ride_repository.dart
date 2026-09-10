import 'package:urbanogo/core/models/ride_model.dart';
import 'package:urbanogo/core/network/api_client.dart';

class RideRepository {
  final ApiClient _client;

  RideRepository(this._client);

  Future<Map<String, dynamic>> getQuote(Map<String, dynamic> payload) async {
    final data = await _client.post('/quotes', body: payload);
    return data; 
  }

  Future<RideModel> createRide(Map<String, dynamic> payload) async {
    final data = await _client.post('/rides', body: payload);
    return RideModel.fromJson(data['ride']);
  }

  Future<RideModel> getRide(String id) async {
    final data = await _client.get('/rides/$id');
    return RideModel.fromJson(data['ride']);
  }

  Future<RideModel> cancelRide(String id, {String? reason}) async {
    final data = await _client.post(
      '/rides/$id/cancel',
      body: {if (reason != null) 'reason': reason},
    );
    return RideModel.fromJson(data['ride']);
  }

  Future<void> arrive(String id) async {
    await _client.post('/rides/$id/arrive');
  }

  Future<void> start(String id) async {
    await _client.post('/rides/$id/start');
  }

  Future<void> complete(String id) async {
    await _client.post('/rides/$id/complete');
  }

  Future<void> rate(String id, int score, {String? comment}) async {
    await _client.post(
      '/rides/$id/ratings',
      body: {'score': score, if (comment != null) 'comment': comment},
    );
  }
}

class OfferRepository {
  final ApiClient _client;

  OfferRepository(this._client);

  Future<RideModel> acceptOffer(String offerId) async {
    final data = await _client.post('/offers/$offerId/accept');
    return RideModel.fromJson(data['ride']);
  }

  Future<void> rejectOffer(String offerId) async {
    await _client.post('/offers/$offerId/reject');
  }
}
