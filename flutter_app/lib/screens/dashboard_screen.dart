import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/loan.dart';
import '../store/app_state.dart';
import '../utils/loan_utils.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_progress_bar.dart';
import '../widgets/custom_card.dart';
import '../widgets/stat_card.dart';

class DashboardScreen extends StatelessWidget {
  final Function(String) onSelectLoan;
  final Function(String) onSelectBorrower;

  const DashboardScreen({
    super.key,
    required this.onSelectLoan,
    required this.onSelectBorrower,
  });

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final loans = state.loans;
    final borrowers = state.borrowers;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final borrowerMap = {for (var b in borrowers) b.id: b};

    int activeLoansCount = 0;
    double totalDisbursed = 0.0;
    double outstandingBalance = 0.0;
    double overdueAmount = 0.0;
    double collectedThisMonth = 0.0;
    double expectedThisMonth = 0.0;

    final now = DateTime.now();
    final currentYearMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    for (var loan in loans) {
      final stats = LoanUtils.getLoanStats(loan);

      if (loan.status == 'active') {
        activeLoansCount += 1;
      }

      if (['active', 'completed', 'defaulted'].contains(loan.status)) {
        totalDisbursed += loan.principal;
        outstandingBalance += stats.outstandingBalance;
        overdueAmount += stats.overdueAmount;
      }

      for (var pay in loan.payments) {
        if (pay.date.startsWith(currentYearMonth)) {
          collectedThisMonth += pay.amount;
        }
      }

      for (var inst in loan.schedule) {
        if (inst.dueDate.startsWith(currentYearMonth)) {
          expectedThisMonth += inst.amount;
        }
      }
    }

    // Cash flow data
    final List<FlSpot> expectedSpots = [];
    final List<FlSpot> collectedSpots = [];
    final List<String> monthLabels = [];

    for (int i = -1; i < 5; i++) {
      final d = DateTime(now.year, now.month + i, 1);
      final yearMonth = '${d.year}-${d.month.toString().padLeft(2, '0')}';
      monthLabels.add(LoanUtils.formatDate(yearMonth).split(' ')[0]);

      double exp = 0.0;
      double col = 0.0;

      for (var loan in loans) {
        if (['active', 'completed', 'defaulted'].contains(loan.status)) {
          for (var inst in loan.schedule) {
            if (inst.dueDate.startsWith(yearMonth)) {
              exp += inst.amount;
            }
          }
          for (var pay in loan.payments) {
            if (pay.date.startsWith(yearMonth)) {
              col += pay.amount;
            }
          }
        }
      }

      expectedSpots.add(FlSpot((i + 1).toDouble(), exp));
      collectedSpots.add(FlSpot((i + 1).toDouble(), col));
    }

    // Donut data
    final Map<String, int> statusCounts = {};
    for (var l in loans) {
      statusCounts[l.status] = (statusCounts[l.status] ?? 0) + 1;
    }

    // Overdue loans
    final overdueLoans = loans.where((loan) {
      final stats = LoanUtils.getLoanStats(loan);
      return stats.overdueAmount > 0 && loan.status != 'completed';
    }).toList();

    // Recent loans
    final recentLoans = [...loans]..sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 6 Stat Cards Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              StatCard(
                title: 'Active Loans',
                value: '$activeLoansCount',
                subtext: 'In good standing',
                icon: Icons.trending_up,
              ),
              StatCard(
                title: 'Total Disbursed',
                value: LoanUtils.formatCurrency(totalDisbursed),
                subtext: 'Cumulative principal',
                icon: Icons.attach_money,
              ),
              StatCard(
                title: 'Outstanding',
                value: LoanUtils.formatCurrency(outstandingBalance),
                subtext: 'Remaining balance',
                icon: Icons.access_time,
              ),
              StatCard(
                title: 'Overdue',
                value: LoanUtils.formatCurrency(overdueAmount),
                subtext: 'Requires attention',
                icon: Icons.warning_amber_rounded,
              ),
              StatCard(
                title: 'Collected (Month)',
                value: LoanUtils.formatCurrency(collectedThisMonth),
                subtext: 'Recorded this month',
                icon: Icons.check_circle_outline,
              ),
              StatCard(
                title: 'Expected (Month)',
                value: LoanUtils.formatCurrency(expectedThisMonth),
                subtext: 'Scheduled this month',
                icon: Icons.calendar_today,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 6-Month Cash Flow Line/Area Chart
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '6-Month Expected Cash Flow',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Expected vs Collected payments',
                  style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 160,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, meta) {
                              final idx = val.toInt();
                              if (idx >= 0 && idx < monthLabels.length) {
                                return Text(monthLabels[idx], style: const TextStyle(fontSize: 10));
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: expectedSpots,
                          isCurved: true,
                          color: Colors.grey,
                          barWidth: 2,
                          belowBarData: BarAreaData(show: true, color: Colors.grey.withOpacity(0.1)),
                        ),
                        LineChartBarData(
                          spots: collectedSpots,
                          isCurved: true,
                          color: const Color(0xFF10B981),
                          barWidth: 2,
                          belowBarData: BarAreaData(show: true, color: const Color(0xFF10B981).withOpacity(0.2)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Overdue Loans List Card
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.warning, color: Colors.redAccent, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Overdue Repayments',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    AppBadge(text: '${overdueLoans.length} requiring action', variant: 'high'),
                  ],
                ),
                const SizedBox(height: 12),
                if (overdueLoans.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Text('No overdue loans!', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: overdueLoans.length,
                    separatorBuilder: (_, __) => const Divider(height: 16),
                    itemBuilder: (context, idx) {
                      final loan = overdueLoans[idx];
                      final b = borrowerMap[loan.borrowerId];
                      final stats = LoanUtils.getLoanStats(loan);

                      return InkWell(
                        onTap: () => onSelectLoan(loan.id),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  b?.fullName ?? 'Unknown',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '${loan.purpose} • ${LoanUtils.formatCurrency(loan.principal)}',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${LoanUtils.formatCurrency(stats.overdueAmount)} overdue',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.redAccent),
                                ),
                                if (stats.nextDue != null)
                                  Text(
                                    'Due ${LoanUtils.formatDate(stats.nextDue!.dueDate)}',
                                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Recent Loans List
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recent Loans & Progress',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentLoans.length > 5 ? 5 : recentLoans.length,
                  separatorBuilder: (_, __) => const Divider(height: 16),
                  itemBuilder: (context, idx) {
                    final loan = recentLoans[idx];
                    final b = borrowerMap[loan.borrowerId];
                    final stats = LoanUtils.getLoanStats(loan);

                    return InkWell(
                      onTap: () => onSelectLoan(loan.id),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${b?.fullName ?? 'Unknown'} (${LoanUtils.formatCurrency(loan.principal)})',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              AppBadge(text: loan.status, variant: loan.status),
                            ],
                          ),
                          const SizedBox(height: 6),
                          if (loan.status == 'active' || loan.status == 'completed')
                            AppProgressBar(percentage: stats.progressPct)
                          else
                            Text(
                              'Purpose: ${loan.purpose}',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
