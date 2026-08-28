import React from 'react';

export function Card({ children, className = '', onClick = null, hover = false }) {
  return (
    <div
      onClick={onClick}
      className={`bg-white dark:bg-zinc-900 border border-zinc-200/80 dark:border-zinc-800 rounded-xl p-5 shadow-xs ${
        hover || onClick ? 'transition-all duration-200 hover:border-zinc-400 dark:hover:border-zinc-700 hover:shadow-md cursor-pointer' : ''
      } ${className}`}
    >
      {children}
    </div>
  );
}

export function StatCard({ title, value, subtext, icon: Icon, onClick = null, color = 'zinc' }) {
  return (
    <Card onClick={onClick} hover={!!onClick} className="relative overflow-hidden">
      <div className="flex items-center justify-between">
        <span className="text-xs font-semibold uppercase tracking-wider text-zinc-500 dark:text-zinc-400">
          {title}
        </span>
        {Icon && (
          <div className="p-2 rounded-lg bg-zinc-100 dark:bg-zinc-800 text-zinc-700 dark:text-zinc-300">
            <Icon className="w-5 h-5" />
          </div>
        )}
      </div>
      <div className="mt-3">
        <div className="text-2xl font-bold tracking-tight text-zinc-900 dark:text-zinc-50">
          {value}
        </div>
        {subtext && (
          <p className="mt-1 text-xs text-zinc-500 dark:text-zinc-400">
            {subtext}
          </p>
        )}
      </div>
    </Card>
  );
}
