import { describe, it, expect, beforeEach } from 'vitest';
import {
  getCollection,
  saveCollection,
  addItem,
  updateItem,
  deleteItem,
  seedInitialData,
  getQueue,
  clearStoreCache,
} from './offlineStore';

describe('offlineStore', () => {
  beforeEach(() => {
    localStorage.clear();
    clearStoreCache();
  });

  it('seeds sample data when localStorage is empty', () => {
    seedInitialData();
    const borrowers = getCollection('borrowers');
    const loans = getCollection('loans');

    expect(borrowers).toHaveLength(3);
    expect(loans).toHaveLength(3);
  });

  it('adds, updates, and deletes items properly while queuing operations', () => {
    const newItem = addItem('borrowers', { full_name: 'Test Borrower', monthly_income: 3000 });
    expect(newItem.id).toBeDefined();

    const collection = getCollection('borrowers');
    expect(collection).toHaveLength(1);
    expect(collection[0].full_name).toBe('Test Borrower');

    updateItem('borrowers', newItem.id, { full_name: 'Updated Name' });
    const updatedCollection = getCollection('borrowers');
    expect(updatedCollection[0].full_name).toBe('Updated Name');

    deleteItem('borrowers', newItem.id);
    expect(getCollection('borrowers')).toHaveLength(0);

    const queue = getQueue();
    expect(queue.length).toBeGreaterThanOrEqual(3);
  });
});
