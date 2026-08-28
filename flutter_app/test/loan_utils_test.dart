import 'package:flutter_test/flutter_test.dart';
import 'package:microlend/models/borrower.dart';
import 'package:microlend/models/loan.dart';
import 'package:microlend/models/payment.dart';
import 'package:microlend/models/schedule_installment.dart';
import 'package:microlend/utils/loan_utils.dart';

void main() {
  group('LoanUtils Formatting', () {
    test('formatCurrency returns formatted string with selected currency symbol', () {
      expect(LoanUtils.formatCurrency(1250.5, 'USD'), '\$1,250.50');
      expect(LoanUtils.formatCurrency(1250.5, 'EUR'), '€1,250.50');
      expect(LoanUtils.formatCurrency(1250.5, 'PHP'), '₱1,250.50');
      expect(LoanUtils.formatCurrency(1250.5, 'GBP'), '£1,250.50');
      expect(LoanUtils.formatCurrency(0.0), '\$0.00');
    });

    test('formatDate formats date properly', () {
      expect(LoanUtils.formatDate('2025-01-15'), 'Jan 15, 2025');
      expect(LoanUtils.formatDate(''), 'N/A');
    });

    test('formatPercent formats percentage string', () {
      expect(LoanUtils.formatPercent(12.5), '12.5%');
    });
  });

  group('LoanUtils Upfront Deduction', () {
    test('calculates upfront deduction correctly for percent and fixed types', () {
      expect(LoanUtils.calculateUpfrontDeduction(1000.0, 'none', 50.0), 0.0);
      expect(LoanUtils.calculateUpfrontDeduction(1000.0, 'fixed', 50.0), 50.0);
      expect(LoanUtils.calculateUpfrontDeduction(1000.0, 'percent', 5.0), 50.0);
      expect(LoanUtils.calculateUpfrontDeduction(1000.0, 'fixed', 1500.0), 1000.0);
    });

    test('calculates net disbursed correctly', () {
      expect(LoanUtils.calculateNetDisbursed(1000.0, 'none', 0.0), 1000.0);
      expect(LoanUtils.calculateNetDisbursed(1000.0, 'fixed', 50.0), 950.0);
      expect(LoanUtils.calculateNetDisbursed(1000.0, 'percent', 2.5), 975.0);
    });

    test('getLoanStats uses net disbursed for totalDisbursed', () {
      final loan = Loan(
        id: 'l1',
        borrowerId: 'b1',
        principal: 1000.0,
        interestRate: 12.0,
        termMonths: 12,
        purpose: 'Test',
        status: 'active',
        disbursementDate: '2025-01-01',
        upfrontDeductionType: 'percent',
        upfrontDeductionValue: 5.0,
        schedule: [],
        payments: [],
        notes: '',
      );

      final stats = LoanUtils.getLoanStats(loan);
      expect(stats.totalDisbursed, 950.0);
    });
  });

  group('LoanUtils.generateSchedule', () {
    test('generates 12 month amortizing loan schedule correctly', () {
      final schedule = LoanUtils.generateSchedule(1000.0, 12.0, 12, '2025-01-01');
      expect(schedule.length, 12);
      expect(schedule[0].dueDate, '2025-02-01');
      expect(schedule[0].amount, greaterThan(0.0));
      expect(schedule[11].balance, 0.0);
    });

    test('handles 0% interest rate gracefully', () {
      final schedule = LoanUtils.generateSchedule(1200.0, 0.0, 12, '2025-01-01');
      expect(schedule.length, 12);
      expect(schedule[0].amount, 100.0);
      expect(schedule[0].interest, 0.0);
      expect(schedule[11].balance, 0.0);
    });
  });

  group('LoanUtils.getScheduleWithStatus', () {
    test('marks installments as paid or partial based on payments', () {
      final schedule = [
        ScheduleInstallment(installmentNo: 1, dueDate: '2025-02-01', amount: 100.0, principal: 90.0, interest: 10.0, balance: 900.0),
        ScheduleInstallment(installmentNo: 2, dueDate: '2025-03-01', amount: 100.0, principal: 91.0, interest: 9.0, balance: 809.0),
      ];
      final payments = [Payment(id: 'p1', date: '2025-01-10', amount: 150.0, method: 'Cash', note: '')];
      final result = LoanUtils.getScheduleWithStatus(schedule, payments, 'active', DateTime.parse('2025-01-15'));

      expect(result[0].status, 'paid');
      expect(result[0].paidAmount, 100.0);
      expect(result[1].status, 'partial');
      expect(result[1].paidAmount, 50.0);
      expect(result[1].remainingAmount, 50.0);
    });
  });

  group('LoanUtils.assessBorrower', () {
    test('calculates credit score, DTI and risk rating', () {
      final borrower = Borrower(
        id: 'b1',
        fullName: 'Elena',
        email: '',
        phone: '',
        address: '',
        idNumber: '',
        employment: '',
        monthlyIncome: 4000.0,
        creditScore: 80,
        riskRating: 'low',
        notes: '',
      );
      final loans = [
        Loan(
          id: 'l1',
          borrowerId: 'b1',
          principal: 1000.0,
          interestRate: 10.0,
          termMonths: 12,
          purpose: 'Test',
          status: 'active',
          disbursementDate: '2025-01-01',
          schedule: [ScheduleInstallment(installmentNo: 1, dueDate: '2025-02-01', amount: 400.0, principal: 390.0, interest: 10.0, balance: 600.0)],
          payments: [],
          notes: '',
        ),
      ];

      final assessment = LoanUtils.assessBorrower(borrower, loans);
      expect(assessment.dtiPct, 10);
      expect(assessment.riskRating, 'low');
    });
  });
}
