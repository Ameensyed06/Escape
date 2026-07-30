# ESCAPE — Web

A React + TypeScript port of the ESCAPE Flutter app, covering the same features: Focus Mode, Daily Commitments, App Blocker, Training Plan, Community, and Profile.

It talks to the **same Supabase project** as the mobile app (see `../lib/config/supabase_config.dart` / `../supabase/schema.sql`), so signing in with the same account shows the same friends, profile, and social activity on both platforms.

## Tech stack

| Concern | Choice |
|---|---|
| Framework | React 19 + TypeScript, via Vite |
| Routing | `react-router-dom` |
| Styling | Tailwind CSS v4 (`@theme` tokens mirror `lib/theme/app_theme.dart`) |
| Icons | `lucide-react` |
| Backend | `@supabase/supabase-js` — same project as mobile |
| State | React Context (`AuthContext`, `AppStore`) — no external state library |
| Local persistence | `localStorage` (the web analogue of `shared_preferences`) |

## Running locally

```bash
npm install
npm run dev      # http://localhost:5173
npm run build    # type-check + production build to dist/
npm run lint
```

No environment setup required — the Supabase URL/anon key are baked in (`src/lib/supabase.ts`), same as the mobile app's approach. Set `VITE_SUPABASE_URL` / `VITE_SUPABASE_ANON_KEY` (see `.env.example`) only if you want to point this at a different project.

## What's shared with mobile vs. local-only

- **Shared via Supabase** (same tables, same RLS policies — see `../supabase/schema.sql`): auth, friend codes/connections, activity feed, kudos, cross-user stats (`user_stats`).
- **Local to this browser** (`localStorage`, not synced anywhere — same scope as the mobile app's on-device data): goals, blocked apps, the workout plan and its set logs, focus timer state.

## Notifications

Uses the browser `Notification` API (`src/lib/notifications.ts`) — a permission prompt via Profile → Push Notifications, then notifications for focus-session completion and new friend connections. Like the mobile app's local notifications, these are **not real push**: they only fire while this tab is open, since there's no service worker / Push API wiring here. Scheduled reminders (goal times, streak nudges, workout days) that the mobile app has via OS-level scheduling aren't replicated here — a plain browser tab has no equivalent background scheduler.

## Known limitations

- Goals/workouts/blocked apps don't sync between the website and the mobile app — each keeps its own local copy. Only the Supabase-backed social features (friends, activity, profile/stats) are shared.
- Reordering goals uses up/down buttons rather than drag-and-drop.
- Google Sign-In uses the standard browser OAuth redirect (simpler here than mobile — no deep link / custom URL scheme needed).
