import React, { useState } from 'react';
import Header from './components/Header';
import { Sidebar, BottomNav } from './components/Navigation';
import Dashboard from './pages/Dashboard';
import Borrowers from './pages/Borrowers';
import BorrowerDetail from './pages/BorrowerDetail';
import Loans from './pages/Loans';
import LoanDetail from './pages/LoanDetail';

export default function App() {
  const [activeTab, setActiveTab] = useState('dashboard');
  const [selectedBorrowerId, setSelectedBorrowerId] = useState(null);
  const [selectedLoanId, setSelectedLoanId] = useState(null);
  const [issueLoanBorrowerId, setIssueLoanBorrowerId] = useState(null);

  // Navigation handlers
  const handleNavTab = (tab) => {
    setActiveTab(tab);
    setSelectedBorrowerId(null);
    setSelectedLoanId(null);
    setIssueLoanBorrowerId(null);
  };

  const handleSelectBorrower = (id) => {
    setSelectedBorrowerId(id);
    setSelectedLoanId(null);
  };

  const handleSelectLoan = (id) => {
    setSelectedLoanId(id);
  };

  const handleCreateLoanForBorrower = (borrowerId) => {
    setIssueLoanBorrowerId(borrowerId);
    setActiveTab('loans');
    setSelectedBorrowerId(null);
  };

  const getPageTitle = () => {
    if (selectedLoanId) return 'Loan Details';
    if (selectedBorrowerId) return 'Borrower Profile';
    if (activeTab === 'dashboard') return 'Dashboard';
    if (activeTab === 'borrowers') return 'Borrowers';
    if (activeTab === 'loans') return 'Loans';
    return 'MicroLend';
  };

  return (
    <div className="min-h-screen bg-zinc-50 dark:bg-zinc-950 text-zinc-900 dark:text-zinc-100 flex">
      {/* Responsive Desktop Sidebar */}
      <Sidebar activeTab={activeTab} setActiveTab={handleNavTab} />

      {/* Main Content Area */}
      <div className="flex-1 flex flex-col min-w-0 pb-16 md:pb-0">
        <Header pageTitle={getPageTitle()} />

        <main className="flex-1 p-4 md:p-8 max-w-7xl mx-auto w-full">
          {/* Detail Views vs Tab Views */}
          {selectedLoanId ? (
            <LoanDetail
              loanId={selectedLoanId}
              onBack={() => setSelectedLoanId(null)}
              onSelectBorrower={handleSelectBorrower}
            />
          ) : selectedBorrowerId ? (
            <BorrowerDetail
              borrowerId={selectedBorrowerId}
              onBack={() => setSelectedBorrowerId(null)}
              onSelectLoan={handleSelectLoan}
              onCreateLoanForBorrower={handleCreateLoanForBorrower}
            />
          ) : (
            <>
              {activeTab === 'dashboard' && (
                <Dashboard
                  onSelectLoan={handleSelectLoan}
                  onSelectBorrower={handleSelectBorrower}
                />
              )}

              {activeTab === 'borrowers' && (
                <Borrowers onSelectBorrower={handleSelectBorrower} />
              )}

              {activeTab === 'loans' && (
                <Loans
                  onSelectLoan={handleSelectLoan}
                  initialBorrowerId={issueLoanBorrowerId}
                />
              )}
            </>
          )}
        </main>
      </div>

      {/* Responsive Mobile Bottom Nav */}
      <BottomNav activeTab={activeTab} setActiveTab={handleNavTab} />
    </div>
  );
}
