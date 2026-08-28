import React from 'react';
import { ArrowLeft, User, Phone, Mail, MapPin, Briefcase, DollarSign, ShieldAlert, CreditCard, PlusCircle } from 'lucide-react';
import { useCollection } from '../store/useStore';
import { assessBorrower, formatCurrency, formatDate, getLoanStats } from '../utils/loanUtils';
import { Card } from '../components/Card';
import Badge from '../components/Badge';
import ProgressBar from '../components/ProgressBar';

export default function BorrowerDetail({ borrowerId, onBack, onSelectLoan, onCreateLoanForBorrower }) {
  const borrowers = useCollection('borrowers');
  const loans = useCollection('loans');

  const borrower = borrowers.find((b) => b.id === borrowerId);

  if (!borrower) {
    return (
      <div className="py-12 text-center">
        <p className="text-zinc-500">Borrower not found.</p>
        <button
          onClick={onBack}
          className="mt-4 px-4 py-2 bg-zinc-900 text-white dark:bg-zinc-100 dark:text-zinc-900 rounded-lg text-sm font-medium"
        >
          Back to Borrowers
        </button>
      </div>
    );
  }

  const borrowerLoans = loans.filter((l) => l.borrower_id === borrower.id);
  const assessment = assessBorrower(borrower, borrowerLoans);

  // Compute total active outstanding for borrower
  const activeOutstanding = borrowerLoans
    .filter((l) => l.status === 'active' || l.status === 'defaulted')
    .reduce((sum, loan) => sum + getLoanStats(loan).outstandingBalance, 0);

  return (
    <div className="space-y-6 pb-12">
      {/* Back button */}
      <div className="flex items-center justify-between">
        <button
          onClick={onBack}
          className="inline-flex items-center gap-2 text-sm font-medium text-zinc-600 dark:text-zinc-400 hover:text-zinc-900 dark:hover:text-zinc-100 transition"
        >
          <ArrowLeft className="w-4 h-4" /> Back to Borrowers
        </button>
        <button
          onClick={() => onCreateLoanForBorrower(borrower.id)}
          className="inline-flex items-center gap-2 px-3.5 py-2 bg-zinc-900 dark:bg-zinc-100 text-white dark:text-zinc-900 rounded-lg text-sm font-semibold hover:bg-zinc-800 dark:hover:bg-zinc-200 transition"
        >
          <PlusCircle className="w-4 h-4" /> Issue New Loan
        </button>
      </div>

      {/* Main Info Header */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Contact Info Card */}
        <Card className="lg:col-span-2 space-y-4">
          <div className="flex items-start justify-between">
            <div>
              <h2 className="text-2xl font-bold text-zinc-900 dark:text-zinc-50">{borrower.full_name}</h2>
              <p className="text-xs text-zinc-500 dark:text-zinc-400 mt-0.5">ID: {borrower.id_number || 'N/A'}</p>
            </div>
            <Badge variant={assessment.riskRating}>{assessment.riskRating} risk</Badge>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 pt-2 text-sm">
            <div className="flex items-center gap-2.5 text-zinc-700 dark:text-zinc-300">
              <Mail className="w-4 h-4 text-zinc-400 shrink-0" />
              <span>{borrower.email || 'No email provided'}</span>
            </div>
            <div className="flex items-center gap-2.5 text-zinc-700 dark:text-zinc-300">
              <Phone className="w-4 h-4 text-zinc-400 shrink-0" />
              <span>{borrower.phone || 'No phone provided'}</span>
            </div>
            <div className="flex items-center gap-2.5 text-zinc-700 dark:text-zinc-300">
              <MapPin className="w-4 h-4 text-zinc-400 shrink-0" />
              <span>{borrower.address || 'No address provided'}</span>
            </div>
            <div className="flex items-center gap-2.5 text-zinc-700 dark:text-zinc-300">
              <Briefcase className="w-4 h-4 text-zinc-400 shrink-0" />
              <span>{borrower.employment || 'N/A'}</span>
            </div>
          </div>

          {borrower.notes && (
            <div className="p-3 bg-zinc-50 dark:bg-zinc-800/60 rounded-lg text-xs text-zinc-600 dark:text-zinc-300 border border-zinc-200/50 dark:border-zinc-700/50">
              <span className="font-semibold text-zinc-700 dark:text-zinc-200">Notes:</span> {borrower.notes}
            </div>
          )}
        </Card>

        {/* Financial & Assessment Card */}
        <Card className="space-y-4 flex flex-col justify-between">
          <div>
            <h3 className="font-bold text-zinc-900 dark:text-zinc-100 flex items-center gap-2">
              <ShieldAlert className="w-4 h-4 text-zinc-500" /> Credit Risk Assessment
            </h3>
            <p className="text-xs text-zinc-500 dark:text-zinc-400">Derived from income, DTI ratio & history</p>
          </div>

          <div className="space-y-3">
            <div className="flex items-center justify-between">
              <span className="text-xs font-medium text-zinc-500">Derived Credit Score</span>
              <span className="text-lg font-extrabold text-zinc-900 dark:text-zinc-100">{assessment.creditScore} / 100</span>
            </div>

            <div className="flex items-center justify-between">
              <span className="text-xs font-medium text-zinc-500">Monthly Income</span>
              <span className="text-sm font-semibold text-zinc-900 dark:text-zinc-100">{formatCurrency(borrower.monthly_income)}</span>
            </div>

            <div className="flex items-center justify-between">
              <span className="text-xs font-medium text-zinc-500">Debt-To-Income (DTI)</span>
              <span className="text-sm font-semibold text-zinc-900 dark:text-zinc-100">{assessment.dtiPct}%</span>
            </div>

            <div className="pt-2 border-t border-zinc-200 dark:border-zinc-800 flex items-center justify-between">
              <span className="text-xs font-medium text-zinc-500">Active Outstanding Debt</span>
              <span className="text-base font-bold text-emerald-600 dark:text-emerald-400">{formatCurrency(activeOutstanding)}</span>
            </div>
          </div>
        </Card>
      </div>

      {/* Loan History Section */}
      <Card>
        <div className="flex items-center justify-between mb-4">
          <div>
            <h3 className="font-bold text-zinc-900 dark:text-zinc-100 flex items-center gap-2">
              <CreditCard className="w-4 h-4" /> Loan History ({borrowerLoans.length})
            </h3>
            <p className="text-xs text-zinc-500">All historical and active loans for {borrower.full_name}</p>
          </div>
        </div>

        {borrowerLoans.length === 0 ? (
          <div className="py-8 text-center text-sm text-zinc-500">
            No loans found for this borrower.
          </div>
        ) : (
          <div className="divide-y divide-zinc-200 dark:divide-zinc-800">
            {borrowerLoans.map((loan) => {
              const stats = getLoanStats(loan);
              return (
                <div
                  key={loan.id}
                  onClick={() => onSelectLoan(loan.id)}
                  className="py-4 hover:bg-zinc-50 dark:hover:bg-zinc-800/50 px-3 rounded-lg cursor-pointer transition flex flex-col sm:flex-row sm:items-center justify-between gap-4"
                >
                  <div className="space-y-1">
                    <div className="flex items-center gap-2">
                      <span className="font-bold text-sm text-zinc-900 dark:text-zinc-100">{loan.purpose}</span>
                      <Badge variant={loan.status}>{loan.status}</Badge>
                    </div>
                    <p className="text-xs text-zinc-500">
                      Principal: {formatCurrency(loan.principal)} @ {loan.interest_rate}% rate • {loan.term_months} months term
                    </p>
                  </div>

                  <div className="sm:w-48 text-right space-y-1">
                    {loan.status === 'active' || loan.status === 'completed' ? (
                      <div>
                        <ProgressBar value={stats.progressPct} max={100} showLabel={true} />
                        <span className="text-[11px] text-zinc-400">
                          Bal: {formatCurrency(stats.outstandingBalance)}
                        </span>
                      </div>
                    ) : (
                      <span className="text-xs text-zinc-400">Created: {formatDate(loan.createdAt)}</span>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </Card>
    </div>
  );
}
