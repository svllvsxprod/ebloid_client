import 'package:flutter/material.dart';

@immutable
final class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.bg,
    required this.surface,
    required this.surfaceElevated,
    required this.fg,
    required this.muted,
    required this.divider,
    required this.controlBorder,
    required this.accent,
    required this.onAccent,
    required this.danger,
    required this.warning,
    required this.success,
    required this.info,
    required this.mediaBackdrop,
    required this.overlayScrim,
  });

  static const dark = AppColors(
    bg: Color(0xFF171A18),
    surface: Color(0xFF202521),
    surfaceElevated: Color(0xFF292F2A),
    fg: Color(0xFFF1F4EC),
    muted: Color(0xFFAAB2A4),
    divider: Color(0xFF3B433C),
    controlBorder: Color(0xFF717B70),
    accent: Color(0xFFA7C957),
    onAccent: Color(0xFF172008),
    danger: Color(0xFFF0A092),
    warning: Color(0xFFE2BB68),
    success: Color(0xFFA7C957),
    info: Color(0xFF78B8F0),
    mediaBackdrop: Color(0xFF101311),
    overlayScrim: Color(0xE6191D1A),
  );

  final Color bg;
  final Color surface;
  final Color surfaceElevated;
  final Color fg;
  final Color muted;
  final Color divider;
  final Color controlBorder;
  final Color accent;
  final Color onAccent;
  final Color danger;
  final Color warning;
  final Color success;
  final Color info;
  final Color mediaBackdrop;
  final Color overlayScrim;

  Color get soft =>
      Color.alphaBlend(accent.withValues(alpha: .08), surfaceElevated);

  @override
  AppColors copyWith({
    Color? bg,
    Color? surface,
    Color? surfaceElevated,
    Color? fg,
    Color? muted,
    Color? divider,
    Color? controlBorder,
    Color? accent,
    Color? onAccent,
    Color? danger,
    Color? warning,
    Color? success,
    Color? info,
    Color? mediaBackdrop,
    Color? overlayScrim,
  }) => AppColors(
    bg: bg ?? this.bg,
    surface: surface ?? this.surface,
    surfaceElevated: surfaceElevated ?? this.surfaceElevated,
    fg: fg ?? this.fg,
    muted: muted ?? this.muted,
    divider: divider ?? this.divider,
    controlBorder: controlBorder ?? this.controlBorder,
    accent: accent ?? this.accent,
    onAccent: onAccent ?? this.onAccent,
    danger: danger ?? this.danger,
    warning: warning ?? this.warning,
    success: success ?? this.success,
    info: info ?? this.info,
    mediaBackdrop: mediaBackdrop ?? this.mediaBackdrop,
    overlayScrim: overlayScrim ?? this.overlayScrim,
  );

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      fg: Color.lerp(fg, other.fg, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      controlBorder: Color.lerp(controlBorder, other.controlBorder, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      success: Color.lerp(success, other.success, t)!,
      info: Color.lerp(info, other.info, t)!,
      mediaBackdrop: Color.lerp(mediaBackdrop, other.mediaBackdrop, t)!,
      overlayScrim: Color.lerp(overlayScrim, other.overlayScrim, t)!,
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
  static ThemeData get dark => _buildDark();

  @visibleForTesting
  static ThemeData darkWithFontFamily(String fontFamily) {
    return _buildDark(fontFamily: fontFamily);
  }

  static ThemeData _buildDark({String? fontFamily}) {
    const colors = AppColors.dark;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: colors.accent,
          brightness: Brightness.dark,
          primary: colors.accent,
          surface: colors.surface,
          onSurface: colors.fg,
          outline: colors.controlBorder,
          outlineVariant: colors.divider,
        ).copyWith(
          primary: colors.accent,
          onPrimary: colors.onAccent,
          surface: colors.surface,
          onSurface: colors.fg,
          surfaceContainerLowest: colors.bg,
          surfaceContainerLow: colors.surface,
          surfaceContainer: colors.surfaceElevated,
          surfaceContainerHigh: colors.soft,
          outline: colors.controlBorder,
          outlineVariant: colors.divider,
          error: colors.danger,
          onError: colors.mediaBackdrop,
        );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
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
      focusColor: colors.accent.withValues(alpha: .24),
      highlightColor: colors.accent.withValues(alpha: .1),
      disabledColor: colors.muted.withValues(alpha: .45),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
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
        backgroundColor: colors.surfaceElevated,
        selectedColor: colors.soft,
        disabledColor: colors.bg,
        labelStyle: text.labelLarge?.copyWith(color: colors.fg),
        secondaryLabelStyle: text.labelLarge?.copyWith(color: colors.accent),
        side: BorderSide(color: colors.divider),
        shape: const StadiumBorder(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(AppSpacing.target, AppSpacing.target),
          backgroundColor: colors.accent,
          foregroundColor: colors.onAccent,
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(AppSpacing.target, AppSpacing.target),
          foregroundColor: colors.fg,
          side: BorderSide(color: colors.controlBorder),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(AppSpacing.target, AppSpacing.target),
          foregroundColor: colors.accent,
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
        fillColor: colors.surfaceElevated,
        hintStyle: text.bodyLarge?.copyWith(color: colors.muted),
        labelStyle: text.bodyLarge?.copyWith(color: colors.muted),
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
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(AppSpacing.target, AppSpacing.target),
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? colors.soft
                : colors.surfaceElevated,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? colors.accent
                : colors.muted,
          ),
          side: WidgetStateProperty.resolveWith(
            (states) => BorderSide(
              color: states.contains(WidgetState.selected)
                  ? colors.accent
                  : colors.divider,
            ),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.onAccent
              : colors.muted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.accent
              : colors.surfaceElevated,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.accent
              : colors.controlBorder,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.accent,
        foregroundColor: colors.onAccent,
        elevation: 2,
        focusElevation: 2,
        hoverElevation: 2,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.accent,
        linearTrackColor: colors.surfaceElevated,
        circularTrackColor: colors.surfaceElevated,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.surfaceElevated,
        contentTextStyle: text.bodyMedium?.copyWith(color: colors.fg),
        actionTextColor: colors.accent,
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: colors.divider),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colors.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          side: BorderSide(color: colors.divider),
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
