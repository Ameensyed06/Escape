import { createContext, useContext, useEffect, useRef, useState, type ReactNode } from 'react';
import { useAuth } from './AuthContext';
import { loadJSON, saveJSON, loadBool, loadNumber, loadString } from '../lib/storage';
import { seedBlockedApps, seedRoutine, newId } from '../lib/seedData';
import { todayKey, dateKey } from '../lib/dateUtils';
import { xpForStats, levelForXp, xpIntoLevel, levelProgressForXp, rankTitleForLevel } from '../lib/rankUtils';
import {
  ensureFriendCode,
  fetchFriends,
  fetchActivity,
  fetchFriend,
  addFriendByCode as socialAddFriend,
  setKudos,
  postActivity,
  upsertUserStats,
} from '../lib/socialService';
import { requestNotificationPermission, showNotification } from '../lib/notifications';
import type { ActivityItem, BlockedApp, Friend, Goal, RoutineExercise, SetLog, WorkoutDay } from '../types/models';

const FOCUS_DEFAULT_MINUTES = 25;

function isDoneOn(goal: Goal, key: string): boolean {
  return goal.history.includes(key);
}

interface AppStoreValue {
  ready: boolean;

  // Goals
  goals: Goal[];
  completedGoalsTodayCount: number;
  goalsProgress: number;
  totalCompletedGoalsLifetime: number;
  toggleGoal: (id: string) => void;
  addGoal: (title: string, target: string, iconKey: string, scheduledMinutes: number | null) => void;
  updateGoal: (id: string, patch: Partial<Pick<Goal, 'title' | 'target' | 'iconKey' | 'scheduledMinutes'>>) => void;
  deleteGoal: (id: string) => void;
  moveGoal: (index: number, direction: -1 | 1) => void;

  // Blocked apps
  blockedApps: BlockedApp[];
  reclaimedMinutesToday: number;
  toggleAppBlocked: (id: string) => void;
  addBlockedApp: (name: string, iconKey: string) => void;
  removeBlockedApp: (id: string) => void;

  // Focus timer
  focusRemainingSeconds: number;
  focusActive: boolean;
  focusStatusLabel: string;
  startFocus: () => void;
  stopFocus: () => void;
  toggleFocus: () => void;
  addFocusMinutes: (minutes: number) => void;
  setFocusDuration: (minutes: number) => void;

  // Workouts
  routine: WorkoutDay[];
  dayFor: (weekday: number) => WorkoutDay;
  logsFor: (exercise: RoutineExercise) => SetLog[];
  updateSetLog: (exercise: RoutineExercise, setIndex: number, patch: Partial<SetLog>) => void;
  toggleSetDone: (exercise: RoutineExercise, setIndex: number) => void;
  isExerciseComplete: (exercise: RoutineExercise) => boolean;
  dayCompletionRatio: (day: WorkoutDay) => number;
  isWorkoutFinished: (day: WorkoutDay) => boolean;
  finishWorkout: (day: WorkoutDay) => Promise<void>;
  updateWorkoutDayTitle: (weekday: number, title: string) => void;
  addExercise: (weekday: number, name: string, targetSets: number, targetReps: number) => void;
  updateExercise: (
    weekday: number,
    exerciseId: string,
    patch: Partial<Pick<RoutineExercise, 'name' | 'targetSets' | 'targetReps'>>,
  ) => void;
  deleteExercise: (weekday: number, exerciseId: string) => void;

  // Stats / rank
  focusMinutesToday: number;
  focusMinutesTotal: number;
  streakDays: number;
  totalVolume: number;
  workoutsCompletedTotal: number;
  xp: number;
  level: number;
  xpIntoLevel: number;
  levelProgress: number;
  rankTitle: string;

  // Social
  myFriendCode: string | null;
  friends: Friend[];
  activity: ActivityItem[];
  refreshSocial: () => Promise<void>;
  addFriendByCode: (code: string) => Promise<Friend>;
  friendProfile: (friendId: string) => Promise<Friend | null>;
  friendActivity: (friendId: string) => Promise<ActivityItem[]>;
  toggleKudos: (activityId: string) => void;

  // Settings
  notificationsEnabled: boolean;
  setNotifications: (value: boolean) => Promise<boolean>;
  clearAllData: () => void;
}

const AppStoreContext = createContext<AppStoreValue | null>(null);

export function AppStoreProvider({ children }: { children: ReactNode }) {
  const { user, signedIn } = useAuth();

  const [ready, setReady] = useState(false);
  const [goals, setGoals] = useState<Goal[]>([]);
  const [blockedApps, setBlockedApps] = useState<BlockedApp[]>([]);
  const [routine, setRoutine] = useState<WorkoutDay[]>([]);
  const [exerciseLogs, setExerciseLogs] = useState<Record<string, SetLog[]>>({});
  const [completedWorkoutKeys, setCompletedWorkoutKeys] = useState<Set<string>>(new Set());

  const [notificationsEnabled, setNotificationsEnabledState] = useState(false);

  const [focusRemainingSeconds, setFocusRemainingSeconds] = useState(FOCUS_DEFAULT_MINUTES * 60);
  const [focusActive, setFocusActive] = useState(false);
  const focusSessionSecondsRef = useRef(0);
  const secondAccumulatorRef = useRef(0);
  const tickerRef = useRef<number | null>(null);

  const [focusMinutesToday, setFocusMinutesToday] = useState(0);
  const [focusMinutesTotal, setFocusMinutesTotal] = useState(0);
  const [streakDays, setStreakDays] = useState(0);
  const [totalVolume, setTotalVolume] = useState(0);
  const [workoutsCompletedTotal, setWorkoutsCompletedTotal] = useState(0);
  const lastFocusDateKeyRef = useRef('');
  const lastStreakDateKeyRef = useRef('');

  const [myFriendCode, setMyFriendCode] = useState<string | null>(null);
  const [friends, setFriends] = useState<Friend[]>([]);
  const [activity, setActivity] = useState<ActivityItem[]>([]);
  const hasLoadedFriendsOnce = useRef(false);
  const socialPollRef = useRef<number | null>(null);
  const friendsRef = useRef<Friend[]>([]);
  const notificationsEnabledRef = useRef(false);
  useEffect(() => {
    friendsRef.current = friends;
  }, [friends]);
  useEffect(() => {
    notificationsEnabledRef.current = notificationsEnabled;
  }, [notificationsEnabled]);

  // ---- Initial local load ----
  useEffect(() => {
    setGoals(loadJSON<Goal[]>('goals_v1', []));
    setBlockedApps(loadJSON<BlockedApp[]>('blocked_apps_v1', seedBlockedApps()));
    setRoutine(loadJSON<WorkoutDay[]>('routine_v1', seedRoutine()));
    setNotificationsEnabledState(loadBool('notifications_enabled', false));

    setFocusMinutesTotal(loadNumber('focus_minutes_total_v1', 0));
    setStreakDays(loadNumber('streak_days_v1', 0));
    setTotalVolume(loadNumber('volume_total_v1', 0));
    setWorkoutsCompletedTotal(loadNumber('workouts_completed_total_v1', 0));
    lastFocusDateKeyRef.current = loadString('focus_date_v1', '');
    lastStreakDateKeyRef.current = loadString('streak_date_v1', '');
    setFocusMinutesToday(
      lastFocusDateKeyRef.current === todayKey() ? loadNumber('focus_minutes_today_v1', 0) : 0,
    );

    setReady(true);
  }, []);

  useEffect(() => saveJSON('goals_v1', goals), [goals]);
  useEffect(() => saveJSON('blocked_apps_v1', blockedApps), [blockedApps]);
  useEffect(() => saveJSON('routine_v1', routine), [routine]);

  function saveStats() {
    localStorage.setItem('focus_minutes_total_v1', String(focusMinutesTotal));
    localStorage.setItem('focus_minutes_today_v1', String(focusMinutesToday));
    localStorage.setItem('focus_date_v1', lastFocusDateKeyRef.current);
    localStorage.setItem('streak_days_v1', String(streakDays));
    localStorage.setItem('streak_date_v1', lastStreakDateKeyRef.current);
    localStorage.setItem('volume_total_v1', String(totalVolume));
    localStorage.setItem('workouts_completed_total_v1', String(workoutsCompletedTotal));
    if (user) {
      upsertUserStats(user.id, focusMinutesTotal, streakDays, totalVolume, workoutsCompletedTotal).catch(
        () => {},
      );
    }
  }
  // Persist stats whenever any of them change (also syncs to Supabase for friends to
  // see) — re-running on `user` too means a returning session with local stats already
  // in place gets pushed up as soon as the user becomes available, not just on the next change.
  useEffect(saveStats, [focusMinutesTotal, focusMinutesToday, streakDays, totalVolume, workoutsCompletedTotal, user]);

  function postActivityIfSignedIn(type: ActivityItem['type'], message: string, statLabel: string) {
    if (!user) return;
    postActivity(user.id, type, message, statLabel).catch(() => {});
  }

  // ---- Social data ----
  async function loadSocialData() {
    if (!user) return;
    try {
      const code = await ensureFriendCode(user.id);
      setMyFriendCode(code);

      const previousIds = new Set(friendsRef.current.map((f) => f.id));
      const newFriends = await fetchFriends(user.id);

      if (hasLoadedFriendsOnce.current && notificationsEnabledRef.current) {
        for (const f of newFriends) {
          if (!previousIds.has(f.id)) {
            showNotification('New Friend', `${f.name} connected with you on ESCAPE`);
          }
        }
      }
      hasLoadedFriendsOnce.current = true;

      setFriends(newFriends);
      setActivity(await fetchActivity(user.id));
    } catch {
      // Offline or not configured yet — leave lists as-is.
    }
  }

  useEffect(() => {
    if (signedIn && user) {
      loadSocialData();
      socialPollRef.current = window.setInterval(loadSocialData, 60_000);
    } else {
      setFriends([]);
      setActivity([]);
      setMyFriendCode(null);
      hasLoadedFriendsOnce.current = false;
      if (socialPollRef.current) window.clearInterval(socialPollRef.current);
    }
    return () => {
      if (socialPollRef.current) window.clearInterval(socialPollRef.current);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [signedIn, user?.id]);

  // ---- Focus timer ----
  function stopFocus() {
    setFocusActive(false);
    if (tickerRef.current) {
      window.clearInterval(tickerRef.current);
      tickerRef.current = null;
    }
    saveStats();
  }

  // Bookkeeping lives here rather than inside the setFocusRemainingSeconds
  // updater: StrictMode double-invokes updaters, so mutating refs in there
  // accrued focus minutes twice per second.
  function tickFocus() {
    focusSessionSecondsRef.current += 1;
    const key = todayKey();
    if (lastFocusDateKeyRef.current !== key) {
      lastFocusDateKeyRef.current = key;
      setFocusMinutesToday(0);
    }
    secondAccumulatorRef.current += 1;
    if (secondAccumulatorRef.current >= 60) {
      secondAccumulatorRef.current = 0;
      setFocusMinutesToday((m) => m + 1);
      setFocusMinutesTotal((m) => m + 1);
    }
    setFocusRemainingSeconds((remaining) => (remaining > 0 ? remaining - 1 : 0));
  }

  // Session completion — runs when the countdown lands on zero.
  useEffect(() => {
    if (!focusActive || focusRemainingSeconds > 0) return;
    stopFocus();
    const sessionMinutes = Math.floor(focusSessionSecondsRef.current / 60);
    focusSessionSecondsRef.current = 0;
    setFocusRemainingSeconds(FOCUS_DEFAULT_MINUTES * 60);
    if (sessionMinutes > 0) {
      postActivityIfSignedIn('focus', 'completed a focus session', `${sessionMinutes} min focused`);
      if (notificationsEnabled) {
        showNotification('Focus session complete', `You focused for ${sessionMinutes} min. Nice work.`);
      }
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [focusActive, focusRemainingSeconds]);

  function startFocus() {
    if (focusActive) return;
    setFocusActive(true);
    focusSessionSecondsRef.current = 0;
    if (tickerRef.current) window.clearInterval(tickerRef.current);
    tickerRef.current = window.setInterval(tickFocus, 1000);
  }

  useEffect(() => {
    return () => {
      if (tickerRef.current) window.clearInterval(tickerRef.current);
    };
  }, []);

  // ---- Goals ----
  function maybeAdvanceStreak(currentGoals: Goal[]) {
    if (currentGoals.length === 0) return;
    const key = todayKey();
    const allDone = currentGoals.every((g) => isDoneOn(g, key));
    if (!allDone || lastStreakDateKeyRef.current === key) return;
    const yesterday = dateKey(new Date(Date.now() - 86_400_000));
    setStreakDays((prev) => {
      const next = lastStreakDateKeyRef.current === yesterday ? prev + 1 : 1;
      postActivityIfSignedIn('streak', `hit a ${next} day streak`, `${next} day streak`);
      return next;
    });
    lastStreakDateKeyRef.current = key;
  }

  function toggleGoal(id: string) {
    const key = todayKey();
    setGoals((prev) => {
      const next = prev.map((g) =>
        g.id === id
          ? { ...g, history: isDoneOn(g, key) ? g.history.filter((k) => k !== key) : [...g.history, key] }
          : g,
      );
      const wasIncomplete = !isDoneOn(prev.find((g) => g.id === id)!, key);
      if (wasIncomplete) maybeAdvanceStreak(next);
      return next;
    });
  }

  function addGoal(title: string, target: string, iconKey: string, scheduledMinutes: number | null) {
    setGoals((prev) => [...prev, { id: newId(), title, target, iconKey, scheduledMinutes, history: [] }]);
  }

  function updateGoal(id: string, patch: Partial<Pick<Goal, 'title' | 'target' | 'iconKey' | 'scheduledMinutes'>>) {
    setGoals((prev) => prev.map((g) => (g.id === id ? { ...g, ...patch } : g)));
  }

  function deleteGoal(id: string) {
    setGoals((prev) => prev.filter((g) => g.id !== id));
  }

  function moveGoal(index: number, direction: -1 | 1) {
    setGoals((prev) => {
      const target = index + direction;
      if (target < 0 || target >= prev.length) return prev;
      const next = [...prev];
      [next[index], next[target]] = [next[target], next[index]];
      return next;
    });
  }

  // ---- Blocked apps ----
  function toggleAppBlocked(id: string) {
    setBlockedApps((prev) => prev.map((a) => (a.id === id ? { ...a, blocked: !a.blocked } : a)));
  }

  function addBlockedApp(name: string, iconKey: string) {
    setBlockedApps((prev) => [
      ...prev,
      { id: newId(), name, iconKey, blocked: true, minutesSavedToday: 0 },
    ]);
  }

  function removeBlockedApp(id: string) {
    setBlockedApps((prev) => prev.filter((a) => a.id !== id));
  }

  // ---- Workouts ----
  function dayFor(weekday: number): WorkoutDay {
    return routine.find((d) => d.weekday === weekday) ?? { weekday, title: 'Rest Day', exercises: [] };
  }

  function logsFor(exercise: RoutineExercise): SetLog[] {
    const existing = exerciseLogs[exercise.id];
    if (existing) return existing;
    const fresh = Array.from({ length: exercise.targetSets }, () => ({
      weight: exercise.lastWeight ?? 0,
      reps: exercise.lastReps ?? exercise.targetReps,
      done: false,
    }));
    setExerciseLogs((prev) => ({ ...prev, [exercise.id]: fresh }));
    return fresh;
  }

  function updateSetLog(exercise: RoutineExercise, setIndex: number, patch: Partial<SetLog>) {
    setExerciseLogs((prev) => {
      const logs = prev[exercise.id] ?? logsFor(exercise);
      if (setIndex >= logs.length) return prev;
      const nextLogs = logs.map((l, i) => (i === setIndex ? { ...l, ...patch } : l));
      return { ...prev, [exercise.id]: nextLogs };
    });
  }

  function toggleSetDone(exercise: RoutineExercise, setIndex: number) {
    setExerciseLogs((prev) => {
      const logs = prev[exercise.id] ?? logsFor(exercise);
      if (setIndex >= logs.length) return prev;
      const log = logs[setIndex];
      const done = !log.done;
      const delta = log.weight * log.reps * (done ? 1 : -1);
      setTotalVolume((v) => Math.max(0, v + delta));
      const nextLogs = logs.map((l, i) => (i === setIndex ? { ...l, done } : l));
      return { ...prev, [exercise.id]: nextLogs };
    });
  }

  function isExerciseComplete(exercise: RoutineExercise): boolean {
    const logs = exerciseLogs[exercise.id];
    if (!logs) return false;
    return logs.every((l) => l.done);
  }

  function dayCompletionRatio(day: WorkoutDay): number {
    if (day.exercises.length === 0) return 0;
    const done = day.exercises.filter(isExerciseComplete).length;
    return done / day.exercises.length;
  }

  function isWorkoutFinished(day: WorkoutDay): boolean {
    return completedWorkoutKeys.has(`${todayKey()}:${day.weekday}`);
  }

  async function finishWorkout(day: WorkoutDay) {
    let sessionVolume = 0;
    setRoutine((prev) =>
      prev.map((d) => {
        if (d.weekday !== day.weekday) return d;
        return {
          ...d,
          exercises: d.exercises.map((ex) => {
            const logs = exerciseLogs[ex.id];
            if (!logs) return ex;
            const doneLogs = logs.filter((l) => l.done);
            if (doneLogs.length === 0) return ex;
            sessionVolume += doneLogs.reduce((sum, l) => sum + l.weight * l.reps, 0);
            const last = doneLogs[doneLogs.length - 1];
            return { ...ex, lastWeight: last.weight, lastReps: last.reps };
          }),
        };
      }),
    );
    setCompletedWorkoutKeys((prev) => new Set(prev).add(`${todayKey()}:${day.weekday}`));
    setWorkoutsCompletedTotal((n) => n + 1);
    postActivityIfSignedIn('workout', `finished ${day.title}`, `${Math.round(sessionVolume)} kg lifted`);
  }

  function updateWorkoutDayTitle(weekday: number, title: string) {
    setRoutine((prev) => prev.map((d) => (d.weekday === weekday ? { ...d, title } : d)));
  }

  function addExercise(weekday: number, name: string, targetSets: number, targetReps: number) {
    setRoutine((prev) =>
      prev.map((d) =>
        d.weekday === weekday
          ? {
              ...d,
              exercises: [
                ...d.exercises,
                { id: newId(), name, targetSets, targetReps, tags: [], lastWeight: null, lastReps: null },
              ],
            }
          : d,
      ),
    );
  }

  function updateExercise(
    weekday: number,
    exerciseId: string,
    patch: Partial<Pick<RoutineExercise, 'name' | 'targetSets' | 'targetReps'>>,
  ) {
    setRoutine((prev) =>
      prev.map((d) =>
        d.weekday === weekday
          ? { ...d, exercises: d.exercises.map((e) => (e.id === exerciseId ? { ...e, ...patch } : e)) }
          : d,
      ),
    );
    setExerciseLogs((prev) => {
      const next = { ...prev };
      delete next[exerciseId];
      return next;
    });
  }

  function deleteExercise(weekday: number, exerciseId: string) {
    setRoutine((prev) =>
      prev.map((d) =>
        d.weekday === weekday ? { ...d, exercises: d.exercises.filter((e) => e.id !== exerciseId) } : d,
      ),
    );
    setExerciseLogs((prev) => {
      const next = { ...prev };
      delete next[exerciseId];
      return next;
    });
  }

  // ---- Social actions ----
  function toggleKudosAction(activityId: string) {
    setActivity((prev) =>
      prev.map((a) =>
        a.id === activityId
          ? { ...a, kudosGiven: !a.kudosGiven, kudos: a.kudos + (!a.kudosGiven ? 1 : -1) }
          : a,
      ),
    );
    if (!user) return;
    const item = activity.find((a) => a.id === activityId);
    const given = item ? !item.kudosGiven : true;
    setKudos(activityId, user.id, given).catch(() => {});
  }

  async function addFriendByCodeAction(code: string): Promise<Friend> {
    if (!user) throw new Error('You need to be signed in to connect with friends.');
    const friend = await socialAddFriend(user.id, code);
    await loadSocialData();
    return friend;
  }

  async function friendActivityAction(friendId: string): Promise<ActivityItem[]> {
    if (!user) return [];
    try {
      return await fetchActivity(user.id, [friendId]);
    } catch {
      return [];
    }
  }

  async function friendProfileAction(friendId: string): Promise<Friend | null> {
    const cached = friends.find((f) => f.id === friendId);
    if (cached) return cached;
    try {
      return await fetchFriend(friendId);
    } catch {
      return null;
    }
  }

  // ---- Settings ----
  async function setNotifications(value: boolean): Promise<boolean> {
    if (value) {
      const granted = await requestNotificationPermission();
      if (!granted) {
        setNotificationsEnabledState(false);
        localStorage.setItem('notifications_enabled', 'false');
        return false;
      }
    }
    setNotificationsEnabledState(value);
    localStorage.setItem('notifications_enabled', String(value));
    return true;
  }

  function clearAllData() {
    localStorage.clear();
    setGoals([]);
    setBlockedApps(seedBlockedApps());
    setRoutine(seedRoutine());
    setExerciseLogs({});
    setCompletedWorkoutKeys(new Set());
    setFocusMinutesToday(0);
    setFocusMinutesTotal(0);
    setStreakDays(0);
    setTotalVolume(0);
    setWorkoutsCompletedTotal(0);
    setFocusRemainingSeconds(FOCUS_DEFAULT_MINUTES * 60);
    stopFocus();
    setNotificationsEnabledState(false);
  }

  const xp = xpForStats({
    focusMinutesTotal,
    streakDays,
    totalVolume,
    workoutsCompleted: workoutsCompletedTotal,
    goalsCompleted: goals.reduce((sum, g) => sum + g.history.length, 0),
  });

  const value: AppStoreValue = {
    ready,
    goals,
    completedGoalsTodayCount: goals.filter((g) => isDoneOn(g, todayKey())).length,
    goalsProgress: goals.length === 0 ? 0 : goals.filter((g) => isDoneOn(g, todayKey())).length / goals.length,
    totalCompletedGoalsLifetime: goals.reduce((sum, g) => sum + g.history.length, 0),
    toggleGoal,
    addGoal,
    updateGoal,
    deleteGoal,
    moveGoal,

    blockedApps,
    reclaimedMinutesToday: blockedApps.reduce((sum, a) => sum + a.minutesSavedToday, 0),
    toggleAppBlocked,
    addBlockedApp,
    removeBlockedApp,

    focusRemainingSeconds,
    focusActive,
    focusStatusLabel: focusActive ? 'Active' : 'Idle',
    startFocus,
    stopFocus,
    toggleFocus: () => (focusActive ? stopFocus() : startFocus()),
    addFocusMinutes: (m) => setFocusRemainingSeconds((s) => s + m * 60),
    setFocusDuration: (m) => {
      if (m > 0) setFocusRemainingSeconds(m * 60);
    },

    routine,
    dayFor,
    logsFor,
    updateSetLog,
    toggleSetDone,
    isExerciseComplete,
    dayCompletionRatio,
    isWorkoutFinished,
    finishWorkout,
    updateWorkoutDayTitle,
    addExercise,
    updateExercise,
    deleteExercise,

    focusMinutesToday,
    focusMinutesTotal,
    streakDays,
    totalVolume,
    workoutsCompletedTotal,
    xp,
    level: levelForXp(xp),
    xpIntoLevel: xpIntoLevel(xp),
    levelProgress: levelProgressForXp(xp),
    rankTitle: rankTitleForLevel(levelForXp(xp)),

    myFriendCode,
    friends,
    activity,
    refreshSocial: loadSocialData,
    addFriendByCode: addFriendByCodeAction,
    friendProfile: friendProfileAction,
    friendActivity: friendActivityAction,
    toggleKudos: toggleKudosAction,

    notificationsEnabled,
    setNotifications,
    clearAllData,
  };

  return <AppStoreContext.Provider value={value}>{children}</AppStoreContext.Provider>;
}

export function useAppStore(): AppStoreValue {
  const ctx = useContext(AppStoreContext);
  if (!ctx) throw new Error('useAppStore must be used within AppStoreProvider');
  return ctx;
}
