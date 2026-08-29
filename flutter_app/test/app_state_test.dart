import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:microlend/models/loan.dart';
import 'package:microlend/models/payment.dart';
import 'package:microlend/models/schedule_installment.dart';
import 'package:microlend/store/offline_store.dart';
import 'package:microlend/store/app_state.dart';
import 'package:microlend/utils/loan_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppState loan lifecycle, RBAC, race protection & overpayment', () {
    late OfflineStore store;
    late AppState appState;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      store = await OfflineStore.init();
      appState = AppState(store);
      // Login default approver for initial setups
      await appState.login('approver', 'approver123');
    });

    test('RBAC role enforcement and separation of duties', () async {
      // 1. Viewer role cannot create loans
      await appState.login('viewer', 'viewer123');
      final loanCandidate = Loan(
        id: 'viewer_loan',
        borrowerId: 'b1',
        principal: 1000.0,
        interestRate: 10.0,
        termMonths: 6,
        purpose: 'Viewer Loan',
        status: 'pending',
        disbursementDate: '2026-01-01',
        schedule: [],
        payments: [],
        notes: '',
      );
      expect(() => appState.addLoan(loanCandidate), throwsStateError);

      // 2. Officer role CAN create loan
      await appState.login('officer', 'officer123');
      final officerLoan = Loan(
        id: 'officer_loan_1',
        borrowerId: 'b1',
        principal: 2000.0,
        interestRate: 10.0,
        termMonths: 6,
        purpose: 'Officer Created Loan',
        status: 'pending',
        disbursementDate: '2026-01-01',
        schedule: [],
        payments: [],
        notes: '',
      );
      await appState.addLoan(officerLoan);
      expect(appState.loans.any((l) => l.id == 'officer_loan_1'), isTrue);

      // 3. Officer role CANNOT approve loan
      expect(() => appState.approveLoan('officer_loan_1'), throwsStateError);

      // 4. Approver role CAN approve loan created by officer
      await appState.login('approver', 'approver123');
      await appState.approveLoan('officer_loan_1');
      var approvedLoan = appState.loans.firstWhere((l) => l.id == 'officer_loan_1');
      expect(approvedLoan.status, 'active');

      // 5. Approver role CANNOT approve loan created by themselves (separation of duties)
      final approverOwnLoan = Loan(
        id: 'approver_own_loan',
        borrowerId: 'b1',
        principal: 1500.0,
        interestRate: 12.0,
        termMonths: 6,
        purpose: 'Approver Own Loan',
        status: 'pending',
        disbursementDate: '2026-01-01',
        schedule: [],
        payments: [],
        notes: '',
      );
      await appState.addLoan(approverOwnLoan); // createdBy set to 'usr_approver'
      expect(() => appState.approveLoan('approver_own_loan'), throwsStateError);
    });

    test('approving a weekly/flat loan preserves frequency, method, installment count and disbursement date', () async {
      await appState.login('officer', 'officer123');
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

      await appState.login('approver', 'approver123');
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
      await appState.login('officer', 'officer123');
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

      await appState.login('approver', 'approver123');

      // Re-approving active/non-pending loan is rejected
      expect(() => appState.approveLoan('loan_active'), throwsArgumentError);
      expect(() => appState.approveLoan('loan_completed'), throwsArgumentError);

      // Illegal markLoanStatus transitions are rejected
      expect(() => appState.markLoanStatus('loan_pending', 'completed'), throwsArgumentError);
      expect(() => appState.markLoanStatus('loan_pending', 'defaulted'), throwsArgumentError);
      expect(() => appState.markLoanStatus('loan_defaulted', 'completed'), throwsArgumentError);
      expect(() => appState.markLoanStatus('loan_completed', 'active'), throwsArgumentError);
    });

    test('idempotent recordPayment ignores duplicate payment id', () async {
      await appState.login('officer', 'officer123');
      final activeLoan = Loan(
        id: 'loan_idempotent',
        borrowerId: 'b1',
        principal: 1000.0,
        interestRate: 10.0,
        termMonths: 6,
        purpose: 'Idempotence Test',
        status: 'active',
        disbursementDate: '2026-01-01',
        schedule: [],
        payments: [],
        notes: '',
      );
      await appState.addLoan(activeLoan);

      final pay1 = Payment(id: 'unique_pay_123', date: '2026-02-01', amount: 200.0, method: 'Cash', note: 'First');
      await appState.recordPayment('loan_idempotent', pay1);
      var current = appState.loans.firstWhere((l) => l.id == 'loan_idempotent');
      expect(current.payments.length, 1);

      // Re-record exact same payment id
      await appState.recordPayment('loan_idempotent', pay1);
      current = appState.loans.firstWhere((l) => l.id == 'loan_idempotent');
      expect(current.payments.length, 1); // No duplicate added
    });

    test('serialized concurrent store writes preserve data', () async {
      // Fire 10 concurrent addItem operations
      final futures = List.generate(10, (i) {
        return store.addItem('loans', {
          'id': 'concurrent_loan_$i',
          'purpose': 'Concurrent Test $i',
          'principal': 1000.0 + i,
        });
      });

      await Future.wait(futures);

      final allLoans = store.getCollection('loans');
      for (int i = 0; i < 10; i++) {
        expect(allLoans.any((l) => l['id'] == 'concurrent_loan_$i'), isTrue);
      }
    });

    test('completion accounts for penalties and overpayment produces credit balance', () async {
      await appState.login('officer', 'officer123');
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

      // 2nd payment: 100.0 (covers 50.0 penalty + 50.0 overpayment)
      final pay2 = Payment(id: 'p2', date: '2026-01-02', amount: 100.0, method: 'Cash', note: '');
      await appState.recordPayment('loan_penalty_1', pay2);

      updatedLoan = appState.loans.firstWhere((l) => l.id == 'loan_penalty_1');
      expect(updatedLoan.status, 'completed');

      final stats = LoanUtils.getLoanStats(updatedLoan);
      expect(stats.creditBalance, 100.0);
    });
  });
}
