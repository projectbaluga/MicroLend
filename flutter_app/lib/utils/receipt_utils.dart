import '../models/borrower.dart';
import '../models/loan.dart';
import '../models/payment.dart';
import 'loan_utils.dart';

class ReceiptUtils {
  static String generatePaymentReceipt({
    required String businessName,
    required Borrower borrower,
    required Loan loan,
    required Payment payment,
    required double runningOutstandingBalance,
    String? currencyCode,
  }) {
    final cur = currencyCode ?? LoanUtils.defaultCurrencyCode;
    final buffer = StringBuffer();

    buffer.writeln('========================================');
    buffer.writeln('           OFFICIAL RECEIPT            ');
    buffer.writeln('========================================');
    buffer.writeln(businessName.isNotEmpty ? businessName.toUpperCase() : 'MICROLEND SUITE');
    buffer.writeln('----------------------------------------');
    buffer.writeln('Receipt Ref: ${payment.id}');
    buffer.writeln('Date: ${LoanUtils.formatDate(payment.date)}');
    buffer.writeln('Borrower: ${borrower.fullName}');
    buffer.writeln('Loan ID: ${loan.id}');
    buffer.writeln('Purpose: ${loan.purpose}');
    buffer.writeln('----------------------------------------');
    buffer.writeln('Amount Paid: ${LoanUtils.formatCurrency(payment.amount, cur)}');
    buffer.writeln('Payment Method: ${payment.method}');
    if (payment.note.isNotEmpty) {
      buffer.writeln('Note: ${payment.note}');
    }
    buffer.writeln('----------------------------------------');
    buffer.writeln('Remaining Balance: ${LoanUtils.formatCurrency(runningOutstandingBalance, cur)}');
    buffer.writeln('========================================');
    buffer.writeln('       Thank you for your payment!      ');
    buffer.writeln('========================================');

    return buffer.toString();
  }

  static String generateStatementOfAccount({
    required String businessName,
    required Borrower borrower,
    required Loan loan,
    required LoanStats stats,
    String? currencyCode,
  }) {
    final cur = currencyCode ?? LoanUtils.defaultCurrencyCode;
    final buffer = StringBuffer();

    buffer.writeln('========================================');
    buffer.writeln('       STATEMENT OF ACCOUNT (SOA)       ');
    buffer.writeln('========================================');
    buffer.writeln(businessName.isNotEmpty ? businessName.toUpperCase() : 'MICROLEND SUITE');
    buffer.writeln('Date Generated: ${LoanUtils.formatDate(DateTime.now().toIso8601String().split('T')[0])}');
    buffer.writeln('----------------------------------------');
    buffer.writeln('BORROWER DETAILS:');
    buffer.writeln('Name: ${borrower.fullName}');
    buffer.writeln('Contact: ${borrower.phone.isNotEmpty ? borrower.phone : borrower.email}');
    buffer.writeln('Address: ${borrower.address.isNotEmpty ? borrower.address : "N/A"}');
    buffer.writeln('----------------------------------------');
    buffer.writeln('LOAN DETAILS:');
    buffer.writeln('Loan ID: ${loan.id}');
    buffer.writeln('Purpose: ${loan.purpose}');
    buffer.writeln('Principal: ${LoanUtils.formatCurrency(loan.principal, cur)}');
    buffer.writeln('Interest Rate: ${loan.interestRate}%');
    buffer.writeln('Frequency: ${loan.repaymentFrequency.toUpperCase()}');
    buffer.writeln('Interest Method: ${loan.interestMethod.replaceAll('_', ' ').toUpperCase()}');
    buffer.writeln('Disbursement Date: ${LoanUtils.formatDate(loan.disbursementDate)}');
    buffer.writeln('Status: ${loan.status.toUpperCase()}');
    buffer.writeln('----------------------------------------');
    buffer.writeln('AMORTIZATION SCHEDULE:');
    buffer.writeln('#   Due Date     Amount     Status');

    for (final inst in stats.scheduleWithStatus) {
      final noStr = inst.installmentNo.toString().padRight(3);
      final dateStr = LoanUtils.formatDate(inst.dueDate, 'yyyy-MM-dd').padRight(12);
      final amtStr = LoanUtils.formatCurrency(inst.amount, cur).padRight(10);
      final statusStr = inst.status.toUpperCase();
      buffer.writeln('$noStr $dateStr $amtStr $statusStr');
    }

    buffer.writeln('----------------------------------------');
    buffer.writeln('SUMMARY:');
    buffer.writeln('Total Scheduled:     ${LoanUtils.formatCurrency(stats.totalScheduled, cur)}');
    buffer.writeln('Total Paid:          ${LoanUtils.formatCurrency(stats.totalPaid, cur)}');
    buffer.writeln('Outstanding Balance: ${LoanUtils.formatCurrency(stats.outstandingBalance, cur)}');
    if (stats.penaltyAmount > 0) {
      buffer.writeln('Penalty Amount:      ${LoanUtils.formatCurrency(stats.penaltyAmount, cur)}');
      buffer.writeln('TOTAL DUE WITH PENALTY: ${LoanUtils.formatCurrency(stats.totalDueWithPenalty, cur)}');
    } else {
      buffer.writeln('TOTAL DUE:           ${LoanUtils.formatCurrency(stats.outstandingBalance, cur)}');
    }
    buffer.writeln('========================================');

    return buffer.toString();
  }
}
