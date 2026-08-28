class ScheduleInstallment {
  final int installmentNo;
  final String dueDate;
  final double amount;
  final double principal;
  final double interest;
  final double balance;
  final double paidAmount;
  final double remainingAmount;
  final String status;

  ScheduleInstallment({
    required this.installmentNo,
    required this.dueDate,
    required this.amount,
    required this.principal,
    required this.interest,
    required this.balance,
    this.paidAmount = 0.0,
    this.remainingAmount = 0.0,
    this.status = 'pending',
  });

  factory ScheduleInstallment.fromMap(Map<String, dynamic> map) {
    return ScheduleInstallment(
      installmentNo: (map['installmentNo'] as num?)?.toInt() ?? 0,
      dueDate: map['due_date']?.toString() ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      principal: (map['principal'] as num?)?.toDouble() ?? 0.0,
      interest: (map['interest'] as num?)?.toDouble() ?? 0.0,
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0.0,
      remainingAmount: (map['remainingAmount'] as num?)?.toDouble() ?? 0.0,
      status: map['status']?.toString() ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'installmentNo': installmentNo,
      'due_date': dueDate,
      'amount': amount,
      'principal': principal,
      'interest': interest,
      'balance': balance,
      'paidAmount': paidAmount,
      'remainingAmount': remainingAmount,
      'status': status,
    };
  }

  ScheduleInstallment copyWith({
    int? installmentNo,
    String? dueDate,
    double? amount,
    double? principal,
    double? interest,
    double? balance,
    double? paidAmount,
    double? remainingAmount,
    String? status,
  }) {
    return ScheduleInstallment(
      installmentNo: installmentNo ?? this.installmentNo,
      dueDate: dueDate ?? this.dueDate,
      amount: amount ?? this.amount,
      principal: principal ?? this.principal,
      interest: interest ?? this.interest,
      balance: balance ?? this.balance,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      status: status ?? this.status,
    );
  }
}
