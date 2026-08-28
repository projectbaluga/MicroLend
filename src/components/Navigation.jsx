import React from 'react';
import { LayoutDashboard, Users, CreditCard, ShieldCheck } from 'lucide-react';

const navItems = [
  { id: 'dashboard', label: 'Dashboard', icon: LayoutDashboard },
  { id: 'borrowers', label: 'Borrowers', icon: Users },
  { id: 'loans', label: 'Loans', icon: CreditCard },
];

export function Sidebar({ activeTab, setActiveTab }) {
  return (
    <aside className="hidden md:flex flex-col w-64 bg-white dark:bg-zinc-900 border-r border-zinc-200 dark:border-zinc-800 min-h-screen">
      {/* Brand Header */}
      <div className="flex items-center gap-3 px-6 h-16 border-b border-zinc-200 dark:border-zinc-800">
        <div className="p-2 rounded-xl bg-zinc-900 text-white dark:bg-zinc-100 dark:text-zinc-900 font-extrabold text-lg flex items-center justify-center">
          <ShieldCheck className="w-5 h-5" />
        </div>
        <div>
          <span className="font-bold text-lg text-zinc-900 dark:text-zinc-100 tracking-tight">MicroLend</span>
          <p className="text-[10px] uppercase font-semibold text-zinc-400 dark:text-zinc-500 tracking-wider">Solo Suite</p>
        </div>
      </div>

      {/* Navigation */}
      <nav className="flex-1 px-3 py-6 space-y-1">
        {navItems.map((item) => {
          const Icon = item.icon;
          const isActive = activeTab === item.id;
          return (
            <button
              key={item.id}
              onClick={() => setActiveTab(item.id)}
              className={`flex items-center w-full px-3 py-2.5 text-sm font-medium rounded-lg transition-colors ${
                isActive
                  ? 'bg-zinc-900 text-white dark:bg-zinc-100 dark:text-zinc-900 font-semibold'
                  : 'text-zinc-600 dark:text-zinc-400 hover:text-zinc-900 dark:hover:text-zinc-100 hover:bg-zinc-100 dark:hover:bg-zinc-800/60'
              }`}
            >
              <Icon className="w-4 h-4 mr-3" />
              {item.label}
            </button>
          );
        })}
      </nav>

      {/* Footer Info */}
      <div className="p-4 border-t border-zinc-200 dark:border-zinc-800 text-xs text-zinc-400 dark:text-zinc-500">
        <p className="font-medium text-zinc-600 dark:text-zinc-400">MicroLend v1.0</p>
        <p className="mt-0.5">Local-First Storage</p>
      </div>
    </aside>
  );
}

export function BottomNav({ activeTab, setActiveTab }) {
  return (
    <nav className="md:hidden fixed bottom-0 left-0 right-0 z-40 bg-white/95 dark:bg-zinc-900/95 backdrop-blur-md border-t border-zinc-200 dark:border-zinc-800 px-4 py-2 flex justify-around">
      {navItems.map((item) => {
        const Icon = item.icon;
        const isActive = activeTab === item.id;
        return (
          <button
            key={item.id}
            onClick={() => setActiveTab(item.id)}
            className={`flex flex-col items-center py-1 px-3 rounded-lg text-xs font-medium transition ${
              isActive
                ? 'text-zinc-900 dark:text-zinc-100 font-semibold'
                : 'text-zinc-500 dark:text-zinc-400 hover:text-zinc-900 dark:hover:text-zinc-200'
            }`}
          >
            <Icon className={`w-5 h-5 mb-0.5 ${isActive ? 'scale-110' : ''}`} />
            {item.label}
          </button>
        );
      })}
    </nav>
  );
}
