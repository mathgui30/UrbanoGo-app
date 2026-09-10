class RatingModel {
  final String id;
  final String rideId;
  final String raterId;
  final String rateeId;
  final int score;
  final String? comment;
  final DateTime createdAt;

  RatingModel({
    required this.id,
    required this.rideId,
    required this.raterId,
    required this.rateeId,
    required this.score,
    this.comment,
    required this.createdAt,
  });

  factory RatingModel.fromJson(Map<String, dynamic> json) {
    return RatingModel(
      id: json['id'] as String,
      rideId: json['ride_id'] as String,
      raterId: json['rater_id'] as String,
      rateeId: json['ratee_id'] as String,
      score: json['score'] as int,
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ride_id': rideId,
      'rater_id': raterId,
      'ratee_id': rateeId,
      'score': score,
      'comment': comment,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }
}
