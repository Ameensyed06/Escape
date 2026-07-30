import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Read-only view of a friend's progress — focus, streak, workouts, and
/// their recent activity — mirroring the signed-in user's own Profile
/// screen but sourced entirely from Supabase.
class FriendDashboardScreen extends StatefulWidget {
  const FriendDashboardScreen({super.key, required this.friendId, this.preview});

  final String friendId;

  /// Pass the already-hydrated [Friend] when navigating from a list that
  /// has one (friends rail, activity card) so the header renders instantly
  /// while the activity history loads in the background.
  final Friend? preview;

  @override
  State<FriendDashboardScreen> createState() => _FriendDashboardScreenState();
}

class _FriendDashboardScreenState extends State<FriendDashboardScreen> {
  Friend? _friend;
  List<ActivityItem> _activity = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _friend = widget.preview;
    _load();
  }

  Future<void> _load() async {
    final state = context.read<AppState>();
    final results = await Future.wait([
      state.friendProfile(widget.friendId),
      state.friendActivity(widget.friendId),
    ]);
    if (!mounted) return;
    setState(() {
      _friend = results[0] as Friend? ?? _friend;
      _activity = results[1] as List<ActivityItem>;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final friend = _friend;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(friend?.name ?? 'Friend')),
      body: friend == null
          ? _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.electricCyan))
                : const Center(
                    child: Text("Couldn't load this profile.",
                        style: TextStyle(color: AppColors.onSurfaceVariant)),
                  )
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.electricCyan,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 100),
                children: [
                  Center(
                    child: Column(
                      children: [
                        GradientAvatar(name: friend.name, size: 88, seed: friend.avatarSeed),
                        const SizedBox(height: 12),
                        Text(friend.name, style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 4),
                        Pill(
                          label: friend.rank,
                          color: AppColors.cyanSoft,
                          textColor: AppColors.cyanDeep,
                          icon: Symbols.emoji_events_rounded,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.05, end: 0),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Progress', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  _StatsGrid(friend: friend),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Recent Activity', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator(color: AppColors.electricCyan)),
                    )
                  else if (_activity.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text('No activity yet.', style: TextStyle(color: AppColors.onSurfaceVariant)),
                      ),
                    )
                  else
                    ..._activity.map((item) => _FriendActivityCard(item: item)),
                ],
              ),
            ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.friend});

  final Friend friend;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        icon: Symbols.bolt_rounded,
        color: AppColors.electricCyan,
        soft: AppColors.cyanSoft,
        label: 'Focus Score',
        value: '${friend.focusScore}',
      ),
      (
        icon: Symbols.local_fire_department_rounded,
        color: AppColors.amber,
        soft: AppColors.amberSoft,
        label: 'Streak Days',
        value: '${friend.currentStreak}',
      ),
      (
        icon: Symbols.fitness_center_rounded,
        color: AppColors.actionOrange,
        soft: AppColors.actionOrangeSoft,
        label: 'Workouts Done',
        value: '${friend.workoutsDone}',
      ),
      (
        icon: Symbols.emoji_events_rounded,
        color: AppColors.cyanDeep,
        soft: AppColors.cyanSoft,
        label: 'Rank',
        value: friend.rank,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.5,
      children: [
        for (int i = 0; i < items.length; i++)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: items[i].soft, borderRadius: AppRadii.mdRadius),
                  alignment: Alignment.center,
                  child: Icon(items[i].icon, size: 16, color: items[i].color),
                ),
                const Spacer(),
                Text(
                  items[i].value,
                  style: Theme.of(context).textTheme.titleLarge,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(items[i].label, style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 11)),
              ],
            ),
          ).animate().fadeIn(duration: 250.ms, delay: (60 * i).ms).scale(begin: const Offset(0.9, 0.9)),
      ],
    );
  }
}

class _FriendActivityCard extends StatelessWidget {
  const _FriendActivityCard({required this.item});

  final ActivityItem item;

  IconData get _icon {
    switch (item.type) {
      case 'workout':
        return Symbols.fitness_center_rounded;
      case 'focus':
        return Symbols.bolt_rounded;
      case 'streak':
        return Symbols.local_fire_department_rounded;
      default:
        return Symbols.emoji_events_rounded;
    }
  }

  String _timeAgo() {
    final diff = DateTime.now().difference(item.timestamp);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: AppColors.cyanSoft, borderRadius: AppRadii.mdRadius),
              alignment: Alignment.center,
              child: Icon(_icon, size: 18, color: AppColors.electricCyan),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.message, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(item.statLabel,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.electricCyan)),
                      const SizedBox(width: 8),
                      Text('· ${_timeAgo()}',
                          style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => state.toggleKudos(item.id),
              child: Column(
                children: [
                  Icon(
                    Symbols.thumb_up_rounded,
                    color: item.kudosGiven ? AppColors.electricCyan : AppColors.onSurfaceVariant,
                    size: 20,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.kudos}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: item.kudosGiven ? AppColors.electricCyan : AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
