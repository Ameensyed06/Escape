import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';
import '../utils/rank_utils.dart';

/// Thrown for user-facing failures when connecting a friend (invalid code,
/// self-add, already connected) — the message is safe to show directly.
class FriendConnectException implements Exception {
  FriendConnectException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Supabase-backed friend connections, activity feed, and cross-user stats.
///
/// Friendships are stored as a single directed row: whoever enters the code
/// is `user_id`, the code's owner is `friend_id`. Both people can read the
/// row (RLS allows a match on either column), so there's no need for a
/// mirrored second row — see `friendships_owner` in supabase/schema.sql.
class SocialService {
  SocialService(this._client);

  final SupabaseClient _client;

  static const _codeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  String _generateCode() {
    final rand = Random.secure();
    return List.generate(6, (_) => _codeAlphabet[rand.nextInt(_codeAlphabet.length)]).join();
  }

  /// Returns this user's shareable friend code, creating one on first call.
  Future<String> ensureFriendCode(String userId) async {
    final existing = await _client
        .from('friend_codes')
        .select('code')
        .eq('user_id', userId)
        .maybeSingle();
    if (existing != null) return existing['code'] as String;

    final code = _generateCode();
    await _client.from('friend_codes').insert({'user_id': userId, 'code': code});
    return code;
  }

  /// Connects with whoever owns [code], returning their hydrated profile so
  /// the UI can show a personalized "Connected with X!" confirmation.
  Future<Friend> addFriendByCode({required String myUserId, required String code}) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) {
      throw FriendConnectException('Enter a friend code.');
    }

    final match = await _client
        .from('friend_codes')
        .select('user_id')
        .eq('code', normalized)
        .maybeSingle();
    if (match == null) {
      throw FriendConnectException('No account found with that code.');
    }

    final targetId = match['user_id'] as String;
    if (targetId == myUserId) {
      throw FriendConnectException("That's your own code.");
    }

    final existing = await _client
        .from('friendships')
        .select('user_id')
        .or(
          'and(user_id.eq.$myUserId,friend_id.eq.$targetId),'
          'and(user_id.eq.$targetId,friend_id.eq.$myUserId)',
        )
        .maybeSingle();
    if (existing != null) {
      throw FriendConnectException("You're already connected with this person.");
    }

    await _client.from('friendships').insert({
      'user_id': myUserId,
      'friend_id': targetId,
      'status': 'accepted',
    });

    final hydrated = await _hydrateFriends([targetId]);
    return hydrated.isNotEmpty
        ? hydrated.first
        : Friend(
            id: targetId,
            name: 'Operative',
            code: normalized,
            avatarSeed: targetId.hashCode.abs() % 30,
            rank: 'Recruit',
            focusScore: 0,
            currentStreak: 0,
            workoutsDone: 0,
            minutesFocusedToday: 0,
          );
  }

  Future<List<Friend>> fetchFriends(String myUserId) async {
    final rows = await _client
        .from('friendships')
        .select('user_id, friend_id')
        .eq('status', 'accepted')
        .or('user_id.eq.$myUserId,friend_id.eq.$myUserId');

    final friendIds = (rows as List)
        .map((r) => (r['user_id'] == myUserId) ? r['friend_id'] as String : r['user_id'] as String)
        .toSet()
        .toList();
    if (friendIds.isEmpty) return [];

    return _hydrateFriends(friendIds);
  }

  Future<List<Friend>> _hydrateFriends(List<String> ids) async {
    if (ids.isEmpty) return [];

    final profiles = await _client.from('profiles').select('id, display_name').inFilter('id', ids);
    final stats = await _client
        .from('user_stats')
        .select('user_id, focus_minutes_total, streak_days, total_volume, workouts_completed_total')
        .inFilter('user_id', ids);

    final statsById = {for (final s in stats as List) s['user_id'] as String: s};

    return (profiles as List).map((p) {
      final id = p['id'] as String;
      final s = statsById[id];
      final focusMinutesTotal = (s?['focus_minutes_total'] as int?) ?? 0;
      final streakDays = (s?['streak_days'] as int?) ?? 0;
      final totalVolume = ((s?['total_volume'] as num?) ?? 0).toDouble();
      final workoutsCompleted = (s?['workouts_completed_total'] as int?) ?? 0;
      final xp = xpForStats(RankStats(
        focusMinutesTotal: focusMinutesTotal,
        streakDays: streakDays,
        totalVolume: totalVolume,
        workoutsCompleted: workoutsCompleted,
      ));
      final name = (p['display_name'] as String?)?.trim() ?? '';
      return Friend(
        id: id,
        name: name.isEmpty ? 'Operative' : name,
        code: '',
        avatarSeed: id.hashCode.abs() % 30,
        rank: rankTitleForLevel(levelForXp(xp)),
        focusScore: xp,
        currentStreak: streakDays,
        workoutsDone: workoutsCompleted,
        minutesFocusedToday: 0,
      );
    }).toList();
  }

  /// Fetches a single friend's hydrated profile — used by the friend
  /// dashboard when navigated to directly with just an id.
  Future<Friend?> fetchFriend(String userId) async {
    final results = await _hydrateFriends([userId]);
    return results.isEmpty ? null : results.first;
  }

  /// Recent activity authored by [authorIds]. Pass a single friend's id to
  /// show just their history (friend dashboard), or omit to fall back to
  /// every connected friend (main feed).
  Future<List<ActivityItem>> fetchActivity({
    required String myUserId,
    List<String>? authorIds,
    int limit = 30,
  }) async {
    final ids = authorIds ?? (await fetchFriends(myUserId)).map((f) => f.id).toList();
    if (ids.isEmpty) return [];

    final feed = await _client
        .from('activity_feed')
        .select('id, user_id, type, message, stat_label, created_at')
        .inFilter('user_id', ids)
        .order('created_at', ascending: false)
        .limit(limit);

    final feedList = feed as List;
    if (feedList.isEmpty) return [];

    final authorSet = feedList.map((f) => f['user_id'] as String).toSet().toList();
    final profiles = await _client.from('profiles').select('id, display_name').inFilter('id', authorSet);
    final nameById = {
      for (final p in profiles as List) p['id'] as String: (p['display_name'] as String?) ?? '',
    };

    final activityIds = feedList.map((f) => f['id'] as String).toList();
    final kudos = await _client
        .from('activity_kudos')
        .select('activity_id, user_id')
        .inFilter('activity_id', activityIds);

    final kudosCountById = <String, int>{};
    final myKudosGiven = <String>{};
    for (final k in kudos as List) {
      final aid = k['activity_id'] as String;
      kudosCountById[aid] = (kudosCountById[aid] ?? 0) + 1;
      if (k['user_id'] == myUserId) myKudosGiven.add(aid);
    }

    return feedList.map((f) {
      final id = f['id'] as String;
      final authorId = f['user_id'] as String;
      final name = nameById[authorId] ?? '';
      return ActivityItem(
        id: id,
        friendId: authorId,
        friendName: name.isEmpty ? 'Operative' : name,
        avatarSeed: authorId.hashCode.abs() % 30,
        type: f['type'] as String,
        message: f['message'] as String,
        statLabel: (f['stat_label'] as String?) ?? '',
        timestamp: DateTime.parse(f['created_at'] as String),
        kudos: kudosCountById[id] ?? 0,
        kudosGiven: myKudosGiven.contains(id),
      );
    }).toList();
  }

  Future<void> postActivity({
    required String userId,
    required String type,
    required String message,
    required String statLabel,
  }) {
    return _client.from('activity_feed').insert({
      'user_id': userId,
      'type': type,
      'message': message,
      'stat_label': statLabel,
    });
  }

  Future<void> setKudos({required String activityId, required String userId, required bool given}) {
    if (given) {
      return _client.from('activity_kudos').upsert({'activity_id': activityId, 'user_id': userId});
    }
    return _client.from('activity_kudos').delete().eq('activity_id', activityId).eq('user_id', userId);
  }

  Future<void> upsertUserStats({
    required String userId,
    required int focusMinutesTotal,
    required int streakDays,
    required double totalVolume,
    required int workoutsCompletedTotal,
  }) {
    return _client.from('user_stats').upsert({
      'user_id': userId,
      'focus_minutes_total': focusMinutesTotal,
      'streak_days': streakDays,
      'total_volume': totalVolume,
      'workouts_completed_total': workoutsCompletedTotal,
    });
  }
}
