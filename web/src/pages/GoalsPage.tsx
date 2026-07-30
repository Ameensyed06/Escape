import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Plus, Check, ChevronUp, ChevronDown, Trash2, ShieldCheck, ChevronRight } from 'lucide-react';
import { useAppStore } from '../state/AppStore';
import { AppCard, GradientButton, Modal, OutlineButton, ProgressRing, TextField } from '../components/ui';
import { iconForKey, goalIconKeys } from '../lib/iconMap';
import { formatMinutesLabel, todayKey } from '../lib/dateUtils';
import type { Goal } from '../types/models';

export default function GoalsPage() {
  const state = useAppStore();
  const navigate = useNavigate();
  const [editing, setEditing] = useState<Goal | null | 'new'>(null);

  return (
    <div className="mx-auto w-full max-w-2xl px-6 py-6">
      <h1 className="mb-6 text-2xl font-extrabold tracking-tight">Commitments</h1>

      <div className="mb-6 flex justify-center">
        <ProgressRing progress={state.goalsProgress} size={132} strokeWidth={12}>
          <div className="text-center">
            <div className="text-3xl font-extrabold">{state.completedGoalsTodayCount}</div>
            <div className="text-xs text-on-surface-variant">of {state.goals.length} done</div>
          </div>
        </ProgressRing>
      </div>

      {state.goals.length === 0 ? (
        <p className="py-6 text-center text-sm text-on-surface-variant">
          No commitments yet — add your first one below.
        </p>
      ) : (
        <div className="mb-4 flex flex-col gap-2.5">
          {state.goals.map((goal, i) => {
            const Icon = iconForKey(goal.iconKey);
            const done = goal.history.includes(todayKey());
            return (
              <AppCard key={goal.id} onClick={() => setEditing(goal)}>
                <div className="flex items-center gap-3">
                  <span
                    role="button"
                    onClick={(e) => {
                      e.stopPropagation();
                      state.toggleGoal(goal.id);
                    }}
                    className={`flex h-7 w-7 shrink-0 items-center justify-center rounded-full border-2 transition ${
                      done ? 'border-cyan bg-cyan text-white' : 'border-outline'
                    }`}
                  >
                    {done && <Check size={16} />}
                  </span>
                  <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-md bg-cyan-soft text-cyan-deep">
                    <Icon size={17} />
                  </span>
                  <div className="min-w-0 flex-1">
                    <p className={`truncate text-sm font-bold ${done ? 'text-on-surface-variant line-through' : ''}`}>
                      {goal.title}
                    </p>
                    {goal.target && <p className="truncate text-xs text-on-surface-variant">{goal.target}</p>}
                  </div>
                  <div className="flex shrink-0 flex-col">
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        state.moveGoal(i, -1);
                      }}
                      disabled={i === 0}
                      className="text-on-surface-variant disabled:opacity-25"
                    >
                      <ChevronUp size={16} />
                    </button>
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        state.moveGoal(i, 1);
                      }}
                      disabled={i === state.goals.length - 1}
                      className="text-on-surface-variant disabled:opacity-25"
                    >
                      <ChevronDown size={16} />
                    </button>
                  </div>
                </div>
              </AppCard>
            );
          })}
        </div>
      )}

      <OutlineButton label="Add New Goal" icon={<Plus size={18} />} onClick={() => setEditing('new')} />

      <div className="mt-6">
        <AppCard className="!bg-orange-soft !border-transparent" onClick={() => navigate('/blocker')}>
          <div className="flex items-center gap-3.5">
            <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-md bg-gradient-to-br from-orange to-orange-deep text-white">
              <ShieldCheck size={20} />
            </div>
            <div className="flex-1">
              <p className="text-sm font-extrabold text-orange">App Blocker</p>
              <p className="text-xs text-on-surface-variant">
                {formatMinutesLabel(state.reclaimedMinutesToday)} reclaimed today
              </p>
            </div>
            <ChevronRight size={20} className="text-orange" />
          </div>
        </AppCard>
      </div>

      {editing && (
        <GoalEditorModal
          existing={editing === 'new' ? null : editing}
          onClose={() => setEditing(null)}
        />
      )}
    </div>
  );
}

function GoalEditorModal({ existing, onClose }: { existing: Goal | null; onClose: () => void }) {
  const state = useAppStore();
  const [title, setTitle] = useState(existing?.title ?? '');
  const [target, setTarget] = useState(existing?.target ?? '');
  const [icon, setIcon] = useState(existing?.iconKey ?? goalIconKeys[0]);
  const [scheduledTime, setScheduledTime] = useState(
    existing?.scheduledMinutes != null
      ? `${String(Math.floor(existing.scheduledMinutes / 60)).padStart(2, '0')}:${String(existing.scheduledMinutes % 60).padStart(2, '0')}`
      : '',
  );

  function handleSave() {
    if (!title.trim()) return;
    let scheduledMinutes: number | null = null;
    if (scheduledTime) {
      const [h, m] = scheduledTime.split(':').map(Number);
      scheduledMinutes = h * 60 + m;
    }
    if (existing) {
      state.updateGoal(existing.id, { title: title.trim(), target: target.trim(), iconKey: icon, scheduledMinutes });
    } else {
      state.addGoal(title.trim(), target.trim(), icon, scheduledMinutes);
    }
    onClose();
  }

  return (
    <Modal open onClose={onClose} title={existing ? 'Edit Goal' : 'Add New Goal'}>
      <TextField label="Title" value={title} onChange={(e) => setTitle(e.target.value)} autoFocus />
      <TextField label='Target (e.g. "20 pages")' value={target} onChange={(e) => setTarget(e.target.value)} />
      <TextField
        label="Scheduled time (optional)"
        type="time"
        value={scheduledTime}
        onChange={(e) => setScheduledTime(e.target.value)}
      />
      <div className="flex flex-wrap gap-2">
        {goalIconKeys.map((key) => {
          const Icon = iconForKey(key);
          const selected = key === icon;
          return (
            <button
              key={key}
              onClick={() => setIcon(key)}
              className={`flex h-11 w-11 items-center justify-center rounded-md border transition ${
                selected ? 'border-cyan bg-cyan-soft text-cyan-deep' : 'border-outline text-on-surface-variant'
              }`}
            >
              <Icon size={18} />
            </button>
          );
        })}
      </div>
      <div className="flex gap-3">
        {existing && (
          <OutlineButton
            label="Delete"
            icon={<Trash2 size={16} />}
            onClick={() => {
              state.deleteGoal(existing.id);
              onClose();
            }}
          />
        )}
        <GradientButton label={existing ? 'Save' : 'Add Goal'} onClick={handleSave} />
      </div>
    </Modal>
  );
}
