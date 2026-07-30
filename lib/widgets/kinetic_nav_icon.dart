import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Bottom nav item: an icon that scales/springs into a colored circular
/// highlight when active, with a small label beneath.
class KineticNavIcon extends StatelessWidget {
  const KineticNavIcon({
    super.key,
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.color = AppColors.electricCyan,
    this.softColor = AppColors.cyanSoft,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final Color color;
  final Color softColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutBack,
                tween: Tween(begin: 0, end: active ? 1 : 0),
                builder: (context, t, child) {
                  return Container(
                    width: 44,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Color.lerp(Colors.transparent, softColor, t),
                      borderRadius: AppRadii.pillRadius,
                    ),
                    alignment: Alignment.center,
                    child: Transform.scale(
                      scale: 1 + (0.15 * t),
                      child: Icon(
                        icon,
                        size: 24,
                        color: Color.lerp(AppColors.onSurfaceVariant, color, t),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  color: active ? color : AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
