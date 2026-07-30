// Mirrors lib/services/social_service.dart — same Supabase tables as the
// mobile app, so friend connections work across both platforms.

import { supabase } from './supabase';
import { rankTitleForLevel, levelForXp, xpForStats } from './rankUtils';
import type { ActivityItem, Friend } from '../types/models';

export class FriendConnectError extends Error {}

const CODE_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

function generateCode(): string {
  let out = '';
  const bytes = new Uint8Array(6);
  crypto.getRandomValues(bytes);
  for (const b of bytes) out += CODE_ALPHABET[b % CODE_ALPHABET.length];
  return out;
}

function hashSeed(id: string): number {
  let hash = 0;
  for (let i = 0; i < id.length; i++) {
    hash = (hash * 31 + id.charCodeAt(i)) | 0;
  }
  return Math.abs(hash) % 30;
}

export async function ensureFriendCode(userId: string): Promise<string> {
  const { data: existing } = await supabase
    .from('friend_codes')
    .select('code')
    .eq('user_id', userId)
    .maybeSingle();
  if (existing) return existing.code as string;

  const code = generateCode();
  await supabase.from('friend_codes').insert({ user_id: userId, code });
  return code;
}

async function hydrateFriends(ids: string[]): Promise<Friend[]> {
  if (ids.length === 0) return [];

  const [{ data: profiles }, { data: stats }] = await Promise.all([
    supabase.from('profiles').select('id, display_name').in('id', ids),
    supabase
      .from('user_stats')
      .select('user_id, focus_minutes_total, streak_days, total_volume, workouts_completed_total')
      .in('user_id', ids),
  ]);

  const statsById = new Map((stats ?? []).map((s) => [s.user_id as string, s]));

  return (profiles ?? []).map((p) => {
    const id = p.id as string;
    const s = statsById.get(id);
    const focusMinutesTotal = (s?.focus_minutes_total as number) ?? 0;
    const streakDays = (s?.streak_days as number) ?? 0;
    const totalVolume = (s?.total_volume as number) ?? 0;
    const workoutsCompleted = (s?.workouts_completed_total as number) ?? 0;
    const xp = xpForStats({ focusMinutesTotal, streakDays, totalVolume, workoutsCompleted });
    const name = ((p.display_name as string) ?? '').trim();
    return {
      id,
      name: name.length > 0 ? name : 'Operative',
      avatarSeed: hashSeed(id),
      rank: rankTitleForLevel(levelForXp(xp)),
      focusScore: xp,
      currentStreak: streakDays,
      workoutsDone: workoutsCompleted,
    };
  });
}

export async function addFriendByCode(myUserId: string, code: string): Promise<Friend> {
  const normalized = code.trim().toUpperCase();
  if (!normalized) throw new FriendConnectError('Enter a friend code.');

  const { data: match } = await supabase
    .from('friend_codes')
    .select('user_id')
    .eq('code', normalized)
    .maybeSingle();
  if (!match) throw new FriendConnectError('No account found with that code.');

  const targetId = match.user_id as string;
  if (targetId === myUserId) throw new FriendConnectError("That's your own code.");

  const { data: existing } = await supabase
    .from('friendships')
    .select('user_id')
    .or(
      `and(user_id.eq.${myUserId},friend_id.eq.${targetId}),` +
        `and(user_id.eq.${targetId},friend_id.eq.${myUserId})`,
    )
    .maybeSingle();
  if (existing) throw new FriendConnectError("You're already connected with this person.");

  await supabase
    .from('friendships')
    .insert({ user_id: myUserId, friend_id: targetId, status: 'accepted' });

  const [friend] = await hydrateFriends([targetId]);
  return (
    friend ?? {
      id: targetId,
      name: 'Operative',
      avatarSeed: hashSeed(targetId),
      rank: 'Recruit',
      focusScore: 0,
      currentStreak: 0,
      workoutsDone: 0,
    }
  );
}

export async function fetchFriends(myUserId: string): Promise<Friend[]> {
  const { data: rows } = await supabase
    .from('friendships')
    .select('user_id, friend_id')
    .eq('status', 'accepted')
    .or(`user_id.eq.${myUserId},friend_id.eq.${myUserId}`);

  const ids = Array.from(
    new Set(
      (rows ?? []).map((r) =>
        (r.user_id as string) === myUserId ? (r.friend_id as string) : (r.user_id as string),
      ),
    ),
  );
  return hydrateFriends(ids);
}

export async function fetchFriend(friendId: string): Promise<Friend | null> {
  const [friend] = await hydrateFriends([friendId]);
  return friend ?? null;
}

export async function fetchActivity(
  myUserId: string,
  authorIds?: string[],
  limit = 30,
): Promise<ActivityItem[]> {
  const ids = authorIds ?? (await fetchFriends(myUserId)).map((f) => f.id);
  if (ids.length === 0) return [];

  const { data: feed } = await supabase
    .from('activity_feed')
    .select('id, user_id, type, message, stat_label, created_at')
    .in('user_id', ids)
    .order('created_at', { ascending: false })
    .limit(limit);
  if (!feed || feed.length === 0) return [];

  const authorSet = Array.from(new Set(feed.map((f) => f.user_id as string)));
  const activityIds = feed.map((f) => f.id as string);

  const [{ data: profiles }, { data: kudos }] = await Promise.all([
    supabase.from('profiles').select('id, display_name').in('id', authorSet),
    supabase.from('activity_kudos').select('activity_id, user_id').in('activity_id', activityIds),
  ]);

  const nameById = new Map((profiles ?? []).map((p) => [p.id as string, (p.display_name as string) ?? '']));
  const kudosCountById = new Map<string, number>();
  const myKudosGiven = new Set<string>();
  for (const k of kudos ?? []) {
    const aid = k.activity_id as string;
    kudosCountById.set(aid, (kudosCountById.get(aid) ?? 0) + 1);
    if (k.user_id === myUserId) myKudosGiven.add(aid);
  }

  return feed.map((f) => {
    const id = f.id as string;
    const authorId = f.user_id as string;
    const name = nameById.get(authorId) ?? '';
    return {
      id,
      friendId: authorId,
      friendName: name.length > 0 ? name : 'Operative',
      avatarSeed: hashSeed(authorId),
      type: f.type as ActivityItem['type'],
      message: f.message as string,
      statLabel: (f.stat_label as string) ?? '',
      timestamp: f.created_at as string,
      kudos: kudosCountById.get(id) ?? 0,
      kudosGiven: myKudosGiven.has(id),
    };
  });
}

export async function postActivity(
  userId: string,
  type: ActivityItem['type'],
  message: string,
  statLabel: string,
): Promise<void> {
  await supabase.from('activity_feed').insert({ user_id: userId, type, message, stat_label: statLabel });
}

export async function setKudos(activityId: string, userId: string, given: boolean): Promise<void> {
  if (given) {
    await supabase.from('activity_kudos').upsert({ activity_id: activityId, user_id: userId });
  } else {
    await supabase.from('activity_kudos').delete().eq('activity_id', activityId).eq('user_id', userId);
  }
}

export async function upsertUserStats(
  userId: string,
  focusMinutesTotal: number,
  streakDays: number,
  totalVolume: number,
  workoutsCompletedTotal: number,
): Promise<void> {
  await supabase.from('user_stats').upsert({
    user_id: userId,
    focus_minutes_total: focusMinutesTotal,
    streak_days: streakDays,
    total_volume: totalVolume,
    workouts_completed_total: workoutsCompletedTotal,
  });
}
