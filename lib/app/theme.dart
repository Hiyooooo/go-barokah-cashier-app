import 'package:flutter/material.dart';

abstract final class AppColors {
  static const canvas = Color(0xFFF7F8F6);
  static const surface = Color(0xFFFFFFFF);

  static const forestGreen = Color(0xFF2B5D42);
  static const forestGreenPressed = Color(0xFF214A33);
  static const warmBrown = Color(0xFF8A653B);
  static const sageGreen = Color(0xFF9EB394);
  static const cream = Color(0xFFEEE9D3);

  static const textStrong = Color(0xFF1A1A1A);
  static const textHeading = Color(0xFF222222);
  static const textBody = Color(0xFF4A4A4A);
  static const textMuted = Color(0xFF6B6B6B);

  static const border = Color(0xFFE5E5E5);
  static const borderSubtle = Color(0xFFECECEC);

  static const warning = Color(0xFFE8B84B);
  static const warningContainer = Color(0xFFFFF7E0);
  static const error = Color(0xFFD9534F);
  static const errorContainer = Color(0xFFFBEAE9);
  static const successContainer = Color(0xFFEAF2EC);
}

abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;
  static const huge = 40.0;
  static const section = 48.0;
}

abstract final class AppRadius {
  static const input = 8.0;
  static const badge = 8.0;
  static const card = 12.0;
  static const panel = 16.0;
  static const button = 24.0;
}

final ThemeData appTheme = _buildAppTheme();

ThemeData _buildAppTheme() {
  final colorScheme = ColorScheme.light(
    primary: AppColors.forestGreen,
    onPrimary: AppColors.surface,
    primaryContainer: AppColors.sageGreen,
    onPrimaryContainer: const Color(0xFF173524),
    secondary: AppColors.warmBrown,
    onSecondary: AppColors.surface,
    secondaryContainer: AppColors.cream,
    onSecondaryContainer: const Color(0xFF49321B),
    tertiary: AppColors.sageGreen,
    onTertiary: const Color(0xFF173524),
    tertiaryContainer: AppColors.successContainer,
    onTertiaryContainer: const Color(0xFF173524),
    error: AppColors.error,
    onError: AppColors.surface,
    errorContainer: AppColors.errorContainer,
    onErrorContainer: const Color(0xFF5F1715),
    surface: AppColors.surface,
    onSurface: AppColors.textStrong,
    onSurfaceVariant: AppColors.textBody,
    outline: AppColors.border,
    outlineVariant: AppColors.borderSubtle,
  );

  final textTheme = TextTheme(
    displayLarge: _text(
      32,
      FontWeight.w700,
      AppColors.textStrong,
      letterSpacing: -0.64,
    ),
    headlineLarge: _text(
      28,
      FontWeight.w700,
      AppColors.textStrong,
      letterSpacing: -0.56,
    ),
    headlineMedium: _text(24, FontWeight.w700, AppColors.textStrong),
    titleLarge: _text(18, FontWeight.w600, AppColors.textHeading),
    titleMedium: _text(16, FontWeight.w600, AppColors.textHeading),
    bodyLarge: _text(16, FontWeight.w400, AppColors.textBody, height: 1.5),
    bodyMedium: _text(14, FontWeight.w400, AppColors.textBody, height: 1.45),
    bodySmall: _text(12, FontWeight.w400, AppColors.textMuted, height: 1.4),
    labelLarge: _text(14, FontWeight.w600, AppColors.textStrong),
    labelMedium: _text(12, FontWeight.w600, AppColors.textBody),
    labelSmall: _text(11, FontWeight.w600, AppColors.textMuted),
  );

  final fieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.input),
    borderSide: const BorderSide(color: AppColors.border),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.canvas,
    textTheme: textTheme,
    visualDensity: VisualDensity.standard,
    dividerTheme: const DividerThemeData(
      color: AppColors.borderSubtle,
      thickness: 1,
      space: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      labelStyle: textTheme.bodyMedium,
      hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
      errorStyle: textTheme.bodySmall?.copyWith(color: AppColors.error),
      border: fieldBorder,
      enabledBorder: fieldBorder,
      focusedBorder: fieldBorder.copyWith(
        borderSide: const BorderSide(color: AppColors.forestGreen, width: 2),
      ),
      errorBorder: fieldBorder.copyWith(
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: fieldBorder.copyWith(
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size.fromHeight(48)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
        textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.borderSubtle;
          }
          if (states.contains(WidgetState.pressed)) {
            return AppColors.forestGreenPressed;
          }
          return AppColors.forestGreen;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.textMuted;
          }
          return AppColors.surface;
        }),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size.fromHeight(48)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
        side: const WidgetStatePropertyAll(BorderSide(color: AppColors.border)),
        textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
        foregroundColor: const WidgetStatePropertyAll(AppColors.forestGreen),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size.fromHeight(44)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: AppSpacing.md),
        ),
        textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
        foregroundColor: const WidgetStatePropertyAll(AppColors.forestGreen),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.canvas,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge,
      iconTheme: const IconThemeData(color: AppColors.textHeading),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 72,
      indicatorColor: AppColors.cream,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final color = states.contains(WidgetState.selected)
            ? AppColors.forestGreen
            : AppColors.textMuted;
        return textTheme.labelMedium?.copyWith(color: color);
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final color = states.contains(WidgetState.selected)
            ? AppColors.forestGreen
            : AppColors.textMuted;
        return IconThemeData(color: color);
      }),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.cream,
      selectedIconTheme: const IconThemeData(color: AppColors.forestGreen),
      unselectedIconTheme: const IconThemeData(color: AppColors.textMuted),
      selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
        color: AppColors.forestGreen,
      ),
      unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
        color: AppColors.textMuted,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.textStrong,
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: AppColors.surface,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.forestGreen,
      linearTrackColor: AppColors.borderSubtle,
    ),
  );
}

TextStyle _text(
  double size,
  FontWeight weight,
  Color color, {
  double? height,
  double? letterSpacing,
}) => TextStyle(
  fontSize: size,
  fontWeight: weight,
  color: color,
  height: height,
  letterSpacing: letterSpacing,
);
