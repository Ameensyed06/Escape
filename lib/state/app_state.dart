import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/social_service.dart';
import '../utils/date_utils.dart';
import '../utils/rank_utils.dart';
import 'seed_data.dart';

const _uuid = Uuid();

class SetLog {
  SetLog({this.weight = 0, this.reps = 0, this.done = false});
  double weight;
  int reps;
  bool done;
}

/// Single ChangeNotifier holding all ESCAPE app state and local persistence.
class AppState extends ChangeNotifier {
  AppState() {
    _authService = AuthService(Supabase.instance.client);
    _social = SocialService(Supabase.instance.client);
    _load();
  }

  static const int focusDefaultMinutes = 25;

  late SharedPreferences _prefs;
  late final AuthService _authService;
  late final SocialService _social;
  StreamSubscription<AuthState>? _authSub;
  bool ready = false;

  AuthService get auth => _authService;

  /// This user's shareable friend code, once loaded (see [_loadSocialData]).
  String? myFriendCode;

  // ---- Auth ----
  bool signedIn = false;
  String displayName = '';
  String email = '';

  /// True right after the user taps a "reset password" email link; the UI
  /// should show the reset-password screen until [clearPasswordRecovery].
  bool passwordRecoveryPending = false;

  // ---- Core data ----
  List<Goal> goals = [];
  List<BlockedApp> blockedApps = [];
  List<WorkoutDay> routine = [];
  List<Friend> friends = [];
  List<ActivityItem> activity = [];

  // ---- Settings ----
  bool hapticsEnabled = true;
  bool notificationsEnabled = true;

  // ---- Focus timer ----
  Duration focusRemaining = const Duration(minutes: focusDefaultMinutes);
  bool focusActive = false;
  Timer? _ticker;
  int _secondAccumulator = 0;

  // ---- Stats ----
  int focusMinutesToday = 0;
  int focusMinutesTotal = 0;
  int streakDays = 0;
  double totalVolume = 0;
  int workoutsCompletedTotal = 0;
  String _lastFocusDateKey = '';
  String _lastStreakDateKey = '';
  int _focusSessionSeconds = 0;

  // ---- In-memory workout set logging (per exercise id) ----
  final Map<String, List<SetLog>> exerciseLogs = {};
  final Set<String> _completedWorkoutKeys = {}; // '$dateKey:$weekday'

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();

    _bindAuth();
    hapticsEnabled = _prefs.getBool('haptics_enabled') ?? true;
    notificationsEnabled = _prefs.getBool('notifications_enabled') ?? true;

    goals = _readList('goals_v1', Goal.fromJson) ?? seedGoals();
    blockedApps = _readList('blocked_apps_v1', BlockedApp.fromJson) ?? seedBlockedApps();
    routine = _readList('routine_v1', WorkoutDay.fromJson) ?? seedRoutine();
    // friends/activity are cloud-backed (see _loadSocialData) — no local seed.

    focusMinutesTotal = _prefs.getInt('focus_minutes_total_v1') ?? 0;
    streakDays = _prefs.getInt('streak_days_v1') ?? 0;
    totalVolume = _prefs.getDouble('volume_total_v1') ?? 0;
    workoutsCompletedTotal = _prefs.getInt('workouts_completed_total_v1') ?? 0;
    _lastFocusDateKey = _prefs.getString('focus_date_v1') ?? '';
    _lastStreakDateKey = _prefs.getString('streak_date_v1') ?? '';
    focusMinutesToday = _lastFocusDateKey == todayKey()
        ? (_prefs.getInt('focus_minutes_today_v1') ?? 0)
        : 0;

    ready = true;
    notifyListeners();
  }

  List<T>? _readList<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveGoals() => _prefs.setString(
    'goals_v1',
    jsonEncode(goals.map((g) => g.toJson()).toList()),
  );

  Future<void> _saveBlockedApps() => _prefs.setString(
    'blocked_apps_v1',
    jsonEncode(blockedApps.map((a) => a.toJson()).toList()),
  );

  Future<void> _saveRoutine() => _prefs.setString(
    'routine_v1',
    jsonEncode(routine.map((d) => d.toJson()).toList()),
  );

  Future<void> _saveStats() async {
    await _prefs.setInt('focus_minutes_total_v1', focusMinutesTotal);
    await _prefs.setInt('focus_minutes_today_v1', focusMinutesToday);
    await _prefs.setString('focus_date_v1', _lastFocusDateKey);
    await _prefs.setInt('streak_days_v1', streakDays);
    await _prefs.setString('streak_date_v1', _lastStreakDateKey);
    await _prefs.setDouble('volume_total_v1', totalVolume);
    await _prefs.setInt('workouts_completed_total_v1', workoutsCompletedTotal);
    _syncStatsToCloud();
  }

  /// Best-effort push of aggregate stats to Supabase so friends can see them
  /// on the friend dashboard. Never blocks or throws into the caller.
  void _syncStatsToCloud() {
    final uid = _authService.currentUser?.id;
    if (uid == null) return;
    _social
        .upsertUserStats(
          userId: uid,
          focusMinutesTotal: focusMinutesTotal,
          streakDays: streakDays,
          totalVolume: totalVolume,
          workoutsCompletedTotal: workoutsCompletedTotal,
        )
        .catchError((_) {});
  }

  /// Best-effort post to the activity feed. Never blocks or throws into the
  /// caller — if Supabase isn't configured yet or the request fails, the
  /// local action (finishing a workout, etc.) still succeeds.
  void _postActivity(String type, String message, String statLabel) {
    final uid = _authService.currentUser?.id;
    if (uid == null) return;
    _social
        .postActivity(userId: uid, type: type, message: message, statLabel: statLabel)
        .catchError((_) {});
  }

  void _haptic([HapticType type = HapticType.light]) {
    if (!hapticsEnabled) return;
    switch (type) {
      case HapticType.light:
        HapticFeedback.lightImpact();
      case HapticType.medium:
        HapticFeedback.mediumImpact();
      case HapticType.selection:
        HapticFeedback.selectionClick();
    }
  }

  // ================= Auth =================

  void _bindAuth() {
    _applyUser(_authService.currentUser);
    if (signedIn) _loadSocialData();
    _authSub = _authService.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        passwordRecoveryPending = true;
      }
      final wasSignedIn = signedIn;
      _applyUser(data.session?.user);
      if (signedIn && !wasSignedIn) {
        _loadSocialData();
      } else if (!signedIn && wasSignedIn) {
        friends = [];
        activity = [];
        myFriendCode = null;
      }
      notifyListeners();
    });
  }

  void _applyUser(User? user) {
    signedIn = user != null;
    if (user == null) {
      displayName = '';
      email = '';
      return;
    }
    email = user.email ?? '';
    final metaName = user.userMetadata?['display_name'] as String?;
    displayName = (metaName != null && metaName.trim().isNotEmpty)
        ? metaName.trim()
        : email.split('@').first;
  }

  /// Loads (or refreshes) this user's friend code, friends list, and feed
  /// from Supabase. Safe to call repeatedly; silently no-ops if Supabase
  /// isn't configured yet or the request fails.
  Future<void> _loadSocialData() async {
    final uid = _authService.currentUser?.id;
    if (uid == null) return;
    try {
      myFriendCode = await _social.ensureFriendCode(uid);
      friends = await _social.fetchFriends(uid);
      activity = await _social.fetchActivity(myUserId: uid);
      notifyListeners();
    } catch (_) {
      // Offline, or Supabase not configured yet — leave lists as-is; the
      // UI already has an empty-state message for this.
    }
  }

  Future<void> refreshSocial() => _loadSocialData();

  void clearPasswordRecovery() {
    passwordRecoveryPending = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    stopFocus();
    await _authService.signOut();
  }

  Future<void> clearAllData() async {
    await _prefs.clear();
    goals = seedGoals();
    blockedApps = seedBlockedApps();
    routine = seedRoutine();
    focusMinutesToday = 0;
    focusMinutesTotal = 0;
    streakDays = 0;
    totalVolume = 0;
    workoutsCompletedTotal = 0;
    focusRemaining = const Duration(minutes: focusDefaultMinutes);
    focusActive = false;
    _ticker?.cancel();
    notifyListeners();
  }

  // ================= Goals =================

  String get firstName =>
      displayName.trim().isEmpty ? 'there' : displayName.trim().split(' ').first;

  int get completedGoalsTodayCount =>
      goals.where((g) => g.isDoneOn(todayKey())).length;

  double get goalsProgress =>
      goals.isEmpty ? 0 : completedGoalsTodayCount / goals.length;

  int get totalCompletedGoalsLifetime =>
      goals.fold(0, (sum, g) => sum + g.history.length);

  // ================= Rank / XP =================

  RankStats get _myRankStats => RankStats(
    focusMinutesTotal: focusMinutesTotal,
    streakDays: streakDays,
    totalVolume: totalVolume,
    workoutsCompleted: workoutsCompletedTotal,
    goalsCompleted: totalCompletedGoalsLifetime,
  );

  int get xp => xpForStats(_myRankStats);

  int get level => levelForXp(xp);

  int get xpIntoLevel => xp % 200;

  double get levelProgress => xpIntoLevel / 200;

  String get rankTitle => rankTitleForLevel(level);

  Future<void> toggleGoal(String id) async {
    final goal = goals.firstWhere((g) => g.id == id);
    final key = todayKey();
    _haptic(HapticType.selection);
    if (goal.isDoneOn(key)) {
      goal.history.remove(key);
    } else {
      goal.history.add(key);
      _maybeAdvanceStreak();
    }
    await _saveGoals();
    notifyListeners();
  }

  void _maybeAdvanceStreak() {
    if (goals.isEmpty) return;
    final key = todayKey();
    final allDone = goals.every((g) => g.isDoneOn(key));
    if (!allDone || _lastStreakDateKey == key) return;
    final yesterday = dateKey(DateTime.now().subtract(const Duration(days: 1)));
    streakDays = _lastStreakDateKey == yesterday ? streakDays + 1 : 1;
    _lastStreakDateKey = key;
    _saveStats();
    _postActivity('streak', 'hit a $streakDays day streak', '$streakDays day streak');
  }

  Future<void> reorderGoals(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = goals.removeAt(oldIndex);
    goals.insert(newIndex, item);
    await _saveGoals();
    notifyListeners();
  }

  Future<void> addGoal({
    required String title,
    required String target,
    required String iconKey,
    int? scheduledMinutes,
  }) async {
    goals.add(Goal(
      id: _uuid.v4(),
      title: title,
      target: target,
      iconKey: iconKey,
      scheduledMinutes: scheduledMinutes,
    ));
    await _saveGoals();
    notifyListeners();
  }

  Future<void> updateGoal(
    String id, {
    String? title,
    String? target,
    String? iconKey,
    int? scheduledMinutes,
  }) async {
    final goal = goals.firstWhere((g) => g.id == id);
    if (title != null) goal.title = title;
    if (target != null) goal.target = target;
    if (iconKey != null) goal.iconKey = iconKey;
    goal.scheduledMinutes = scheduledMinutes;
    await _saveGoals();
    notifyListeners();
  }

  Future<void> deleteGoal(String id) async {
    goals.removeWhere((g) => g.id == id);
    await _saveGoals();
    notifyListeners();
  }

  // ================= Focus Mode =================

  String get focusStatusLabel => focusActive ? 'Active' : 'Idle';

  void startFocus() {
    if (focusActive) return;
    focusActive = true;
    _focusSessionSeconds = 0;
    _haptic(HapticType.medium);
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tickFocus());
    notifyListeners();
  }

  void stopFocus() {
    if (!focusActive) return;
    focusActive = false;
    _ticker?.cancel();
    _ticker = null;
    _haptic(HapticType.medium);
    _saveStats();
    notifyListeners();
  }

  void toggleFocus() => focusActive ? stopFocus() : startFocus();

  void addFocusMinutes(int minutes) {
    focusRemaining += Duration(minutes: minutes);
    _haptic();
    notifyListeners();
  }

  void _tickFocus() {
    if (focusRemaining.inSeconds <= 0) {
      stopFocus();
      focusRemaining = const Duration(minutes: focusDefaultMinutes);
      final sessionMinutes = _focusSessionSeconds ~/ 60;
      _focusSessionSeconds = 0;
      if (sessionMinutes > 0) {
        _postActivity('focus', 'completed a focus session', '$sessionMinutes min focused');
      }
      notifyListeners();
      return;
    }
    focusRemaining -= const Duration(seconds: 1);
    _focusSessionSeconds += 1;

    final key = todayKey();
    if (_lastFocusDateKey != key) {
      _lastFocusDateKey = key;
      focusMinutesToday = 0;
    }
    _secondAccumulator += 1;
    if (_secondAccumulator >= 60) {
      _secondAccumulator = 0;
      focusMinutesToday += 1;
      focusMinutesTotal += 1;
      _saveStats();
    }
    notifyListeners();
  }

  // ================= Blocked Apps =================

  int get reclaimedMinutesToday =>
      blockedApps.fold(0, (sum, a) => sum + a.minutesSavedToday);

  Future<void> toggleAppBlocked(String id) async {
    final app = blockedApps.firstWhere((a) => a.id == id);
    app.blocked = !app.blocked;
    _haptic(HapticType.selection);
    await _saveBlockedApps();
    notifyListeners();
  }

  Future<void> addBlockedApp(String name, String iconKey) async {
    blockedApps.add(BlockedApp(id: _uuid.v4(), name: name, iconKey: iconKey, blocked: true));
    await _saveBlockedApps();
    notifyListeners();
  }

  Future<void> removeBlockedApp(String id) async {
    blockedApps.removeWhere((a) => a.id == id);
    await _saveBlockedApps();
    notifyListeners();
  }

  // ================= Workouts =================

  WorkoutDay dayFor(int weekday) => routine.firstWhere((d) => d.weekday == weekday);

  List<SetLog> logsFor(RoutineExercise ex) {
    return exerciseLogs.putIfAbsent(
      ex.id,
      () => List.generate(ex.targetSets, (_) => SetLog(
        weight: ex.lastWeight ?? 0,
        reps: ex.lastReps ?? ex.targetReps,
      )),
    );
  }

  void updateSetLog(RoutineExercise ex, int setIndex, {double? weight, int? reps}) {
    final logs = logsFor(ex);
    if (setIndex >= logs.length) return;
    if (weight != null) logs[setIndex].weight = weight;
    if (reps != null) logs[setIndex].reps = reps;
    notifyListeners();
  }

  void toggleSetDone(RoutineExercise ex, int setIndex) {
    final logs = logsFor(ex);
    if (setIndex >= logs.length) return;
    final log = logs[setIndex];
    log.done = !log.done;
    _haptic(HapticType.selection);
    final delta = log.weight * log.reps * (log.done ? 1 : -1);
    totalVolume = max(0, totalVolume + delta);
    _saveStats();
    notifyListeners();
  }

  bool isExerciseComplete(RoutineExercise ex) {
    final logs = exerciseLogs[ex.id];
    if (logs == null) return false;
    return logs.every((l) => l.done);
  }

  double dayCompletionRatio(WorkoutDay day) {
    if (day.exercises.isEmpty) return 0;
    final done = day.exercises.where(isExerciseComplete).length;
    return done / day.exercises.length;
  }

  bool isWorkoutFinished(WorkoutDay day) =>
      _completedWorkoutKeys.contains('${todayKey()}:${day.weekday}');

  Future<void> finishWorkout(WorkoutDay day) async {
    double sessionVolume = 0;
    for (final ex in day.exercises) {
      final logs = exerciseLogs[ex.id];
      if (logs == null) continue;
      final doneLogs = logs.where((l) => l.done).toList();
      if (doneLogs.isEmpty) continue;
      ex.lastWeight = doneLogs.last.weight;
      ex.lastReps = doneLogs.last.reps;
      sessionVolume += doneLogs.fold<double>(0, (sum, l) => sum + l.weight * l.reps);
    }
    _completedWorkoutKeys.add('${todayKey()}:${day.weekday}');
    workoutsCompletedTotal += 1;
    _haptic(HapticType.medium);
    await _saveRoutine();
    await _saveStats();
    _postActivity('workout', 'finished ${day.title}', '${sessionVolume.round()} kg lifted');
    notifyListeners();
  }

  // ================= Social =================
  //
  // Friends/activity are fetched from Supabase (see _loadSocialData) rather
  // than kept locally — this is real cross-account social data, not a demo
  // seed. Connecting a friend uses a shareable per-user code (myFriendCode).

  void toggleKudos(String activityId) {
    final item = activity.firstWhere((a) => a.id == activityId);
    item.kudosGiven = !item.kudosGiven;
    item.kudos += item.kudosGiven ? 1 : -1;
    _haptic(HapticType.medium);
    notifyListeners();

    final uid = _authService.currentUser?.id;
    if (uid == null) return;
    _social
        .setKudos(activityId: activityId, userId: uid, given: item.kudosGiven)
        .catchError((_) {});
  }

  /// Connects with whoever owns [code]. Throws [FriendConnectException] with
  /// a user-facing message on failure (invalid code, self-add, duplicate).
  Future<void> addFriendByCode(String code) async {
    final uid = _authService.currentUser?.id;
    if (uid == null) return;
    await _social.addFriendByCode(myUserId: uid, code: code);
    await _loadSocialData();
  }

  /// Looks up a friend's hydrated profile — checks the already-loaded
  /// [friends] list first, falling back to a fresh fetch.
  Future<Friend?> friendProfile(String friendId) async {
    for (final f in friends) {
      if (f.id == friendId) return f;
    }
    try {
      return await _social.fetchFriend(friendId);
    } catch (_) {
      return null;
    }
  }

  /// A single friend's activity history, for the friend dashboard.
  Future<List<ActivityItem>> friendActivity(String friendId) async {
    final uid = _authService.currentUser?.id;
    if (uid == null) return [];
    try {
      return await _social.fetchActivity(myUserId: uid, authorIds: [friendId]);
    } catch (_) {
      return [];
    }
  }

  // ================= Settings =================

  Future<void> setHaptics(bool value) async {
    hapticsEnabled = value;
    await _prefs.setBool('haptics_enabled', value);
    notifyListeners();
  }

  Future<void> setNotifications(bool value) async {
    notificationsEnabled = value;
    await _prefs.setBool('notifications_enabled', value);
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _authSub?.cancel();
    super.dispose();
  }
}

enum HapticType { light, medium, selection }
