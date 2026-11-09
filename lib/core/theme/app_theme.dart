import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Deep teal "ink" with a brass accent on a cool stone canvas.
class AppColors {
  AppColors._();

  static const ink = Color(0xFF0E3F3D);
  static const inkDeep = Color(0xFF0A2E2D);
  static const inkSoft = Color(0xFFE2EFED);

  static const brass = Color(0xFFC49A45);
  static const brassSoft = Color(0xFFF6EDD6);
  static const brassText = Color(0xFF7A5A1B);

  static const canvas = Color(0xFFF3F4F1);
  static const surface = Colors.white;
  static const line = Color(0xFFE1E5DF);

  static const text = Color(0xFF16221F);
  static const muted = Color(0xFF5B6865);

  static const success = Color(0xFF1B8458);
  static const successSoft = Color(0xFFE2F2EA);
  static const warning = Color(0xFFB7791F);
  static const warningText = Color(0xFF8A5A0E);
  static const warningSoft = Color(0xFFF9EBD2);
  static const danger = Color(0xFFB83A2E);
  static const dangerSoft = Color(0xFFF8E3E0);
}

class AppTheme {
  AppTheme._();

  /// Tests switch this off so no font download is attempted.
  static bool useGoogleFonts = true;

  /// Keeps money columns aligned.
  static const List<FontFeature> tabular = [FontFeature.tabularFigures()];

  static const primary = AppColors.ink;
  static const background = AppColors.canvas;

  static ThemeData get light {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.ink,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.ink,
          onPrimary: Colors.white,
          primaryContainer: AppColors.inkSoft,
          onPrimaryContainer: AppColors.ink,
          secondary: AppColors.brass,
          surface: AppColors.surface,
          onSurface: AppColors.text,
          onSurfaceVariant: AppColors.muted,
          outline: AppColors.line,
          outlineVariant: AppColors.line,
          error: AppColors.danger,
        );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    final textTheme =
        (useGoogleFonts
                ? GoogleFonts.manropeTextTheme(base.textTheme)
                : base.textTheme)
            .apply(bodyColor: AppColors.text, displayColor: AppColors.text);

    final radius12 = BorderRadius.circular(12);

    OutlineInputBorder border(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: radius12,
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return base.copyWith(
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.canvas,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.canvas,
        foregroundColor: AppColors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.text,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.line),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.line,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: const TextStyle(color: AppColors.muted),
        hintStyle: const TextStyle(color: AppColors.muted),
        border: border(AppColors.line),
        enabledBorder: border(AppColors.line),
        focusedBorder: border(AppColors.ink, 1.6),
        errorBorder: border(AppColors.danger),
        focusedErrorBorder: border(AppColors.danger, 1.6),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.line,
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(borderRadius: radius12),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: AppColors.line),
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(borderRadius: radius12),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.ink,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
        elevation: 2,
        extendedTextStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.inkSoft,
        height: 68,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.ink : AppColors.muted,
            size: 24,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? AppColors.ink : AppColors.muted,
          );
        }),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.inkSoft,
        labelType: NavigationRailLabelType.all,
        selectedIconTheme: IconThemeData(color: AppColors.ink),
        unselectedIconTheme: IconThemeData(color: AppColors.muted),
        selectedLabelTextStyle: TextStyle(
          color: AppColors.ink,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: AppColors.muted,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.text,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.inkDeep,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: radius12),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: radius12,
          side: const BorderSide(color: AppColors.line),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: AppColors.inkSoft,
        side: const BorderSide(color: AppColors.line),
        showCheckmark: false,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.text,
        ),
        secondaryLabelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.ink,
      ),
    );
  }
}
