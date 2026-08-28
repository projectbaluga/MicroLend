import { describe, it, expect } from 'vitest';
import {
  formatCurrency,
  formatDate,
  formatPercent,
  generateSchedule,
  getScheduleWithStatus,
  getLoanStats,
  assessBorrower,
} from './loanUtils';

describe('loanUtils', () => {
  describe('formatting', () => {
    it('formats currency properly', () => {
      expect(formatCurrency(1250.5)).toBe('$1,250.50');
      expect(formatCurrency(0)).toBe('$0.00');
    });

    it('formats dates properly', () => {
      expect(formatDate('2025-01-15')).toBe('Jan 15, 2025');
      expect(formatDate('')).toBe('N/A');
    });

    it('formats percentage properly', () => {
      expect(formatPercent(12.5)).toBe('12.5%');
    });
  });

  describe('generateSchedule', () => {
    it('generates standard amortizing schedule correctly', () => {
      const schedule = generateSchedule(1000, 12, 12, '2025-01-01');
      expect(schedule).toHaveLength(12);
      expect(schedule[0].due_date).toBe('2025-02-01');
      expect(schedule[0].amount).toBeGreaterThan(0);
      expect(schedule[11].balance).toBe(0);
    });

    it('handles 0% interest rate gracefully', () => {
      const schedule = generateSchedule(1200, 0, 12, '2025-01-01');
      expect(schedule).toHaveLength(12);
      expect(schedule[0].amount).toBe(100);
      expect(schedule[0].interest).toBe(0);
      expect(schedule[11].balance).toBe(0);
    });
  });

  describe('getScheduleWithStatus', () => {
    it('marks installments as paid or partial based on payments', () => {
      const schedule = [
        { installmentNo: 1, due_date: '2025-02-01', amount: 100 },
        { installmentNo: 2, due_date: '2025-03-01', amount: 100 },
      ];
      const payments = [{ amount: 150 }];
      const result = getScheduleWithStatus(schedule, payments, 'active', '2025-01-15');

      expect(result[0].status).toBe('paid');
      expect(result[0].paidAmount).toBe(100);
      expect(result[1].status).toBe('partial');
      expect(result[1].paidAmount).toBe(50);
      expect(result[1].remainingAmount).toBe(50);
    });

    it('marks past-due pending installments as overdue', () => {
      const schedule = [{ installmentNo: 1, due_date: '2025-01-01', amount: 100 }];
      const payments = [];
      const result = getScheduleWithStatus(schedule, payments, 'active', '2025-02-01');

      expect(result[0].status).toBe('overdue');
    });
  });

  describe('getLoanStats', () => {
    it('calculates totals, balance, and progress percentage correctly', () => {
      const loan = {
        principal: 1000,
        status: 'active',
        schedule: [
          { installmentNo: 1, due_date: '2025-02-01', amount: 100 },
          { installmentNo: 2, due_date: '2025-03-01', amount: 100 },
        ],
        payments: [{ amount: 100 }],
      };

      const stats = getLoanStats(loan);
      expect(stats.totalDisbursed).toBe(1000);
      expect(stats.totalPaid).toBe(100);
      expect(stats.outstandingBalance).toBe(100);
      expect(stats.progressPct).toBe(50);
    });
  });

  describe('assessBorrower', () => {
    it('assesses risk rating and DTI properly', () => {
      const borrower = {
        credit_score: 80,
        monthly_income: 4000,
      };
      const loans = [
        {
          status: 'active',
          schedule: [{ amount: 400 }],
        },
        {
          status: 'completed',
        },
      ];

      const assessment = assessBorrower(borrower, loans);
      expect(assessment.dtiPct).toBe(10);
      expect(assessment.riskRating).toBe('low');
      expect(assessment.completedCount).toBe(1);
    });

    it('assigns high risk rating for defaulted loans or high DTI', () => {
      const borrower = {
        credit_score: 50,
        monthly_income: 1000,
      };
      const loans = [{ status: 'defaulted' }];

      const assessment = assessBorrower(borrower, loans);
      expect(assessment.riskRating).toBe('high');
    });
  });
});
