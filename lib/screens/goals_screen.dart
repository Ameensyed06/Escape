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
import 'blocker_screen.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Commitments')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 120),
        children: [
          Center(
            child: ProgressRing(
              progress: state.goalsProgress,
              size: 132,
              strokeWidth: 12,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${state.completedGoalsTodayCount}',
                    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    'of ${state.goals.length} done',
                    style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.9, 0.9)),
          const SizedBox(height: AppSpacing.lg),
          if (state.goals.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('No commitments yet — add your first one below.',
                    style: TextStyle(color: AppColors.onSurfaceVariant)),
              ),
            )
          else
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              onReorder: state.reorderGoals,
              children: [
                for (int i = 0; i < state.goals.length; i++)
                  _GoalCard(key: ValueKey(state.goals[i].id), goal: state.goals[i], index: i),
              ],
            ),
          const SizedBox(height: AppSpacing.md),
          OutlineButton(
            label: 'Add New Goal',
            icon: Symbols.add_rounded,
            onTap: () => showGoalEditor(context, state),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            color: AppColors.actionOrangeSoft,
            borderColor: Colors.transparent,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BlockerScreen()),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppColors.orangeGradient,
                    borderRadius: AppRadii.mdRadius,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Symbols.shield_lock_rounded, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'App Blocker',
                        style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.actionOrange),
                      ),
                      Text(
                        '${formatMinutesLabel(state.reclaimedMinutesToday)} reclaimed today',
                        style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Symbols.chevron_right_rounded, color: AppColors.actionOrange),
              ],
            ),
          ),
        ],
      ),
    );
  }

}

/// Shared bottom-sheet editor for creating or editing a [Goal].
void showGoalEditor(BuildContext context, AppState state, {Goal? existing}) {
  final titleCtrl = TextEditingController(text: existing?.title ?? '');
  final targetCtrl = TextEditingController(text: existing?.target ?? '');
  String icon = existing?.iconKey ?? goalIconKeys.first;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheetState) => Padding(
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
              Text(
                existing == null ? 'Add New Goal' : 'Edit Goal',
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: targetCtrl,
                decoration: const InputDecoration(labelText: 'Target (e.g. "20 pages")'),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: goalIconKeys.map((k) {
                  final selected = k == icon;
                  return GestureDetector(
                    onTap: () => setSheetState(() => icon = k),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: selected ? AppColors.cyanSoft : AppColors.background,
                        borderRadius: AppRadii.mdRadius,
                        border: Border.all(
                          color: selected ? AppColors.electricCyan : AppColors.outline,
                        ),
                      ),
                      child: Icon(
                        iconForKey(k),
                        color: selected ? AppColors.electricCyan : AppColors.onSurfaceVariant,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  if (existing != null) ...[
                    Expanded(
                      child: OutlineButton(
                        label: 'Delete',
                        icon: Symbols.delete_rounded,
                        onTap: () {
                          state.deleteGoal(existing.id);
                          Navigator.of(ctx).pop();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: GradientButton(
                      label: existing == null ? 'Add Goal' : 'Save',
                      onTap: () {
                        if (titleCtrl.text.trim().isEmpty) return;
                        if (existing == null) {
                          state.addGoal(
                            title: titleCtrl.text.trim(),
                            target: targetCtrl.text.trim(),
                            iconKey: icon,
                          );
                        } else {
                          state.updateGoal(
                            existing.id,
                            title: titleCtrl.text.trim(),
                            target: targetCtrl.text.trim(),
                            iconKey: icon,
                          );
                        }
                        Navigator.of(ctx).pop();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({super.key, required this.goal, required this.index});

  final Goal goal;
  final int index;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final done = goal.isDoneOn(todayKey());

    return Padding(
      key: ValueKey('pad-${goal.id}'),
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: () => showGoalEditor(context, state, existing: goal),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => state.toggleGoal(goal.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? AppColors.electricCyan : Colors.transparent,
                  border: Border.all(
                    color: done ? AppColors.electricCyan : AppColors.outline,
                    width: 2,
                  ),
                ),
                child: done ? const Icon(Symbols.check_rounded, size: 18, color: Colors.white) : null,
              ),
            ),
            const SizedBox(width: 14),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: AppColors.cyanSoft, borderRadius: AppRadii.mdRadius),
              alignment: Alignment.center,
              child: Icon(iconForKey(goal.iconKey), size: 18, color: AppColors.cyanDeep),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      decoration: done ? TextDecoration.lineThrough : null,
                      color: done ? AppColors.onSurfaceVariant : AppColors.onSurface,
                    ),
                  ),
                  if (goal.target.isNotEmpty)
                    Text(
                      goal.target,
                      style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
                    ),
                ],
              ),
            ),
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Symbols.drag_handle_rounded, color: AppColors.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 250.ms, delay: (30 * index).ms);
  }
}
