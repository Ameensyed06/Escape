import { useState } from 'react';
import { Bell, Trash2, LogOut, Zap, Flame, Dumbbell, Target, Trophy } from 'lucide-react';
import { useAuth } from '../state/AuthContext';
import { useAppStore } from '../state/AppStore';
import { AppCard, GradientAvatar, Switch } from '../components/ui';
import { formatMinutesLabel } from '../lib/dateUtils';

export default function ProfilePage() {
  const { displayName, email, signOut } = useAuth();
  const state = useAppStore();
  const [notifWarning, setNotifWarning] = useState(false);
  const [confirmingClear, setConfirmingClear] = useState(false);

  async function handleNotificationsToggle(value: boolean) {
    const granted = await state.setNotifications(value);
    setNotifWarning(!granted && value);
  }

  return (
    <div className="mx-auto w-full max-w-2xl px-6 py-6">
      <h1 className="mb-6 text-2xl font-extrabold tracking-tight">Profile</h1>

      <div className="mb-6 flex flex-col items-center gap-2 text-center">
        <GradientAvatar name={displayName || 'You'} size={88} />
        <h2 className="text-xl font-extrabold">{displayName || 'Operative'}</h2>
        {email && <p className="text-sm text-on-surface-variant">{email}</p>}
      </div>

      <div className="mb-6 rounded-xl bg-gradient-to-br from-cyan to-cyan-deep p-5 text-white shadow-lg shadow-cyan/25">
        <div className="mb-2 flex items-center justify-between">
          <div className="flex items-center gap-1.5">
            <Trophy size={18} />
            <span className="text-sm font-extrabold">Level {state.level}</span>
          </div>
          <span className="text-xs font-semibold text-white/70">{state.xpIntoLevel} / 200 XP</span>
        </div>
        <p className="mb-3.5 text-2xl font-extrabold">{state.rankTitle}</p>
        <div className="h-2 overflow-hidden rounded-full bg-white/25">
          <div className="h-full rounded-full bg-white transition-all" style={{ width: `${state.levelProgress * 100}%` }} />
        </div>
      </div>

      <h3 className="mb-3 text-lg font-bold">Statistics</h3>
      <div className="mb-6 grid grid-cols-2 gap-2.5">
        <StatTile icon={Zap} color="text-cyan" bg="bg-cyan-soft" label="Focus Minutes" value={formatMinutesLabel(state.focusMinutesTotal)} />
        <StatTile icon={Flame} color="text-amber" bg="bg-amber-soft" label="Streak Days" value={String(state.streakDays)} />
        <StatTile icon={Dumbbell} color="text-orange" bg="bg-orange-soft" label="Weight Lifted" value={`${Math.round(state.totalVolume)} kg`} />
        <StatTile icon={Target} color="text-cyan-deep" bg="bg-cyan-soft" label="Goals Completed" value={String(state.totalCompletedGoalsLifetime)} />
      </div>

      <h3 className="mb-3 text-lg font-bold">Settings</h3>
      <AppCard className="mb-4 overflow-hidden !p-0">
        <div className="flex items-center gap-3 border-b border-outline p-4">
          <Bell size={20} className="shrink-0 text-on-surface-variant" />
          <div className="flex-1">
            <p className="text-sm font-semibold">Push Notifications</p>
            <p className="text-[11px] text-on-surface-variant">
              Focus, goal, workout & streak reminders — plus friend connects while this tab is open.
            </p>
          </div>
          <Switch checked={state.notificationsEnabled} onChange={handleNotificationsToggle} />
        </div>
        {notifWarning && (
          <p className="bg-orange-soft p-4 text-xs text-orange">
            Notifications are blocked for this site — enable them in your browser's site settings.
          </p>
        )}
      </AppCard>

      <AppCard className="!p-0">
        <button
          onClick={() => setConfirmingClear(true)}
          className="flex w-full items-center gap-3 border-b border-outline p-4 text-left text-orange"
        >
          <Trash2 size={20} />
          <span className="text-sm font-semibold">Clear Local Data</span>
        </button>
        <button onClick={signOut} className="flex w-full items-center gap-3 p-4 text-left">
          <LogOut size={20} className="text-on-surface-variant" />
          <span className="text-sm font-semibold">Sign Out</span>
        </button>
      </AppCard>

      {confirmingClear && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-6" onClick={() => setConfirmingClear(false)}>
          <div className="w-full max-w-sm rounded-xl bg-surface p-5" onClick={(e) => e.stopPropagation()}>
            <h3 className="mb-2 text-lg font-bold">Clear all local data?</h3>
            <p className="mb-5 text-sm text-on-surface-variant">
              This resets goals, workouts, blocked apps, and stats on this device. This cannot be undone.
            </p>
            <div className="flex justify-end gap-4 text-sm font-bold">
              <button onClick={() => setConfirmingClear(false)} className="text-on-surface-variant">
                Cancel
              </button>
              <button
                onClick={() => {
                  state.clearAllData();
                  setConfirmingClear(false);
                }}
                className="text-orange"
              >
                Clear
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

function StatTile({
  icon: Icon,
  color,
  bg,
  label,
  value,
}: {
  icon: typeof Zap;
  color: string;
  bg: string;
  label: string;
  value: string;
}) {
  return (
    <AppCard>
      <span className={`mb-2 flex h-8 w-8 items-center justify-center rounded-md ${bg} ${color}`}>
        <Icon size={16} />
      </span>
      <p className="truncate text-lg font-extrabold">{value}</p>
      <p className="text-[11px] text-on-surface-variant">{label}</p>
    </AppCard>
  );
}
