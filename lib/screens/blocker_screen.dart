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

/// Standalone App Blocker screen — urgency-orange styled focus enforcement.
class BlockerScreen extends StatefulWidget {
  const BlockerScreen({super.key});

  @override
  State<BlockerScreen> createState() => _BlockerScreenState();
}

class _BlockerScreenState extends State<BlockerScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final apps = state.blockedApps
        .where((a) => a.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    final reclaimed = state.reclaimedMinutesToday;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('App Blocker')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.actionOrange,
        onPressed: () => _showAddAppSheet(context, state),
        child: const Icon(Symbols.add_rounded, color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 100),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.orangeGradient,
              borderRadius: AppRadii.xlRadius,
              boxShadow: AppShadows.glow(AppColors.actionOrange),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Symbols.shield_lock_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 6),
                    Text(
                      'Reclaimed Focus Time',
                      style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  formatMinutesLabel(reclaimed),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${apps.where((a) => a.blocked).length} apps blocked today',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.06, end: 0),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Search apps',
              prefixIcon: const Icon(Symbols.search_rounded),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: AppRadii.pillRadius,
                borderSide: const BorderSide(color: AppColors.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadii.pillRadius,
                borderSide: const BorderSide(color: AppColors.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadii.pillRadius,
                borderSide: const BorderSide(color: AppColors.actionOrange),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...apps.map((a) => _AppTile(app: a)),
          if (apps.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(
                child: Text('No apps found', style: TextStyle(color: AppColors.onSurfaceVariant)),
              ),
            ),
        ],
      ),
    );
  }

  void _showAddAppSheet(BuildContext context, AppState state) {
    final controller = TextEditingController();
    String icon = appIconKeys.first;
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
                Text('Block a New App', style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(labelText: 'App name'),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: appIconKeys.map((k) {
                    final selected = k == icon;
                    return GestureDetector(
                      onTap: () => setSheetState(() => icon = k),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: selected ? AppColors.actionOrangeSoft : AppColors.background,
                          borderRadius: AppRadii.mdRadius,
                          border: Border.all(
                            color: selected ? AppColors.actionOrange : AppColors.outline,
                          ),
                        ),
                        child: Icon(
                          iconForKey(k),
                          color: selected ? AppColors.actionOrange : AppColors.onSurfaceVariant,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                GradientButton(
                  label: 'Add & Block',
                  gradient: AppColors.orangeGradient,
                  onTap: () {
                    if (controller.text.trim().isEmpty) return;
                    state.addBlockedApp(controller.text.trim(), icon);
                    Navigator.of(ctx).pop();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppTile extends StatelessWidget {
  const _AppTile({required this.app});

  final BlockedApp app;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: () => state.toggleAppBlocked(app.id),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: app.blocked ? AppColors.actionOrangeSoft : AppColors.background,
                borderRadius: AppRadii.mdRadius,
              ),
              alignment: Alignment.center,
              child: Icon(
                iconForKey(app.iconKey),
                color: app.blocked ? AppColors.actionOrange : AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(app.name, style: Theme.of(context).textTheme.titleMedium),
                  if (app.minutesSavedToday > 0)
                    Text(
                      '${formatMinutesLabel(app.minutesSavedToday)} saved today',
                      style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
                    ),
                ],
              ),
            ),
            Switch(
              value: app.blocked,
              activeThumbColor: AppColors.actionOrange,
              onChanged: (_) => state.toggleAppBlocked(app.id),
            ),
          ],
        ),
      ),
    );
  }
}
