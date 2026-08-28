import 'dart:math';
import 'package:intl/intl.dart';
import '../models/borrower.dart';
import '../models/credit_assessment.dart';
import '../models/loan.dart';
import '../models/payment.dart';
import '../models/schedule_installment.dart';

class LoanStats {
  final double totalDisbursed;
  final double totalScheduled;
  final double totalPaid;
  final double outstandingBalance;
  final double overdueAmount;
  final int progressPct;
  final ScheduleInstallment? nextDue;
  final List<ScheduleInstallment> scheduleWithStatus;

  LoanStats({
    required this.totalDisbursed,
    required this.totalScheduled,
    required this.totalPaid,
    required this.outstandingBalance,
    required this.overdueAmount,
    required this.progressPct,
    this.nextDue,
    required this.scheduleWithStatus,
  });
}

class LoanUtils {
  static String defaultCurrencyCode = 'USD';
  static String defaultDateFormat = 'MMM d, yyyy';

  static double round2(double val) {
    return (val * 100.0).round() / 100.0;
  }

  static double calculateUpfrontDeduction(double principal, String type, double value) {
    final p = max(0.0, principal);
    final val = max(0.0, value);

    if (type == 'percent') {
      return round2(p * (val / 100.0));
    } else if (type == 'fixed') {
      return round2(min(p, val));
    }
    return 0.0;
  }

  static double calculateNetDisbursed(double principal, String type, double value) {
    final deduction = calculateUpfrontDeduction(principal, type, value);
    return round2(max(0.0, principal - deduction));
  }

  static String formatCurrency(double amount, [String? currencyCode]) {
    final code = currencyCode ?? defaultCurrencyCode;
    String symbol = '\$';
    switch (code.toUpperCase()) {
      case 'EUR':
        symbol = '€';
        break;
      case 'PHP':
        symbol = '₱';
        break;
      case 'GBP':
        symbol = '£';
        break;
      case 'USD':
      default:
        symbol = '\$';
        break;
    }

    final formatter = NumberFormat.currency(locale: 'en_US', symbol: symbol, decimalDigits: 2);
    return formatter.format(amount);
  }

  static String formatDate(String? dateStr, [String? formatPattern]) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    final pattern = formatPattern ?? defaultDateFormat;
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat(pattern).format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  static String formatPercent(double rate) {
    return '${rate.toStringAsFixed(1)}%';
  }

  static List<ScheduleInstallment> generateSchedule(
    double principal,
    double interestRateAnnual,
    int termMonths,
    String disbursementDate,
  ) {
    final p = max(0.0, principal);
    final rate = max(0.0, interestRateAnnual);
    final n = max(1, termMonths);

    DateTime startDate;
    try {
      startDate = disbursementDate.isNotEmpty ? DateTime.parse(disbursementDate) : DateTime.now();
    } catch (_) {
      startDate = DateTime.now();
    }

    final r = (rate / 100.0) / 12.0;

    double monthlyPayment = 0.0;
    if (r > 0) {
      monthlyPayment = (p * r * pow(1 + r, n)) / (pow(1 + r, n) - 1);
    } else {
      monthlyPayment = p / n;
    }

    double balance = p;
    final List<ScheduleInstallment> schedule = [];

    for (int i = 1; i <= n; i++) {
      var year = startDate.year;
      var month = startDate.month + i;
      while (month > 12) {
        month -= 12;
        year += 1;
      }
      final day = min(startDate.day, 28);
      final dueDateStr = DateFormat('yyyy-MM-dd').format(DateTime(year, month, day));

      final interestForMonth = balance * r;
      double principalForMonth = monthlyPayment - interestForMonth;

      if (i == n || (balance - principalForMonth) < 0.01) {
        principalForMonth = balance;
        balance = 0.0;
      } else {
        balance = balance - principalForMonth;
      }

      final installmentAmount = principalForMonth + interestForMonth;

      schedule.add(ScheduleInstallment(
        installmentNo: i,
        dueDate: dueDateStr,
        amount: round2(installmentAmount),
        principal: round2(principalForMonth),
        interest: round2(interestForMonth),
        balance: max(0.0, round2(balance)),
      ));
    }

    return schedule;
  }

  static List<ScheduleInstallment> getScheduleWithStatus(
    List<ScheduleInstallment> schedule,
    List<Payment> payments, [
    String loanStatus = 'active',
    DateTime? referenceDate,
  ]) {
    final refDate = referenceDate ?? DateTime.now();
    final cutoffDate = DateTime(refDate.year, refDate.month, refDate.day, 23, 59, 59, 999);

    double availablePayment = payments.fold(0.0, (sum, p) => sum + p.amount);

    return schedule.map((inst) {
      final instAmount = inst.amount;
      double paidAmount = 0.0;
      String status = 'pending';

      if (availablePayment >= instAmount) {
        paidAmount = instAmount;
        availablePayment -= instAmount;
        status = 'paid';
      } else if (availablePayment > 0) {
        paidAmount = availablePayment;
        availablePayment = 0.0;
        status = 'partial';
      } else {
        paidAmount = 0.0;
      }

      if (status != 'paid') {
        try {
          final due = DateTime.parse(inst.dueDate);
          final dueCutoff = DateTime(due.year, due.month, due.day, 23, 59, 59, 999);
          if (dueCutoff.isBefore(cutoffDate)) {
            status = 'overdue';
          }
        } catch (_) {}
      }

      if (loanStatus == 'rejected') {
        status = 'cancelled';
      } else if (loanStatus == 'defaulted' && status != 'paid') {
        status = 'overdue';
      }

      final remainingAmount = max(0.0, round2(instAmount - paidAmount));

      return inst.copyWith(
        paidAmount: round2(paidAmount),
        remainingAmount: remainingAmount,
        status: status,
      );
    }).toList();
  }

  static LoanStats getLoanStats(Loan loan, [DateTime? referenceDate]) {
    final payments = loan.payments;
    final schedule = loan.schedule;

    final totalPaid = payments.fold(0.0, (sum, p) => sum + p.amount);
    final totalScheduled = schedule.fold(0.0, (sum, s) => sum + s.amount) > 0
        ? schedule.fold(0.0, (sum, s) => sum + s.amount)
        : loan.principal;

    final scheduleWithStatus = getScheduleWithStatus(schedule, payments, loan.status, referenceDate);

    final outstandingBalance = scheduleWithStatus.fold(0.0, (sum, inst) => sum + inst.remainingAmount);

    final overdueAmount = scheduleWithStatus
        .where((inst) => inst.status == 'overdue')
        .fold(0.0, (sum, inst) => sum + inst.remainingAmount);

    final progressPct = totalScheduled > 0
        ? min(100, ((totalPaid / totalScheduled) * 100).round())
        : 0;

    ScheduleInstallment? nextDue;
    try {
      nextDue = scheduleWithStatus.firstWhere(
        (inst) => inst.status == 'pending' || inst.status == 'overdue' || inst.status == 'partial',
      );
    } catch (_) {
      nextDue = null;
    }

    final netDisbursed = calculateNetDisbursed(
      loan.principal,
      loan.upfrontDeductionType,
      loan.upfrontDeductionValue,
    );

    return LoanStats(
      totalDisbursed: netDisbursed,
      totalScheduled: round2(totalScheduled),
      totalPaid: round2(totalPaid),
      outstandingBalance: round2(outstandingBalance),
      overdueAmount: round2(overdueAmount),
      progressPct: progressPct,
      nextDue: nextDue,
      scheduleWithStatus: scheduleWithStatus,
    );
  }

  static CreditAssessment assessBorrower(Borrower borrower, List<Loan> borrowerLoans) {
    final baseCreditScore = borrower.creditScore;
    final monthlyIncome = borrower.monthlyIncome;

    final activeLoans = borrowerLoans.where((l) => l.status == 'active').toList();
    double monthlyDebt = 0.0;

    for (final loan in activeLoans) {
      if (loan.schedule.isNotEmpty) {
        monthlyDebt += loan.schedule[0].amount;
      } else if (loan.principal > 0 && loan.termMonths > 0) {
        monthlyDebt += loan.principal / loan.termMonths;
      }
    }

    final dtiPct = monthlyIncome > 0
        ? ((monthlyDebt / monthlyIncome) * 100).round()
        : (monthlyDebt > 0 ? 100 : 0);

    final completedLoans = borrowerLoans.where((l) => l.status == 'completed').toList();
    final defaultedLoans = borrowerLoans.where((l) => l.status == 'defaulted').toList();

    int scoreAdjustment = 0;
    scoreAdjustment += min(30, completedLoans.length * 10);
    scoreAdjustment -= defaultedLoans.length * 25;

    if (dtiPct > 50) {
      scoreAdjustment -= 15;
    } else if (dtiPct > 35) {
      scoreAdjustment -= 5;
    }

    final derivedScore = max(0, min(100, baseCreditScore + scoreAdjustment));

    String riskRating = 'medium';
    if (derivedScore >= 70 && dtiPct <= 35) {
      riskRating = 'low';
    } else if (derivedScore < 45 || dtiPct > 50 || defaultedLoans.isNotEmpty) {
      riskRating = 'high';
    }

    return CreditAssessment(
      creditScore: derivedScore,
      baseCreditScore: baseCreditScore,
      dtiPct: dtiPct,
      riskRating: riskRating,
      monthlyDebt: round2(monthlyDebt),
      completedCount: completedLoans.length,
      defaultedCount: defaultedLoans.length,
      activeCount: activeLoans.length,
    );
  }
}
