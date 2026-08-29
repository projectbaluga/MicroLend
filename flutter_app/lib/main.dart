import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/borrower_detail_screen.dart';
import 'screens/borrowers_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/loan_detail_screen.dart';
import 'screens/loans_screen.dart';
import 'screens/login_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/users_screen.dart';
import 'widgets/responsive_container.dart';
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
      home: !state.isLoggedIn
          ? const LoginScreen()
          : (state.currentUser?.mustChangePassword == true
              ? const ForcePasswordChangeScreen()
              : const MainShell()),
    );
  }
}

class ForcePasswordChangeScreen extends StatefulWidget {
  const ForcePasswordChangeScreen({super.key});

  @override
  State<ForcePasswordChangeScreen> createState() => _ForcePasswordChangeScreenState();
}

class _ForcePasswordChangeScreenState extends State<ForcePasswordChangeScreen> {
  final _oldPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  String? _errorMsg;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final user = state.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Password Change Required'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: state.logout),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ResponsiveContainer(
            maxWidth: 420,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.lock_reset, size: 48, color: Colors.orangeAccent),
                    const SizedBox(height: 12),
                    Text(
                      'Welcome, ${user?.username ?? "User"}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'You must change your initial password before proceeding.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    if (_errorMsg != null) ...[
                      Text(_errorMsg!, style: const TextStyle(color: Colors.redAccent, fontSize: 12), textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: _oldPasswordCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Current Password', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _newPasswordCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'New Password', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _confirmPasswordCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Confirm New Password', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () async {
                              final oldP = _oldPasswordCtrl.text.trim();
                              final newP = _newPasswordCtrl.text.trim();
                              final confP = _confirmPasswordCtrl.text.trim();

                              if (oldP.isEmpty || newP.isEmpty) {
                                setState(() => _errorMsg = 'Please enter all fields.');
                                return;
                              }

                              if (newP != confP) {
                                setState(() => _errorMsg = 'New passwords do not match.');
                                return;
                              }

                              setState(() {
                                _isLoading = true;
                                _errorMsg = null;
                              });

                              try {
                                await state.changePassword(user!.id, oldP, newP);
                              } catch (e) {
                                setState(() {
                                  _isLoading = false;
                                  _errorMsg = e.toString().replaceAll('ArgumentError: ', '');
                                });
                              }
                            },
                      child: _isLoading
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Update Password & Continue'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
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
      title = 'Users';
    } else if (_currentIndex == 4) {
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
          content = const UsersScreen();
          break;
        case 4:
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
                    icon: Icon(Icons.manage_accounts_outlined),
                    selectedIcon: Icon(Icons.manage_accounts),
                    label: Text('Users'),
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
                  icon: Icon(Icons.manage_accounts_outlined),
                  activeIcon: Icon(Icons.manage_accounts),
                  label: 'Users',
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
