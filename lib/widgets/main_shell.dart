import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../screens/dashboard_screen.dart';
import '../screens/goals_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/social_screen.dart';
import '../screens/workout_screen.dart';
import '../theme/app_theme.dart';
import 'kinetic_nav_icon.dart';

/// Root scaffold hosting the 5-tab bottom navigation via an [IndexedStack].
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _screens = [
    DashboardScreen(),
    GoalsScreen(),
    WorkoutScreen(),
    SocialScreen(),
    ProfileScreen(),
  ];

  void _go(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _index,
          sizing: StackFit.expand,
          children: _screens,
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.outline)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            children: [
              KineticNavIcon(
                icon: Symbols.home_rounded,
                label: 'Home',
                active: _index == 0,
                onTap: () => _go(0),
              ),
              KineticNavIcon(
                icon: Symbols.target_rounded,
                label: 'Goals',
                active: _index == 1,
                onTap: () => _go(1),
              ),
              KineticNavIcon(
                icon: Symbols.fitness_center_rounded,
                label: 'Train',
                active: _index == 2,
                onTap: () => _go(2),
                color: AppColors.amber,
                softColor: AppColors.amberSoft,
              ),
              KineticNavIcon(
                icon: Symbols.groups_rounded,
                label: 'Social',
                active: _index == 3,
                onTap: () => _go(3),
              ),
              KineticNavIcon(
                icon: Symbols.person_rounded,
                label: 'Profile',
                active: _index == 4,
                onTap: () => _go(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
