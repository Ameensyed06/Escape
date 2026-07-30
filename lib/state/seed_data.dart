import 'package:uuid/uuid.dart';

import '../models/models.dart';

const _uuid = Uuid();

List<Goal> seedGoals() => [
  Goal(id: _uuid.v4(), title: 'Read', target: '20 pages', iconKey: 'book', scheduledMinutes: 540),
  Goal(id: _uuid.v4(), title: 'Drink water', target: '3 liters', iconKey: 'water', scheduledMinutes: null),
  Goal(id: _uuid.v4(), title: 'Meditate', target: '10 minutes', iconKey: 'meditation', scheduledMinutes: 420),
  Goal(id: _uuid.v4(), title: 'No junk food', target: 'All day', iconKey: 'no_junk', scheduledMinutes: null),
  Goal(id: _uuid.v4(), title: 'Sleep by 11', target: '11:00 PM', iconKey: 'sleep', scheduledMinutes: 1380),
];

List<BlockedApp> seedBlockedApps() => [
  BlockedApp(id: _uuid.v4(), name: 'Instagram', iconKey: 'instagram', blocked: true, minutesSavedToday: 42),
  BlockedApp(id: _uuid.v4(), name: 'TikTok', iconKey: 'tiktok', blocked: true, minutesSavedToday: 65),
  BlockedApp(id: _uuid.v4(), name: 'YouTube', iconKey: 'youtube', blocked: false, minutesSavedToday: 12),
  BlockedApp(id: _uuid.v4(), name: 'X', iconKey: 'twitter', blocked: true, minutesSavedToday: 8),
  BlockedApp(id: _uuid.v4(), name: 'Reddit', iconKey: 'reddit', blocked: false, minutesSavedToday: 0),
  BlockedApp(id: _uuid.v4(), name: 'Mobile Games', iconKey: 'games', blocked: true, minutesSavedToday: 20),
];

List<WorkoutDay> seedRoutine() => [
  WorkoutDay(
    weekday: 1,
    title: 'Push — Chest / Shoulders / Triceps',
    exercises: [
      RoutineExercise(id: _uuid.v4(), name: 'Barbell Bench Press', targetSets: 4, targetReps: 8, tags: ['Chest'], lastWeight: 60, lastReps: 8),
      RoutineExercise(id: _uuid.v4(), name: 'Overhead Press', targetSets: 3, targetReps: 10, tags: ['Shoulders'], lastWeight: 32, lastReps: 10),
      RoutineExercise(id: _uuid.v4(), name: 'Incline Dumbbell Press', targetSets: 3, targetReps: 10, tags: ['Chest'], lastWeight: 22, lastReps: 9),
      RoutineExercise(id: _uuid.v4(), name: 'Triceps Pushdown', targetSets: 3, targetReps: 12, tags: ['Triceps'], lastWeight: 25, lastReps: 12),
    ],
  ),
  WorkoutDay(
    weekday: 2,
    title: 'Pull — Back / Biceps',
    exercises: [
      RoutineExercise(id: _uuid.v4(), name: 'Deadlift', targetSets: 3, targetReps: 5, tags: ['Back'], lastWeight: 100, lastReps: 5),
      RoutineExercise(id: _uuid.v4(), name: 'Pull-Ups', targetSets: 4, targetReps: 8, tags: ['Back'], lastWeight: null, lastReps: 8),
      RoutineExercise(id: _uuid.v4(), name: 'Barbell Row', targetSets: 3, targetReps: 10, tags: ['Back'], lastWeight: 50, lastReps: 10),
      RoutineExercise(id: _uuid.v4(), name: 'Barbell Curl', targetSets: 3, targetReps: 12, tags: ['Biceps'], lastWeight: 20, lastReps: 12),
    ],
  ),
  WorkoutDay(weekday: 3, title: 'Rest Day', exercises: []),
  WorkoutDay(
    weekday: 4,
    title: 'Legs — Quads / Hamstrings / Glutes',
    exercises: [
      RoutineExercise(id: _uuid.v4(), name: 'Back Squat', targetSets: 4, targetReps: 6, tags: ['Quads'], lastWeight: 80, lastReps: 6),
      RoutineExercise(id: _uuid.v4(), name: 'Romanian Deadlift', targetSets: 3, targetReps: 10, tags: ['Hamstrings'], lastWeight: 60, lastReps: 10),
      RoutineExercise(id: _uuid.v4(), name: 'Walking Lunges', targetSets: 3, targetReps: 12, tags: ['Glutes'], lastWeight: 16, lastReps: 12),
      RoutineExercise(id: _uuid.v4(), name: 'Leg Curl', targetSets: 3, targetReps: 12, tags: ['Hamstrings'], lastWeight: 35, lastReps: 12),
    ],
  ),
  WorkoutDay(
    weekday: 5,
    title: 'Push — Chest / Shoulders / Triceps',
    exercises: [
      RoutineExercise(id: _uuid.v4(), name: 'Dumbbell Bench Press', targetSets: 4, targetReps: 10, tags: ['Chest'], lastWeight: 26, lastReps: 10),
      RoutineExercise(id: _uuid.v4(), name: 'Arnold Press', targetSets: 3, targetReps: 10, tags: ['Shoulders'], lastWeight: 16, lastReps: 10),
      RoutineExercise(id: _uuid.v4(), name: 'Cable Fly', targetSets: 3, targetReps: 12, tags: ['Chest'], lastWeight: 15, lastReps: 12),
      RoutineExercise(id: _uuid.v4(), name: 'Lateral Raise', targetSets: 3, targetReps: 15, tags: ['Shoulders'], lastWeight: 8, lastReps: 15),
    ],
  ),
  WorkoutDay(
    weekday: 6,
    title: 'Pull — Back / Biceps',
    exercises: [
      RoutineExercise(id: _uuid.v4(), name: 'Lat Pulldown', targetSets: 4, targetReps: 10, tags: ['Back'], lastWeight: 55, lastReps: 10),
      RoutineExercise(id: _uuid.v4(), name: 'Seated Cable Row', targetSets: 3, targetReps: 10, tags: ['Back'], lastWeight: 48, lastReps: 10),
      RoutineExercise(id: _uuid.v4(), name: 'Face Pull', targetSets: 3, targetReps: 15, tags: ['Shoulders'], lastWeight: 18, lastReps: 15),
      RoutineExercise(id: _uuid.v4(), name: 'Hammer Curl', targetSets: 3, targetReps: 12, tags: ['Biceps'], lastWeight: 14, lastReps: 12),
    ],
  ),
  WorkoutDay(weekday: 7, title: 'Rest Day', exercises: []),
];

List<Friend> seedFriends() => [
  Friend(id: _uuid.v4(), name: 'Maya Chen', code: 'MAYA482', avatarSeed: 3, rank: 'Elite Focus Operative', focusScore: 892, currentStreak: 14, workoutsDone: 41, minutesFocusedToday: 95),
  Friend(id: _uuid.v4(), name: 'Diego Torres', code: 'DIEGO117', avatarSeed: 7, rank: 'Focus Operative', focusScore: 640, currentStreak: 6, workoutsDone: 22, minutesFocusedToday: 40),
  Friend(id: _uuid.v4(), name: 'Priya Nair', code: 'PRIYA905', avatarSeed: 12, rank: 'Discipline Cadet', focusScore: 410, currentStreak: 3, workoutsDone: 15, minutesFocusedToday: 0),
  Friend(id: _uuid.v4(), name: 'Owen Blake', code: 'OWEN339', avatarSeed: 19, rank: 'Elite Focus Operative', focusScore: 955, currentStreak: 21, workoutsDone: 58, minutesFocusedToday: 130),
];
