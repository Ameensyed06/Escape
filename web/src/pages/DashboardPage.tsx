import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Zap, Pencil, Dumbbell, ChevronRight, Check, Timer } from 'lucide-react';
import { useAuth } from '../state/AuthContext';
import { useAppStore } from '../state/AppStore';
import { AppCard, GradientAvatar, GradientButton, Modal, Pill, TextField } from '../components/ui';
import { formatHms, isoWeekday, todayKey } from '../lib/dateUtils';
import { iconForKey } from '../lib/iconMap';

const TIMER_PRESETS = [15, 25, 45, 60, 90];

function greeting(): string {
  const hour = new Date().getHours();
  if (hour < 5) return 'Still up';
  if (hour < 12) return 'Good morning';
  if (hour < 18) return 'Good afternoon';
  return 'Good evening';
}

export default function DashboardPage() {
  const { displayName } = useAuth();
  const state = useAppStore();
  const navigate = useNavigate();
  const firstName = displayName.trim().split(' ')[0] || 'there';

  const day = state.dayFor(isoWeekday(new Date()));

  return (
    <div className="mx-auto w-full max-w-2xl px-6 py-6">
      <div className="mb-6 flex items-center justify-between">
        <div>
          <p className="text-sm text-on-surface-variant">{greeting()}</p>
          <h1 className="text-2xl font-extrabold tracking-tight text-on-surface">{firstName}</h1>
        </div>
        <button onClick={() => navigate('/profile')}>
          <GradientAvatar name={displayName || 'You'} size={48} />
        </button>
      </div>

      <FocusCard />

      <div className="mt-4">
        <AppCard>
          <div className="mb-2 flex items-center justify-between">
            <h2 className="text-lg font-bold">Today's Commitments</h2>
            <span className="text-sm font-bold text-on-surface-variant">
              {state.completedGoalsTodayCount}/{state.goals.length}
            </span>
          </div>
          {state.goals.length === 0 ? (
            <p className="py-3 text-sm text-on-surface-variant">No commitments yet.</p>
          ) : (
            <div className="flex flex-col">
              {state.goals.slice(0, 4).map((goal) => {
                const Icon = iconForKey(goal.iconKey);
                const done = goal.history.includes(todayKey());
                return (
                  <button
                    key={goal.id}
                    onClick={() => state.toggleGoal(goal.id)}
                    className="flex items-center gap-3 rounded-md py-2 text-left transition hover:bg-black/[0.02]"
                  >
                    <span
                      className={`flex h-6 w-6 shrink-0 items-center justify-center rounded-full border-2 transition ${
                        done ? 'border-cyan bg-cyan text-white' : 'border-outline'
                      }`}
                    >
                      {done && <Check size={14} />}
                    </span>
                    <Icon size={17} className="shrink-0 text-on-surface-variant" />
                    <span className={`text-sm font-semibold ${done ? 'text-on-surface-variant line-through' : ''}`}>
                      {goal.title}
                    </span>
                  </button>
                );
              })}
            </div>
          )}
        </AppCard>
      </div>

      <div className="mt-4">
        <AppCard onClick={() => navigate('/train')}>
          <div className="flex items-center gap-3.5">
            <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-lg bg-gradient-to-br from-amber to-amber-deep text-white">
              <Dumbbell size={22} />
            </div>
            <div className="min-w-0 flex-1">
              <p className="text-sm text-on-surface-variant">Today's Workout</p>
              <p className="truncate text-base font-bold">{day.title}</p>
              {!(day.exercises.length === 0) && (
                <p className="text-xs text-on-surface-variant">{day.exercises.length} exercises</p>
              )}
            </div>
            <ChevronRight size={20} className="shrink-0 text-on-surface-variant" />
          </div>
        </AppCard>
      </div>
    </div>
  );
}

function FocusCard() {
  const state = useAppStore();
  const active = state.focusActive;
  const [showTimerModal, setShowTimerModal] = useState(false);
  const [customMinutes, setCustomMinutes] = useState('');

  return (
    <AppCard className={active ? '!border-cyan-deep !bg-cyan-deep' : ''}>
      <div className="flex items-center gap-1.5">
        <Zap size={20} className={active ? 'text-white' : 'text-cyan'} />
        <span className={`text-sm font-bold ${active ? 'text-white/70' : 'text-on-surface-variant'}`}>
          Focus Mode
        </span>
        <div className="flex-1" />
        <span
          className={`rounded-pill px-2.5 py-1 text-xs font-extrabold ${
            active ? 'bg-white/15 text-white' : 'bg-cyan-soft text-cyan-deep'
          }`}
        >
          {state.focusStatusLabel}
        </span>
        <button
          onClick={() => setShowTimerModal(true)}
          className={`ml-1 rounded-md p-1.5 transition hover:bg-black/5 ${active ? 'text-white/70' : 'text-on-surface-variant'}`}
          title="Set timer"
        >
          <Pencil size={16} />
        </button>
      </div>

      <div className={`my-5 text-center text-5xl font-extrabold tabular-nums tracking-tight ${active ? 'text-white' : ''}`}>
        {formatHms(state.focusRemainingSeconds)}
      </div>

      <div className="mb-5 flex justify-center gap-2">
        {[15, 30, 60].map((m) => (
          <Pill
            key={m}
            label={`+${m} Min`}
            onClick={() => state.addFocusMinutes(m)}
            color={active ? 'bg-white/15' : 'bg-cyan-soft'}
            textColor={active ? 'text-white' : 'text-cyan-deep'}
          />
        ))}
      </div>

      <button
        onClick={state.toggleFocus}
        className={`w-full rounded-pill py-3.5 text-[15px] font-extrabold transition ${
          active ? 'bg-white text-cyan-deep' : 'bg-cyan text-white hover:brightness-105'
        }`}
      >
        {active ? 'Stop Focus' : 'Start Focus'}
      </button>

      <Modal open={showTimerModal} onClose={() => setShowTimerModal(false)} title="Set Focus Timer">
        <p className="text-sm text-on-surface-variant">Pick a duration or enter your own.</p>
        <div className="flex flex-wrap gap-2">
          {TIMER_PRESETS.map((m) => (
            <Pill
              key={m}
              label={`${m} min`}
              onClick={() => {
                state.setFocusDuration(m);
                setShowTimerModal(false);
              }}
            />
          ))}
        </div>
        <TextField
          label="Custom minutes"
          type="number"
          min={1}
          value={customMinutes}
          onChange={(e) => setCustomMinutes(e.target.value)}
        />
        <GradientButton
          label="Set Timer"
          icon={<Timer size={16} />}
          onClick={() => {
            const m = parseInt(customMinutes, 10);
            if (m > 0) {
              state.setFocusDuration(m);
              setShowTimerModal(false);
              setCustomMinutes('');
            }
          }}
        />
      </Modal>
    </AppCard>
  );
}
