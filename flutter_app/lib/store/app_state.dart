import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/borrower.dart';
import '../models/loan.dart';
import '../models/payment.dart';
import '../utils/loan_utils.dart';
import 'offline_store.dart';

class AppState extends ChangeNotifier {
  final OfflineStore store;

  late String _currencyCode;
  late String _dateFormat;
  late int _defaultTermMonths;
  late double _defaultInterestRate;
  late ThemeMode _themeMode;

  AppState(this.store) {
    _loadSettings();
  }

  void _loadSettings() {
    _currencyCode = store.getSetting('currencyCode', 'USD');
    _dateFormat = store.getSetting('dateFormat', 'MMM d, yyyy');
    _defaultTermMonths = int.tryParse(store.getSetting('defaultTermMonths', '6')) ?? 6;
    _defaultInterestRate = double.tryParse(store.getSetting('defaultInterestRate', '12.0')) ?? 12.0;

    LoanUtils.defaultCurrencyCode = _currencyCode;
    LoanUtils.defaultDateFormat = _dateFormat;

    final savedTheme = store.getSetting('themeMode', 'dark');
    _themeMode = savedTheme == 'light' ? ThemeMode.light : ThemeMode.dark;
  }

  String get currencyCode => _currencyCode;
  String get dateFormat => _dateFormat;
  int get defaultTermMonths => _defaultTermMonths;
  double get defaultInterestRate => _defaultInterestRate;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> setCurrencyCode(String code) async {
    _currencyCode = code;
    LoanUtils.defaultCurrencyCode = code;
    await store.setSetting('currencyCode', code);
    notifyListeners();
  }

  Future<void> setDateFormat(String format) async {
    _dateFormat = format;
    LoanUtils.defaultDateFormat = format;
    await store.setSetting('dateFormat', format);
    notifyListeners();
  }

  Future<void> setDefaultTermMonths(int months) async {
    _defaultTermMonths = months;
    await store.setSetting('defaultTermMonths', months.toString());
    notifyListeners();
  }

  Future<void> setDefaultInterestRate(double rate) async {
    _defaultInterestRate = rate;
    await store.setSetting('defaultInterestRate', rate.toString());
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await store.setSetting('themeMode', mode == ThemeMode.light ? 'light' : 'dark');
    notifyListeners();
  }

  void toggleTheme() {
    setThemeMode(isDarkMode ? ThemeMode.light : ThemeMode.dark);
  }

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

  String exportDataJson() {
    final data = {
      'borrowers': store.getCollection('borrowers'),
      'loans': store.getCollection('loans'),
      'exportedAt': DateTime.now().toIso8601String(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<void> importDataJson(String jsonStr) async {
    final decoded = jsonDecode(jsonStr);
    if (decoded is! Map<String, dynamic> ||
        !decoded.containsKey('borrowers') ||
        !decoded.containsKey('loans') ||
        decoded['borrowers'] is! List ||
        decoded['loans'] is! List) {
      throw const FormatException('Invalid backup file format: missing borrowers or loans data.');
    }

    final List borrowersList = decoded['borrowers'];
    final List loansList = decoded['loans'];

    final borrowers = borrowersList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final loans = loansList.map((e) => Map<String, dynamic>.from(e as Map)).toList();

    await store.saveCollection('borrowers', borrowers);
    await store.saveCollection('loans', loans);
    notifyListeners();
  }

  Future<void> clearAllData() async {
    await store.clearAllData();
    notifyListeners();
  }

  Future<void> restoreSampleData() async {
    await store.seedInitialData(force: true);
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
