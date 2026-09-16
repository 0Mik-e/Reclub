import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  // Brand
  static const yellow = Color(0xFFFFC72C);
  static const yellowDeep = Color(0xFFF5A623);
  static const yellowSoft = Color(0xFFFFF1C9);
  static const green = Color(0xFF17C964);
  static const greenDark = Color(0xFF0E9F4C);
  static const greenSoft = Color(0xFFDCFCE9);

  // Neutrals
  static const ink = Color(0xFF12141A);
  static const ink70 = Color(0xFF3C424E);
  static const muted = Color(0xFF858B99);
  static const faint = Color(0xFFAAB0BC);
  static const hairline = Color(0xFFECEDF1);
  static const surface = Color(0xFFFFFFFF);
  static const canvas = Color(0xFFF5F6F8);
  static const chip = Color(0xFFF2F3F6);

  // Accents
  static const blue = Color(0xFF3B5BFD);
  static const blueSoft = Color(0xFFE9EDFF);
  static const lavender = Color(0xFFEFF1FC);
  static const violet = Color(0xFF7A5AF8);
  static const cream = Color(0xFFFDF6E3);
  static const red = Color(0xFFF04438);
  static const redSoft = Color(0xFFFEE4E2);
  static const orange = Color(0xFFFF8A3D);

  static const avatarTints = <Color>[
    Color(0xFF7A5AF8), Color(0xFF17C964), Color(0xFF3B5BFD), Color(0xFFF5A623),
    Color(0xFFEC4899), Color(0xFF06B6D4), Color(0xFFEF4444), Color(0xFF8B5CF6),
    Color(0xFF14B8A6), Color(0xFFF97316),
  ];

  static Color tintFor(String seed) {
    var h = 0;
    for (final c in seed.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return avatarTints[h % avatarTints.length];
  }

  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD556), Color(0xFFFFB020)],
  );
  static const greenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF23D97A), Color(0xFF0E9F4C)],
  );
  static const inkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1B1E27), Color(0xFF0B0D12)],
  );
}

class Shadows {
  static const card = [
    BoxShadow(color: Color(0x0D101828), blurRadius: 16, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x08101828), blurRadius: 2, offset: Offset(0, 1)),
  ];
  static const raised = [
    BoxShadow(color: Color(0x1A101828), blurRadius: 28, offset: Offset(0, 10)),
  ];
  static const soft = [
    BoxShadow(color: Color(0x0A101828), blurRadius: 10, offset: Offset(0, 2)),
  ];
}

class R {
  static const sm = BorderRadius.all(Radius.circular(10));
  static const md = BorderRadius.all(Radius.circular(14));
  static const lg = BorderRadius.all(Radius.circular(20));
  static const xl = BorderRadius.all(Radius.circular(26));
  static const pill = BorderRadius.all(Radius.circular(999));
}

/// Type scale. Kept short so page code stays readable.
class T {
  static const display = TextStyle(fontSize: 30, height: 1.15, fontWeight: FontWeight.w800, color: AppColors.ink, letterSpacing: -0.6);
  static const h1 = TextStyle(fontSize: 24, height: 1.2, fontWeight: FontWeight.w800, color: AppColors.ink, letterSpacing: -0.4);
  static const h2 = TextStyle(fontSize: 19, height: 1.25, fontWeight: FontWeight.w800, color: AppColors.ink, letterSpacing: -0.3);
  static const title = TextStyle(fontSize: 15.5, height: 1.3, fontWeight: FontWeight.w700, color: AppColors.ink, letterSpacing: -0.1);
  static const body = TextStyle(fontSize: 14, height: 1.45, fontWeight: FontWeight.w500, color: AppColors.ink70);
  static const bodyStrong = TextStyle(fontSize: 14, height: 1.4, fontWeight: FontWeight.w700, color: AppColors.ink);
  static const label = TextStyle(fontSize: 12.5, height: 1.3, fontWeight: FontWeight.w600, color: AppColors.muted);
  static const small = TextStyle(fontSize: 11.5, height: 1.25, fontWeight: FontWeight.w600, color: AppColors.muted);
  static const caps = TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.muted, letterSpacing: 0.9);
  static const num = TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink, fontFeatures: [FontFeature.tabularFigures()]);
}

ThemeData buildTheme() {
  final base = ThemeData(useMaterial3: true, brightness: Brightness.light);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.canvas,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.green,
      secondary: AppColors.yellow,
      surface: AppColors.surface,
      error: AppColors.red,
    ),
    splashFactory: InkSparkle.splashFactory,
    dividerColor: AppColors.hairline,
    textSelectionTheme: const TextSelectionThemeData(cursorColor: AppColors.green),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      contentTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.5),
      insetPadding: EdgeInsets.fromLTRB(16, 8, 16, 16),
      shape: RoundedRectangleBorder(borderRadius: R.md),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: R.lg),
    ),
  );
}

const systemLightOverlay = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.dark,
  statusBarBrightness: Brightness.light,
);
const systemDarkOverlay = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.dark,
);
