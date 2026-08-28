/**
 * Utility functions for MicroLend loan calculations, schedule generation,
 * borrower risk assessment, and formatting.
 */

/**
 * Formats a number as USD currency.
 */
export function formatCurrency(amount) {
  const num = Number(amount) || 0;
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(num);
}

/**
 * Formats a date string into MMM DD, YYYY format.
 */
export function formatDate(dateStr) {
  if (!dateStr) return 'N/A';
  const date = new Date(dateStr);
  if (isNaN(date.getTime())) return dateStr;
  return new Intl.DateTimeFormat('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  }).format(date);
}

/**
 * Formats a number as a percentage string.
 */
export function formatPercent(rate) {
  const num = Number(rate) || 0;
  return `${num.toFixed(1)}%`;
}

/**
 * Generates an amortizing loan schedule using standard equal-monthly-payment formula.
 * @param {number} principal - Loan amount
 * @param {number} interestRateAnnual - Annual interest rate percentage (e.g. 12 for 12%)
 * @param {number} termMonths - Loan duration in months
 * @param {string} disbursementDate - Start / disbursement date string (YYYY-MM-DD)
 * @returns {Array} Array of schedule installments
 */
export function generateSchedule(principal, interestRateAnnual, termMonths, disbursementDate) {
  const p = Math.max(0, Number(principal) || 0);
  const rate = Math.max(0, Number(interestRateAnnual) || 0);
  const n = Math.max(1, parseInt(termMonths, 10) || 1);
  const startDate = disbursementDate ? new Date(disbursementDate) : new Date();

  const r = (rate / 100) / 12;

  let monthlyPayment = 0;
  if (r > 0) {
    monthlyPayment = (p * r * Math.pow(1 + r, n)) / (Math.pow(1 + r, n) - 1);
  } else {
    monthlyPayment = p / n;
  }

  let balance = p;
  const schedule = [];

  for (let i = 1; i <= n; i++) {
    const dueDate = new Date(startDate);
    dueDate.setMonth(dueDate.getMonth() + i);
    const dateStr = dueDate.toISOString().split('T')[0];

    const interestForMonth = balance * r;
    let principalForMonth = monthlyPayment - interestForMonth;

    // Handle last installment edge cases / rounding drift
    if (i === n || balance - principalForMonth < 0.01) {
      principalForMonth = balance;
      balance = 0;
    } else {
      balance = balance - principalForMonth;
    }

    const installmentAmount = principalForMonth + interestForMonth;

    schedule.push({
      installmentNo: i,
      due_date: dateStr,
      amount: Math.round(installmentAmount * 100) / 100,
      principal: Math.round(principalForMonth * 100) / 100,
      interest: Math.round(interestForMonth * 100) / 100,
      balance: Math.max(0, Math.round(balance * 100) / 100),
    });
  }

  return schedule;
}

/**
 * Evaluates payment history against schedule to assign status to each installment.
 * Statuses: 'paid', 'partial', 'overdue', 'pending'
 */
export function getScheduleWithStatus(schedule = [], payments = [], loanStatus = 'active', referenceDate = new Date()) {
  const refDate = new Date(referenceDate);
  refDate.setHours(23, 59, 59, 999);

  // Total paid available to allocate sequentially
  let availablePayment = (payments || []).reduce((sum, p) => sum + (Number(p.amount) || 0), 0);

  return (schedule || []).map((inst) => {
    const instAmount = Number(inst.amount) || 0;
    let paidAmount = 0;
    let status = 'pending';

    if (availablePayment >= instAmount) {
      paidAmount = instAmount;
      availablePayment -= instAmount;
      status = 'paid';
    } else if (availablePayment > 0) {
      paidAmount = availablePayment;
      availablePayment = 0;
      status = 'partial';
    } else {
      paidAmount = 0;
    }

    if (status !== 'paid') {
      const dueDate = new Date(inst.due_date);
      dueDate.setHours(23, 59, 59, 999);

      if (dueDate < refDate) {
        status = 'overdue';
      }
    }

    // Override if loan was rejected or completed or defaulted
    if (loanStatus === 'rejected') {
      status = 'cancelled';
    } else if (loanStatus === 'defaulted' && status !== 'paid') {
      status = 'overdue'; // or defaulted
    }

    const remainingAmount = Math.max(0, Math.round((instAmount - paidAmount) * 100) / 100);

    return {
      ...inst,
      paidAmount: Math.round(paidAmount * 100) / 100,
      remainingAmount,
      status,
    };
  });
}

/**
 * Computes aggregated statistics for a single loan.
 */
export function getLoanStats(loan) {
  if (!loan) return {};

  const payments = loan.payments || [];
  const schedule = loan.schedule || [];

  const totalPaid = payments.reduce((sum, p) => sum + (Number(p.amount) || 0), 0);
  const totalScheduled = schedule.reduce((sum, s) => sum + (Number(s.amount) || 0), 0) || Number(loan.principal) || 0;

  const scheduleWithStatus = getScheduleWithStatus(schedule, payments, loan.status);

  const outstandingBalance = scheduleWithStatus.reduce((sum, inst) => {
    return sum + (inst.remainingAmount || 0);
  }, 0);

  const overdueAmount = scheduleWithStatus
    .filter((inst) => inst.status === 'overdue')
    .reduce((sum, inst) => sum + inst.remainingAmount, 0);

  const progressPct = totalScheduled > 0 ? Math.min(100, Math.round((totalPaid / totalScheduled) * 100)) : 0;

  const nextDue = scheduleWithStatus.find((inst) => inst.status === 'pending' || inst.status === 'overdue' || inst.status === 'partial');

  return {
    totalDisbursed: Number(loan.principal) || 0,
    totalScheduled: Math.round(totalScheduled * 100) / 100,
    totalPaid: Math.round(totalPaid * 100) / 100,
    outstandingBalance: Math.round(outstandingBalance * 100) / 100,
    overdueAmount: Math.round(overdueAmount * 100) / 100,
    progressPct,
    nextDue: nextDue ? { due_date: nextDue.due_date, amount: nextDue.remainingAmount, status: nextDue.status } : null,
    scheduleWithStatus,
  };
}

/**
 * Assesses a borrower's risk rating based on income, active loan obligations,
 * credit score, and payment track record.
 */
export function assessBorrower(borrower, borrowerLoans = []) {
  if (!borrower) return { creditScore: 50, dtiPct: 0, riskRating: 'medium' };

  const baseCreditScore = Number(borrower.credit_score) || 50;
  const monthlyIncome = Number(borrower.monthly_income) || 0;

  // Active loans monthly payment obligation
  const activeLoans = borrowerLoans.filter((l) => l.status === 'active');
  let monthlyDebt = 0;

  activeLoans.forEach((loan) => {
    if (loan.schedule && loan.schedule.length > 0) {
      monthlyDebt += Number(loan.schedule[0].amount) || 0;
    } else if (loan.principal && loan.term_months) {
      monthlyDebt += Number(loan.principal) / Number(loan.term_months);
    }
  });

  const dtiPct = monthlyIncome > 0 ? Math.round((monthlyDebt / monthlyIncome) * 100) : (monthlyDebt > 0 ? 100 : 0);

  const completedLoans = borrowerLoans.filter((l) => l.status === 'completed');
  const defaultedLoans = borrowerLoans.filter((l) => l.status === 'defaulted');

  // Adjust score based on history
  let scoreAdjustment = 0;
  scoreAdjustment += Math.min(30, completedLoans.length * 10);
  scoreAdjustment -= defaultedLoans.length * 25;

  if (dtiPct > 50) scoreAdjustment -= 15;
  else if (dtiPct > 35) scoreAdjustment -= 5;

  const derivedScore = Math.max(0, Math.min(100, baseCreditScore + scoreAdjustment));

  let riskRating = 'medium';
  if (derivedScore >= 70 && dtiPct <= 35) {
    riskRating = 'low';
  } else if (derivedScore < 45 || dtiPct > 50 || defaultedLoans.length > 0) {
    riskRating = 'high';
  }

  return {
    creditScore: derivedScore,
    baseCreditScore,
    dtiPct,
    riskRating,
    monthlyDebt: Math.round(monthlyDebt * 100) / 100,
    completedCount: completedLoans.length,
    defaultedCount: defaultedLoans.length,
    activeCount: activeLoans.length,
  };
}
