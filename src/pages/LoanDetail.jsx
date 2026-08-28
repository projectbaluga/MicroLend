import React, { useState } from 'react';
import {
  ArrowLeft,
  User,
  CheckCircle,
  XCircle,
  AlertTriangle,
  DollarSign,
  Calendar,
  CreditCard,
  PlusCircle,
  Receipt,
  Check,
} from 'lucide-react';
import { useCollection, updateItem } from '../store/useStore';
import { getLoanStats, generateSchedule, formatCurrency, formatDate } from '../utils/loanUtils';
import { Card } from '../components/Card';
import Badge from '../components/Badge';
import ProgressBar from '../components/ProgressBar';
import Modal from '../components/Modal';

export default function LoanDetail({ loanId, onBack, onSelectBorrower }) {
  const loans = useCollection('loans');
  const borrowers = useCollection('borrowers');

  const loan = loans.find((l) => l.id === loanId);
  const [isPaymentModalOpen, setIsPaymentModalOpen] = useState(false);

  // Record Payment Form State
  const [paymentForm, setPaymentForm] = useState({
    amount: '',
    method: 'Bank Transfer',
    date: new Date().toISOString().split('T')[0],
    note: '',
  });

  if (!loan) {
    return (
      <div className="py-12 text-center">
        <p className="text-zinc-500">Loan not found.</p>
        <button
          onClick={onBack}
          className="mt-4 px-4 py-2 bg-zinc-900 text-white dark:bg-zinc-100 dark:text-zinc-900 rounded-lg text-sm font-medium"
        >
          Back to Loans
        </button>
      </div>
    );
  }

  const borrower = borrowers.find((b) => b.id === loan.borrower_id);
  const stats = getLoanStats(loan);

  // Status transition handlers
  const handleApprove = () => {
    const todayStr = new Date().toISOString().split('T')[0];
    const newSchedule = generateSchedule(loan.principal, loan.interest_rate, loan.term_months, todayStr);
    updateItem('loans', loan.id, {
      status: 'active',
      disbursement_date: todayStr,
      schedule: newSchedule,
    });
  };

  const handleMarkCompleted = () => {
    updateItem('loans', loan.id, { status: 'completed' });
  };

  const handleMarkDefaulted = () => {
    updateItem('loans', loan.id, { status: 'defaulted' });
  };

  const handleReject = () => {
    updateItem('loans', loan.id, { status: 'rejected' });
  };

  // Record Payment Handler
  const handleRecordPayment = (e) => {
    e.preventDefault();
    const payAmt = Number(paymentForm.amount);
    if (!payAmt || payAmt <= 0) return;

    const newPayment = {
      id: `pay_${Date.now()}_${Math.random().toString(36).substr(2, 4)}`,
      amount: payAmt,
      method: paymentForm.method,
      date: paymentForm.date,
      note: paymentForm.note,
    };

    const updatedPayments = [...(loan.payments || []), newPayment];

    // Check if total paid now clears scheduled balance -> auto-complete if so
    const totalPaidNow = updatedPayments.reduce((s, p) => s + (Number(p.amount) || 0), 0);
    const newStatus = totalPaidNow >= stats.totalScheduled && loan.status === 'active' ? 'completed' : loan.status;

    updateItem('loans', loan.id, {
      payments: updatedPayments,
      status: newStatus,
    });

    setIsPaymentModalOpen(false);
    setPaymentForm({
      amount: '',
      method: 'Bank Transfer',
      date: new Date().toISOString().split('T')[0],
      note: '',
    });
  };

  return (
    <div className="space-y-6 pb-12">
      {/* Back button & Action controls */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <button
          onClick={onBack}
          className="inline-flex items-center gap-2 text-sm font-medium text-zinc-600 dark:text-zinc-400 hover:text-zinc-900 dark:hover:text-zinc-100 transition"
        >
          <ArrowLeft className="w-4 h-4" /> Back to Loans
        </button>

        {/* Status Transition Action Buttons */}
        <div className="flex flex-wrap items-center gap-2">
          {loan.status === 'pending' && (
            <>
              <button
                onClick={handleApprove}
                className="inline-flex items-center gap-1.5 px-3.5 py-2 bg-emerald-600 text-white rounded-lg text-sm font-semibold hover:bg-emerald-700 transition"
              >
                <Check className="w-4 h-4" /> Approve & Disburse
              </button>
              <button
                onClick={handleReject}
                className="inline-flex items-center gap-1.5 px-3.5 py-2 bg-zinc-200 dark:bg-zinc-800 text-zinc-800 dark:text-zinc-200 rounded-lg text-sm font-semibold hover:bg-zinc-300 dark:hover:bg-zinc-700 transition"
              >
                <XCircle className="w-4 h-4" /> Reject Loan
              </button>
            </>
          )}

          {loan.status === 'active' && (
            <>
              <button
                onClick={() => setIsPaymentModalOpen(true)}
                className="inline-flex items-center gap-1.5 px-3.5 py-2 bg-zinc-900 dark:bg-zinc-100 text-white dark:text-zinc-900 rounded-lg text-sm font-semibold hover:bg-zinc-800 dark:hover:bg-zinc-200 transition shadow-xs"
              >
                <PlusCircle className="w-4 h-4" /> Record Payment
              </button>
              <button
                onClick={handleMarkCompleted}
                className="inline-flex items-center gap-1.5 px-3 py-2 bg-emerald-100 text-emerald-800 dark:bg-emerald-950 dark:text-emerald-300 border border-emerald-300 dark:border-emerald-800 rounded-lg text-xs font-semibold hover:bg-emerald-200 transition"
              >
                <CheckCircle className="w-3.5 h-3.5" /> Mark Completed
              </button>
              <button
                onClick={handleMarkDefaulted}
                className="inline-flex items-center gap-1.5 px-3 py-2 bg-rose-100 text-rose-800 dark:bg-rose-950 dark:text-rose-300 border border-rose-300 dark:border-rose-800 rounded-lg text-xs font-semibold hover:bg-rose-200 transition"
              >
                <AlertTriangle className="w-3.5 h-3.5" /> Mark Defaulted
              </button>
            </>
          )}
        </div>
      </div>

      {/* Main Loan Info Header */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Loan Overview Card */}
        <Card className="lg:col-span-2 space-y-4">
          <div className="flex items-start justify-between">
            <div>
              <div className="flex items-center gap-2">
                <h2 className="text-2xl font-bold text-zinc-900 dark:text-zinc-50">{loan.purpose}</h2>
                <Badge variant={loan.status}>{loan.status}</Badge>
              </div>
              <p className="text-xs text-zinc-500 mt-0.5">Loan ID: {loan.id}</p>
            </div>

            <div className="text-right">
              <span className="text-2xl font-extrabold text-zinc-900 dark:text-zinc-100">
                {formatCurrency(loan.principal)}
              </span>
              <p className="text-xs text-zinc-500">{loan.interest_rate}% Interest • {loan.term_months} Months</p>
            </div>
          </div>

          <div className="pt-2">
            <ProgressBar value={stats.progressPct} max={100} showLabel={true} />
          </div>

          {/* Key Metric Blocks */}
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 pt-2 text-xs">
            <div className="p-3 bg-zinc-50 dark:bg-zinc-800/60 rounded-lg border border-zinc-200/50 dark:border-zinc-700/50">
              <span className="text-zinc-500 block">Total Scheduled</span>
              <span className="font-bold text-sm text-zinc-900 dark:text-zinc-100">{formatCurrency(stats.totalScheduled)}</span>
            </div>
            <div className="p-3 bg-zinc-50 dark:bg-zinc-800/60 rounded-lg border border-zinc-200/50 dark:border-zinc-700/50">
              <span className="text-zinc-500 block">Total Paid</span>
              <span className="font-bold text-sm text-emerald-600 dark:text-emerald-400">{formatCurrency(stats.totalPaid)}</span>
            </div>
            <div className="p-3 bg-zinc-50 dark:bg-zinc-800/60 rounded-lg border border-zinc-200/50 dark:border-zinc-700/50">
              <span className="text-zinc-500 block">Outstanding</span>
              <span className="font-bold text-sm text-zinc-900 dark:text-zinc-100">{formatCurrency(stats.outstandingBalance)}</span>
            </div>
            <div className="p-3 bg-zinc-50 dark:bg-zinc-800/60 rounded-lg border border-zinc-200/50 dark:border-zinc-700/50">
              <span className="text-zinc-500 block">Overdue Amount</span>
              <span className={`font-bold text-sm ${stats.overdueAmount > 0 ? 'text-rose-600 dark:text-rose-400' : 'text-zinc-900 dark:text-zinc-100'}`}>
                {formatCurrency(stats.overdueAmount)}
              </span>
            </div>
          </div>
        </Card>

        {/* Borrower Summary Card */}
        <Card className="space-y-4 flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between">
              <h3 className="font-bold text-zinc-900 dark:text-zinc-100 flex items-center gap-2">
                <User className="w-4 h-4" /> Borrower
              </h3>
              {borrower && (
                <button
                  onClick={() => onSelectBorrower(borrower.id)}
                  className="text-xs text-blue-600 dark:text-blue-400 hover:underline font-medium"
                >
                  View Profile
                </button>
              )}
            </div>

            {borrower ? (
              <div className="mt-3 space-y-2 text-sm">
                <p className="font-bold text-base text-zinc-900 dark:text-zinc-100">{borrower.full_name}</p>
                <p className="text-xs text-zinc-500">{borrower.email}</p>
                <p className="text-xs text-zinc-500">{borrower.phone}</p>
                <div className="pt-2 flex items-center gap-2">
                  <span className="text-xs text-zinc-400">Risk Assessment:</span>
                  <Badge variant={borrower.risk_rating}>{borrower.risk_rating}</Badge>
                </div>
              </div>
            ) : (
              <p className="text-xs text-zinc-400 mt-2">No borrower linked.</p>
            )}
          </div>

          <div className="text-xs text-zinc-400 pt-3 border-t border-zinc-200 dark:border-zinc-800">
            <span>Disbursement Date: </span>
            <span className="font-semibold text-zinc-700 dark:text-zinc-300">{formatDate(loan.disbursement_date)}</span>
          </div>
        </Card>
      </div>

      {/* Amortization Schedule Table */}
      <Card>
        <div className="flex items-center justify-between mb-4">
          <div>
            <h3 className="font-bold text-zinc-900 dark:text-zinc-100">Amortization Schedule</h3>
            <p className="text-xs text-zinc-500">Per-installment principal, interest & payment status</p>
          </div>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm text-zinc-700 dark:text-zinc-300">
            <thead className="bg-zinc-50 dark:bg-zinc-800/60 text-xs uppercase font-semibold text-zinc-500 border-b border-zinc-200 dark:border-zinc-800">
              <tr>
                <th className="px-4 py-3">#</th>
                <th className="px-4 py-3">Due Date</th>
                <th className="px-4 py-3">Amount</th>
                <th className="px-4 py-3">Principal</th>
                <th className="px-4 py-3">Interest</th>
                <th className="px-4 py-3">Remaining Balance</th>
                <th className="px-4 py-3">Paid Amount</th>
                <th className="px-4 py-3">Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-zinc-200 dark:divide-zinc-800 font-mono text-xs">
              {stats.scheduleWithStatus.map((inst) => (
                <tr key={inst.installmentNo} className="hover:bg-zinc-50 dark:hover:bg-zinc-800/40">
                  <td className="px-4 py-3 font-bold">{inst.installmentNo}</td>
                  <td className="px-4 py-3">{formatDate(inst.due_date)}</td>
                  <td className="px-4 py-3 font-semibold">{formatCurrency(inst.amount)}</td>
                  <td className="px-4 py-3 text-zinc-500">{formatCurrency(inst.principal)}</td>
                  <td className="px-4 py-3 text-zinc-500">{formatCurrency(inst.interest)}</td>
                  <td className="px-4 py-3">{formatCurrency(inst.balance)}</td>
                  <td className="px-4 py-3 font-medium text-emerald-600 dark:text-emerald-400">
                    {formatCurrency(inst.paidAmount)}
                  </td>
                  <td className="px-4 py-3">
                    <Badge variant={inst.status}>{inst.status}</Badge>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </Card>

      {/* Payment History Log */}
      <Card>
        <div className="flex items-center justify-between mb-4">
          <div>
            <h3 className="font-bold text-zinc-900 dark:text-zinc-100 flex items-center gap-2">
              <Receipt className="w-4 h-4" /> Payment History ({loan.payments?.length || 0})
            </h3>
            <p className="text-xs text-zinc-500">Log of received payments</p>
          </div>

          {loan.status === 'active' && (
            <button
              onClick={() => setIsPaymentModalOpen(true)}
              className="px-3 py-1.5 text-xs font-semibold bg-zinc-900 dark:bg-zinc-100 text-white dark:text-zinc-900 rounded-lg hover:bg-zinc-800 dark:hover:bg-zinc-200"
            >
              + Record Payment
            </button>
          )}
        </div>

        {!loan.payments || loan.payments.length === 0 ? (
          <div className="py-8 text-center text-sm text-zinc-400">
            No payments recorded yet.
          </div>
        ) : (
          <div className="divide-y divide-zinc-200 dark:divide-zinc-800">
            {loan.payments.map((p) => (
              <div key={p.id} className="py-3 flex items-center justify-between text-sm">
                <div>
                  <span className="font-bold text-zinc-900 dark:text-zinc-100">{formatCurrency(p.amount)}</span>
                  <span className="ml-2 text-xs text-zinc-500">via {p.method}</span>
                  {p.note && <p className="text-xs text-zinc-400 mt-0.5">{p.note}</p>}
                </div>
                <div className="text-xs text-zinc-500 font-mono">
                  {formatDate(p.date)}
                </div>
              </div>
            ))}
          </div>
        )}
      </Card>

      {/* Record Payment Modal */}
      <Modal
        isOpen={isPaymentModalOpen}
        onClose={() => setIsPaymentModalOpen(false)}
        title="Record Repayment"
      >
        <form onSubmit={handleRecordPayment} className="space-y-4">
          <div>
            <label className="block text-xs font-semibold text-zinc-700 dark:text-zinc-300 mb-1">
              Payment Amount ($) *
            </label>
            <input
              type="number"
              required
              step="0.01"
              min="0.01"
              placeholder="e.g. 150.00"
              value={paymentForm.amount}
              onChange={(e) => setPaymentForm({ ...paymentForm, amount: e.target.value })}
              className="w-full px-3 py-2 text-sm bg-white dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-zinc-900 dark:focus:ring-zinc-100 text-zinc-900 dark:text-zinc-100"
            />
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-semibold text-zinc-700 dark:text-zinc-300 mb-1">
                Payment Method
              </label>
              <select
                value={paymentForm.method}
                onChange={(e) => setPaymentForm({ ...paymentForm, method: e.target.value })}
                className="w-full px-3 py-2 text-sm bg-white dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-zinc-900 dark:focus:ring-zinc-100 text-zinc-900 dark:text-zinc-100"
              >
                <option value="Bank Transfer">Bank Transfer</option>
                <option value="Cash">Cash</option>
                <option value="Debit Card">Debit Card</option>
                <option value="Check">Check</option>
                <option value="Mobile Payment">Mobile Payment</option>
              </select>
            </div>

            <div>
              <label className="block text-xs font-semibold text-zinc-700 dark:text-zinc-300 mb-1">
                Payment Date
              </label>
              <input
                type="date"
                required
                value={paymentForm.date}
                onChange={(e) => setPaymentForm({ ...paymentForm, date: e.target.value })}
                className="w-full px-3 py-2 text-sm bg-white dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-zinc-900 dark:focus:ring-zinc-100 text-zinc-900 dark:text-zinc-100"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-semibold text-zinc-700 dark:text-zinc-300 mb-1">
              Note
            </label>
            <input
              type="text"
              placeholder="e.g. Installment 3 full payment"
              value={paymentForm.note}
              onChange={(e) => setPaymentForm({ ...paymentForm, note: e.target.value })}
              className="w-full px-3 py-2 text-sm bg-white dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-zinc-900 dark:focus:ring-zinc-100 text-zinc-900 dark:text-zinc-100"
            />
          </div>

          <div className="flex justify-end gap-3 pt-4 border-t border-zinc-200 dark:border-zinc-800">
            <button
              type="button"
              onClick={() => setIsPaymentModalOpen(false)}
              className="px-4 py-2 text-sm font-medium text-zinc-600 dark:text-zinc-400 hover:text-zinc-900 dark:hover:text-zinc-100"
            >
              Cancel
            </button>
            <button
              type="submit"
              className="px-4 py-2 text-sm font-semibold text-white bg-zinc-900 dark:bg-zinc-100 dark:text-zinc-900 rounded-lg hover:bg-zinc-800 dark:hover:bg-zinc-200"
            >
              Save Payment
            </button>
          </div>
        </form>
      </Modal>
    </div>
  );
}
