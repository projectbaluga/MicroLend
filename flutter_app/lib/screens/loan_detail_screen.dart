import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/payment.dart';
import '../store/app_state.dart';
import '../utils/loan_utils.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_progress_bar.dart';
import '../widgets/custom_card.dart';

class LoanDetailScreen extends StatelessWidget {
  final String loanId;
  final VoidCallback onBack;
  final Function(String) onSelectBorrower;

  const LoanDetailScreen({
    super.key,
    required this.loanId,
    required this.onBack,
    required this.onSelectBorrower,
  });

  void _showRecordPaymentDialog(BuildContext context, String loanId) {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final dateCtrl = TextEditingController(text: DateTime.now().toIso8601String().split('T')[0]);
    String selectedMethod = 'Bank Transfer';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            top: 16,
            left: 16,
            right: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Record Repayment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount (\$) *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedMethod,
                decoration: const InputDecoration(labelText: 'Method', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer')),
                  DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'Debit Card', child: Text('Debit Card')),
                  DropdownMenuItem(value: 'Check', child: Text('Check')),
                  DropdownMenuItem(value: 'Mobile Payment', child: Text('Mobile Payment')),
                ],
                onChanged: (val) => selectedMethod = val ?? 'Bank Transfer',
              ),
              const SizedBox(height: 10),
              TextField(
                controller: dateCtrl,
                decoration: const InputDecoration(labelText: 'Payment Date (YYYY-MM-DD)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(labelText: 'Note', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final amt = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                      if (amt <= 0) return;

                      final payment = Payment(
                        id: 'pay_${DateTime.now().millisecondsSinceEpoch}',
                        date: dateCtrl.text.trim(),
                        amount: amt,
                        method: selectedMethod,
                        note: noteCtrl.text.trim(),
                      );

                      Provider.of<AppState>(context, listen: false).recordPayment(loanId, payment);
                      Navigator.pop(ctx);
                    },
                    child: const Text('Save Payment'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final loans = state.loans;
    final borrowers = state.borrowers;

    final loan = loans.firstWhere((l) => l.id == loanId, orElse: () => loans.first);
    final borrower = borrowers.firstWhere((b) => b.id == loan.borrowerId, orElse: () => borrowers.first);
    final stats = LoanUtils.getLoanStats(loan);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack),
        title: Text(loan.purpose),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Transitions Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (loan.status == 'pending') ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669)),
                    onPressed: () => state.approveLoan(loan.id),
                    icon: const Icon(Icons.check, size: 16, color: Colors.white),
                    label: const Text('Approve', style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => state.markLoanStatus(loan.id, 'rejected'),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Reject'),
                  ),
                ],
                if (loan.status == 'active') ...[
                  ElevatedButton.icon(
                    onPressed: () => _showRecordPaymentDialog(context, loan.id),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Record Payment'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => state.markLoanStatus(loan.id, 'completed'),
                    child: const Text('Complete'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
                    onPressed: () => state.markLoanStatus(loan.id, 'defaulted'),
                    child: const Text('Default'),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 12),

            // Overview Card
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(loan.purpose, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      AppBadge(text: loan.status, variant: loan.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${LoanUtils.formatCurrency(loan.principal)} @ ${loan.interestRate}% • ${loan.termMonths} mo',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 12),
                  AppProgressBar(percentage: stats.progressPct),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Scheduled', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          Text(LoanUtils.formatCurrency(stats.totalScheduled), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Paid', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          Text(LoanUtils.formatCurrency(stats.totalPaid),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Outstanding', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          Text(LoanUtils.formatCurrency(stats.outstandingBalance), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Overdue', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          Text(LoanUtils.formatCurrency(stats.overdueAmount),
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: stats.overdueAmount > 0 ? Colors.redAccent : Colors.white)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Borrower Summary Card
            CustomCard(
              onTap: () => onSelectBorrower(borrower.id),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(borrower.fullName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      Text(borrower.email.isNotEmpty ? borrower.email : borrower.phone,
                          style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                  AppBadge(text: borrower.riskRating, variant: borrower.riskRating),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Amortization Schedule Table Card
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Amortization Schedule', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 16,
                      headingRowHeight: 32,
                      dataRowHeight: 36,
                      columns: const [
                        DataColumn(label: Text('#', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Due Date', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Amount', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Principal', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Interest', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                      ],
                      rows: stats.scheduleWithStatus.map((inst) {
                        return DataRow(
                          cells: [
                            DataCell(Text('${inst.installmentNo}', style: const TextStyle(fontSize: 11))),
                            DataCell(Text(LoanUtils.formatDate(inst.dueDate), style: const TextStyle(fontSize: 11))),
                            DataCell(Text(LoanUtils.formatCurrency(inst.amount), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                            DataCell(Text(LoanUtils.formatCurrency(inst.principal), style: const TextStyle(fontSize: 11, color: Colors.grey))),
                            DataCell(Text(LoanUtils.formatCurrency(inst.interest), style: const TextStyle(fontSize: 11, color: Colors.grey))),
                            DataCell(AppBadge(text: inst.status, variant: inst.status)),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Payments Log Card
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payment Log (${loan.payments.length})', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (loan.payments.isEmpty)
                    const Text('No payments recorded yet.', style: TextStyle(fontSize: 11, color: Colors.grey))
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: loan.payments.length,
                      separatorBuilder: (_, __) => const Divider(height: 12),
                      itemBuilder: (context, idx) {
                        final p = loan.payments[idx];
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(LoanUtils.formatCurrency(p.amount),
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                Text('via ${p.method} • ${p.note}',
                                    style: const TextStyle(fontSize: 10, color: Colors.grey)),
                              ],
                            ),
                            Text(LoanUtils.formatDate(p.date), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
