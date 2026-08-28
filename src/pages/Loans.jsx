import React, { useState, useMemo } from 'react';
import { Search, Plus, CheckCircle, FilePlus, Calendar, DollarSign, Percent } from 'lucide-react';
import { useCollection, addItem, updateItem } from '../store/useStore';
import { generateSchedule, assessBorrower, getLoanStats, formatCurrency, formatDate } from '../utils/loanUtils';
import Badge from '../components/Badge';
import Modal from '../components/Modal';

export default function Loans({ onSelectLoan, initialBorrowerId = null }) {
  const loans = useCollection('loans');
  const borrowers = useCollection('borrowers');

  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [isNewLoanModalOpen, setIsNewLoanModalOpen] = useState(false);

  // Form State
  const [formData, setFormData] = useState({
    borrower_id: initialBorrowerId || '',
    principal: '3000',
    interest_rate: '12',
    term_months: '6',
    purpose: 'Working Capital',
    disbursement_date: new Date().toISOString().split('T')[0],
    notes: '',
  });

  const borrowerMap = useMemo(() => {
    return borrowers.reduce((acc, b) => {
      acc[b.id] = b;
      return acc;
    }, {});
  }, [borrowers]);

  // Handle open modal with selected borrower pre-filled
  React.useEffect(() => {
    if (initialBorrowerId) {
      setFormData((prev) => ({ ...prev, borrower_id: initialBorrowerId }));
      setIsNewLoanModalOpen(true);
    }
  }, [initialBorrowerId]);

  // Live Amortization Schedule Preview
  const schedulePreview = useMemo(() => {
    const p = Number(formData.principal) || 0;
    const r = Number(formData.interest_rate) || 0;
    const t = Number(formData.term_months) || 1;
    if (p <= 0 || t <= 0) return [];
    return generateSchedule(p, r, t, formData.disbursement_date);
  }, [formData.principal, formData.interest_rate, formData.term_months, formData.disbursement_date]);

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
  };

  const handleCreateLoan = (e) => {
    e.preventDefault();
    if (!formData.borrower_id || !formData.principal) return;

    const selectedBorrower = borrowerMap[formData.borrower_id];
    const borrowerLoans = loans.filter((l) => l.borrower_id === formData.borrower_id);
    const assessment = assessBorrower(selectedBorrower, borrowerLoans);

    const generatedSched = generateSchedule(
      Number(formData.principal),
      Number(formData.interest_rate),
      Number(formData.term_months),
      formData.disbursement_date
    );

    addItem('loans', {
      borrower_id: formData.borrower_id,
      principal: Number(formData.principal),
      interest_rate: Number(formData.interest_rate),
      term_months: Number(formData.term_months),
      purpose: formData.purpose,
      status: 'pending',
      disbursement_date: formData.disbursement_date,
      credit_assessment: assessment,
      schedule: generatedSched,
      payments: [],
      notes: formData.notes,
    });

    setIsNewLoanModalOpen(false);
  };

  const handleQuickApprove = (e, loanId) => {
    e.stopPropagation();
    const todayStr = new Date().toISOString().split('T')[0];
    const targetLoan = loans.find((l) => l.id === loanId);
    if (!targetLoan) return;

    // Regulate schedule based on actual approval disbursement date
    const updatedSchedule = generateSchedule(
      targetLoan.principal,
      targetLoan.interest_rate,
      targetLoan.term_months,
      todayStr
    );

    updateItem('loans', loanId, {
      status: 'active',
      disbursement_date: todayStr,
      schedule: updatedSchedule,
    });
  };

  // Filtered Loans
  const filteredLoans = loans.filter((loan) => {
    const borrower = borrowerMap[loan.borrower_id];
    const matchesSearch =
      loan.purpose?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      borrower?.full_name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      String(loan.principal).includes(searchTerm);

    const matchesStatus = statusFilter === 'all' || loan.status === statusFilter;

    return matchesSearch && matchesStatus;
  });

  return (
    <div className="space-y-6 pb-12">
      {/* Page Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold text-zinc-900 dark:text-zinc-50">Loans Portfolio</h2>
          <p className="text-xs text-zinc-500 dark:text-zinc-400">
            Track loan applications, active amortization, and status transitions
          </p>
        </div>

        <button
          onClick={() => setIsNewLoanModalOpen(true)}
          className="inline-flex items-center justify-center gap-2 px-4 py-2 bg-zinc-900 dark:bg-zinc-100 text-white dark:text-zinc-900 rounded-lg text-sm font-semibold hover:bg-zinc-800 dark:hover:bg-zinc-200 transition shadow-xs"
        >
          <FilePlus className="w-4 h-4" /> New Loan
        </button>
      </div>

      {/* Filters & Tabs */}
      <div className="flex flex-col sm:flex-row items-center gap-3">
        {/* Search Input */}
        <div className="relative flex-1 w-full">
          <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-zinc-400" />
          <input
            type="text"
            placeholder="Search by borrower name, purpose, or principal..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full pl-9 pr-4 py-2 text-sm bg-white dark:bg-zinc-900 border border-zinc-200 dark:border-zinc-800 rounded-lg focus:outline-none focus:ring-2 focus:ring-zinc-900 dark:focus:ring-zinc-100 text-zinc-900 dark:text-zinc-100 placeholder-zinc-400"
          />
        </div>

        {/* Status Filter */}
        <div className="flex items-center gap-1.5 w-full sm:w-auto">
          <span className="text-xs font-medium text-zinc-500 shrink-0">Status:</span>
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="w-full sm:w-auto px-3 py-2 text-sm bg-white dark:bg-zinc-900 border border-zinc-200 dark:border-zinc-800 rounded-lg focus:outline-none focus:ring-2 focus:ring-zinc-900 dark:focus:ring-zinc-100 text-zinc-900 dark:text-zinc-100"
          >
            <option value="all">All Statuses</option>
            <option value="pending">Pending</option>
            <option value="active">Active</option>
            <option value="completed">Completed</option>
            <option value="defaulted">Defaulted</option>
            <option value="rejected">Rejected</option>
          </select>
        </div>
      </div>

      {/* Loans Table */}
      <div className="bg-white dark:bg-zinc-900 border border-zinc-200 dark:border-zinc-800 rounded-xl overflow-hidden shadow-xs">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm text-zinc-700 dark:text-zinc-300">
            <thead className="bg-zinc-50 dark:bg-zinc-800/60 text-xs uppercase font-semibold text-zinc-500 border-b border-zinc-200 dark:border-zinc-800">
              <tr>
                <th className="px-6 py-3.5">Borrower / Purpose</th>
                <th className="px-6 py-3.5">Terms</th>
                <th className="px-6 py-3.5">Disbursement</th>
                <th className="px-6 py-3.5">Progress / Balance</th>
                <th className="px-6 py-3.5">Status</th>
                <th className="px-6 py-3.5 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-zinc-200 dark:divide-zinc-800">
              {filteredLoans.length === 0 ? (
                <tr>
                  <td colSpan={6} className="px-6 py-8 text-center text-zinc-400 text-sm">
                    No loans found matching filter criteria.
                  </td>
                </tr>
              ) : (
                filteredLoans.map((loan) => {
                  const borrower = borrowerMap[loan.borrower_id];
                  const stats = getLoanStats(loan);

                  return (
                    <tr
                      key={loan.id}
                      onClick={() => onSelectLoan(loan.id)}
                      className="hover:bg-zinc-50 dark:hover:bg-zinc-800/50 cursor-pointer transition"
                    >
                      <td className="px-6 py-4">
                        <div className="font-semibold text-zinc-900 dark:text-zinc-100">
                          {borrower?.full_name || 'Unknown Borrower'}
                        </div>
                        <div className="text-xs text-zinc-500">{loan.purpose}</div>
                      </td>

                      <td className="px-6 py-4">
                        <div className="font-bold text-zinc-900 dark:text-zinc-100">
                          {formatCurrency(loan.principal)}
                        </div>
                        <div className="text-xs text-zinc-500">
                          {loan.interest_rate}% APR • {loan.term_months} mo
                        </div>
                      </td>

                      <td className="px-6 py-4 text-xs font-medium text-zinc-600 dark:text-zinc-400">
                        {formatDate(loan.disbursement_date)}
                      </td>

                      <td className="px-6 py-4">
                        {loan.status === 'active' || loan.status === 'completed' ? (
                          <div className="w-36">
                            <div className="flex justify-between text-xs mb-1">
                              <span className="font-medium text-zinc-500">{stats.progressPct}%</span>
                              <span className="font-bold">{formatCurrency(stats.outstandingBalance)}</span>
                            </div>
                            <div className="w-full h-1.5 bg-zinc-200 dark:bg-zinc-800 rounded-full overflow-hidden">
                              <div
                                className="h-full bg-zinc-900 dark:bg-zinc-100 rounded-full"
                                style={{ width: `${stats.progressPct}%` }}
                              />
                            </div>
                          </div>
                        ) : (
                          <span className="text-xs text-zinc-400">N/A</span>
                        )}
                      </td>

                      <td className="px-6 py-4">
                        <Badge variant={loan.status}>{loan.status}</Badge>
                      </td>

                      <td className="px-6 py-4 text-right" onClick={(e) => e.stopPropagation()}>
                        {loan.status === 'pending' ? (
                          <button
                            onClick={(e) => handleQuickApprove(e, loan.id)}
                            className="inline-flex items-center gap-1 px-3 py-1 bg-emerald-600 text-white rounded-md text-xs font-semibold hover:bg-emerald-700 transition"
                          >
                            <CheckCircle className="w-3.5 h-3.5" /> Approve
                          </button>
                        ) : (
                          <button
                            onClick={() => onSelectLoan(loan.id)}
                            className="text-xs font-medium text-zinc-600 dark:text-zinc-400 hover:text-zinc-900 dark:hover:text-zinc-100"
                          >
                            View Details
                          </button>
                        )}
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* New Loan Modal Dialog */}
      <Modal
        isOpen={isNewLoanModalOpen}
        onClose={() => setIsNewLoanModalOpen(false)}
        title="Issue New Loan"
        maxWidth="max-w-2xl"
      >
        <form onSubmit={handleCreateLoan} className="space-y-4">
          <div>
            <label className="block text-xs font-semibold text-zinc-700 dark:text-zinc-300 mb-1">
              Select Borrower *
            </label>
            <select
              name="borrower_id"
              required
              value={formData.borrower_id}
              onChange={handleInputChange}
              className="w-full px-3 py-2 text-sm bg-white dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-zinc-900 dark:focus:ring-zinc-100 text-zinc-900 dark:text-zinc-100"
            >
              <option value="">-- Choose Borrower --</option>
              {borrowers.map((b) => (
                <option key={b.id} value={b.id}>
                  {b.full_name} ({b.id_number || b.email || 'No ID'})
                </option>
              ))}
            </select>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
            <div>
              <label className="block text-xs font-semibold text-zinc-700 dark:text-zinc-300 mb-1">
                Principal Amount ($) *
              </label>
              <input
                type="number"
                name="principal"
                required
                min="1"
                value={formData.principal}
                onChange={handleInputChange}
                className="w-full px-3 py-2 text-sm bg-white dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-zinc-900 dark:focus:ring-zinc-100 text-zinc-900 dark:text-zinc-100"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-zinc-700 dark:text-zinc-300 mb-1">
                Annual Rate (%) *
              </label>
              <input
                type="number"
                name="interest_rate"
                required
                step="0.1"
                min="0"
                value={formData.interest_rate}
                onChange={handleInputChange}
                className="w-full px-3 py-2 text-sm bg-white dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-zinc-900 dark:focus:ring-zinc-100 text-zinc-900 dark:text-zinc-100"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-zinc-700 dark:text-zinc-300 mb-1">
                Term (Months) *
              </label>
              <input
                type="number"
                name="term_months"
                required
                min="1"
                max="60"
                value={formData.term_months}
                onChange={handleInputChange}
                className="w-full px-3 py-2 text-sm bg-white dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-zinc-900 dark:focus:ring-zinc-100 text-zinc-900 dark:text-zinc-100"
              />
            </div>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-semibold text-zinc-700 dark:text-zinc-300 mb-1">
                Loan Purpose *
              </label>
              <input
                type="text"
                name="purpose"
                required
                placeholder="e.g. Working Capital, Equipment"
                value={formData.purpose}
                onChange={handleInputChange}
                className="w-full px-3 py-2 text-sm bg-white dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-zinc-900 dark:focus:ring-zinc-100 text-zinc-900 dark:text-zinc-100"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-zinc-700 dark:text-zinc-300 mb-1">
                Disbursement Date
              </label>
              <input
                type="date"
                name="disbursement_date"
                value={formData.disbursement_date}
                onChange={handleInputChange}
                className="w-full px-3 py-2 text-sm bg-white dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-zinc-900 dark:focus:ring-zinc-100 text-zinc-900 dark:text-zinc-100"
              />
            </div>
          </div>

          {/* Auto-generated Amortization Preview */}
          {schedulePreview.length > 0 && (
            <div className="p-3 bg-zinc-50 dark:bg-zinc-800/60 rounded-lg border border-zinc-200 dark:border-zinc-700 space-y-2">
              <div className="flex justify-between items-center text-xs font-bold text-zinc-800 dark:text-zinc-200">
                <span>Amortization Schedule Preview</span>
                <span>Est. Monthly: {formatCurrency(schedulePreview[0].amount)}</span>
              </div>
              <div className="max-h-32 overflow-y-auto text-xs font-mono divide-y divide-zinc-200 dark:divide-zinc-700">
                {schedulePreview.map((inst) => (
                  <div key={inst.installmentNo} className="py-1 flex justify-between">
                    <span># {inst.installmentNo} ({formatDate(inst.due_date)})</span>
                    <span>P: {formatCurrency(inst.principal)} | I: {formatCurrency(inst.interest)} | Total: {formatCurrency(inst.amount)}</span>
                  </div>
                ))}
              </div>
            </div>
          )}

          <div>
            <label className="block text-xs font-semibold text-zinc-700 dark:text-zinc-300 mb-1">
              Notes
            </label>
            <textarea
              name="notes"
              rows="2"
              placeholder="Underwriting remarks..."
              value={formData.notes}
              onChange={handleInputChange}
              className="w-full px-3 py-2 text-sm bg-white dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-zinc-900 dark:focus:ring-zinc-100 text-zinc-900 dark:text-zinc-100"
            />
          </div>

          <div className="flex justify-end gap-3 pt-4 border-t border-zinc-200 dark:border-zinc-800">
            <button
              type="button"
              onClick={() => setIsNewLoanModalOpen(false)}
              className="px-4 py-2 text-sm font-medium text-zinc-600 dark:text-zinc-400 hover:text-zinc-900 dark:hover:text-zinc-100"
            >
              Cancel
            </button>
            <button
              type="submit"
              className="px-4 py-2 text-sm font-semibold text-white bg-zinc-900 dark:bg-zinc-100 dark:text-zinc-900 rounded-lg hover:bg-zinc-800 dark:hover:bg-zinc-200"
            >
              Create Pending Loan
            </button>
          </div>
        </form>
      </Modal>
    </div>
  );
}
