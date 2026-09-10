class DriverModel {
  final String id;
  final String userId;
  final String servicePreference; 
  final bool isOnline;
  final String vehicleModel;
  final String vehiclePlate;
  final DateTime createdAt;

  DriverModel({
    required this.id,
    required this.userId,
    required this.servicePreference,
    required this.isOnline,
    required this.vehicleModel,
    required this.vehiclePlate,
    required this.createdAt,
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      servicePreference: json['service_preference'] as String,
      isOnline: json['is_online'] as bool,
      vehicleModel: json['vehicle_model'] as String,
      vehiclePlate: json['vehicle_plate'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'service_preference': servicePreference,
      'is_online': isOnline,
      'vehicle_model': vehicleModel,
      'vehicle_plate': vehiclePlate,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }
}
