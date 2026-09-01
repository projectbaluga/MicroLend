import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:microlend/models/borrower.dart';
import 'package:microlend/models/loan.dart';
import 'package:microlend/store/app_state.dart';
import 'package:microlend/store/offline_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Creation feedback & persistence tests', () {
    late OfflineStore store;
    late AppState appState;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      store = await OfflineStore.init();
      appState = AppState(store);
      await appState.login('admin', 'admin123');
    });

    test('addBorrower persists borrower item', () async {
      final newBorrower = Borrower(
        id: 'bor_test_unit',
        fullName: 'Test Unit Borrower',
        email: 'unit@example.com',
        phone: '123456',
        address: '123 St',
        idNumber: 'ID-123',
        employment: 'Engineer',
        monthlyIncome: 4000.0,
        creditScore: 80,
        riskRating: 'low',
        notes: '',
        createdAt: '2026-01-01',
      );

      await appState.addBorrower(newBorrower);

      expect(appState.borrowers.any((b) => b.id == 'bor_test_unit'), isTrue);
    });

    test('addLoan persists loan item', () async {
      final newLoan = Loan(
        id: 'loan_test_unit',
        borrowerId: 'b1',
        principal: 2500.0,
        interestRate: 12.0,
        termMonths: 6,
        purpose: 'Unit Test Loan',
        status: 'pending',
        disbursementDate: '2026-01-01',
        schedule: [],
        payments: [],
        notes: '',
      );

      await appState.addLoan(newLoan);

      expect(appState.loans.any((l) => l.id == 'loan_test_unit'), isTrue);
    });
  });
}
