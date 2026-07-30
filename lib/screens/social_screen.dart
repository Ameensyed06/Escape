import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class SocialScreen extends StatelessWidget {
  const SocialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Community')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.electricCyan,
        onPressed: () => _showAddFriendSheet(context, state),
        child: const Icon(Symbols.person_add_rounded, color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, AppSpacing.md, 0, 120),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text('Friends', style: Theme.of(context).textTheme.titleLarge),
          ),
          const SizedBox(height: 10),
          _FriendsRail(friends: state.friends),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text('Activity', style: Theme.of(context).textTheme.titleLarge),
          ),
          const SizedBox(height: 10),
          if (state.activity.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 24),
              child: Center(
                child: Text('No activity yet — add friends to see their progress.',
                    style: TextStyle(color: AppColors.onSurfaceVariant)),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                children: [
                  for (int i = 0; i < state.activity.length; i++)
                    _ActivityCard(item: state.activity[i], index: i),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showAddFriendSheet(BuildContext context, AppState state) {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Connect a Friend', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 6),
              const Text(
                "Enter your friend's name and their invite code to connect.",
                style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Friend name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: codeCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Invite code',
                  prefixIcon: Icon(Symbols.qr_code_rounded),
                ),
              ),
              const SizedBox(height: 20),
              GradientButton(
                label: 'Connect',
                onTap: () {
                  if (nameCtrl.text.trim().isEmpty || codeCtrl.text.trim().isEmpty) return;
                  state.addFriendByCode(codeCtrl.text.trim(), nameCtrl.text.trim());
                  Navigator.of(ctx).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FriendsRail extends StatelessWidget {
  const _FriendsRail({required this.friends});

  final List<Friend> friends;

  @override
  Widget build(BuildContext context) {
    if (friends.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Text('No friends connected yet.', style: TextStyle(color: AppColors.onSurfaceVariant)),
      );
    }
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: friends.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final f = friends[i];
          final active = f.minutesFocusedToday > 0;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: active ? AppColors.electricCyan : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: GradientAvatar(name: f.name, size: 52, seed: f.avatarSeed),
                  ),
                  if (f.currentStreak > 0)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.amber,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.surface, width: 1.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Symbols.local_fire_department_rounded, size: 10, color: Colors.white),
                            Text(
                              '${f.currentStreak}',
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 60,
                child: Text(
                  f.name.split(' ').first,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ).animate().fadeIn(duration: 250.ms, delay: (60 * i).ms).scale(begin: const Offset(0.85, 0.85));
        },
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.item, required this.index});

  final ActivityItem item;
  final int index;

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
            GradientAvatar(name: item.friendName, size: 40, seed: item.avatarSeed),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(color: AppColors.onSurface, fontSize: 14),
                      children: [
                        TextSpan(text: item.friendName, style: const TextStyle(fontWeight: FontWeight.w800)),
                        TextSpan(text: ' ${item.message}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(_icon, size: 14, color: AppColors.electricCyan),
                      const SizedBox(width: 4),
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
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 260),
                curve: Curves.elasticOut,
                tween: Tween(begin: 1, end: item.kudosGiven ? 1.25 : 1),
                builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
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
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 250.ms, delay: (40 * index).ms).slideY(begin: 0.04, end: 0);
  }
}
