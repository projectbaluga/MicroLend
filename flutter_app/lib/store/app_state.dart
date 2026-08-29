import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/borrower.dart';
import '../models/loan.dart';
import '../models/payment.dart';
import '../models/user.dart';
import '../utils/loan_utils.dart';
import 'offline_store.dart';

class AppState extends ChangeNotifier {
  static const Map<String, List<String>> _allowedTransitions = {
    'pending': ['active', 'rejected'],
    'active': ['completed', 'defaulted'],
    'completed': [],
    'defaulted': [],
    'rejected': [],
  };

  final OfflineStore store;

  User? _currentUser;
  late String _currencyCode;
  late String _dateFormat;
  late String _businessName;
  late int _defaultTermMonths;
  late double _defaultInterestRate;
  late String _defaultRepaymentFrequency;
  late String _defaultInterestMethod;
  late String _defaultPenaltyType;
  late double _defaultPenaltyValue;
  late ThemeMode _themeMode;

  AppState(this.store) {
    _loadSettings();
  }

  void _loadSettings() {
    _currencyCode = store.getSetting('currencyCode', 'PHP');
    _dateFormat = store.getSetting('dateFormat', 'MMM d, yyyy');
    _businessName = store.getSetting('businessName', 'MicroLend Suite');
    _defaultTermMonths = int.tryParse(store.getSetting('defaultTermMonths', '6')) ?? 6;
    _defaultInterestRate = double.tryParse(store.getSetting('defaultInterestRate', '12.0')) ?? 12.0;
    _defaultRepaymentFrequency = store.getSetting('defaultRepaymentFrequency', 'monthly');
    _defaultInterestMethod = store.getSetting('defaultInterestMethod', 'reducing');
    _defaultPenaltyType = store.getSetting('defaultPenaltyType', 'none');
    _defaultPenaltyValue = double.tryParse(store.getSetting('defaultPenaltyValue', '0.0')) ?? 0.0;

    LoanUtils.defaultCurrencyCode = _currencyCode;
    LoanUtils.defaultDateFormat = _dateFormat;

    final savedTheme = store.getSetting('themeMode', 'dark');
    _themeMode = savedTheme == 'light' ? ThemeMode.light : ThemeMode.dark;

    final sessionUserId = store.getSetting('session_user_id', '');
    if (sessionUserId.isNotEmpty) {
      final userMaps = store.getCollection('users');
      final match = userMaps.where((m) => m['id'] == sessionUserId).toList();
      if (match.isNotEmpty) {
        _currentUser = User.fromMap(match.first);
      }
    }
  }

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  Future<bool> login(String username, String password) async {
    final userMaps = store.getCollection('users');
    final users = userMaps.map((e) => User.fromMap(e)).toList();
    final match = users.where((u) => u.username.toLowerCase() == username.trim().toLowerCase()).toList();
    if (match.isEmpty) return false;

    final user = match.first;
    if (user.verifyPassword(password.trim())) {
      _currentUser = user;
      await store.setSetting('session_user_id', user.id);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    _currentUser = null;
    await store.setSetting('session_user_id', '');
    notifyListeners();
  }

  String get currencyCode => _currencyCode;
  String get dateFormat => _dateFormat;
  String get businessName => _businessName;
  int get defaultTermMonths => _defaultTermMonths;
  double get defaultInterestRate => _defaultInterestRate;
  String get defaultRepaymentFrequency => _defaultRepaymentFrequency;
  String get defaultInterestMethod => _defaultInterestMethod;
  String get defaultPenaltyType => _defaultPenaltyType;
  double get defaultPenaltyValue => _defaultPenaltyValue;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> setBusinessName(String name) async {
    _businessName = name;
    await store.setSetting('businessName', name);
    notifyListeners();
  }

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

  Future<void> setDefaultRepaymentFrequency(String freq) async {
    _defaultRepaymentFrequency = freq;
    await store.setSetting('defaultRepaymentFrequency', freq);
    notifyListeners();
  }

  Future<void> setDefaultInterestMethod(String method) async {
    _defaultInterestMethod = method;
    await store.setSetting('defaultInterestMethod', method);
    notifyListeners();
  }

  Future<void> setDefaultPenaltyType(String type) async {
    _defaultPenaltyType = type;
    await store.setSetting('defaultPenaltyType', type);
    notifyListeners();
  }

  Future<void> setDefaultPenaltyValue(double value) async {
    _defaultPenaltyValue = value;
    await store.setSetting('defaultPenaltyValue', value.toString());
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
    if (_currentUser == null || _currentUser!.role == 'viewer') {
      throw StateError('Unauthorized: Role "${_currentUser?.role ?? "unauthenticated"}" cannot create loans.');
    }
    final loanToSave = loan.createdBy == null
        ? loan.copyWith(createdBy: _currentUser!.id)
        : loan;
    await store.addItem('loans', loanToSave.toMap());
    notifyListeners();
  }

  Future<void> updateLoan(String id, Map<String, dynamic> updates) async {
    await store.updateItem('loans', id, updates);
    notifyListeners();
  }

  Future<void> approveLoan(String loanId) async {
    if (_currentUser == null || _currentUser!.role != 'approver') {
      throw StateError('Unauthorized: Only approvers can approve loans.');
    }

    final loan = loans.firstWhere((l) => l.id == loanId);
    if (loan.status != 'pending') {
      throw ArgumentError('Cannot approve loan with status "${loan.status}". Only pending loans can be approved.');
    }

    if (loan.createdBy != null && loan.createdBy == _currentUser!.id) {
      throw StateError('Unauthorized: Separation of duties violation. Loan creator cannot approve their own loan.');
    }

    final disbursementDate = loan.disbursementDate.isNotEmpty
        ? loan.disbursementDate
        : DateTime.now().toIso8601String().split('T')[0];

    final updatedSchedule = loan.schedule.isNotEmpty
        ? loan.schedule
        : LoanUtils.generateSchedule(
            loan.principal,
            loan.interestRate,
            loan.termCount,
            disbursementDate,
            repaymentFrequency: loan.repaymentFrequency,
            interestMethod: loan.interestMethod,
          );

    await store.updateItem('loans', loanId, {
      'status': 'active',
      'disbursement_date': disbursementDate,
      'schedule': updatedSchedule.map((e) => e.toMap()).toList(),
    });
    notifyListeners();
  }

  Future<void> markLoanStatus(String loanId, String status) async {
    if (_currentUser == null || _currentUser!.role != 'approver') {
      throw StateError('Unauthorized: Only approvers can change loan status.');
    }

    final loan = loans.firstWhere((l) => l.id == loanId);
    final allowed = _allowedTransitions[loan.status] ?? [];
    if (!allowed.contains(status)) {
      throw ArgumentError('Cannot transition loan status from "${loan.status}" to "$status".');
    }
    await store.updateItem('loans', loanId, {'status': status});
    notifyListeners();
  }

  Future<void> recordPayment(String loanId, Payment payment) async {
    if (_currentUser == null || (_currentUser!.role != 'officer' && _currentUser!.role != 'approver')) {
      throw StateError('Unauthorized: Role "${_currentUser?.role ?? "unauthenticated"}" cannot record payments.');
    }

    final loan = loans.firstWhere((l) => l.id == loanId);
    if (loan.payments.any((p) => p.id == payment.id)) {
      // Idempotent: payment already recorded
      return;
    }

    final updatedPayments = [...loan.payments, payment];

    final stats = LoanUtils.getLoanStats(loan);
    final totalPaidNow = updatedPayments.fold(0.0, (s, p) => s + p.amount);
    final totalRequired = LoanUtils.round2(stats.totalScheduled + stats.penaltyAmount);

    String newStatus = loan.status;
    if (totalPaidNow >= totalRequired && loan.status == 'active') {
      newStatus = 'completed';
    }

    await store.updateItem('loans', loanId, {
      'payments': updatedPayments.map((p) => p.toMap()).toList(),
      'status': newStatus,
    });
    notifyListeners();
  }
}
