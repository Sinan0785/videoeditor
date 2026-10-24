import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color surfaceVariant = Color(0xFF2A2A2A);
  static const Color primary = Color(0xFFFF2D55);
  static const Color primaryVariant = Color(0xFFFF6B6B);
  static const Color accent = Color(0xFF00D2FF);
  static const Color accentGreen = Color(0xFF00E676);
  static const Color accentYellow = Color(0xFFFFD600);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color textTertiary = Color(0xFF616161);
  static const Color divider = Color(0xFF2A2A2A);
  static const Color selectedTool = Color(0xFF29B6F6);
  static const Color timeline = Color(0xFF1E1E1E);
  static const Color timelineHandle = Color(0xFFFFD600);
  static const Color overlayDark = Color(0x99000000);
}

class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const TextStyle label = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );

  static const TextStyle toolbarLabel = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
}

class AppConstants {
  static const double timelineHeight = 80.0;
  static const double audioTrackHeight = 40.0;
  static const double toolbarHeight = 80.0;
  static const double bottomSheetRadius = 20.0;
  static const double previewAspectRatio = 9 / 16;
  static const Duration defaultTransitionDuration = Duration(milliseconds: 300);
  static const Duration snackbarDuration = Duration(seconds: 2);
  static const int maxAudioTracks = 5;
  static const double minClipDuration = 0.5; // seconds
  static const double maxExportDuration = 600.0; // 10 minutes
  static const double timelinePixelsPerSecond = 60.0;
  static const double minZoom = 0.25;
  static const double maxZoom = 4.0;
  static const List<double> speedPresets = [0.1, 0.25, 0.5, 0.75, 1.0, 1.5, 2.0, 3.0, 5.0, 10.0];
  static const List<String> fontFamilies = [
    'Roboto',
    'Montserrat',
    'Playfair Display',
    'Dancing Script',
    'Oswald',
    'Raleway',
    'Lobster',
    'Pacifico',
    'Ubuntu',
    'Nunito',
  ];
}

class FilterConstants {
  static const Map<String, List<double>> filterMatrices = {
    'none': [
      1, 0, 0, 0, 0,
      0, 1, 0, 0, 0,
      0, 0, 1, 0, 0,
      0, 0, 0, 1, 0,
    ],
    'vintage': [
      0.9, 0.5, 0.1, 0, 0,
      0.3, 0.8, 0.1, 0, 0,
      0.2, 0.3, 0.5, 0, 0,
      0, 0, 0, 1, 0,
    ],
    'blackAndWhite': [
      0.33, 0.33, 0.33, 0, 0,
      0.33, 0.33, 0.33, 0, 0,
      0.33, 0.33, 0.33, 0, 0,
      0, 0, 0, 1, 0,
    ],
    'sepia': [
      0.393, 0.769, 0.189, 0, 0,
      0.349, 0.686, 0.168, 0, 0,
      0.272, 0.534, 0.131, 0, 0,
      0, 0, 0, 1, 0,
    ],
    'vivid': [
      1.2, 0, 0, 0, 0,
      0, 1.2, 0, 0, 0,
      0, 0, 1.2, 0, 0,
      0, 0, 0, 1, 0,
    ],
    'cool': [
      0.8, 0, 0.1, 0, 0,
      0, 0.9, 0.1, 0, 0,
      0.1, 0.1, 1.2, 0, 0,
      0, 0, 0, 1, 0,
    ],
    'warm': [
      1.2, 0.1, 0, 0, 0,
      0.1, 1.0, 0, 0, 0,
      0, 0, 0.8, 0, 0,
      0, 0, 0, 1, 0,
    ],
  };
}
