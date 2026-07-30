import { useState } from 'react';
import {
  Bed,
  Dumbbell,
  Plus,
  Pencil,
  Check,
  ChevronDown,
  ChevronUp,
  Trash2,
  CheckCircle2,
} from 'lucide-react';
import { useAppStore } from '../state/AppStore';
import { AppCard, GradientButton, Modal, OutlineButton, Pill, ProgressRing, TextField } from '../components/ui';
import { isoWeekday, weekdayFull, weekdayShort } from '../lib/dateUtils';
import type { RoutineExercise, WorkoutDay } from '../types/models';

export default function WorkoutPage() {
  const state = useAppStore();
  const today = isoWeekday(new Date());
  const [selected, setSelected] = useState(today);
  const [editingDay, setEditingDay] = useState(false);
  const [editingExercise, setEditingExercise] = useState<RoutineExercise | null | 'new'>(null);

  const day = state.dayFor(selected);
  const ratio = state.dayCompletionRatio(day);
  const finished = state.isWorkoutFinished(day);

  return (
    <div className="mx-auto w-full max-w-2xl px-6 py-6">
      <h1 className="mb-6 text-2xl font-extrabold tracking-tight">Training Plan</h1>

      <div className="mb-6 flex gap-2.5 overflow-x-auto pb-1">
        {Array.from({ length: 7 }, (_, i) => i + 1).map((weekday) => {
          const d = state.dayFor(weekday);
          const isSelected = weekday === selected;
          const isToday = weekday === today;
          return (
            <button
              key={weekday}
              onClick={() => setSelected(weekday)}
              className={`flex w-14 shrink-0 flex-col items-center gap-1.5 rounded-lg border py-2.5 transition ${
                isSelected
                  ? 'border-on-surface bg-on-surface text-white'
                  : isToday
                    ? 'border-cyan bg-surface'
                    : 'border-outline bg-surface'
              }`}
            >
              <span
                className={`text-xs font-bold ${
                  isSelected ? 'text-white' : d.exercises.length === 0 ? 'text-on-surface-variant/50' : 'text-on-surface-variant'
                }`}
              >
                {weekdayShort[weekday - 1]}
              </span>
              {d.exercises.length === 0 ? (
                <Bed size={16} className={isSelected ? 'text-white' : 'text-on-surface-variant/40'} />
              ) : (
                <Dumbbell size={16} className={isSelected ? 'text-white' : 'text-amber'} />
              )}
            </button>
          );
        })}
      </div>

      <div className="mb-2 flex items-start justify-between">
        <div>
          <h2 className="text-xl font-extrabold">{day.title}</h2>
          <p className="text-sm text-on-surface-variant">
            {day.exercises.length === 0
              ? 'Rest day — recover up'
              : `${day.exercises.length} exercises${selected === today ? '' : ` • ${weekdayFull[selected - 1]}`}`}
          </p>
        </div>
        <div className="flex items-center gap-2">
          {finished && (
            <Pill label="Finished" icon={<CheckCircle2 size={14} />} color="bg-cyan-soft" textColor="text-cyan-deep" />
          )}
          <button onClick={() => setEditingDay(true)} className="text-on-surface-variant" title="Rename day">
            <Pencil size={18} />
          </button>
        </div>
      </div>

      {day.exercises.length > 0 ? (
        <>
          <div className="my-4">
            <AppCard className="!border-transparent !bg-amber-soft">
              <div className="flex items-center gap-3">
                <div className="flex-1">
                  <p className="text-sm font-bold text-amber-deep">Today's Progress</p>
                  <p className="text-xs text-on-surface-variant">
                    {Math.round(ratio * day.exercises.length)} / {day.exercises.length} exercises logged
                  </p>
                </div>
                <ProgressRing progress={ratio} size={44} strokeWidth={5} color="#db8a0f" />
              </div>
            </AppCard>
          </div>

          <div className="mb-4 flex flex-col gap-2.5">
            {day.exercises.map((ex) => (
              <ExerciseCard key={ex.id} exercise={ex} onEdit={() => setEditingExercise(ex)} />
            ))}
          </div>

          <OutlineButton label="Add Exercise" icon={<Plus size={18} />} onClick={() => setEditingExercise('new')} />

          <div className="mt-4">
            <GradientButton
              label={finished ? 'Workout Finished' : 'Finish Workout'}
              gradient="from-amber to-amber-deep"
              disabled={ratio !== 1 || finished}
              onClick={() => state.finishWorkout(day)}
            />
          </div>
        </>
      ) : (
        <div className="flex flex-col items-center gap-5 py-14">
          <Bed size={44} className="text-on-surface-variant" />
          <p className="text-sm text-on-surface-variant">Nothing scheduled — enjoy the rest.</p>
          <div className="w-full max-w-xs">
            <OutlineButton label="Add Exercise" icon={<Plus size={18} />} onClick={() => setEditingExercise('new')} />
          </div>
        </div>
      )}

      {editingDay && (
        <DayTitleModal day={day} onClose={() => setEditingDay(false)} />
      )}
      {editingExercise && (
        <ExerciseEditorModal
          weekday={selected}
          existing={editingExercise === 'new' ? null : editingExercise}
          onClose={() => setEditingExercise(null)}
        />
      )}
    </div>
  );
}

function ExerciseCard({ exercise, onEdit }: { exercise: RoutineExercise; onEdit: () => void }) {
  const state = useAppStore();
  const [expanded, setExpanded] = useState(false);
  const complete = state.isExerciseComplete(exercise);
  const logs = state.logsFor(exercise);

  return (
    <AppCard className={complete ? '!border-amber' : ''}>
      <div className="flex w-full items-center gap-3">
        <button onClick={() => setExpanded((v) => !v)} className="flex min-w-0 flex-1 items-center gap-3 text-left">
          <span className={`h-2 w-2 shrink-0 rounded-full ${complete ? 'bg-amber' : 'bg-outline'}`} />
          <div className="min-w-0 flex-1">
            <p className="truncate text-base font-bold">{exercise.name}</p>
            <div className="flex items-center gap-2 text-xs text-on-surface-variant">
              <span>
                {exercise.targetSets} sets × {exercise.targetReps} reps
              </span>
              {exercise.lastWeight != null && (
                <span className="rounded bg-amber-soft px-1.5 py-0.5 text-[10px] font-extrabold text-amber-deep">
                  PREV {exercise.lastWeight}kg × {exercise.lastReps}
                </span>
              )}
            </div>
          </div>
        </button>
        <button onClick={onEdit} className="shrink-0 text-on-surface-variant">
          <Pencil size={16} />
        </button>
        <button onClick={() => setExpanded((v) => !v)} className="shrink-0 text-on-surface-variant">
          {expanded ? <ChevronUp size={20} /> : <ChevronDown size={20} />}
        </button>
      </div>

      {expanded && (
        <div className="mt-3 flex flex-col gap-2 border-t border-outline pt-3">
          {logs.map((log, i) => (
            <div key={i} className="flex items-center gap-2">
              <span className="w-5 text-sm font-bold">{i + 1}</span>
              <input
                type="number"
                value={log.weight}
                onChange={(e) => state.updateSetLog(exercise, i, { weight: Number(e.target.value) })}
                className="w-full rounded-md border border-outline px-2 py-2 text-center text-sm font-bold outline-none focus:border-amber"
              />
              <span className="text-xs text-on-surface-variant">kg</span>
              <input
                type="number"
                value={log.reps}
                onChange={(e) => state.updateSetLog(exercise, i, { reps: Number(e.target.value) })}
                className="w-full rounded-md border border-outline px-2 py-2 text-center text-sm font-bold outline-none focus:border-amber"
              />
              <span className="text-xs text-on-surface-variant">reps</span>
              <button
                onClick={() => state.toggleSetDone(exercise, i)}
                className={`flex h-8 w-8 shrink-0 items-center justify-center rounded-full border-2 transition ${
                  log.done ? 'border-amber bg-amber text-white' : 'border-outline'
                }`}
              >
                {log.done && <Check size={16} />}
              </button>
            </div>
          ))}
        </div>
      )}
    </AppCard>
  );
}

function DayTitleModal({ day, onClose }: { day: WorkoutDay; onClose: () => void }) {
  const state = useAppStore();
  const [title, setTitle] = useState(day.title);
  return (
    <Modal open onClose={onClose} title="Rename Day">
      <TextField label="Day title" value={title} onChange={(e) => setTitle(e.target.value)} autoFocus />
      <GradientButton
        label="Save"
        gradient="from-amber to-amber-deep"
        onClick={() => {
          if (!title.trim()) return;
          state.updateWorkoutDayTitle(day.weekday, title.trim());
          onClose();
        }}
      />
    </Modal>
  );
}

function ExerciseEditorModal({
  weekday,
  existing,
  onClose,
}: {
  weekday: number;
  existing: RoutineExercise | null;
  onClose: () => void;
}) {
  const state = useAppStore();
  const [name, setName] = useState(existing?.name ?? '');
  const [sets, setSets] = useState(String(existing?.targetSets ?? 3));
  const [reps, setReps] = useState(String(existing?.targetReps ?? 10));

  function handleSave() {
    const s = parseInt(sets, 10);
    const r = parseInt(reps, 10);
    if (!name.trim() || !(s > 0) || !(r > 0)) return;
    if (existing) {
      state.updateExercise(weekday, existing.id, { name: name.trim(), targetSets: s, targetReps: r });
    } else {
      state.addExercise(weekday, name.trim(), s, r);
    }
    onClose();
  }

  return (
    <Modal open onClose={onClose} title={existing ? 'Edit Exercise' : 'Add Exercise'}>
      <TextField label="Exercise name" value={name} onChange={(e) => setName(e.target.value)} autoFocus />
      <div className="flex gap-3">
        <TextField label="Sets" type="number" value={sets} onChange={(e) => setSets(e.target.value)} />
        <TextField label="Reps" type="number" value={reps} onChange={(e) => setReps(e.target.value)} />
      </div>
      <div className="flex gap-3">
        {existing && (
          <OutlineButton
            label="Delete"
            icon={<Trash2 size={16} />}
            onClick={() => {
              state.deleteExercise(weekday, existing.id);
              onClose();
            }}
          />
        )}
        <GradientButton label={existing ? 'Save' : 'Add'} gradient="from-amber to-amber-deep" onClick={handleSave} />
      </div>
    </Modal>
  );
}
