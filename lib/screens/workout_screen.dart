import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/date_utils.dart';
import '../widgets/common.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  late int _selectedWeekday = DateTime.now().weekday;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final day = state.dayFor(_selectedWeekday);
    final isToday = _selectedWeekday == DateTime.now().weekday;
    final ratio = state.dayCompletionRatio(day);
    final finished = state.isWorkoutFinished(day);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Training Plan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 120),
        children: [
          _WeekRail(
            selected: _selectedWeekday,
            onSelect: (w) => setState(() => _selectedWeekday = w),
            routine: state.routine,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(day.title, style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text(
                      day.isRestDay
                          ? 'Rest day — recover up'
                          : '${day.exercises.length} exercises${isToday ? '' : ' • ${weekdayFull[day.weekday - 1]}'}',
                      style: const TextStyle(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (finished)
                const Pill(
                  label: 'Finished',
                  color: AppColors.cyanSoft,
                  textColor: AppColors.cyanDeep,
                  icon: Symbols.check_circle_rounded,
                ),
            ],
          ),
          if (!day.isRestDay) ...[
            const SizedBox(height: AppSpacing.md),
            AppCard(
              color: AppColors.amberSoft,
              borderColor: Colors.transparent,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Today's Progress",
                          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.amberDeep),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(ratio * day.exercises.length).round()} / ${day.exercises.length} exercises logged',
                          style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: ProgressRing(
                      progress: ratio,
                      size: 44,
                      strokeWidth: 5,
                      color: AppColors.amber,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ...day.exercises.map((ex) => _ExerciseCard(exercise: ex)),
            const SizedBox(height: AppSpacing.md),
            GradientButton(
              label: finished ? 'Workout Finished' : 'Finish Workout',
              gradient: AppColors.amberGradient,
              onTap: (ratio == 1 && !finished)
                  ? () async {
                      await state.finishWorkout(day);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Workout saved. Great work!')),
                        );
                      }
                    }
                  : null,
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Symbols.bedtime_rounded, size: 48, color: AppColors.onSurfaceVariant),
                    const SizedBox(height: 12),
                    Text('Nothing scheduled — enjoy the rest.',
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WeekRail extends StatelessWidget {
  const _WeekRail({required this.selected, required this.onSelect, required this.routine});

  final int selected;
  final ValueChanged<int> onSelect;
  final List<WorkoutDay> routine;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().weekday;
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final weekday = i + 1;
          final day = routine.firstWhere((d) => d.weekday == weekday);
          final isSelected = weekday == selected;
          final isToday = weekday == today;
          final rest = day.isRestDay;
          return GestureDetector(
            onTap: () => onSelect(weekday),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.onSurface : AppColors.surface,
                borderRadius: AppRadii.lgRadius,
                border: Border.all(
                  color: isToday && !isSelected ? AppColors.electricCyan : AppColors.outline,
                  width: isToday && !isSelected ? 1.6 : 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    weekdayShort[i],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? Colors.white
                          : (rest ? AppColors.onSurfaceVariant.withValues(alpha: 0.5) : AppColors.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Icon(
                    rest ? Symbols.bedtime_rounded : Symbols.fitness_center_rounded,
                    size: 16,
                    color: isSelected
                        ? Colors.white
                        : (rest ? AppColors.onSurfaceVariant.withValues(alpha: 0.4) : AppColors.amber),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ExerciseCard extends StatefulWidget {
  const _ExerciseCard({required this.exercise});

  final RoutineExercise exercise;

  @override
  State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final ex = widget.exercise;
    final complete = state.isExerciseComplete(ex);
    final hasPrev = ex.lastWeight != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        borderColor: complete ? AppColors.amber : AppColors.outline,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: complete ? AppColors.amber : AppColors.outline,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ex.name, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Text(
                              '${ex.targetSets} sets × ${ex.targetReps} reps',
                              style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
                            ),
                            if (hasPrev) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.amberSoft,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'PREV ${ex.lastWeight!.toStringAsFixed(0)}kg × ${ex.lastReps}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.amberDeep,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded ? Symbols.expand_less_rounded : Symbols.expand_more_rounded,
                    color: AppColors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
            if (_expanded) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              ...List.generate(ex.targetSets, (i) => _SetRow(exercise: ex, setIndex: i)),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 250.ms);
  }
}

class _SetRow extends StatelessWidget {
  const _SetRow({required this.exercise, required this.setIndex});

  final RoutineExercise exercise;
  final int setIndex;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final log = state.logsFor(exercise)[setIndex];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text('${setIndex + 1}', style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _NumberField(
              label: 'kg',
              value: log.weight,
              onChanged: (v) => state.updateSetLog(exercise, setIndex, weight: v),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _NumberField(
              label: 'reps',
              value: log.reps.toDouble(),
              isInt: true,
              onChanged: (v) => state.updateSetLog(exercise, setIndex, reps: v.round()),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => state.toggleSetDone(exercise, setIndex),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: log.done ? AppColors.amber : Colors.transparent,
                border: Border.all(color: log.done ? AppColors.amber : AppColors.outline, width: 2),
              ),
              child: log.done ? const Icon(Symbols.check_rounded, size: 18, color: Colors.white) : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.isInt = false,
  });

  final String label;
  final double value;
  final bool isInt;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = isInt ? value.round().toString() : (value == value.roundToDouble() ? value.round().toString() : value.toString());
    return TextFormField(
      key: ValueKey('$label-${value.toStringAsFixed(1)}'),
      initialValue: text,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.center,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      decoration: InputDecoration(
        isDense: true,
        suffixText: label,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        border: OutlineInputBorder(borderRadius: AppRadii.mdRadius, borderSide: const BorderSide(color: AppColors.outline)),
        enabledBorder: OutlineInputBorder(borderRadius: AppRadii.mdRadius, borderSide: const BorderSide(color: AppColors.outline)),
      ),
      onChanged: (v) {
        final parsed = double.tryParse(v);
        if (parsed != null) onChanged(parsed);
      },
    );
  }
}
