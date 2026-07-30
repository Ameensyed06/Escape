import 'package:flutter/material.dart';

/// ESCAPE design tokens — colors, spacing, radii, and the app [ThemeData].
class AppColors {
  AppColors._();

  // Canvas
  static const background = Color(0xFFEEF1F6);
  static const surface = Color(0xFFFFFFFF);

  // Content
  static const onSurface = Color(0xFF12161C);
  static const onSurfaceVariant = Color(0xFF5B6472);
  static const outline = Color(0xFFDDE2E9);

  // Primary accent — cyan
  static const electricCyan = Color(0xFF0AA8B8);
  static const cyanDeep = Color(0xFF066670);
  static const cyanSoft = Color(0xFFE3F7F9);

  // Secondary accent — amber
  static const amber = Color(0xFFDB8A0F);
  static const amberDeep = Color(0xFFB86E0A);
  static const amberSoft = Color(0xFFFBEDD3);

  // Urgency — orange
  static const actionOrange = Color(0xFFE8590C);
  static const actionOrangeSoft = Color(0xFFFCE7DA);

  static const cyanGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [electricCyan, cyanDeep],
  );

  static const amberGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [amber, amberDeep],
  );

  static const orangeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [actionOrange, Color(0xFFB8410A)],
  );
}

class AppSpacing {
  AppSpacing._();

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

class AppRadii {
  AppRadii._();

  static const pill = 999.0;
  static const xl = 24.0;
  static const lg = 16.0;
  static const md = 12.0;

  static const pillRadius = BorderRadius.all(Radius.circular(pill));
  static const xlRadius = BorderRadius.all(Radius.circular(xl));
  static const lgRadius = BorderRadius.all(Radius.circular(lg));
  static const mdRadius = BorderRadius.all(Radius.circular(md));
}

class AppShadows {
  AppShadows._();

  static List<BoxShadow> soft = [
    BoxShadow(
      color: AppColors.onSurface.withValues(alpha: 0.06),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> glow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.28),
      blurRadius: 28,
      offset: const Offset(0, 10),
    ),
  ];
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Roboto',
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.electricCyan,
        brightness: Brightness.light,
        primary: AppColors.electricCyan,
        secondary: AppColors.amber,
        surface: AppColors.surface,
        error: AppColors.actionOrange,
      ),
      scaffoldBackgroundColor: AppColors.background,
    );

    return base.copyWith(
      textTheme: base.textTheme
          .apply(
            bodyColor: AppColors.onSurface,
            displayColor: AppColors.onSurface,
          )
          .copyWith(
            headlineMedium: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
              letterSpacing: -0.4,
            ),
            headlineSmall: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
              letterSpacing: -0.3,
            ),
            titleLarge: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
            titleMedium: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
            bodyLarge: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurface,
            ),
            bodyMedium: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurfaceVariant,
            ),
            labelLarge: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.xlRadius,
          side: const BorderSide(color: AppColors.outline),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.outline,
        thickness: 1,
        space: 1,
      ),
      splashFactory: InkRipple.splashFactory,
    );
  }
}
