import 'package:flutter/material.dart';

class MaterialTheme {
  final TextTheme textTheme;

  const MaterialTheme(this.textTheme);

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF08a8dd),
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFFFFAB91),
      onPrimaryContainer: Color(0xFF5E6A71),
      secondary: Color(0xFF1E1E2E),
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFF747474),
      onSecondaryContainer: Color(0xFFB71C1C),
      error: Color(0xFFB00020),
      onError: Color(0xFFFFFFFF),
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF333333),
      surfaceTint: Color(0xFF0D1B2A),
    );
  }

  ThemeData light() {
    return theme(lightScheme());
  }

  ThemeData theme(ColorScheme colorScheme) => ThemeData(
        useMaterial3: true,
        brightness: colorScheme.brightness,
        colorScheme: colorScheme,
        textTheme: textTheme.apply(
          bodyColor: colorScheme.onSurface,
          displayColor: colorScheme.onSurface,
        ),
        scaffoldBackgroundColor: colorScheme.surface,
        canvasColor: colorScheme.surface,
      );

  static const success = ExtendedColor(
    seed: Color(0xFF4CAF50), // Verde para éxito
    value: Color(0xFF4CAF50),
    light: ColorFamily(
      color: Color(0xFF81C784),
      onColor: Color(0xFFFFFFFF),
      colorContainer: Color(0xFFC8E6C9),
      onColorContainer: Color(0xFF1B5E20),
    ),
    lightMediumContrast: ColorFamily(
      color: Color(0xFF66BB6A),
      onColor: Color(0xFFFFFFFF),
      colorContainer: Color(0xFFA5D6A7),
      onColorContainer: Color(0xFF2E7D32),
    ),
    lightHighContrast: ColorFamily(
      color: Color(0xFF388E3C),
      onColor: Color(0xFFFFFFFF),
      colorContainer: Color(0xFF4CAF50),
      onColorContainer: Color(0xFF1B5E20),
    ),
  );

  static const warning = ExtendedColor(
    seed: Color(0xFFFFEB3B),
    value: Color(0xFFFFEB3B),
    light: ColorFamily(
      color: Color(0xFFFFF176),
      onColor: Color(0xFF000000),
      colorContainer: Color(0xFFFFF9C4),
      onColorContainer: Color(0xFFF57F17),
    ),
    lightMediumContrast: ColorFamily(
      color: Color(0xFFFFF176),
      onColor: Color(0xFF000000),
      colorContainer: Color(0xFFFFF9C4),
      onColorContainer: Color(0xFFF57F17),
    ),
    lightHighContrast: ColorFamily(
      color: Color(0xFFFFD600),
      onColor: Color(0xFF000000),
      colorContainer: Color(0xFFFFF9C4),
      onColorContainer: Color(0xFFF57F17),
    ),
  );

  List<ExtendedColor> get extendedColors => [
        success,
        warning,
      ];
}

class ExtendedColor {
  final Color seed, value;
  final ColorFamily light;
  final ColorFamily lightHighContrast;
  final ColorFamily lightMediumContrast;

  const ExtendedColor({
    required this.seed,
    required this.value,
    required this.light,
    required this.lightHighContrast,
    required this.lightMediumContrast,
  });
}

class ColorFamily {
  const ColorFamily({
    required this.color,
    required this.onColor,
    required this.colorContainer,
    required this.onColorContainer,
  });

  final Color color;
  final Color onColor;
  final Color colorContainer;
  final Color onColorContainer;
}
