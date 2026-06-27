import 'package:flutter/material.dart';

abstract class AppColors {
  // Primary — Deep Navy
  static const primary = Color(0xFF000F1D);
  static const primaryContainer = Color(0xFF0F2537);
  static const onPrimary = Color(0xFFFFFFFF);
  static const onPrimaryContainer = Color(0xFF788DA3);
  static const inversePrimary = Color(0xFFB3C9E0);

  // Secondary — Blue
  static const secondary = Color(0xFF3B618A);
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFFAACFFE);
  static const onSecondaryContainer = Color(0xFF325881);

  // Tertiary — Emerald (AI accent)
  static const tertiary = Color(0xFF001209);
  static const onTertiary = Color(0xFFFFFFFF);
  static const tertiaryContainer = Color(0xFF002A1A);
  static const onTertiaryContainer = Color(0xFF009E6D); // Emerald accent
  static const tertiaryFixed = Color(0xFF6FFBBE);
  static const tertiaryFixedDim = Color(0xFF4EDEA3);

  // Error
  static const error = Color(0xFFBA1A1A);
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);

  // Surface
  static const background = Color(0xFFF7F9FB);
  static const onBackground = Color(0xFF191C1E);
  static const surface = Color(0xFFF7F9FB);
  static const onSurface = Color(0xFF191C1E);
  static const onSurfaceVariant = Color(0xFF43474C);
  static const surfaceVariant = Color(0xFFE0E3E5);
  static const inverseSurface = Color(0xFF2D3133);
  static const inverseOnSurface = Color(0xFFEFF1F3);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF2F4F6);
  static const surfaceContainer = Color(0xFFECEEF0);
  static const surfaceContainerHigh = Color(0xFFE6E8EA);

  // Outline
  static const outline = Color(0xFF74777D);
  static const outlineVariant = Color(0xFFC3C7CD);

  // Gradients
  static const emeraldGradient = LinearGradient(
    colors: [Color(0xFF00C785), Color(0xFF009E6D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const navyGradient = LinearGradient(
    colors: [Color(0xFF0F2537), Color(0xFF000F1D)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
