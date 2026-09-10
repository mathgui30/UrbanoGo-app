import 'package:urbanogo/core/models/ride_model.dart'; 

class QuoteModel {
  final int distanceMeters;
  final int priceCents;
  final String currency;
  final PriceBreakdownModel priceBreakdown;
  final DateTime expiresAt;

  QuoteModel({
    required this.distanceMeters,
    required this.priceCents,
    required this.currency,
    required this.priceBreakdown,
    required this.expiresAt,
  });

  factory QuoteModel.fromJson(Map<String, dynamic> json) {
    return QuoteModel(
      distanceMeters: json['distance_meters'] as int,
      priceCents: json['price_cents'] as int,
      currency: json['currency'] as String,
      priceBreakdown: PriceBreakdownModel.fromJson(
        json['price_breakdown'] as Map<String, dynamic>,
      ),
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }
}
