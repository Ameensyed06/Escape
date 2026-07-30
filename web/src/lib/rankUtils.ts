// Mirrors lib/utils/rank_utils.dart — same formula used for the signed-in
// user and for friends fetched from Supabase, so ranks are comparable.

export interface RankStats {
  focusMinutesTotal: number;
  streakDays: number;
  totalVolume: number;
  workoutsCompleted: number;
  goalsCompleted?: number;
}

export function xpForStats(s: RankStats): number {
  return (
    s.focusMinutesTotal +
    (s.goalsCompleted ?? 0) * 10 +
    s.streakDays * 5 +
    Math.floor(Math.round(s.totalVolume) / 10) +
    s.workoutsCompleted * 15
  );
}

export function levelForXp(xp: number): number {
  return Math.floor(xp / 200) + 1;
}

export function xpIntoLevel(xp: number): number {
  return xp % 200;
}

export function levelProgressForXp(xp: number): number {
  return xpIntoLevel(xp) / 200;
}

export function rankTitleForLevel(level: number): string {
  if (level >= 10) return 'Elite Focus Operative';
  if (level >= 6) return 'Focus Operative';
  if (level >= 3) return 'Discipline Cadet';
  return 'Recruit';
}
