import 'package:flutter/foundation.dart';
import '../models/borrower.dart';
import '../models/loan.dart';
import '../models/payment.dart';
import '../utils/loan_utils.dart';
import 'offline_store.dart';

class AppState extends ChangeNotifier {
  final OfflineStore store;
  bool isDarkMode = true;
  bool isSyncing = false;

  AppState(this.store);

  List<Borrower> get borrowers {
    return store
        .getCollection('borrowers')
        .map((e) => Borrower.fromMap(e))
        .toList();
  }

  List<Loan> get loans {
    return store
        .getCollection('loans')
        .map((e) => Loan.fromMap(e))
        .toList();
  }

  int get pendingQueueCount => store.getQueue().length;

  void toggleTheme() {
    isDarkMode = !isDarkMode;
    notifyListeners();
  }

  Future<void> syncOfflineQueue() async {
    isSyncing = true;
    notifyListeners();
    await store.syncAll();
    isSyncing = false;
    notifyListeners();
  }

  Future<void> addBorrower(Borrower borrower) async {
    await store.addItem('borrowers', borrower.toMap());
    notifyListeners();
  }

  Future<void> updateBorrower(String id, Map<String, dynamic> updates) async {
    await store.updateItem('borrowers', id, updates);
    notifyListeners();
  }

  Future<void> deleteBorrower(String id) async {
    await store.deleteItem('borrowers', id);
    notifyListeners();
  }

  Future<void> addLoan(Loan loan) async {
    await store.addItem('loans', loan.toMap());
    notifyListeners();
  }

  Future<void> updateLoan(String id, Map<String, dynamic> updates) async {
    await store.updateItem('loans', id, updates);
    notifyListeners();
  }

  Future<void> approveLoan(String loanId) async {
    final loan = loans.firstWhere((l) => l.id == loanId);
    final todayStr = DateTime.now().toIso8601String().split('T')[0];
    final updatedSchedule = LoanUtils.generateSchedule(
      loan.principal,
      loan.interestRate,
      loan.termMonths,
      todayStr,
    );

    await store.updateItem('loans', loanId, {
      'status': 'active',
      'disbursement_date': todayStr,
      'schedule': updatedSchedule.map((e) => e.toMap()).toList(),
    });
    notifyListeners();
  }

  Future<void> markLoanStatus(String loanId, String status) async {
    await store.updateItem('loans', loanId, {'status': status});
    notifyListeners();
  }

  Future<void> recordPayment(String loanId, Payment payment) async {
    final loan = loans.firstWhere((l) => l.id == loanId);
    final updatedPayments = [...loan.payments, payment];

    final stats = LoanUtils.getLoanStats(loan);
    final totalPaidNow = updatedPayments.fold(0.0, (s, p) => s + p.amount);

    String newStatus = loan.status;
    if (totalPaidNow >= stats.totalScheduled && loan.status == 'active') {
      newStatus = 'completed';
    }

    await store.updateItem('loans', loanId, {
      'payments': updatedPayments.map((p) => p.toMap()).toList(),
      'status': newStatus,
    });
    notifyListeners();
  }
}
