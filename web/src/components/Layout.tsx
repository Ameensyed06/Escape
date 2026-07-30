import { NavLink, Outlet } from 'react-router-dom';
import { Home, Target, Dumbbell, Users, User } from 'lucide-react';

// Mirrors lib/widgets/main_shell.dart — desktop-friendly nav on the left,
// bottom tab bar on small screens.
const TABS = [
  { to: '/', label: 'Home', icon: Home, end: true },
  { to: '/goals', label: 'Goals', icon: Target },
  { to: '/train', label: 'Train', icon: Dumbbell },
  { to: '/social', label: 'Social', icon: Users },
  { to: '/profile', label: 'Profile', icon: User },
];

export function Layout() {
  return (
    <div className="flex min-h-svh bg-background">
      <nav className="hidden w-56 shrink-0 flex-col border-r border-outline bg-surface p-4 md:flex">
        <div className="mb-8 flex items-center gap-2 px-2">
          <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-gradient-to-br from-cyan to-cyan-deep text-white">
            ⚡
          </div>
          <span className="text-lg font-extrabold tracking-tight">ESCAPE</span>
        </div>
        <div className="flex flex-col gap-1">
          {TABS.map((tab) => (
            <NavLink
              key={tab.to}
              to={tab.to}
              end={tab.end}
              className={({ isActive }) =>
                `flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-semibold transition ${
                  isActive ? 'bg-cyan-soft text-cyan-deep' : 'text-on-surface-variant hover:bg-black/[0.03]'
                }`
              }
            >
              <tab.icon size={18} />
              {tab.label}
            </NavLink>
          ))}
        </div>
      </nav>

      <div className="flex min-w-0 flex-1 flex-col pb-20 md:pb-0">
        <Outlet />
      </div>

      <nav className="fixed inset-x-0 bottom-0 z-10 flex border-t border-outline bg-surface md:hidden">
        {TABS.map((tab) => (
          <NavLink
            key={tab.to}
            to={tab.to}
            end={tab.end}
            className={({ isActive }) =>
              `flex flex-1 flex-col items-center gap-0.5 py-2.5 text-[11px] font-semibold transition ${
                isActive ? 'text-cyan' : 'text-on-surface-variant'
              }`
            }
          >
            <tab.icon size={22} />
            {tab.label}
          </NavLink>
        ))}
      </nav>
    </div>
  );
}
