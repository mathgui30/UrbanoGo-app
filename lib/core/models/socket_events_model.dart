import 'package:urbanogo/core/models/ride_model.dart';

class DriverLocationModel {
  final String?
  rideId; 
  final double lat;
  final double lng;
  final double? heading;
  final double? speed;
  final double?
  accuracy; 
  final DateTime recordedAt;
  final bool?
  predicted; 

  DriverLocationModel({
    this.rideId,
    required this.lat,
    required this.lng,
    this.heading,
    this.speed,
    this.accuracy,
    required this.recordedAt,
    this.predicted,
  });

  factory DriverLocationModel.fromJson(Map<String, dynamic> json) {
    return DriverLocationModel(
      rideId: json['ride_id'] as String?,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      heading: json['heading'] != null
          ? (json['heading'] as num).toDouble()
          : null,
      speed: json['speed'] != null ? (json['speed'] as num).toDouble() : null,
      accuracy: json['accuracy'] != null
          ? (json['accuracy'] as num).toDouble()
          : null,
      recordedAt: DateTime.parse(json['recorded_at'] as String),
      predicted: json['predicted'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (rideId != null) 'ride_id': rideId,
      'lat': lat,
      'lng': lng,
      if (heading != null) 'heading': heading,
      if (speed != null) 'speed': speed,
      if (accuracy != null) 'accuracy': accuracy,
      'recorded_at': recordedAt.toUtc().toIso8601String(),
      if (predicted != null) 'predicted': predicted,
    };
  }
}

class RideStatusEventModel {
  final String rideId;
  final String status;
  final RideDriverModel? driver;
  final DateTime updatedAt;

  RideStatusEventModel({
    required this.rideId,
    required this.status,
    this.driver,
    required this.updatedAt,
  });

  factory RideStatusEventModel.fromJson(Map<String, dynamic> json) {
    return RideStatusEventModel(
      rideId: json['ride_id'] as String,
      status: json['status'] as String,
      driver: json['driver'] != null
          ? RideDriverModel.fromJson(json['driver'] as Map<String, dynamic>)
          : null,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
