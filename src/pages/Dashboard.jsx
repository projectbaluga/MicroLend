import React from 'react';
import {
  DollarSign,
  TrendingUp,
  AlertTriangle,
  Clock,
  CheckCircle,
  FileSpreadsheet,
  ArrowRight,
  ChevronRight,
} from 'lucide-react';
import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
  Legend,
} from 'recharts';
import { useCollection } from '../store/useStore';
import { getLoanStats, formatCurrency, formatDate } from '../utils/loanUtils';
import { StatCard, Card } from '../components/Card';
import Badge from '../components/Badge';
import ProgressBar from '../components/ProgressBar';

export default function Dashboard({ onSelectLoan, onSelectBorrower }) {
  const loans = useCollection('loans');
  const borrowers = useCollection('borrowers');

  const borrowerMap = React.useMemo(() => {
    return borrowers.reduce((acc, b) => {
      acc[b.id] = b;
      return acc;
    }, {});
  }, [borrowers]);

  // Compute stat metrics
  const stats = React.useMemo(() => {
    let activeLoansCount = 0;
    let totalDisbursed = 0;
    let outstandingBalance = 0;
    let overdueAmount = 0;
    let collectedThisMonth = 0;
    let expectedThisMonth = 0;

    const now = new Date();
    const currentYearMonth = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;

    loans.forEach((loan) => {
      const loanStat = getLoanStats(loan);

      if (loan.status === 'active') {
        activeLoansCount += 1;
      }

      if (['active', 'completed', 'defaulted'].includes(loan.status)) {
        totalDisbursed += Number(loan.principal) || 0;
        outstandingBalance += loanStat.outstandingBalance;
        overdueAmount += loanStat.overdueAmount;
      }

      // Payments collected this month
      (loan.payments || []).forEach((payment) => {
        if (payment.date && payment.date.startsWith(currentYearMonth)) {
          collectedThisMonth += Number(payment.amount) || 0;
        }
      });

      // Expected this month from schedule
      (loan.schedule || []).forEach((inst) => {
        if (inst.due_date && inst.due_date.startsWith(currentYearMonth)) {
          expectedThisMonth += Number(inst.amount) || 0;
        }
      });
    });

    return {
      activeLoansCount,
      totalDisbursed,
      outstandingBalance,
      overdueAmount,
      collectedThisMonth,
      expectedThisMonth,
    };
  }, [loans]);

  // 6-Month Cash Flow Data
  const cashFlowData = React.useMemo(() => {
    const months = [];
    const now = new Date();

    for (let i = -1; i < 5; i++) {
      const d = new Date(now.getFullYear(), now.getMonth() + i, 1);
      const yearMonth = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
      const monthLabel = d.toLocaleString('en-US', { month: 'short' });

      let expected = 0;
      let collected = 0;

      loans.forEach((loan) => {
        if (['active', 'completed', 'defaulted'].includes(loan.status)) {
          (loan.schedule || []).forEach((inst) => {
            if (inst.due_date && inst.due_date.startsWith(yearMonth)) {
              expected += Number(inst.amount) || 0;
            }
          });

          (loan.payments || []).forEach((pay) => {
            if (pay.date && pay.date.startsWith(yearMonth)) {
              collected += Number(pay.amount) || 0;
            }
          });
        }
      });

      months.push({
        month: monthLabel,
        expected: Math.round(expected),
        collected: Math.round(collected),
      });
    }

    return months;
  }, [loans]);

  // Portfolio Donut Data
  const donutData = React.useMemo(() => {
    const counts = {
      active: 0,
      pending: 0,
      completed: 0,
      defaulted: 0,
      rejected: 0,
    };

    loans.forEach((l) => {
      const st = l.status || 'pending';
      counts[st] = (counts[st] || 0) + 1;
    });

    const colors = {
      active: '#3b82f6', // blue
      pending: '#f59e0b', // amber
      completed: '#10b981', // emerald
      defaulted: '#f43f5e', // rose
      rejected: '#6b7280', // gray
    };

    return Object.keys(counts)
      .filter((st) => counts[st] > 0)
      .map((st) => ({
        name: st.charAt(0).toUpperCase() + st.slice(1),
        value: counts[st],
        color: colors[st] || '#6b7280',
      }));
  }, [loans]);

  // Overdue Loans List
  const overdueLoans = React.useMemo(() => {
    return loans
      .map((loan) => {
        const stats = getLoanStats(loan);
        return { loan, stats, borrower: borrowerMap[loan.borrower_id] };
      })
      .filter(({ stats, loan }) => stats.overdueAmount > 0 && loan.status !== 'completed');
  }, [loans, borrowerMap]);

  // Recent Loans List
  const recentLoans = React.useMemo(() => {
    return [...loans]
      .sort((a, b) => new Date(b.createdAt || 0) - new Date(a.createdAt || 0))
      .slice(0, 5)
      .map((loan) => {
        const stats = getLoanStats(loan);
        return { loan, stats, borrower: borrowerMap[loan.borrower_id] };
      });
  }, [loans, borrowerMap]);

  return (
    <div className="space-y-8 pb-12">
      {/* 6 Stat Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-6 gap-4">
        <StatCard
          title="Active Loans"
          value={stats.activeLoansCount}
          subtext="In good standing or past due"
          icon={TrendingUp}
        />
        <StatCard
          title="Total Disbursed"
          value={formatCurrency(stats.totalDisbursed)}
          subtext="Cumulative principal"
          icon={DollarSign}
        />
        <StatCard
          title="Outstanding"
          value={formatCurrency(stats.outstandingBalance)}
          subtext="Remaining total principal/interest"
          icon={Clock}
        />
        <StatCard
          title="Overdue"
          value={formatCurrency(stats.overdueAmount)}
          subtext="Requires payment attention"
          icon={AlertTriangle}
        />
        <StatCard
          title="Collected (Month)"
          value={formatCurrency(stats.collectedThisMonth)}
          subtext="Recorded payments this month"
          icon={CheckCircle}
        />
        <StatCard
          title="Expected (Month)"
          value={formatCurrency(stats.expectedThisMonth)}
          subtext="Scheduled for current month"
          icon={FileSpreadsheet}
        />
      </div>

      {/* Charts Row */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* 6-Month Expected Cash-Flow Area Chart */}
        <Card className="lg:col-span-2 flex flex-col justify-between">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h3 className="font-bold text-zinc-900 dark:text-zinc-100">6-Month Expected Cash Flow</h3>
              <p className="text-xs text-zinc-500 dark:text-zinc-400">Scheduled installments vs actual collected payments</p>
            </div>
            <div className="flex items-center gap-4 text-xs font-medium">
              <span className="flex items-center gap-1 text-zinc-700 dark:text-zinc-300">
                <span className="w-2.5 h-2.5 rounded-full bg-zinc-900 dark:bg-zinc-100" /> Expected
              </span>
              <span className="flex items-center gap-1 text-zinc-700 dark:text-zinc-300">
                <span className="w-2.5 h-2.5 rounded-full bg-emerald-500" /> Collected
              </span>
            </div>
          </div>

          <div className="h-64 w-full">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={cashFlowData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                <defs>
                  <linearGradient id="expectedGrad" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#71717a" stopOpacity={0.3} />
                    <stop offset="95%" stopColor="#71717a" stopOpacity={0} />
                  </linearGradient>
                  <linearGradient id="collectedGrad" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#10b981" stopOpacity={0.4} />
                    <stop offset="95%" stopColor="#10b981" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#3f3f4622" />
                <XAxis dataKey="month" tickLine={false} axisLine={false} tick={{ fontSize: 12, fill: '#888' }} />
                <YAxis tickLine={false} axisLine={false} tick={{ fontSize: 12, fill: '#888' }} />
                <Tooltip
                  formatter={(val) => [`$${val}`, 'Amount']}
                  contentStyle={{ backgroundColor: '#18181b', border: 'none', borderRadius: '8px', color: '#fff' }}
                />
                <Area type="monotone" dataKey="expected" stroke="#71717a" fillOpacity={1} fill="url(#expectedGrad)" strokeWidth={2} />
                <Area type="monotone" dataKey="collected" stroke="#10b981" fillOpacity={1} fill="url(#collectedGrad)" strokeWidth={2} />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </Card>

        {/* Portfolio Status Donut Chart */}
        <Card className="flex flex-col justify-between">
          <div>
            <h3 className="font-bold text-zinc-900 dark:text-zinc-100">Portfolio Distribution</h3>
            <p className="text-xs text-zinc-500 dark:text-zinc-400">Breakdown of loans by current status</p>
          </div>

          <div className="h-56 w-full my-2">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={donutData}
                  cx="50%"
                  cy="50%"
                  innerRadius={50}
                  outerRadius={75}
                  paddingAngle={4}
                  dataKey="value"
                >
                  {donutData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.color} />
                  ))}
                </Pie>
                <Tooltip
                  formatter={(value) => [`${value} loan(s)`, 'Count']}
                  contentStyle={{ backgroundColor: '#18181b', border: 'none', borderRadius: '8px', color: '#fff' }}
                />
                <Legend verticalAlign="bottom" height={36} />
              </PieChart>
            </ResponsiveContainer>
          </div>
        </Card>
      </div>

      {/* Lists Row: Overdue Loans & Recent Loans */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Overdue Loans Alert List */}
        <Card>
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-2">
              <AlertTriangle className="w-5 h-5 text-rose-500" />
              <h3 className="font-bold text-zinc-900 dark:text-zinc-100">Overdue Repayments</h3>
            </div>
            <span className="text-xs font-semibold px-2.5 py-0.5 rounded-full bg-rose-100 text-rose-800 dark:bg-rose-950 dark:text-rose-300">
              {overdueLoans.length} requiring action
            </span>
          </div>

          {overdueLoans.length === 0 ? (
            <div className="py-8 text-center text-sm text-zinc-500 dark:text-zinc-400">
              No overdue loans! All repayments are up to date.
            </div>
          ) : (
            <div className="divide-y divide-zinc-200 dark:divide-zinc-800">
              {overdueLoans.map(({ loan, stats, borrower }) => (
                <div
                  key={loan.id}
                  onClick={() => onSelectLoan(loan.id)}
                  className="py-3 flex items-center justify-between hover:bg-zinc-50 dark:hover:bg-zinc-800/50 px-2 rounded-lg cursor-pointer transition"
                >
                  <div>
                    <p className="font-semibold text-sm text-zinc-900 dark:text-zinc-100">
                      {borrower?.full_name || 'Unknown Borrower'}
                    </p>
                    <p className="text-xs text-zinc-500 dark:text-zinc-400">
                      {loan.purpose} • Principal: {formatCurrency(loan.principal)}
                    </p>
                  </div>
                  <div className="text-right flex items-center gap-3">
                    <div>
                      <p className="text-sm font-bold text-rose-600 dark:text-rose-400">
                        {formatCurrency(stats.overdueAmount)} overdue
                      </p>
                      {stats.nextDue && (
                        <p className="text-[11px] text-zinc-400">Due {formatDate(stats.nextDue.due_date)}</p>
                      )}
                    </div>
                    <ChevronRight className="w-4 h-4 text-zinc-400" />
                  </div>
                </div>
              ))}
            </div>
          )}
        </Card>

        {/* Recent Loans List */}
        <Card>
          <div className="flex items-center justify-between mb-4">
            <h3 className="font-bold text-zinc-900 dark:text-zinc-100">Recent Loans & Repayment Progress</h3>
            <span className="text-xs text-zinc-500">Latest active & pending</span>
          </div>

          <div className="divide-y divide-zinc-200 dark:divide-zinc-800">
            {recentLoans.map(({ loan, stats, borrower }) => (
              <div
                key={loan.id}
                onClick={() => onSelectLoan(loan.id)}
                className="py-3 hover:bg-zinc-50 dark:hover:bg-zinc-800/50 px-2 rounded-lg cursor-pointer transition"
              >
                <div className="flex items-center justify-between mb-2">
                  <div>
                    <span className="font-semibold text-sm text-zinc-900 dark:text-zinc-100">
                      {borrower?.full_name || 'Unknown Borrower'}
                    </span>
                    <span className="ml-2 text-xs text-zinc-500 dark:text-zinc-400">
                      ({formatCurrency(loan.principal)})
                    </span>
                  </div>
                  <Badge variant={loan.status}>{loan.status}</Badge>
                </div>

                {loan.status === 'active' || loan.status === 'completed' ? (
                  <ProgressBar value={stats.progressPct} max={100} showLabel={true} />
                ) : (
                  <div className="text-xs text-zinc-500 dark:text-zinc-400">
                    Created on {formatDate(loan.createdAt)} • Purpose: {loan.purpose}
                  </div>
                )}
              </div>
            ))}
          </div>
        </Card>
      </div>
    </div>
  );
}
