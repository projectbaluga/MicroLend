import { useSyncExternalStore } from 'react';
import { getCollection, subscribe, seedInitialData, getQueue, syncAll, addItem, updateItem, deleteItem } from './offlineStore';

// Ensure store is seeded once on load
seedInitialData();

/**
 * Custom hook to read a collection from LocalStorage with automatic re-renders on mutation.
 * @param {string} collectionName - 'borrowers' | 'loans'
 */
export function useCollection(collectionName) {
  const collection = useSyncExternalStore(
    subscribe,
    () => getCollection(collectionName),
    () => getCollection(collectionName)
  );

  return collection;
}

/**
 * Custom hook for sync state and operations.
 */
export function useSyncState() {
  const queue = useSyncExternalStore(
    subscribe,
    getQueue,
    getQueue
  );

  return {
    pendingCount: queue.length,
    isSyncing: false,
    syncAll,
  };
}

export { addItem, updateItem, deleteItem };
