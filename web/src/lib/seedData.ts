// Mirrors lib/state/seed_data.dart. Goals intentionally have no seed — new
// accounts/browsers start empty, same as the mobile app.

import type { BlockedApp, RoutineExercise, WorkoutDay } from '../types/models';

let idCounter = 0;
function uid(): string {
  idCounter += 1;
  return `local-${Date.now()}-${idCounter}`;
}

export function seedBlockedApps(): BlockedApp[] {
  return [
    { id: uid(), name: 'Instagram', iconKey: 'instagram', blocked: true, minutesSavedToday: 42 },
    { id: uid(), name: 'TikTok', iconKey: 'tiktok', blocked: true, minutesSavedToday: 65 },
    { id: uid(), name: 'YouTube', iconKey: 'youtube', blocked: false, minutesSavedToday: 12 },
    { id: uid(), name: 'X', iconKey: 'twitter', blocked: true, minutesSavedToday: 8 },
    { id: uid(), name: 'Reddit', iconKey: 'reddit', blocked: false, minutesSavedToday: 0 },
    { id: uid(), name: 'Mobile Games', iconKey: 'games', blocked: true, minutesSavedToday: 20 },
  ];
}

function ex(
  name: string,
  targetSets: number,
  targetReps: number,
  tags: string[],
  lastWeight: number | null,
  lastReps: number | null,
): RoutineExercise {
  return { id: uid(), name, targetSets, targetReps, tags, lastWeight, lastReps };
}

export function seedRoutine(): WorkoutDay[] {
  return [
    {
      weekday: 1,
      title: 'Push — Chest / Shoulders / Triceps',
      exercises: [
        ex('Barbell Bench Press', 4, 8, ['Chest'], 60, 8),
        ex('Overhead Press', 3, 10, ['Shoulders'], 32, 10),
        ex('Incline Dumbbell Press', 3, 10, ['Chest'], 22, 9),
        ex('Triceps Pushdown', 3, 12, ['Triceps'], 25, 12),
      ],
    },
    {
      weekday: 2,
      title: 'Pull — Back / Biceps',
      exercises: [
        ex('Deadlift', 3, 5, ['Back'], 100, 5),
        ex('Pull-Ups', 4, 8, ['Back'], null, 8),
        ex('Barbell Row', 3, 10, ['Back'], 50, 10),
        ex('Barbell Curl', 3, 12, ['Biceps'], 20, 12),
      ],
    },
    { weekday: 3, title: 'Rest Day', exercises: [] },
    {
      weekday: 4,
      title: 'Legs — Quads / Hamstrings / Glutes',
      exercises: [
        ex('Back Squat', 4, 6, ['Quads'], 80, 6),
        ex('Romanian Deadlift', 3, 10, ['Hamstrings'], 60, 10),
        ex('Walking Lunges', 3, 12, ['Glutes'], 16, 12),
        ex('Leg Curl', 3, 12, ['Hamstrings'], 35, 12),
      ],
    },
    {
      weekday: 5,
      title: 'Push — Chest / Shoulders / Triceps',
      exercises: [
        ex('Dumbbell Bench Press', 4, 10, ['Chest'], 26, 10),
        ex('Arnold Press', 3, 10, ['Shoulders'], 16, 10),
        ex('Cable Fly', 3, 12, ['Chest'], 15, 12),
        ex('Lateral Raise', 3, 15, ['Shoulders'], 8, 15),
      ],
    },
    {
      weekday: 6,
      title: 'Pull — Back / Biceps',
      exercises: [
        ex('Lat Pulldown', 4, 10, ['Back'], 55, 10),
        ex('Seated Cable Row', 3, 10, ['Back'], 48, 10),
        ex('Face Pull', 3, 15, ['Shoulders'], 18, 15),
        ex('Hammer Curl', 3, 12, ['Biceps'], 14, 12),
      ],
    },
    { weekday: 7, title: 'Rest Day', exercises: [] },
  ];
}

export function newId(): string {
  return uid();
}
