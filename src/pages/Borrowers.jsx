import React, { useState } from 'react';
import { Search, Plus, UserPlus, ShieldAlert } from 'lucide-react';
import { useCollection, addItem } from '../store/useStore';
import { assessBorrower, formatCurrency } from '../utils/loanUtils';
import Badge from '../components/Badge';
import Modal from '../components/Modal';

export default function Borrowers({ onSelectBorrower }) {
  const borrowers = useCollection('borrowers');
  const loans = useCollection('loans');

  const [searchTerm, setSearchTerm] = useState('');
  const [riskFilter, setRiskFilter] = useState('all');
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);

  // Form State
  const [formData, setFormData] = useState({
    full_name: '',
    email: '',
    phone: '',
    address: '',
    id_number: '',
    employment: '',
    monthly_income: '',
    credit_score: '50',
    risk_rating: 'medium',
    notes: '',
  });

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
  };

  const handleAddBorrower = (e) => {
    e.preventDefault();
    if (!formData.full_name) return;

    addItem('borrowers', {
      full_name: formData.full_name,
      email: formData.email,
      phone: formData.phone,
      address: formData.address,
      id_number: formData.id_number,
      employment: formData.employment,
      monthly_income: Number(formData.monthly_income) || 0,
      credit_score: Number(formData.credit_score) || 50,
      risk_rating: formData.risk_rating || 'medium',
      notes: formData.notes,
    });

    setIsAddModalOpen(false);
    setFormData({
      full_name: '',
      email: '',
      phone: '',
      address: '',
      id_number: '',
      employment: '',
      monthly_income: '',
      credit_score: '50',
      risk_rating: 'medium',
      notes: '',
    });
  };

  // Filtered borrowers
  const filteredBorrowers = borrowers.filter((b) => {
    const matchesSearch =
      b.full_name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      b.email?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      b.phone?.includes(searchTerm) ||
      b.id_number?.toLowerCase().includes(searchTerm.toLowerCase());

    const bLoans = loans.filter((l) => l.borrower_id === b.id);
    const assessment = assessBorrower(b, bLoans);

    const matchesRisk = riskFilter === 'all' || assessment.riskRating === riskFilter;

    return matchesSearch && matchesRisk;
  });

  return (
    <div className="space-y-6 pb-12">
      {/* Top Header & Actions */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold text-zinc-900 dark:text-zinc-50">Borrowers</h2>
          <p className="text-xs text-zinc-500 dark:text-zinc-400">
            Manage client profiles, risk assessments & contact information
          </p>
        </div>

        <button
          onClick={() => setIsAddModalOpen(true)}
          className="inline-flex items-center justify-center gap-2 px-4 py-2 bg-zinc-900 dark:bg-zinc-100 text-white dark:text-zinc-900 rounded-lg text-sm font-semibold hover:bg-zinc-800 dark:hover:bg-zinc-200 transition shadow-xs"
        >
          <UserPlus className="w-4 h-4" /> Add Borrower
        </button>
      </div>

      {/* Filters Bar */}
      <div className="flex flex-col sm:flex-row items-center gap-3">
        {/* Search */}
        <div className="relative flex-1 w-full">
          <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-zinc-400" />
          <input
            type="text"
            placeholder="Search by name, email, phone, ID..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full pl-9 pr-4 py-2 text-sm bg-white dark:bg-zinc-900 border border-zinc-200 dark:border-zinc-800 rounded-lg focus:outline-none focus:ring-2 focus:ring-zinc-900 dark:focus:ring-zinc-100 text-zinc-900 dark:text-zinc-100 placeholder-zinc-400"
          />
        </div>

        {/* Risk Filter */}
        <div className="flex items-center gap-1.5 w-full sm:w-auto">
          <span className="text-xs font-medium text-zinc-500 shrink-0">Risk:</span>
          <select
            value={riskFilter}
            onChange={(e) => setRiskFilter(e.target.value)}
            className="w-full sm:w-auto px-3 py-2 text-sm bg-white dark:bg-zinc-900 border border-zinc-200 dark:border-zinc-800 rounded-lg focus:outline-none focus:ring-2 focus:ring-zinc-900 dark:focus:ring-zinc-100 text-zinc-900 dark:text-zinc-100"
          >
            <option value="all">All Risk Ratings</option>
            <option value="low">Low Risk</option>
            <option value="medium">Medium Risk</option>
            <option value="high">High Risk</option>
          </select>
        </div>
      </div>

      {/* Borrowers Table */}
      <div className="bg-white dark:bg-zinc-900 border border-zinc-200 dark:border-zinc-800 rounded-xl overflow-hidden shadow-xs">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm text-zinc-700 dark:text-zinc-300">
            <thead className="bg-zinc-50 dark:bg-zinc-800/60 text-xs uppercase font-semibold text-zinc-500 border-b border-zinc-200 dark:border-zinc-800">
              <tr>
                <th className="px-6 py-3.5">Borrower</th>
                <th className="px-6 py-3.5">ID / Employment</th>
                <th className="px-6 py-3.5">Monthly Income</th>
                <th className="px-6 py-3.5">Credit Score / Risk</th>
                <th className="px-6 py-3.5">Loans</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-zinc-200 dark:divide-zinc-800">
              {filteredBorrowers.length === 0 ? (
                <tr>
                  <td colSpan={5} className="px-6 py-8 text-center text-zinc-400 text-sm">
                    No borrowers found matching your criteria.
                  </td>
                </tr>
              ) : (
                filteredBorrowers.map((borrower) => {
                  const borrowerLoans = loans.filter((l) => l.borrower_id === borrower.id);
                  const assessment = assessBorrower(borrower, borrowerLoans);

                  return (
                    <tr
                      key={borrower.id}
                      onClick={() => onSelectBorrower(borrower.id)}
                      className="hover:bg-zinc-50 dark:hover:bg-zinc-800/50 cursor-pointer transition"
                    >
                      <td className="px-6 py-4">
                        <div className="font-semibold text-zinc-900 dark:text-zinc-100">
                          {borrower.full_name}
                        </div>
                        <div className="text-xs text-zinc-500">{borrower.email || borrower.phone}</div>
                      </td>

                      <td className="px-6 py-4">
                        <div className="font-medium text-zinc-800 dark:text-zinc-200">
                          {borrower.id_number || 'No ID'}
                        </div>
                        <div className="text-xs text-zinc-500">{borrower.employment || 'N/A'}</div>
                      </td>

                      <td className="px-6 py-4 font-semibold text-zinc-900 dark:text-zinc-100">
                        {formatCurrency(borrower.monthly_income)}
                      </td>

                      <td className="px-6 py-4">
                        <div className="flex items-center gap-2">
                          <span className="font-bold text-xs">{assessment.creditScore}/100</span>
                          <Badge variant={assessment.riskRating}>{assessment.riskRating}</Badge>
                        </div>
                      </td>

                      <td className="px-6 py-4">
                        <span className="text-xs font-semibold px-2 py-1 bg-zinc-100 dark:bg-zinc-800 rounded-md text-zinc-700 dark:text-zinc-300">
                          {borrowerLoans.length} loan(s)
                        </span>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Add Borrower Dialog Form */}
      <Modal isOpen={isAddModalOpen} onClose={() => setIsAddModalOpen(false)} title="Add New Borrower">
        <form onSubmit={handleAddBorrower} className="space-y-4">
          <div>
            <label className="block text-xs font-semibold text-zinc-700 dark:text-zinc-300 mb-1">
              Full Name *
            </label>
            <input
              type="text"
              name="full_name"
              required
              placeholder="e.g. Sarah Jenkins"
              value={formData.full_name}
              onChange={handleInputChange}
              className="w-full px-3 py-2 text-sm bg-white dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-zinc-900 dark:focus:ring-zinc-100 text-zinc-900 dark:text-zinc-100"
            />
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-semibold text-zinc-700 dark:text-zinc-300 mb-1">
                Email
              </label>
              <input
                type="email"
                name="email"
                placeholder="sarah@example.com"
                value={formData.email}
                onChange={handleInputChange}
                className="w-full px-3 py-2 text-sm bg-white dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-zinc-900 dark:focus:ring-zinc-100 text-zinc-900 dark:text-zinc-100"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-zinc-700 dark:text-zinc-300 mb-1">
                Phone Number
              </label>
              <input
                type="text"
                name="phone"
                placeholder="+1 (555) 000-0000"
                value={formData.phone}
                onChange={handleInputChange}
                className="w-full px-3 py-2 text-sm bg-white dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-zinc-900 dark:focus:ring-zinc-100 text-zinc-900 dark:text-zinc-100"
              />
            </div>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-semibold text-zinc-700 dark:text-zinc-300 mb-1">
                ID Number
              </label>
              <input
                type="text"
                name="id_number"
                placeholder="ID-123456"
                value={formData.id_number}
                onChange={handleInputChange}
                className="w-full px-3 py-2 text-sm bg-white dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-zinc-900 dark:focus:ring-zinc-100 text-zinc-900 dark:text-zinc-100"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-zinc-700 dark:text-zinc-300 mb-1">
                Employment
              </label>
              <input
                type="text"
                name="employment"
                placeholder="Store Manager / Freelancer"
                value={formData.employment}
                onChange={handleInputChange}
                className="w-full px-3 py-2 text-sm bg-white dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-zinc-900 dark:focus:ring-zinc-100 text-zinc-900 dark:text-zinc-100"
              />
            </div>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
            <div>
              <label className="block text-xs font-semibold text-zinc-700 dark:text-zinc-300 mb-1">
                Monthly Income ($)
              </label>
              <input
                type="number"
                name="monthly_income"
                placeholder="4000"
                value={formData.monthly_income}
                onChange={handleInputChange}
                className="w-full px-3 py-2 text-sm bg-white dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-zinc-900 dark:focus:ring-zinc-100 text-zinc-900 dark:text-zinc-100"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-zinc-700 dark:text-zinc-300 mb-1">
                Credit Score (0–100)
              </label>
              <input
                type="number"
                min="0"
                max="100"
                name="credit_score"
                value={formData.credit_score}
                onChange={handleInputChange}
                className="w-full px-3 py-2 text-sm bg-white dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-zinc-900 dark:focus:ring-zinc-100 text-zinc-900 dark:text-zinc-100"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-zinc-700 dark:text-zinc-300 mb-1">
                Initial Risk
              </label>
              <select
                name="risk_rating"
                value={formData.risk_rating}
                onChange={handleInputChange}
                className="w-full px-3 py-2 text-sm bg-white dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-zinc-900 dark:focus:ring-zinc-100 text-zinc-900 dark:text-zinc-100"
              >
                <option value="low">Low Risk</option>
                <option value="medium">Medium Risk</option>
                <option value="high">High Risk</option>
              </select>
            </div>
          </div>

          <div>
            <label className="block text-xs font-semibold text-zinc-700 dark:text-zinc-300 mb-1">
              Address
            </label>
            <input
              type="text"
              name="address"
              placeholder="123 Main Street, City, State"
              value={formData.address}
              onChange={handleInputChange}
              className="w-full px-3 py-2 text-sm bg-white dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-zinc-900 dark:focus:ring-zinc-100 text-zinc-900 dark:text-zinc-100"
            />
          </div>

          <div>
            <label className="block text-xs font-semibold text-zinc-700 dark:text-zinc-300 mb-1">
              Notes
            </label>
            <textarea
              name="notes"
              rows="2"
              placeholder="Additional client notes or background info..."
              value={formData.notes}
              onChange={handleInputChange}
              className="w-full px-3 py-2 text-sm bg-white dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-zinc-900 dark:focus:ring-zinc-100 text-zinc-900 dark:text-zinc-100"
            />
          </div>

          <div className="flex justify-end gap-3 pt-4 border-t border-zinc-200 dark:border-zinc-800">
            <button
              type="button"
              onClick={() => setIsAddModalOpen(false)}
              className="px-4 py-2 text-sm font-medium text-zinc-600 dark:text-zinc-400 hover:text-zinc-900 dark:hover:text-zinc-100"
            >
              Cancel
            </button>
            <button
              type="submit"
              className="px-4 py-2 text-sm font-semibold text-white bg-zinc-900 dark:bg-zinc-100 dark:text-zinc-900 rounded-lg hover:bg-zinc-800 dark:hover:bg-zinc-200"
            >
              Save Borrower
            </button>
          </div>
        </form>
      </Modal>
    </div>
  );
}
