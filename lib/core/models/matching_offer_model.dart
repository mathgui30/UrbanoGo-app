import 'package:urbanogo/core/models/ride_model.dart'; 

class MatchingOfferPassenger {
  final String name;
  final double trustScore;

  MatchingOfferPassenger({required this.name, required this.trustScore});

  factory MatchingOfferPassenger.fromJson(Map<String, dynamic> json) {
    return MatchingOfferPassenger(
      name: json['name'] as String,
      trustScore: (json['trust_score'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'trust_score': trustScore};
}

class MatchingOfferModel {
  final String offerId;
  final String rideId;
  final DateTime expiresAt;
  final LocationPointModel pickup;
  final LocationPointModel dropoff;
  final MatchingOfferPassenger passenger;
  final int distanceToPickupMeters;
  final int priceCents;

  MatchingOfferModel({
    required this.offerId,
    required this.rideId,
    required this.expiresAt,
    required this.pickup,
    required this.dropoff,
    required this.passenger,
    required this.distanceToPickupMeters,
    required this.priceCents,
  });

  factory MatchingOfferModel.fromJson(Map<String, dynamic> json) {
    return MatchingOfferModel(
      offerId: json['offer_id'] as String,
      rideId: json['ride_id'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      pickup: LocationPointModel.fromJson(
        json['pickup'] as Map<String, dynamic>,
      ),
      dropoff: LocationPointModel.fromJson(
        json['dropoff'] as Map<String, dynamic>,
      ),
      passenger: MatchingOfferPassenger.fromJson(
        json['passenger'] as Map<String, dynamic>,
      ),
      distanceToPickupMeters: json['distance_to_pickup_meters'] as int,
      priceCents: json['price_cents'] as int,
    );
  }
}
