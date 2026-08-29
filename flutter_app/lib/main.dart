import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/borrower_detail_screen.dart';
import 'screens/borrowers_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/loan_detail_screen.dart';
import 'screens/loans_screen.dart';
import 'screens/login_screen.dart';
import 'screens/settings_screen.dart';
import 'store/app_state.dart';
import 'store/offline_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final offlineStore = await OfflineStore.init();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(offlineStore),
      child: const MicroLendApp(),
    ),
  );
}

const String _envAppName = String.fromEnvironment('APP_NAME', defaultValue: 'MicroLend');
final String appTitle = _envAppName.trim().isEmpty ? 'MicroLend' : _envAppName;

class MicroLendApp extends StatelessWidget {
  const MicroLendApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);

    return MaterialApp(
      title: appTitle,
      debugShowCheckedModeBanner: false,
      themeMode: state.themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFFAFAFA),
        colorScheme: const ColorScheme.light(
          surface: Colors.white,
          primary: Color(0xFF18181B),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF09090B),
        colorScheme: const ColorScheme.dark(
          surface: Color(0xFF18181B),
          primary: Colors.white,
        ),
      ),
      home: state.isLoggedIn ? const MainShell() : const LoginScreen(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  String? _selectedBorrowerId;
  String? _selectedLoanId;
  String? _issueLoanBorrowerId;

  void _navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
      _selectedBorrowerId = null;
      _selectedLoanId = null;
      _issueLoanBorrowerId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final isDesktop = MediaQuery.of(context).size.width >= 700;

    String title = appTitle;
    if (_selectedLoanId != null) {
      title = 'Loan Details';
    } else if (_selectedBorrowerId != null) {
      title = 'Borrower Profile';
    } else if (_currentIndex == 0) {
      title = 'Dashboard';
    } else if (_currentIndex == 1) {
      title = 'Borrowers';
    } else if (_currentIndex == 2) {
      title = 'Loans';
    } else if (_currentIndex == 3) {
      title = 'Settings';
    }

    Widget content;
    if (_selectedLoanId != null) {
      content = LoanDetailScreen(
        loanId: _selectedLoanId!,
        onBack: () => setState(() => _selectedLoanId = null),
        onSelectBorrower: (id) {
          setState(() {
            _selectedLoanId = null;
            _selectedBorrowerId = id;
          });
        },
      );
    } else if (_selectedBorrowerId != null) {
      content = BorrowerDetailScreen(
        borrowerId: _selectedBorrowerId!,
        onBack: () => setState(() => _selectedBorrowerId = null),
        onSelectLoan: (id) => setState(() => _selectedLoanId = id),
        onCreateLoanForBorrower: (borrowerId) {
          setState(() {
            _selectedBorrowerId = null;
            _issueLoanBorrowerId = borrowerId;
            _currentIndex = 2;
          });
        },
      );
    } else {
      switch (_currentIndex) {
        case 0:
          content = DashboardScreen(
            onSelectLoan: (id) => setState(() => _selectedLoanId = id),
            onSelectBorrower: (id) => setState(() => _selectedBorrowerId = id),
          );
          break;
        case 1:
          content = BorrowersScreen(
            onSelectBorrower: (id) => setState(() => _selectedBorrowerId = id),
          );
          break;
        case 2:
          content = LoansScreen(
            onSelectLoan: (id) => setState(() => _selectedLoanId = id),
            initialBorrowerId: _issueLoanBorrowerId,
          );
          break;
        case 3:
        default:
          content = const SettingsScreen();
          break;
      }
    }

    final bodyWidget = isDesktop
        ? Row(
            children: [
              NavigationRail(
                selectedIndex: _currentIndex,
                onDestinationSelected: _navigateToTab,
                labelType: NavigationRailLabelType.all,
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard),
                    label: Text('Dashboard'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.people_outline),
                    selectedIcon: Icon(Icons.people),
                    label: Text('Borrowers'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.credit_card_outlined),
                    selectedIcon: Icon(Icons.credit_card),
                    label: Text('Loans'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.settings_outlined),
                    selectedIcon: Icon(Icons.settings),
                    label: Text('Settings'),
                  ),
                ],
              ),
              const VerticalDivider(thickness: 1, width: 1),
              Expanded(child: content),
            ],
          )
        : content;

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          if (state.currentUser != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${state.currentUser!.username} (${state.currentUser!.role})',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout, size: 20),
              onPressed: state.logout,
              tooltip: 'Sign Out',
            ),
          ],
          // Theme toggle
          IconButton(
            icon: Icon(state.isDarkMode ? Icons.wb_sunny : Icons.nightlight_round),
            onPressed: state.toggleTheme,
            tooltip: 'Toggle Theme',
          ),
        ],
      ),
      body: SafeArea(child: bodyWidget),
      bottomNavigationBar: isDesktop
          ? null
          : BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: _navigateToTab,
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_outlined),
                  activeIcon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.people_outline),
                  activeIcon: Icon(Icons.people),
                  label: 'Borrowers',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.credit_card_outlined),
                  activeIcon: Icon(Icons.credit_card),
                  label: 'Loans',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings_outlined),
                  activeIcon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            ),
    );
  }
}
