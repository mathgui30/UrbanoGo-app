class TrustScoreModel {
  final String userId;
  final double score;
  final String source; 
  final DateTime computedAt;

  TrustScoreModel({
    required this.userId,
    required this.score,
    required this.source,
    required this.computedAt,
  });

  factory TrustScoreModel.fromJson(Map<String, dynamic> json) {
    return TrustScoreModel(
      userId: json['user_id'] as String,
      score: (json['score'] as num).toDouble(),
      source: json['source'] as String,
      computedAt: DateTime.parse(json['computed_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'score': score,
      'source': source,
      'computed_at': computedAt.toUtc().toIso8601String(),
    };
  }
}
