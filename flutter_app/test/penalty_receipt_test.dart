import 'package:flutter_test/flutter_test.dart';
import 'package:microlend/models/borrower.dart';
import 'package:microlend/models/loan.dart';
import 'package:microlend/models/payment.dart';
import 'package:microlend/models/schedule_installment.dart';
import 'package:microlend/utils/loan_utils.dart';
import 'package:microlend/utils/receipt_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Penalty & Receipt Unit Tests', () {
    test('calculatePenalty calculates fixed_per_period penalty correctly', () {
      final loan = Loan(
        id: 'test_loan_1',
        borrowerId: 'bor_1',
        principal: 1000.0,
        interestRate: 10.0,
        termMonths: 2,
        purpose: 'Test',
        status: 'active',
        disbursementDate: '2026-01-01',
        penaltyType: 'fixed_per_period',
        penaltyValue: 50.0,
        schedule: [
          ScheduleInstallment(installmentNo: 1, dueDate: '2020-01-01', amount: 500.0, principal: 500.0, interest: 0.0, balance: 500.0),
          ScheduleInstallment(installmentNo: 2, dueDate: '2020-02-01', amount: 500.0, principal: 500.0, interest: 0.0, balance: 0.0),
        ],
        payments: [],
        notes: '',
      );

      final stats = LoanUtils.getLoanStats(loan, DateTime(2026, 1, 1));
      expect(stats.penaltyAmount, 100.0); // 2 overdue installments * 50 = 100
      expect(stats.totalDueWithPenalty, 1100.0);
    });

    test('calculatePenalty calculates percent_per_period penalty correctly', () {
      final loan = Loan(
        id: 'test_loan_2',
        borrowerId: 'bor_1',
        principal: 1000.0,
        interestRate: 10.0,
        termMonths: 1,
        purpose: 'Test',
        status: 'active',
        disbursementDate: '2026-01-01',
        penaltyType: 'percent_per_period',
        penaltyValue: 5.0, // 5% of remaining amount
        schedule: [
          ScheduleInstallment(installmentNo: 1, dueDate: '2020-01-01', amount: 1000.0, principal: 1000.0, interest: 0.0, balance: 0.0),
        ],
        payments: [],
        notes: '',
      );

      final stats = LoanUtils.getLoanStats(loan, DateTime(2026, 1, 1));
      expect(stats.penaltyAmount, 50.0); // 5% of 1000 = 50
      expect(stats.totalDueWithPenalty, 1050.0);
    });

    test('Loan.fromMap maintains backward compatibility when penalty fields are missing', () {
      final oldMap = {
        'id': 'loan_old',
        'borrower_id': 'bor_1',
        'principal': 2000.0,
        'interest_rate': 12.0,
        'term_months': 6,
        'purpose': 'Old Loan',
        'status': 'active',
        'disbursement_date': '2026-01-01',
        'notes': '',
      };

      final loan = Loan.fromMap(oldMap);
      expect(loan.penaltyType, 'none');
      expect(loan.penaltyValue, 0.0);
    });

    test('ReceiptUtils generates formatted receipt text', () {
      final borrower = Borrower(
        id: 'bor_1',
        fullName: 'Juan Dela Cruz',
        email: 'juan@example.com',
        phone: '09171234567',
        address: 'Manila',
        idNumber: 'ID123',
        employment: 'Self-employed',
        monthlyIncome: 15000.0,
        creditScore: 80,
        riskRating: 'low',
        notes: '',
      );

      final loan = Loan(
        id: 'loan_1',
        borrowerId: 'bor_1',
        principal: 5000.0,
        interestRate: 10.0,
        termMonths: 5,
        purpose: 'Sari-Sari Store Capital',
        status: 'active',
        disbursementDate: '2026-01-01',
        schedule: [],
        payments: [],
        notes: '',
      );

      final payment = Payment(
        id: 'pay_1',
        date: '2026-02-01',
        amount: 1000.0,
        method: 'GCash',
        note: 'Partial payment',
      );

      final receipt = ReceiptUtils.generatePaymentReceipt(
        businessName: 'Pinoy MicroLending',
        borrower: borrower,
        loan: loan,
        payment: payment,
        runningOutstandingBalance: 4000.0,
        currencyCode: 'PHP',
      );

      expect(receipt, contains('OFFICIAL RECEIPT'));
      expect(receipt, contains('PINOY MICROLENDING'));
      expect(receipt, contains('Juan Dela Cruz'));
      expect(receipt, contains('₱1,000.00'));
      expect(receipt, contains('GCash'));
    });
  });
}
