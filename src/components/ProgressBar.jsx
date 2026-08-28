import React from 'react';

export default function ProgressBar({ value = 0, max = 100, showLabel = true, className = '', colorClass = 'bg-zinc-900 dark:bg-zinc-100' }) {
  const percentage = Math.min(100, Math.max(0, Math.round((value / max) * 100)));

  return (
    <div className={`w-full ${className}`}>
      {showLabel && (
        <div className="flex justify-between items-center mb-1 text-xs font-medium text-zinc-600 dark:text-zinc-400">
          <span>Progress</span>
          <span>{percentage}%</span>
        </div>
      )}
      <div className="w-full h-2 bg-zinc-200 dark:bg-zinc-800 rounded-full overflow-hidden">
        <div
          className={`h-full transition-all duration-300 rounded-full ${colorClass}`}
          style={{ width: `${percentage}%` }}
        />
      </div>
    </div>
  );
}
