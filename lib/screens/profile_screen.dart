import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/date_utils.dart';
import '../widgets/common.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 120),
        children: [
          Center(
            child: Column(
              children: [
                GradientAvatar(
                  name: state.displayName.isEmpty ? 'You' : state.displayName,
                  size: 88,
                ),
                const SizedBox(height: 12),
                Text(
                  state.displayName.isEmpty ? 'Operative' : state.displayName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (state.email.isNotEmpty)
                  Text(state.email, style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13)),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.05, end: 0),
          const SizedBox(height: AppSpacing.lg),
          _RankCard(state: state),
          const SizedBox(height: AppSpacing.lg),
          Text('Statistics', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          _StatsGrid(state: state),
          const SizedBox(height: AppSpacing.lg),
          Text('Settings', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  value: state.hapticsEnabled,
                  onChanged: state.setHaptics,
                  activeThumbColor: AppColors.electricCyan,
                  secondary: const Icon(Symbols.vibration_rounded),
                  title: const Text('Sound & Haptics'),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: state.notificationsEnabled,
                  onChanged: (value) async {
                    final granted = await state.setNotifications(value);
                    if (!granted && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Notifications are blocked for ESCAPE — enable them in system settings.',
                          ),
                          backgroundColor: AppColors.actionOrange,
                        ),
                      );
                    }
                  },
                  activeThumbColor: AppColors.electricCyan,
                  secondary: const Icon(Symbols.notifications_rounded),
                  title: const Text('Push Notifications'),
                  subtitle: const Text(
                    'Focus, goal, workout & streak reminders — plus friend connects while the app is open.',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Symbols.delete_forever_rounded, color: AppColors.actionOrange),
                  title: const Text('Clear Local Data', style: TextStyle(color: AppColors.actionOrange)),
                  onTap: () => _confirmClear(context, state),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Symbols.logout_rounded),
                  title: const Text('Sign Out'),
                  onTap: () => state.signOut(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmClear(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all local data?'),
        content: const Text('This resets goals, workouts, friends, and stats. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              state.clearAllData();
              Navigator.of(ctx).pop();
            },
            child: const Text('Clear', style: TextStyle(color: AppColors.actionOrange)),
          ),
        ],
      ),
    );
  }
}

class _RankCard extends StatelessWidget {
  const _RankCard({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.cyanGradient,
        borderRadius: AppRadii.xlRadius,
        boxShadow: AppShadows.glow(AppColors.electricCyan),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Symbols.emoji_events_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 6),
              Text('Level ${state.level}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              const Spacer(),
              Text('${state.xpIntoLevel} / 200 XP',
                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            state.rankTitle,
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: state.levelProgress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms, delay: 80.ms).slideY(begin: 0.06, end: 0);
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        icon: Symbols.bolt_rounded,
        color: AppColors.electricCyan,
        soft: AppColors.cyanSoft,
        label: 'Focus Minutes',
        value: formatMinutesLabel(state.focusMinutesTotal),
      ),
      (
        icon: Symbols.local_fire_department_rounded,
        color: AppColors.amber,
        soft: AppColors.amberSoft,
        label: 'Streak Days',
        value: '${state.streakDays}',
      ),
      (
        icon: Symbols.fitness_center_rounded,
        color: AppColors.actionOrange,
        soft: AppColors.actionOrangeSoft,
        label: 'Weight Lifted',
        value: '${state.totalVolume.round()} kg',
      ),
      (
        icon: Symbols.target_rounded,
        color: AppColors.cyanDeep,
        soft: AppColors.cyanSoft,
        label: 'Goals Completed',
        value: '${state.totalCompletedGoalsLifetime}',
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.25,
      children: [
        for (int i = 0; i < items.length; i++)
          AppCard(
            padding: const EdgeInsets.all(12),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  items[i].label,
                  style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ).animate().fadeIn(duration: 250.ms, delay: (60 * i).ms).scale(begin: const Offset(0.9, 0.9)),
      ],
    );
  }
}
