/// Pure XP/level/rank calculation, shared between the signed-in user's own
/// stats (`AppState`) and any friend's stats fetched from Supabase — so both
/// are always ranked with the same formula.
class RankStats {
  const RankStats({
    required this.focusMinutesTotal,
    required this.streakDays,
    required this.totalVolume,
    required this.workoutsCompleted,
    this.goalsCompleted = 0,
  });

  final int focusMinutesTotal;
  final int streakDays;
  final double totalVolume;
  final int workoutsCompleted;
  final int goalsCompleted;
}

int xpForStats(RankStats s) =>
    s.focusMinutesTotal +
    (s.goalsCompleted * 10) +
    (s.streakDays * 5) +
    (s.totalVolume.round() ~/ 10) +
    (s.workoutsCompleted * 15);

int levelForXp(int xp) => (xp ~/ 200) + 1;

int xpIntoLevel(int xp) => xp % 200;

double levelProgressForXp(int xp) => xpIntoLevel(xp) / 200;

String rankTitleForLevel(int level) {
  if (level >= 10) return 'Elite Focus Operative';
  if (level >= 6) return 'Focus Operative';
  if (level >= 3) return 'Discipline Cadet';
  return 'Recruit';
}
