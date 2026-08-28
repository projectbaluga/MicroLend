import 'credit_assessment.dart';
import 'payment.dart';
import 'schedule_installment.dart';

class Loan {
  final String id;
  final String borrowerId;
  final double principal;
  final double interestRate;
  final int termMonths;
  final String purpose;
  final String status;
  final String disbursementDate;
  final CreditAssessment? creditAssessment;
  final List<ScheduleInstallment> schedule;
  final List<Payment> payments;
  final String notes;
  final String? createdAt;
  final String? updatedAt;

  Loan({
    required this.id,
    required this.borrowerId,
    required this.principal,
    required this.interestRate,
    required this.termMonths,
    required this.purpose,
    required this.status,
    required this.disbursementDate,
    this.creditAssessment,
    required this.schedule,
    required this.payments,
    required this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory Loan.fromMap(Map<String, dynamic> map) {
    return Loan(
      id: map['id']?.toString() ?? '',
      borrowerId: map['borrower_id']?.toString() ?? map['borrowerId']?.toString() ?? '',
      principal: (map['principal'] as num?)?.toDouble() ?? 0.0,
      interestRate: (map['interest_rate'] as num?)?.toDouble() ?? (map['interestRate'] as num?)?.toDouble() ?? 0.0,
      termMonths: (map['term_months'] as num?)?.toInt() ?? (map['termMonths'] as num?)?.toInt() ?? 1,
      purpose: map['purpose']?.toString() ?? '',
      status: map['status']?.toString() ?? 'pending',
      disbursementDate: map['disbursement_date']?.toString() ?? map['disbursementDate']?.toString() ?? '',
      creditAssessment: map['credit_assessment'] != null
          ? CreditAssessment.fromMap(Map<String, dynamic>.from(map['credit_assessment']))
          : null,
      schedule: map['schedule'] != null
          ? (map['schedule'] as List).map((e) => ScheduleInstallment.fromMap(Map<String, dynamic>.from(e))).toList()
          : [],
      payments: map['payments'] != null
          ? (map['payments'] as List).map((e) => Payment.fromMap(Map<String, dynamic>.from(e))).toList()
          : [],
      notes: map['notes']?.toString() ?? '',
      createdAt: map['createdAt']?.toString(),
      updatedAt: map['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'borrower_id': borrowerId,
      'principal': principal,
      'interest_rate': interestRate,
      'term_months': termMonths,
      'purpose': purpose,
      'status': status,
      'disbursement_date': disbursementDate,
      if (creditAssessment != null) 'credit_assessment': creditAssessment!.toMap(),
      'schedule': schedule.map((e) => e.toMap()).toList(),
      'payments': payments.map((e) => e.toMap()).toList(),
      'notes': notes,
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
    };
  }

  Loan copyWith({
    String? id,
    String? borrowerId,
    double? principal,
    double? interestRate,
    int? termMonths,
    String? purpose,
    String? status,
    String? disbursementDate,
    CreditAssessment? creditAssessment,
    List<ScheduleInstallment>? schedule,
    List<Payment>? payments,
    String? notes,
    String? createdAt,
    String? updatedAt,
  }) {
    return Loan(
      id: id ?? this.id,
      borrowerId: borrowerId ?? this.borrowerId,
      principal: principal ?? this.principal,
      interestRate: interestRate ?? this.interestRate,
      termMonths: termMonths ?? this.termMonths,
      purpose: purpose ?? this.purpose,
      status: status ?? this.status,
      disbursementDate: disbursementDate ?? this.disbursementDate,
      creditAssessment: creditAssessment ?? this.creditAssessment,
      schedule: schedule ?? this.schedule,
      payments: payments ?? this.payments,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
