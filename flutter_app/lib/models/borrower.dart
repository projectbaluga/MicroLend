class Borrower {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String address;
  final String idNumber;
  final String employment;
  final double monthlyIncome;
  final int creditScore;
  final String riskRating;
  final String notes;
  final String? createdAt;
  final String? updatedAt;

  Borrower({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.address,
    required this.idNumber,
    required this.employment,
    required this.monthlyIncome,
    required this.creditScore,
    required this.riskRating,
    required this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory Borrower.fromMap(Map<String, dynamic> map) {
    return Borrower(
      id: map['id']?.toString() ?? '',
      fullName: map['full_name']?.toString() ?? map['fullName']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      idNumber: map['id_number']?.toString() ?? map['idNumber']?.toString() ?? '',
      employment: map['employment']?.toString() ?? '',
      monthlyIncome: (map['monthly_income'] as num?)?.toDouble() ?? (map['monthlyIncome'] as num?)?.toDouble() ?? 0.0,
      creditScore: (map['credit_score'] as num?)?.toInt() ?? (map['creditScore'] as num?)?.toInt() ?? 50,
      riskRating: map['risk_rating']?.toString() ?? map['riskRating']?.toString() ?? 'medium',
      notes: map['notes']?.toString() ?? '',
      createdAt: map['createdAt']?.toString(),
      updatedAt: map['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'address': address,
      'id_number': idNumber,
      'employment': employment,
      'monthly_income': monthlyIncome,
      'credit_score': creditScore,
      'risk_rating': riskRating,
      'notes': notes,
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
    };
  }

  Borrower copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    String? address,
    String? idNumber,
    String? employment,
    double? monthlyIncome,
    int? creditScore,
    String? riskRating,
    String? notes,
    String? createdAt,
    String? updatedAt,
  }) {
    return Borrower(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      idNumber: idNumber ?? this.idNumber,
      employment: employment ?? this.employment,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      creditScore: creditScore ?? this.creditScore,
      riskRating: riskRating ?? this.riskRating,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
