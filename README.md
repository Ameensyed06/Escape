# ESCAPE

**Escape Mediocrity** — a productivity and focus-oriented fitness companion app. ESCAPE tracks daily goals, enforces a strict app blocker during focus sessions, logs workouts with progressive overload, and layers in friendly social accountability.

Built with Flutter, styled as a light-theme, high-contrast, dark-mode-inspired design system.

## Contents

- [Features](#features)
- [Tech stack](#tech-stack)
- [Project structure](#project-structure)
- [Getting started](#getting-started)
- [Supabase setup](#supabase-setup)
  - [1. Create a project](#1-create-a-project)
  - [2. Run the database schema](#2-run-the-database-schema)
  - [3. Configure auth](#3-configure-auth)
  - [4. Wire the app to your project](#4-wire-the-app-to-your-project)
- [Running the app](#running-the-app)
- [Testing & linting](#testing--linting)
- [Design system](#design-system)
- [Data model](#data-model)
- [Friends & social](#friends--social)
- [Notifications](#notifications)
- [Known limitations](#known-limitations)

## Features

- **Focus Mode** — a countdown timer (default 25 min) with quick +15/+30/+60 minute pills, live `hh:mm:ss` display, and haptic feedback on start/stop.
- **Daily Commitments (Goals)** — reorderable daily goal list with a circular progress ring, custom icons, scheduled times, and a persistent completion streak.
- **App Blocker** — mark distracting apps as blocked, track minutes reclaimed per day, search/add apps.
- **Training Plan (Workouts)** — a Monday–Sunday split with rest days, per-exercise set logging (weight × reps), "PREV" tags showing your last performance for progressive overload, and cumulative volume tracking.
- **Community (Social)** — real cross-account friend connections via a shareable 6-character code, a friends rail with streak badges, a friend dashboard (their focus/streak/volume/workout stats + activity history), an activity feed for workouts/focus sessions/streak milestones, and a kudos (👍) reaction.
- **Profile** — gradient avatar, XP/level/rank progression, a lifetime stats grid (focus minutes, streak days, weight lifted, goals completed), and settings (haptics, notifications, clear local data).
- **Notifications** — real OS permission prompt (Profile → Push Notifications), then on-device reminders for focus completion, scheduled goals, an evening streak-at-risk nudge, weekly workout-day pings, and a "new friend connected" alert (see [Notifications](#notifications) below).
- **Auth** — full Supabase-backed authentication: email/password sign up & sign in, Google sign-in (browser-redirect OAuth), forgot/reset password, and an email confirmation screen.

## Tech stack

| Concern | Choice |
|---|---|
| Framework | Flutter (Dart) |
| State management | `provider` + `ChangeNotifier` (single `AppState`) |
| Local persistence | `shared_preferences` (goals, workouts, blocked apps — device-local) |
| Backend | `supabase_flutter` — Auth, plus the social graph (friends, activity feed, cross-user stats) |
| Animations | `flutter_animate` |
| Icons | `material_symbols_icons` |
| IDs | `uuid` |

## Project structure

```
lib/
├── config/
│   └── supabase_config.dart      # Supabase URL/anon key + OAuth redirect constants
├── models/
│   └── models.dart                # Goal, BlockedApp, RoutineExercise, WorkoutDay, Friend, ActivityItem
├── services/
│   ├── auth_service.dart          # Thin wrapper around Supabase Auth calls
│   └── social_service.dart        # Friend codes, connections, activity feed, cross-user stats
├── state/
│   ├── app_state.dart             # Single ChangeNotifier: all app logic + persistence
│   └── seed_data.dart             # Default goals/apps/routine for first run
├── theme/
│   └── app_theme.dart             # Color tokens, spacing, radii, ThemeData
├── utils/
│   ├── date_utils.dart            # Date-key + duration formatting helpers
│   ├── icon_map.dart              # iconKey string -> Material Symbol mapping
│   └── rank_utils.dart            # Shared XP/level/rank formula (used for you AND friends)
├── widgets/
│   ├── common.dart                 # AppCard, GradientAvatar, ProgressRing, buttons, etc.
│   ├── kinetic_nav_icon.dart       # Animated bottom-nav icon
│   └── main_shell.dart             # 5-tab IndexedStack + bottom nav
├── screens/
│   ├── sign_in_screen.dart
│   ├── sign_up_screen.dart
│   ├── email_confirmation_screen.dart
│   ├── forgot_password_screen.dart
│   ├── reset_password_screen.dart
│   ├── dashboard_screen.dart       # Tab 1
│   ├── goals_screen.dart           # Tab 2
│   ├── workout_screen.dart         # Tab 3
│   ├── social_screen.dart          # Tab 4
│   ├── profile_screen.dart         # Tab 5
│   ├── blocker_screen.dart         # App Blocker (pushed from Goals)
│   └── friend_dashboard_screen.dart # Read-only view of a friend's progress
└── main.dart                       # Supabase.initialize + app root / auth gate

supabase/
└── schema.sql                      # SQL to run in the Supabase SQL editor
```

## Getting started

Prerequisites:

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel; developed against Flutter 3.41 / Dart 3.11)
- Android Studio (Android SDK + platform tools) and/or Xcode, depending on target platform
- A Supabase project (see below) — the app will run and show the sign-in screen without one, but no auth call will actually succeed until it's configured

Install dependencies:

```bash
flutter pub get
```

## Supabase setup

Auth (email/password, Google, password reset, email confirmation) is powered by [Supabase](https://supabase.com). The app ships with placeholder config, so it builds and runs out of the box — but sign-in/sign-up won't work until you point it at a real project.

### 1. Create a project

Create a new project at [supabase.com](https://supabase.com/dashboard) (or reuse an existing one). Note its **Project URL** and **anon/publishable key** (Project Settings → API).

### 2. Run the database schema

Open **SQL Editor → New query** in your Supabase dashboard, paste the contents of [`supabase/schema.sql`](supabase/schema.sql), and run it (safe to re-run any time — every statement is idempotent). This creates 12 tables:

- **`profiles`** (required for auth) — one row per user, auto-populated via a trigger on `auth.users` insert. Stores the display name shown throughout the app.
- **Live and wired into the app** — `user_stats` (your aggregate focus minutes / streak / volume / workouts, synced whenever they change), `friend_codes` (your shareable 6-character code), `friendships` (real cross-account connections), `activity_feed` + `activity_kudos` (the Community tab's feed and 👍 reactions).
- **Reference schema, not yet wired up** — `goals`, `goal_completions`, `blocked_apps`, `workout_days`, `routine_exercises`, `exercise_set_logs`. Goals, workouts, and blocked apps still live on-device (`shared_preferences`); these tables are ready for when that data moves to the cloud too.

All twelve are scoped with row-level security to `auth.uid()` — friendship rows are readable by either side of the connection, and `activity_feed` is readable by the author plus anyone connected to them.

### 3. Configure auth

In **Authentication → Providers**, enable **Google** and supply the OAuth Client ID/Secret from your [Google Cloud Console](https://console.cloud.google.com/apis/credentials) project.

In **Authentication → URL Configuration → Redirect URLs**, add both:

```
io.escape.app://login-callback/
io.escape.app://reset-callback/
```

These match the custom URL scheme already registered in `android/app/src/main/AndroidManifest.xml` and `ios/Runner/Info.plist`, which is how the app receives control back after a Google sign-in or a "reset password" email link.

By default, Supabase requires email confirmation before a new account can sign in — that's what `EmailConfirmationScreen` handles. You can disable this requirement in **Authentication → Providers → Email** if you'd rather skip it during development.

### 4. Wire the app to your project

Edit [`lib/config/supabase_config.dart`](lib/config/supabase_config.dart) and replace the placeholder `defaultValue`s with your project's URL and anon key:

```dart
static const String supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://your-project-ref.supabase.co',
);

static const String supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'your-anon-key',
);
```

Alternatively, keep the placeholders and pass real values at build/run time without editing the file:

```bash
flutter run --dart-define=SUPABASE_URL=https://your-project-ref.supabase.co --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

The anon key is safe to ship in client code — it's designed to be public and is enforced by the row-level security policies in `schema.sql`. Never embed the `service_role` key in the app.

## Running the app

```bash
flutter devices          # list available targets
flutter run -d <device>  # run on a specific device/emulator
flutter run               # run on the only/first available device
```

On Windows, if a first Android build fails with a Kotlin `IllegalArgumentException: this and base files have different roots`, it's a known incremental-compiler issue when the project and Gradle/pub caches live on different drive letters. `android/gradle.properties` already sets `kotlin.incremental=false` to work around it; if you still see it, run `cd android && gradlew.bat --stop` to clear the poisoned Gradle daemon and retry.

## Testing & linting

```bash
flutter analyze   # static analysis (should report zero issues)
flutter test       # widget tests
```

## Design system

Light theme with high-contrast accents (see `lib/theme/app_theme.dart`):

| Role | Token | Hex |
|---|---|---|
| Background | `background` | `#EEF1F6` |
| Surface | `surface` | `#FFFFFF` |
| Primary text | `onSurface` | `#12161C` |
| Secondary text | `onSurfaceVariant` | `#5B6472` |
| Outline | `outline` | `#DDE2E9` |
| Primary accent | `electricCyan` | `#0AA8B8` |
| Secondary accent | `amber` | `#DB8A0F` |
| Urgency (App Blocker) | `actionOrange` | `#E8590C` |

Spacing scale: `4 / 8 / 16 / 24 / 32`. Corner radii: `pill (999)`, `xl (24)`, `lg (16)`, `md (12)`.

## Data model

Core models live in `lib/models/models.dart`:

- **`Goal`** — `title`, `target`, `iconKey`, optional `scheduledMinutes`, and a `history` list of `yyyy-MM-dd` completion date keys.
- **`BlockedApp`** — `name`, `iconKey`, `blocked`, `minutesSavedToday`, optional real Android `packageName`/icon bytes.
- **`RoutineExercise`** — `targetSets`/`targetReps`, `tags`, and `lastWeight`/`lastReps` carried forward for progressive overload.
- **`WorkoutDay`** — a weekday (1–7) with a list of exercises; an empty list means a rest day.
- **`Friend`** / **`ActivityItem`** — real cross-account social data, fetched from Supabase by `lib/services/social_service.dart` (see [Friends & social](#friends--social) below).

All app logic and persistence lives in the single `AppState` (`lib/state/app_state.dart`) — focus timer ticking, goal streaks, XP/level/rank calculation, workout set logging and volume tracking, blocked-app toggles, the Supabase auth session binding, and the friends/activity feed load.

## Friends & social

Every signed-in user gets a shareable 6-character **friend code** (shown at the top of the Community tab, tap to copy). To connect with someone else running the app:

1. They open their own Community tab and copy their code.
2. You tap the **+** button, paste their code into "Connect a Friend", and submit.
3. Supabase looks up the code's owner (`friend_codes` table), checks you're not already connected, and creates the connection (`friendships` table) — instant, no accept/decline step.

Once connected:

- Their avatar appears in your **Friends rail**; tapping it opens their **dashboard** — a read-only view of their focus score, streak, workouts completed, rank, and recent activity (`friend_dashboard_screen.dart`).
- Their **workout finishes**, **completed focus sessions**, and **streak milestones** post to the shared `activity_feed` table automatically (see `AppState._postActivity`), and show up in your Community feed with a 👍 kudos reaction.
- Ranking (`lib/utils/rank_utils.dart`) uses one formula for everyone, so your rank and a friend's rank are always directly comparable.

This is a live, real backend feature — not seeded demo data. Two people both running the app against the **same Supabase project** can connect and see each other's real progress.

## Notifications

Notifications are **on-device (local)** — built with `flutter_local_notifications`, no third-party push service. Toggling **Profile → Push Notifications** on triggers a real OS permission prompt (`NotificationService.requestPermission`); if denied, the toggle snaps back off and the app tells you to enable it in system settings.

Once enabled:

| Notification | Trigger | Frequency |
|---|---|---|
| **Focus session complete** | The countdown timer naturally reaches zero | Immediate |
| **Scheduled goal reminder** | A `Goal`'s own `scheduledMinutes` time of day, e.g. "Time for: Read 20 pages" | Daily, per goal |
| **Streak-at-risk nudge** | 8pm, only if goals aren't all done yet | Re-evaluated whenever a goal is toggled/added/removed |
| **Workout day reminder** | 7am on any non-rest day, e.g. "Today's workout: Push Day — 4 exercises" | Weekly, per training day |
| **New friend connected** | Someone connects using your code | Immediate — but **in-app only** (see caveat below) |

Everything above is scheduled with `AndroidScheduleMode.inexactAllowWhileIdle`, so no special exact-alarm permission is needed — reminders may land a few minutes off the exact time, which is fine for this use case.

**The "new friend connected" notification only fires while the app is open** (it's driven by a 60-second poll that also keeps the Community tab's friends/activity fresh). Making that — or a "kudos received" notification — arrive when the app is fully closed would need real push infrastructure: a Firebase project (FCM), storing each device's push token, and a Supabase Edge Function triggered on `friendships`/`activity_kudos` inserts that calls FCM. That's a separate, bigger setup not included here.

## Known limitations

- Goals, workouts, and blocked apps are stored locally per-device (`shared_preferences`) — they do not sync across devices or survive an uninstall. The Supabase schema for syncing them is ready (`supabase/schema.sql`, section 2) but not yet wired into `AppState`.
- Friend connections are instant (no request/accept step) — entering a valid code connects immediately.
- There's no live "currently focused" presence indicator on the friends rail; the dashboard shows aggregate stats, not real-time activity.
- Google Sign-In uses the browser-redirect OAuth flow rather than a native account picker.
- Notifications are on-device only — see the caveat in [Notifications](#notifications) above for what real push would require.
