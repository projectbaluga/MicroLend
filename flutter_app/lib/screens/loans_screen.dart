import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/loan.dart';
import '../store/app_state.dart';
import '../utils/loan_utils.dart';
import '../widgets/app_badge.dart';
import '../widgets/custom_card.dart';
import '../widgets/responsive_container.dart';

class LoansScreen extends StatefulWidget {
  final Function(String) onSelectLoan;
  final String? initialBorrowerId;

  const LoansScreen({
    super.key,
    required this.onSelectLoan,
    this.initialBorrowerId,
  });

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> {
  String _searchTerm = '';
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    if (widget.initialBorrowerId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showNewLoanDialog(context, initialBorrowerId: widget.initialBorrowerId);
      });
    }
  }

  void _showNewLoanDialog(BuildContext context, {String? initialBorrowerId}) {
    final state = Provider.of<AppState>(context, listen: false);
    final borrowers = state.borrowers;
    if (borrowers.isEmpty) return;

    String selectedBorrowerId = initialBorrowerId ?? borrowers.first.id;
    final principalCtrl = TextEditingController(text: '3000');
    final rateCtrl = TextEditingController(text: state.defaultInterestRate.toString());
    final termCtrl = TextEditingController(text: state.defaultTermMonths.toString());
    final purposeCtrl = TextEditingController(text: 'Working Capital');
    final dateCtrl = TextEditingController(text: DateTime.now().toIso8601String().split('T')[0]);
    final notesCtrl = TextEditingController();

    String deductionType = 'none'; // 'none', 'fixed', 'percent'
    final deductionValueCtrl = TextEditingController(text: '0');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final p = double.tryParse(principalCtrl.text.trim()) ?? 0.0;
            final r = double.tryParse(rateCtrl.text.trim()) ?? 0.0;
            final t = int.tryParse(termCtrl.text.trim()) ?? 1;
            final dVal = double.tryParse(deductionValueCtrl.text.trim()) ?? 0.0;

            final deductionAmount = LoanUtils.calculateUpfrontDeduction(p, deductionType, dVal);
            final netDisbursed = LoanUtils.calculateNetDisbursed(p, deductionType, dVal);

            final schedPreview = (p > 0 && t > 0)
                ? LoanUtils.generateSchedule(p, r, t, dateCtrl.text.trim())
                : [];

            return Padding(
              padding: EdgeInsets.only(
                top: 16,
                left: 16,
                right: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Issue New Loan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedBorrowerId,
                      decoration: const InputDecoration(labelText: 'Borrower *', border: OutlineInputBorder()),
                      items: borrowers.map((b) {
                        return DropdownMenuItem(value: b.id, child: Text(b.fullName));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedBorrowerId = val);
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: principalCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Principal (\$) *', border: OutlineInputBorder()),
                            onChanged: (_) => setModalState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: rateCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Rate (%) *', border: OutlineInputBorder()),
                            onChanged: (_) => setModalState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: termCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Term (mo) *', border: OutlineInputBorder()),
                            onChanged: (_) => setModalState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: deductionType,
                            decoration: const InputDecoration(labelText: 'Upfront Deduction', border: OutlineInputBorder()),
                            items: const [
                              DropdownMenuItem(value: 'none', child: Text('None')),
                              DropdownMenuItem(value: 'fixed', child: Text('Fixed Amount (\$)')),
                              DropdownMenuItem(value: 'percent', child: Text('Percentage (%)')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() {
                                  deductionType = val;
                                });
                              }
                            },
                          ),
                        ),
                        if (deductionType != 'none') ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: deductionValueCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: deductionType == 'fixed' ? 'Deduction Amount (\$)' : 'Deduction Percentage (%)',
                                border: const OutlineInputBorder(),
                              ),
                              onChanged: (_) => setModalState(() {}),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: purposeCtrl,
                      decoration: const InputDecoration(labelText: 'Purpose *', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: dateCtrl,
                      decoration: const InputDecoration(labelText: 'Disbursement Date', border: OutlineInputBorder()),
                      onChanged: (_) => setModalState(() {}),
                    ),
                    const SizedBox(height: 10),
                    if (p > 0) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (deductionType != 'none') ...[
                              Text('Upfront Fee Deduction: -${LoanUtils.formatCurrency(deductionAmount, state.currencyCode)}',
                                  style: const TextStyle(fontSize: 11, color: Colors.redAccent)),
                              const SizedBox(height: 2),
                              Text('Net Disbursed to Borrower: ${LoanUtils.formatCurrency(netDisbursed, state.currencyCode)}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                              const SizedBox(height: 4),
                            ],
                            if (schedPreview.isNotEmpty)
                              Text('Est. Monthly Repayment: ${LoanUtils.formatCurrency(schedPreview[0].amount, state.currencyCode)}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    TextField(
                      controller: notesCtrl,
                      decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            if (p <= 0 || t <= 0) return;
                            final selectedB = borrowers.firstWhere((b) => b.id == selectedBorrowerId);
                            final bLoans = state.loans.where((l) => l.borrowerId == selectedBorrowerId).toList();
                            final assessment = LoanUtils.assessBorrower(selectedB, bLoans);

                            final sched = LoanUtils.generateSchedule(p, r, t, dateCtrl.text.trim());

                            final newLoan = Loan(
                              id: 'loan_${DateTime.now().millisecondsSinceEpoch}',
                              borrowerId: selectedBorrowerId,
                              principal: p,
                              interestRate: r,
                              termMonths: t,
                              purpose: purposeCtrl.text.trim(),
                              status: 'pending',
                              disbursementDate: dateCtrl.text.trim(),
                              upfrontDeductionType: deductionType,
                              upfrontDeductionValue: dVal,
                              creditAssessment: assessment,
                              schedule: sched,
                              payments: [],
                              notes: notesCtrl.text.trim(),
                              createdAt: dateCtrl.text.trim(),
                            );

                            state.addLoan(newLoan);
                            Navigator.pop(ctx);
                          },
                          child: const Text('Create Pending Loan'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final loans = state.loans;
    final borrowers = state.borrowers;
    final borrowerMap = {for (var b in borrowers) b.id: b};

    final filtered = loans.where((loan) {
      final b = borrowerMap[loan.borrowerId];
      final matchesSearch = loan.purpose.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          (b?.fullName.toLowerCase().contains(_searchTerm.toLowerCase()) ?? false) ||
          loan.principal.toString().contains(_searchTerm);

      final matchesStatus = _statusFilter == 'all' || loan.status == _statusFilter;

      return matchesSearch && matchesStatus;
    }).toList();

    final isDesktop = ResponsiveContainer.isDesktop(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ResponsiveContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Loans Portfolio', style: TextStyle(fontSize: isDesktop ? 20 : 18, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: () => _showNewLoanDialog(context),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('New Loan'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search purpose or borrower...',
                      prefixIcon: Icon(Icons.search, size: 18),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    onChanged: (val) => setState(() => _searchTerm = val),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _statusFilter,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Status')),
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(value: 'completed', child: Text('Completed')),
                    DropdownMenuItem(value: 'defaulted', child: Text('Defaulted')),
                    DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                  ],
                  onChanged: (val) => setState(() => _statusFilter = val ?? 'all'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filtered.isEmpty
                  ? Center(child: Text('No loans found.', style: TextStyle(fontSize: isDesktop ? 14 : 12)))
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, idx) {
                        final loan = filtered[idx];
                        final b = borrowerMap[loan.borrowerId];
                        final stats = LoanUtils.getLoanStats(loan);

                        return CustomCard(
                          onTap: () => widget.onSelectLoan(loan.id),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(b?.fullName ?? 'Unknown', style: TextStyle(fontSize: isDesktop ? 15 : 14, fontWeight: FontWeight.bold)),
                                  AppBadge(text: loan.status, variant: loan.status),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('${loan.purpose} • ${LoanUtils.formatCurrency(loan.principal, state.currencyCode)} @ ${loan.interestRate}%',
                                  style: TextStyle(fontSize: isDesktop ? 12 : 11, color: Colors.grey)),
                              const SizedBox(height: 8),
                              if (loan.status == 'pending')
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF059669),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    ),
                                    onPressed: () => state.approveLoan(loan.id),
                                    icon: const Icon(Icons.check, size: 14, color: Colors.white),
                                    label: const Text('Approve', style: TextStyle(fontSize: 11, color: Colors.white)),
                                  ),
                                )
                              else
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Balance: ${LoanUtils.formatCurrency(stats.outstandingBalance, state.currencyCode)}',
                                        style: TextStyle(fontSize: isDesktop ? 12 : 11, fontWeight: FontWeight.bold)),
                                    Text('${stats.progressPct}% Paid',
                                        style: TextStyle(fontSize: isDesktop ? 12 : 11, color: Colors.grey)),
                                  ],
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
