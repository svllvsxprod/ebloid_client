import 'package:flutter/material.dart';

@immutable
final class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.bg,
    required this.surface,
    required this.fg,
    required this.muted,
    required this.divider,
    required this.controlBorder,
    required this.accent,
  });

  static const light = AppColors(
    bg: Color(0xFFFBFCFD),
    surface: Color(0xFFFFFFFF),
    fg: Color(0xFF0E1217),
    muted: Color(0xFF595E64),
    divider: Color(0xFFD7DBDF),
    controlBorder: Color(0xFF8F9396),
    accent: Color(0xFF1175DE),
  );

  final Color bg;
  final Color surface;
  final Color fg;
  final Color muted;
  final Color divider;
  final Color controlBorder;
  final Color accent;

  Color get soft => Color.alphaBlend(fg.withValues(alpha: .05), surface);

  @override
  AppColors copyWith({
    Color? bg,
    Color? surface,
    Color? fg,
    Color? muted,
    Color? divider,
    Color? controlBorder,
    Color? accent,
  }) => AppColors(
    bg: bg ?? this.bg,
    surface: surface ?? this.surface,
    fg: fg ?? this.fg,
    muted: muted ?? this.muted,
    divider: divider ?? this.divider,
    controlBorder: controlBorder ?? this.controlBorder,
    accent: accent ?? this.accent,
  );

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      fg: Color.lerp(fg, other.fg, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      controlBorder: Color.lerp(controlBorder, other.controlBorder, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
    );
  }
}

abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double target = 48;
}

abstract final class AppRadius {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const BorderRadius media = BorderRadius.all(Radius.circular(md));
  static const BorderRadius control = BorderRadius.all(Radius.circular(999));
}

abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration normal = Duration(milliseconds: 180);
  static const Duration slow = Duration(milliseconds: 260);

  static Duration resolve(BuildContext context, Duration duration) {
    final mq = MediaQuery.maybeOf(context);
    final disabled = mq?.disableAnimations == true;
    return disabled ? Duration.zero : duration;
  }
}

extension AppThemeX on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
}

extension AppTextStyleX on TextStyle {
  TextStyle get tabularFigures =>
      merge(const TextStyle(fontFeatures: [FontFeature.tabularFigures()]));
}

abstract final class AppTheme {
  static ThemeData get light => _buildLight();

  @visibleForTesting
  static ThemeData lightWithFontFamily(String fontFamily) {
    return _buildLight(fontFamily: fontFamily);
  }

  static ThemeData _buildLight({String? fontFamily}) {
    const colors = AppColors.light;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: colors.accent,
          brightness: Brightness.light,
          primary: colors.accent,
          surface: colors.surface,
          onSurface: colors.fg,
          outline: colors.controlBorder,
          outlineVariant: colors.divider,
        ).copyWith(
          primary: colors.accent,
          onPrimary: colors.surface,
          surface: colors.surface,
          onSurface: colors.fg,
          surfaceContainerLowest: colors.bg,
          surfaceContainerLow: colors.surface,
          surfaceContainer: colors.surface,
          outline: colors.controlBorder,
          outlineVariant: colors.divider,
        );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: colors.bg,
      extensions: const [colors],
    );
    final text = base.textTheme.apply(
      bodyColor: colors.fg,
      displayColor: colors.fg,
    );

    return base.copyWith(
      textTheme: text,
      dividerColor: colors.divider,
      splashFactory: NoSplash.splashFactory,
      focusColor: colors.accent.withValues(alpha: .16),
      highlightColor: colors.accent.withValues(alpha: .08),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.bg,
        foregroundColor: colors.fg,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: text.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: colors.fg,
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: colors.surface,
        selectedColor: colors.accent,
        disabledColor: colors.bg,
        labelStyle: text.labelLarge?.copyWith(color: colors.fg),
        secondaryLabelStyle: text.labelLarge?.copyWith(color: colors.surface),
        side: BorderSide(color: colors.divider),
        shape: const StadiumBorder(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(AppSpacing.target, AppSpacing.target),
          backgroundColor: colors.accent,
          foregroundColor: colors.surface,
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(AppSpacing.target, AppSpacing.target),
          foregroundColor: colors.fg,
          focusColor: colors.accent.withValues(alpha: .18),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: colors.controlBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: colors.controlBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: colors.accent, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colors.accent.withValues(alpha: .12),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelMedium?.copyWith(
            color: states.contains(WidgetState.selected)
                ? colors.accent
                : colors.muted,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? colors.accent
                : colors.muted,
          ),
        ),
      ),
    );
  }
}
