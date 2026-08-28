class Payment {
  final String id;
  final String date;
  final double amount;
  final String method;
  final String note;

  Payment({
    required this.id,
    required this.date,
    required this.amount,
    required this.method,
    required this.note,
  });

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      method: map['method']?.toString() ?? '',
      note: map['note']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'amount': amount,
      'method': method,
      'note': note,
    };
  }
}
