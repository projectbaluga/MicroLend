import { generateSchedule, assessBorrower } from '../utils/loanUtils';

const STORAGE_PREFIX = 'microlend_';
const QUEUE_KEY = `${STORAGE_PREFIX}write_queue`;

// Event listeners for store reactivity
const listeners = new Set();

// In-memory cache to maintain reference stability for useSyncExternalStore
let cache = {};

export function clearStoreCache() {
  cache = {};
}

function notify() {
  listeners.forEach((listener) => listener());
}

/**
 * Gets item from LocalStorage with in-memory caching for reference stability.
 */
function getItem(key, defaultValue = null) {
  if (cache[key] !== undefined) {
    return cache[key];
  }
  try {
    const data = localStorage.getItem(key);
    const parsed = data ? JSON.parse(data) : defaultValue;
    cache[key] = parsed;
    return parsed;
  } catch (e) {
    console.error(`Error reading ${key} from LocalStorage`, e);
    cache[key] = defaultValue;
    return defaultValue;
  }
}

/**
 * Sets raw item in LocalStorage and updates cache.
 */
function setItem(key, value) {
  try {
    cache[key] = value;
    localStorage.setItem(key, JSON.stringify(value));
  } catch (e) {
    console.error(`Error writing ${key} to LocalStorage`, e);
  }
}

/**
 * Write queue operations
 */
export function getQueue() {
  return getItem(QUEUE_KEY, []);
}

function pushToQueue(operation) {
  const queue = getQueue();
  const updatedQueue = [
    ...queue,
    {
      id: `queue_${Date.now()}_${Math.random().toString(36).substr(2, 5)}`,
      timestamp: new Date().toISOString(),
      ...operation,
    },
  ];
  setItem(QUEUE_KEY, updatedQueue);
}

/**
 * Sync all queued write actions.
 */
export function syncAll() {
  return new Promise((resolve) => {
    setTimeout(() => {
      setItem(QUEUE_KEY, []);
      notify();
      resolve({ success: true, syncedCount: getQueue().length });
    }, 500);
  });
}

/**
 * Collection operations
 */
export function getCollection(collectionName) {
  return getItem(`${STORAGE_PREFIX}${collectionName}`, []);
}

export function saveCollection(collectionName, items) {
  setItem(`${STORAGE_PREFIX}${collectionName}`, items);
  notify();
}

export function addItem(collectionName, item) {
  const collection = getCollection(collectionName);
  const newItem = {
    id: item.id || `${collectionName.slice(0, 3)}_${Date.now()}_${Math.random().toString(36).substr(2, 4)}`,
    createdAt: new Date().toISOString(),
    ...item,
  };
  const updated = [newItem, ...collection];
  saveCollection(collectionName, updated);

  pushToQueue({
    action: 'CREATE',
    collection: collectionName,
    payload: newItem,
  });

  return newItem;
}

export function updateItem(collectionName, id, updates) {
  const collection = getCollection(collectionName);
  let updatedItem = null;

  const updated = collection.map((item) => {
    if (item.id === id) {
      updatedItem = { ...item, ...updates, updatedAt: new Date().toISOString() };
      return updatedItem;
    }
    return item;
  });

  saveCollection(collectionName, updated);

  if (updatedItem) {
    pushToQueue({
      action: 'UPDATE',
      collection: collectionName,
      id,
      payload: updates,
    });
  }

  return updatedItem;
}

export function deleteItem(collectionName, id) {
  const collection = getCollection(collectionName);
  const updated = collection.filter((item) => item.id !== id);
  saveCollection(collectionName, updated);

  pushToQueue({
    action: 'DELETE',
    collection: collectionName,
    id,
  });
}

/**
 * Pub/Sub subscription for store changes
 */
export function subscribe(listener) {
  listeners.add(listener);
  return () => {
    listeners.delete(listener);
  };
}

/**
 * Seed initial sample data if store is empty.
 */
export function seedInitialData() {
  const existingBorrowers = getCollection('borrowers');
  const existingLoans = getCollection('loans');

  if (existingBorrowers.length > 0 || existingLoans.length > 0) {
    return;
  }

  const today = new Date();

  const monthsAgo = (m) => {
    const d = new Date(today);
    d.setMonth(d.getMonth() - m);
    return d.toISOString().split('T')[0];
  };

  const sampleBorrowers = [
    {
      id: 'bor_elena_01',
      full_name: 'Elena Rostova',
      email: 'elena.rostova@example.com',
      phone: '+1 (555) 234-5678',
      address: '742 Evergreen Terrace, Springfield, IL',
      id_number: 'ID-8839201',
      employment: 'Senior Software Engineer at TechCorp',
      monthly_income: 6800,
      credit_score: 82,
      risk_rating: 'low',
      notes: 'Reliable client, always pays on or ahead of time. High income-to-debt ratio.',
      createdAt: monthsAgo(6),
    },
    {
      id: 'bor_marcus_02',
      full_name: 'Marcus Vance',
      email: 'm.vance@example.com',
      phone: '+1 (555) 876-5432',
      address: '1048 Ocean Avenue, Santa Monica, CA',
      id_number: 'ID-4421098',
      employment: 'Retail Store Manager at Urban Outfitters',
      monthly_income: 3900,
      credit_score: 62,
      risk_rating: 'medium',
      notes: 'Seasonal store sales fluctuations. Keeps good communication.',
      createdAt: monthsAgo(4),
    },
    {
      id: 'bor_aisha_03',
      full_name: 'Aisha Patel',
      email: 'aisha.design@example.com',
      phone: '+1 (555) 345-6789',
      address: '302 Pine Street, Austin, TX',
      id_number: 'ID-9920112',
      employment: 'Freelance UI/UX Designer',
      monthly_income: 2900,
      credit_score: 55,
      risk_rating: 'medium',
      notes: 'New applicant requesting working capital for new workstation setup.',
      createdAt: monthsAgo(1),
    },
  ];

  saveCollection('borrowers', sampleBorrowers);

  // Loan 1: Elena Rostova - Active, 12 months, $5000 @ 10%, disbursed 2 months ago
  const loan1Disbursed = monthsAgo(2);
  const loan1Schedule = generateSchedule(5000, 10, 12, loan1Disbursed);

  const loan1Payments = [
    {
      id: 'pay_01',
      date: monthsAgo(1),
      amount: loan1Schedule[0].amount,
      method: 'Bank Transfer',
      note: 'Installment 1 paid',
    },
    {
      id: 'pay_02',
      date: monthsAgo(0),
      amount: loan1Schedule[1].amount,
      method: 'Bank Transfer',
      note: 'Installment 2 paid',
    },
  ];

  // Loan 2: Marcus Vance - Active with overdue payment
  const loan2Disbursed = monthsAgo(3);
  const loan2Schedule = generateSchedule(3000, 14, 6, loan2Disbursed);

  const loan2Payments = [
    {
      id: 'pay_03',
      date: monthsAgo(2),
      amount: loan2Schedule[0].amount,
      method: 'Debit Card',
      note: 'Installment 1 paid',
    },
    {
      id: 'pay_04',
      date: monthsAgo(1),
      amount: 150,
      method: 'Cash',
      note: 'Partial payment for installment 2',
    },
  ];

  // Loan 3: Aisha Patel - Pending loan
  const loan3Disbursed = today.toISOString().split('T')[0];
  const loan3Schedule = generateSchedule(2500, 12, 6, loan3Disbursed);

  const sampleLoans = [
    {
      id: 'loan_elena_01',
      borrower_id: 'bor_elena_01',
      principal: 5000,
      interest_rate: 10,
      term_months: 12,
      purpose: 'Tech Equipment Purchase',
      status: 'active',
      disbursement_date: loan1Disbursed,
      credit_assessment: assessBorrower(sampleBorrowers[0]),
      schedule: loan1Schedule,
      payments: loan1Payments,
      notes: 'Computer upgrade financing for freelance business expansion.',
      createdAt: loan1Disbursed,
    },
    {
      id: 'loan_marcus_02',
      borrower_id: 'bor_marcus_02',
      principal: 3000,
      interest_rate: 14,
      term_months: 6,
      purpose: 'Retail Inventory Restock',
      status: 'active',
      disbursement_date: loan2Disbursed,
      credit_assessment: assessBorrower(sampleBorrowers[1]),
      schedule: loan2Schedule,
      payments: loan2Payments,
      notes: 'Inventory financing for seasonal merchandise.',
      createdAt: loan2Disbursed,
    },
    {
      id: 'loan_aisha_03',
      borrower_id: 'bor_aisha_03',
      principal: 2500,
      interest_rate: 12,
      term_months: 6,
      purpose: 'Studio Design Workstation',
      status: 'pending',
      disbursement_date: loan3Disbursed,
      credit_assessment: assessBorrower(sampleBorrowers[2]),
      schedule: loan3Schedule,
      payments: [],
      notes: 'Awaiting final approval on design portfolio verification.',
      createdAt: today.toISOString().split('T')[0],
    },
  ];

  saveCollection('loans', sampleLoans);
}
