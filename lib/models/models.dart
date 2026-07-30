/// ESCAPE data models — plain, JSON-serializable, storage-agnostic.
library;

class Goal {
  Goal({
    required this.id,
    required this.title,
    required this.target,
    required this.iconKey,
    this.scheduledMinutes,
    List<String>? history,
  }) : history = history ?? [];

  final String id;
  String title;
  String target;
  String iconKey;
  int? scheduledMinutes;
  final List<String> history;

  bool isDoneOn(String dateKey) => history.contains(dateKey);

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'target': target,
    'iconKey': iconKey,
    'scheduledMinutes': scheduledMinutes,
    'history': history,
  };

  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
    id: json['id'] as String,
    title: json['title'] as String,
    target: json['target'] as String,
    iconKey: json['iconKey'] as String,
    scheduledMinutes: json['scheduledMinutes'] as int?,
    history: (json['history'] as List?)?.map((e) => e as String).toList() ?? [],
  );
}

class BlockedApp {
  BlockedApp({
    required this.id,
    required this.name,
    required this.iconKey,
    this.blocked = false,
    this.minutesSavedToday = 0,
    this.packageName,
    this.iconBytesBase64,
  });

  final String id;
  String name;
  String iconKey;
  bool blocked;
  int minutesSavedToday;
  final String? packageName;
  final String? iconBytesBase64;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'iconKey': iconKey,
    'blocked': blocked,
    'minutesSavedToday': minutesSavedToday,
    'packageName': packageName,
    'iconBytesBase64': iconBytesBase64,
  };

  factory BlockedApp.fromJson(Map<String, dynamic> json) => BlockedApp(
    id: json['id'] as String,
    name: json['name'] as String,
    iconKey: json['iconKey'] as String,
    blocked: json['blocked'] as bool? ?? false,
    minutesSavedToday: json['minutesSavedToday'] as int? ?? 0,
    packageName: json['packageName'] as String?,
    iconBytesBase64: json['iconBytesBase64'] as String?,
  );
}

class RoutineExercise {
  RoutineExercise({
    required this.id,
    required this.name,
    required this.targetSets,
    required this.targetReps,
    List<String>? tags,
    this.lastWeight,
    this.lastReps,
  }) : tags = tags ?? [];

  final String id;
  String name;
  int targetSets;
  int targetReps;
  final List<String> tags;
  double? lastWeight;
  int? lastReps;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'targetSets': targetSets,
    'targetReps': targetReps,
    'tags': tags,
    'lastWeight': lastWeight,
    'lastReps': lastReps,
  };

  factory RoutineExercise.fromJson(Map<String, dynamic> json) => RoutineExercise(
    id: json['id'] as String,
    name: json['name'] as String,
    targetSets: json['targetSets'] as int,
    targetReps: json['targetReps'] as int,
    tags: (json['tags'] as List?)?.map((e) => e as String).toList() ?? [],
    lastWeight: (json['lastWeight'] as num?)?.toDouble(),
    lastReps: json['lastReps'] as int?,
  );
}

class WorkoutDay {
  WorkoutDay({
    required this.weekday,
    required this.title,
    List<RoutineExercise>? exercises,
  }) : exercises = exercises ?? [];

  /// 1 (Mon) - 7 (Sun)
  final int weekday;
  String title;
  final List<RoutineExercise> exercises;

  bool get isRestDay => exercises.isEmpty;

  Map<String, dynamic> toJson() => {
    'weekday': weekday,
    'title': title,
    'exercises': exercises.map((e) => e.toJson()).toList(),
  };

  factory WorkoutDay.fromJson(Map<String, dynamic> json) => WorkoutDay(
    weekday: json['weekday'] as int,
    title: json['title'] as String,
    exercises: (json['exercises'] as List?)
            ?.map((e) => RoutineExercise.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
  );
}

class Friend {
  Friend({
    required this.id,
    required this.name,
    required this.code,
    required this.avatarSeed,
    required this.rank,
    required this.focusScore,
    required this.currentStreak,
    required this.workoutsDone,
    required this.minutesFocusedToday,
  });

  final String id;
  final String name;
  final String code;
  final int avatarSeed;
  final String rank;
  final int focusScore;
  final int currentStreak;
  final int workoutsDone;
  final int minutesFocusedToday;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'code': code,
    'avatarSeed': avatarSeed,
    'rank': rank,
    'focusScore': focusScore,
    'currentStreak': currentStreak,
    'workoutsDone': workoutsDone,
    'minutesFocusedToday': minutesFocusedToday,
  };

  factory Friend.fromJson(Map<String, dynamic> json) => Friend(
    id: json['id'] as String,
    name: json['name'] as String,
    code: json['code'] as String,
    avatarSeed: json['avatarSeed'] as int,
    rank: json['rank'] as String,
    focusScore: json['focusScore'] as int,
    currentStreak: json['currentStreak'] as int,
    workoutsDone: json['workoutsDone'] as int,
    minutesFocusedToday: json['minutesFocusedToday'] as int,
  );
}

class ActivityItem {
  ActivityItem({
    required this.id,
    required this.friendId,
    required this.friendName,
    required this.avatarSeed,
    required this.type,
    required this.message,
    required this.statLabel,
    required this.timestamp,
    this.kudos = 0,
    this.kudosGiven = false,
  });

  final String id;
  final String friendId;
  final String friendName;
  final int avatarSeed;
  final String type; // 'workout' | 'focus' | 'streak'
  final String message;
  final String statLabel;
  final DateTime timestamp;
  int kudos;
  bool kudosGiven;
}
