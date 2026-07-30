// Mirrors lib/models/models.dart — kept local-only (localStorage) except
// where noted, same as the Flutter app.

export interface Goal {
  id: string;
  title: string;
  target: string;
  iconKey: string;
  scheduledMinutes: number | null;
  history: string[]; // yyyy-MM-dd completion date keys
}

export interface BlockedApp {
  id: string;
  name: string;
  iconKey: string;
  blocked: boolean;
  minutesSavedToday: number;
}

export interface RoutineExercise {
  id: string;
  name: string;
  targetSets: number;
  targetReps: number;
  tags: string[];
  lastWeight: number | null;
  lastReps: number | null;
}

export interface WorkoutDay {
  weekday: number; // 1 (Mon) - 7 (Sun)
  title: string;
  exercises: RoutineExercise[];
}

export interface SetLog {
  weight: number;
  reps: number;
  done: boolean;
}

// ---- Cloud-backed (Supabase) — shared with the mobile app ----

export interface Friend {
  id: string;
  name: string;
  avatarSeed: number;
  rank: string;
  focusScore: number;
  currentStreak: number;
  workoutsDone: number;
}

export type ActivityType = 'workout' | 'focus' | 'streak';

export interface ActivityItem {
  id: string;
  friendId: string;
  friendName: string;
  avatarSeed: number;
  type: ActivityType;
  message: string;
  statLabel: string;
  timestamp: string;
  kudos: number;
  kudosGiven: boolean;
}
