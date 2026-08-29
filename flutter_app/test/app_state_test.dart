import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:microlend/models/loan.dart';
import 'package:microlend/models/payment.dart';
import 'package:microlend/models/schedule_installment.dart';
import 'package:microlend/store/offline_store.dart';
import 'package:microlend/store/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppState loan lifecycle and status validation', () {
    late OfflineStore store;
    late AppState appState;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      store = await OfflineStore.init();
      appState = AppState(store);
    });

    test('approving a weekly/flat loan preserves frequency, method, installment count and disbursement date', () async {
      final pendingLoan = Loan(
        id: 'weekly_flat_1',
        borrowerId: 'b1',
        principal: 1000.0,
        interestRate: 20.0,
        termMonths: 0,
        repaymentFrequency: 'weekly',
        interestMethod: 'flat',
        termCount: 10,
        purpose: 'Inventory',
        status: 'pending',
        disbursementDate: '2026-02-01',
        schedule: [],
        payments: [],
        notes: '',
      );

      await appState.addLoan(pendingLoan);
      await appState.approveLoan(pendingLoan.id);

      final approved = appState.loans.firstWhere((l) => l.id == pendingLoan.id);
      expect(approved.status, 'active');
      expect(approved.repaymentFrequency, 'weekly');
      expect(approved.interestMethod, 'flat');
      expect(approved.termCount, 10);
      expect(approved.disbursementDate, '2026-02-01');
      expect(approved.schedule.length, 10);
    });

    test('illegal status transitions are rejected', () async {
      final pendingLoan = Loan(
        id: 'loan_pending',
        borrowerId: 'b1',
        principal: 1000.0,
        interestRate: 10.0,
        termMonths: 6,
        purpose: 'Test',
        status: 'pending',
        disbursementDate: '2026-01-01',
        schedule: [],
        payments: [],
        notes: '',
      );
      final activeLoan = Loan(
        id: 'loan_active',
        borrowerId: 'b1',
        principal: 1000.0,
        interestRate: 10.0,
        termMonths: 6,
        purpose: 'Test',
        status: 'active',
        disbursementDate: '2026-01-01',
        schedule: [],
        payments: [],
        notes: '',
      );
      final completedLoan = Loan(
        id: 'loan_completed',
        borrowerId: 'b1',
        principal: 1000.0,
        interestRate: 10.0,
        termMonths: 6,
        purpose: 'Test',
        status: 'completed',
        disbursementDate: '2026-01-01',
        schedule: [],
        payments: [],
        notes: '',
      );
      final defaultedLoan = Loan(
        id: 'loan_defaulted',
        borrowerId: 'b1',
        principal: 1000.0,
        interestRate: 10.0,
        termMonths: 6,
        purpose: 'Test',
        status: 'defaulted',
        disbursementDate: '2026-01-01',
        schedule: [],
        payments: [],
        notes: '',
      );

      await appState.addLoan(pendingLoan);
      await appState.addLoan(activeLoan);
      await appState.addLoan(completedLoan);
      await appState.addLoan(defaultedLoan);

      // Re-approving active/non-pending loan is rejected
      expect(() => appState.approveLoan('loan_active'), throwsArgumentError);
      expect(() => appState.approveLoan('loan_completed'), throwsArgumentError);

      // Illegal markLoanStatus transitions are rejected
      expect(() => appState.markLoanStatus('loan_pending', 'completed'), throwsArgumentError);
      expect(() => appState.markLoanStatus('loan_pending', 'defaulted'), throwsArgumentError);
      expect(() => appState.markLoanStatus('loan_defaulted', 'completed'), throwsArgumentError);
      expect(() => appState.markLoanStatus('loan_completed', 'active'), throwsArgumentError);
    });

    test('completion accounts for penalties', () async {
      final oldDueDate = '2020-01-01'; // Overdue date to trigger penalty
      final schedule = [
        ScheduleInstallment(
          installmentNo: 1,
          dueDate: oldDueDate,
          amount: 500.0,
          principal: 450.0,
          interest: 50.0,
          balance: 0.0,
        ),
      ];

      final loanWithPenalty = Loan(
        id: 'loan_penalty_1',
        borrowerId: 'b1',
        principal: 450.0,
        interestRate: 10.0,
        termMonths: 1,
        purpose: 'Test Penalty Completion',
        status: 'active',
        disbursementDate: '2019-12-01',
        penaltyType: 'fixed_once',
        penaltyValue: 50.0,
        schedule: schedule,
        payments: [],
        notes: '',
      );

      await appState.addLoan(loanWithPenalty);

      // Total scheduled is 500.0, penalty is 50.0, total required for completion is 550.0.
      // 1st payment: 500.0 (covers scheduled amount only)
      final pay1 = Payment(id: 'p1', date: '2026-01-01', amount: 500.0, method: 'Cash', note: '');
      await appState.recordPayment('loan_penalty_1', pay1);

      var updatedLoan = appState.loans.firstWhere((l) => l.id == 'loan_penalty_1');
      expect(updatedLoan.status, 'active');

      // 2nd payment: 50.0 (covers remaining penalty)
      final pay2 = Payment(id: 'p2', date: '2026-01-02', amount: 50.0, method: 'Cash', note: '');
      await appState.recordPayment('loan_penalty_1', pay2);

      updatedLoan = appState.loans.firstWhere((l) => l.id == 'loan_penalty_1');
      expect(updatedLoan.status, 'completed');
    });
  });
}
