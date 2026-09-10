
class RidePassengerModel {
  final String id;
  final String name;

  RidePassengerModel({required this.id, required this.name});

  factory RidePassengerModel.fromJson(Map<String, dynamic> json) =>
      RidePassengerModel(
        id: json['id'] as String,
        name: json['name'] as String,
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

class RideDriverModel {
  final String id;
  final String name;
  final String vehicleModel;
  final String vehiclePlate;
  final double trustScore;

  RideDriverModel({
    required this.id,
    required this.name,
    required this.vehicleModel,
    required this.vehiclePlate,
    required this.trustScore,
  });

  factory RideDriverModel.fromJson(Map<String, dynamic> json) =>
      RideDriverModel(
        id: json['id'] as String,
        name: json['name'] as String,
        vehicleModel: json['vehicle_model'] as String,
        vehiclePlate: json['vehicle_plate'] as String,
      trustScore: (json['trust_score'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'vehicle_model': vehicleModel,
    'vehicle_plate': vehiclePlate,
    'trust_score': trustScore,
  };
}

class LocationPointModel {
  final double lat;
  final double lng;
  final String? address;

  LocationPointModel({required this.lat, required this.lng, this.address});

  factory LocationPointModel.fromJson(Map<String, dynamic> json) =>
      LocationPointModel(
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        address: json['address'] as String?,
      );

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng, 'address': address};
}

class PriceMultipliersModel {
  final double time;
  final double demand;
  final double weather;

  PriceMultipliersModel({
    required this.time,
    required this.demand,
    required this.weather,
  });

  factory PriceMultipliersModel.fromJson(Map<String, dynamic> json) =>
      PriceMultipliersModel(
        time: (json['time'] as num).toDouble(),
        demand: (json['demand'] as num).toDouble(),
        weather: (json['weather'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
    'time': time,
    'demand': demand,
    'weather': weather,
  };
}

class PriceBreakdownModel {
  final int baseCents;
  final int perKmCents;
  final double distanceKm;
  final PriceMultipliersModel multipliers;
  final int serviceFeeCents;

  PriceBreakdownModel({
    required this.baseCents,
    required this.perKmCents,
    required this.distanceKm,
    required this.multipliers,
    required this.serviceFeeCents,
  });

  factory PriceBreakdownModel.fromJson(Map<String, dynamic> json) =>
      PriceBreakdownModel(
        baseCents: json['base_cents'] as int,
        perKmCents: json['per_km_cents'] as int,
        distanceKm: (json['distance_km'] as num).toDouble(),
        multipliers: PriceMultipliersModel.fromJson(
          json['multipliers'] as Map<String, dynamic>,
        ),
        serviceFeeCents: json['service_fee_cents'] as int,
      );

  Map<String, dynamic> toJson() => {
    'base_cents': baseCents,
    'per_km_cents': perKmCents,
    'distance_km': distanceKm,
    'multipliers': multipliers.toJson(),
    'service_fee_cents': serviceFeeCents,
  };
}

class RideModel {
  final String id;
  final String type; 
  final String
  status; 
  final RidePassengerModel passenger;
  final RideDriverModel? driver; 
  final LocationPointModel origin;
  final LocationPointModel destination;
  final int distanceMeters;
  final int? priceCents; 
  final String currency;
  final PriceBreakdownModel? priceBreakdown; 
  final DateTime requestedAt;
  final DateTime? assignedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? cancelledBy; 

  RideModel({
    required this.id,
    required this.type,
    required this.status,
    required this.passenger,
    this.driver,
    required this.origin,
    required this.destination,
    required this.distanceMeters,
    this.priceCents,
    required this.currency,
    this.priceBreakdown,
    required this.requestedAt,
    this.assignedAt,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
    this.cancelledBy,
  });

  factory RideModel.fromJson(Map<String, dynamic> json) {
    return RideModel(
      id: json['id'] as String,
      type: json['type'] as String,
      status: json['status'] as String,
      passenger: RidePassengerModel.fromJson(
        json['passenger'] as Map<String, dynamic>,
      ),
      driver: json['driver'] != null
          ? RideDriverModel.fromJson(json['driver'] as Map<String, dynamic>)
          : null,
      origin: LocationPointModel.fromJson(
        json['origin'] as Map<String, dynamic>,
      ),
      destination: LocationPointModel.fromJson(
        json['destination'] as Map<String, dynamic>,
      ),
      distanceMeters: json['distance_meters'] as int,
      priceCents: json['price_cents'] as int?,
      currency: json['currency'] as String,
      priceBreakdown: json['price_breakdown'] != null
          ? PriceBreakdownModel.fromJson(
              json['price_breakdown'] as Map<String, dynamic>,
            )
          : null,
      requestedAt: DateTime.parse(json['requested_at'] as String),
      assignedAt: json['assigned_at'] != null
          ? DateTime.parse(json['assigned_at'] as String)
          : null,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'] as String)
          : null,
      cancelledBy: json['cancelled_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'status': status,
      'passenger': passenger.toJson(),
      'driver': driver?.toJson(),
      'origin': origin.toJson(),
      'destination': destination.toJson(),
      'distance_meters': distanceMeters,
      'price_cents': priceCents,
      'currency': currency,
      'price_breakdown': priceBreakdown?.toJson(),
      'requested_at': requestedAt.toUtc().toIso8601String(),
      'assigned_at': assignedAt?.toUtc().toIso8601String(),
      'started_at': startedAt?.toUtc().toIso8601String(),
      'completed_at': completedAt?.toUtc().toIso8601String(),
      'cancelled_at': cancelledAt?.toUtc().toIso8601String(),
      'cancelled_by': cancelledBy,
    };
  }
}
