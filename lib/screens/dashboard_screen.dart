import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/date_utils.dart';
import '../utils/icon_map.dart';
import '../widgets/common.dart';
import 'profile_screen.dart';
import 'workout_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 5) return 'Still up';
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          120,
        ),
        children: [
          _Header(greeting: _greeting(), state: state),
          const SizedBox(height: AppSpacing.lg),
          const _FocusCard(),
          const SizedBox(height: AppSpacing.md),
          _GoalsShortcutCard(state: state),
          const SizedBox(height: AppSpacing.md),
          _WorkoutCard(state: state),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.greeting, required this.state});

  final String greeting;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 2),
              Text(
                state.firstName,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          ),
          child: GradientAvatar(name: state.displayName.isEmpty ? 'You' : state.displayName, size: 48),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.08, end: 0);
  }
}

class _FocusCard extends StatelessWidget {
  const _FocusCard();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final active = state.focusActive;

    return AppCard(
      color: active ? AppColors.cyanDeep : AppColors.surface,
      borderColor: active ? AppColors.cyanDeep : AppColors.outline,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Symbols.bolt_rounded,
                color: active ? Colors.white : AppColors.electricCyan,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                'Focus Mode',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white70 : AppColors.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: active ? Colors.white.withValues(alpha: 0.15) : AppColors.cyanSoft,
                  borderRadius: AppRadii.pillRadius,
                ),
                child: Text(
                  state.focusStatusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: active ? Colors.white : AppColors.cyanDeep,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(
              formatHms(state.focusRemaining),
              style: TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
                color: active ? Colors.white : AppColors.onSurface,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _QuickAddPill(minutes: 15, active: active, onTap: () => state.addFocusMinutes(15)),
              const SizedBox(width: 8),
              _QuickAddPill(minutes: 30, active: active, onTap: () => state.addFocusMinutes(30)),
              const SizedBox(width: 8),
              _QuickAddPill(minutes: 60, active: active, onTap: () => state.addFocusMinutes(60)),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: Material(
              color: active ? Colors.white : AppColors.electricCyan,
              borderRadius: AppRadii.pillRadius,
              child: InkWell(
                borderRadius: AppRadii.pillRadius,
                onTap: state.toggleFocus,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Center(
                    child: Text(
                      active ? 'Stop Focus' : 'Start Focus',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: active ? AppColors.cyanDeep : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms, delay: 80.ms).slideY(begin: 0.06, end: 0);
  }
}

class _QuickAddPill extends StatelessWidget {
  const _QuickAddPill({required this.minutes, required this.active, required this.onTap});

  final int minutes;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pill(
      label: '+$minutes Min',
      onTap: onTap,
      color: active ? Colors.white.withValues(alpha: 0.15) : AppColors.cyanSoft,
      textColor: active ? Colors.white : AppColors.cyanDeep,
    );
  }
}

class _GoalsShortcutCard extends StatelessWidget {
  const _GoalsShortcutCard({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final topGoals = state.goals.take(4).toList();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: "Today's Commitments",
            action: Text(
              '${state.completedGoalsTodayCount}/${state.goals.length}',
              style: const TextStyle(color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
          if (topGoals.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('No commitments yet.', style: TextStyle(color: AppColors.onSurfaceVariant)),
            )
          else
            ...topGoals.map((g) => _GoalRow(goal: g)),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms, delay: 140.ms).slideY(begin: 0.06, end: 0);
  }
}

class _GoalRow extends StatelessWidget {
  const _GoalRow({required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final done = goal.isDoneOn(todayKey());
    return InkWell(
      onTap: () => state.toggleGoal(goal.id),
      borderRadius: AppRadii.mdRadius,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? AppColors.electricCyan : Colors.transparent,
                border: Border.all(
                  color: done ? AppColors.electricCyan : AppColors.outline,
                  width: 2,
                ),
              ),
              child: done ? const Icon(Symbols.check_rounded, size: 16, color: Colors.white) : null,
            ),
            const SizedBox(width: 12),
            Icon(iconForKey(goal.iconKey), size: 18, color: AppColors.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                goal.title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  decoration: done ? TextDecoration.lineThrough : null,
                  color: done ? AppColors.onSurfaceVariant : AppColors.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  const _WorkoutCard({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final weekday = DateTime.now().weekday;
    final day = state.dayFor(weekday);
    return AppCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const WorkoutScreen()),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppColors.amberGradient,
              borderRadius: AppRadii.lgRadius,
            ),
            alignment: Alignment.center,
            child: const Icon(Symbols.fitness_center_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Today's Workout", style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 2),
                Text(
                  day.title,
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!day.isRestDay)
                  Text(
                    '${day.exercises.length} exercises',
                    style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
                  ),
              ],
            ),
          ),
          const Icon(Symbols.chevron_right_rounded, color: AppColors.onSurfaceVariant),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms, delay: 200.ms).slideY(begin: 0.06, end: 0);
  }
}
