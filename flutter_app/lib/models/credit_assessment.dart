class CreditAssessment {
  final int creditScore;
  final int baseCreditScore;
  final int dtiPct;
  final String riskRating;
  final double monthlyDebt;
  final int completedCount;
  final int defaultedCount;
  final int activeCount;

  CreditAssessment({
    required this.creditScore,
    required this.baseCreditScore,
    required this.dtiPct,
    required this.riskRating,
    required this.monthlyDebt,
    required this.completedCount,
    required this.defaultedCount,
    required this.activeCount,
  });

  factory CreditAssessment.fromMap(Map<String, dynamic> map) {
    return CreditAssessment(
      creditScore: (map['creditScore'] as num?)?.toInt() ?? 50,
      baseCreditScore: (map['baseCreditScore'] as num?)?.toInt() ?? 50,
      dtiPct: (map['dtiPct'] as num?)?.toInt() ?? 0,
      riskRating: map['riskRating']?.toString() ?? 'medium',
      monthlyDebt: (map['monthlyDebt'] as num?)?.toDouble() ?? 0.0,
      completedCount: (map['completedCount'] as num?)?.toInt() ?? 0,
      defaultedCount: (map['defaultedCount'] as num?)?.toInt() ?? 0,
      activeCount: (map['activeCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'creditScore': creditScore,
      'baseCreditScore': baseCreditScore,
      'dtiPct': dtiPct,
      'riskRating': riskRating,
      'monthlyDebt': monthlyDebt,
      'completedCount': completedCount,
      'defaultedCount': defaultedCount,
      'activeCount': activeCount,
    };
  }
}
