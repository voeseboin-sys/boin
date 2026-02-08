import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colores principales
  static const Color primaryColor = Color(0xFF2ecc71); // Verde esmeralda
  static const Color primaryDark = Color(0xFF27ae60);
  static const Color primaryLight = Color(0xFF58d68d);
  
  // Colores de fondo (Dark Mode)
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF1E1E1E);
  static const Color surfaceVariant = Color(0xFF2C2C2C);
  static const Color surfaceElevated = Color(0xFF242424);
  
  // Colores de texto
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textTertiary = Color(0xFF808080);
  
  // Colores de estado
  static const Color success = Color(0xFF2ecc71);
  static const Color warning = Color(0xFFf1c40f);
  static const Color error = Color(0xFFe74c3c);
  static const Color info = Color(0xFF3498db);
  
  // Colores adicionales
  static const Color accentBlue = Color(0xFF3498db);
  static const Color accentPurple = Color(0xFF9b59b6);
  static const Color accentOrange = Color(0xFFe67e22);
  static const Color accentRed = Color(0xFFe74c3c);
  static const Color accentYellow = Color(0xFFf1c40f);

  // Tema oscuro principal
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        onPrimary: Colors.white,
        primaryContainer: primaryDark,
        onPrimaryContainer: Colors.white,
        secondary: accentBlue,
        onSecondary: Colors.white,
        surface: surface,
        onSurface: textPrimary,
        surfaceVariant: surfaceVariant,
        onSurfaceVariant: textSecondary,
        background: background,
        onBackground: textPrimary,
        error: error,
        onError: Colors.white,
      ),
      textTheme: _buildTextTheme(),
      appBarTheme: _buildAppBarTheme(),
      cardTheme: _buildCardTheme(),
      elevatedButtonTheme: _buildElevatedButtonTheme(),
      outlinedButtonTheme: _buildOutlinedButtonTheme(),
      textButtonTheme: _buildTextButtonTheme(),
      inputDecorationTheme: _buildInputDecorationTheme(),
      bottomNavigationBarTheme: _buildBottomNavTheme(),
      floatingActionButtonTheme: _buildFabTheme(),
      dividerTheme: _buildDividerTheme(),
      chipTheme: _buildChipTheme(),
      dialogTheme: _buildDialogTheme(),
      snackBarTheme: _buildSnackBarTheme(),
    );
  }

  static TextTheme _buildTextTheme() {
    final baseTextTheme = GoogleFonts.interTextTheme();
    
    return baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge?.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: baseTextTheme.displayMedium?.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.bold,
      ),
      displaySmall: baseTextTheme.displaySmall?.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w600,
      ),
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w500,
      ),
      titleSmall: baseTextTheme.titleSmall?.copyWith(
        color: textSecondary,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        color: textPrimary,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        color: textSecondary,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        color: textTertiary,
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w500,
      ),
      labelMedium: baseTextTheme.labelMedium?.copyWith(
        color: textSecondary,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: baseTextTheme.labelSmall?.copyWith(
        color: textTertiary,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  static AppBarTheme _buildAppBarTheme() {
    return const AppBarTheme(
      backgroundColor: surface,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  static CardTheme _buildCardTheme() {
    return CardTheme(
      color: surface,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static OutlinedButtonThemeData _buildOutlinedButtonTheme() {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static TextButtonThemeData _buildTextButtonTheme() {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static InputDecorationTheme _buildInputDecorationTheme() {
    return InputDecorationTheme(
      filled: true,
      fillColor: surfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: error, width: 1.5),
      ),
      labelStyle: const TextStyle(color: textSecondary),
      hintStyle: const TextStyle(color: textTertiary),
      prefixIconColor: textSecondary,
      suffixIconColor: textSecondary,
    );
  }

  static BottomNavigationBarThemeData _buildBottomNavTheme() {
    return const BottomNavigationBarThemeData(
      backgroundColor: surface,
      selectedItemColor: primaryColor,
      unselectedItemColor: textTertiary,
      selectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    );
  }

  static FloatingActionButtonThemeData _buildFabTheme() {
    return const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    );
  }

  static DividerThemeData _buildDividerTheme() {
    return const DividerThemeData(
      color: surfaceVariant,
      thickness: 1,
      space: 1,
    );
  }

  static ChipThemeData _buildChipTheme() {
    return ChipThemeData(
      backgroundColor: surfaceVariant,
      selectedColor: primaryColor.withOpacity(0.2),
      labelStyle: const TextStyle(color: textPrimary),
      secondaryLabelStyle: const TextStyle(color: primaryColor),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  static DialogTheme _buildDialogTheme() {
    return DialogTheme(
      backgroundColor: surface,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      titleTextStyle: const TextStyle(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  static SnackBarThemeData _buildSnackBarTheme() {
    return SnackBarThemeData(
      backgroundColor: surfaceElevated,
      contentTextStyle: const TextStyle(color: textPrimary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      behavior: SnackBarBehavior.floating,
    );
  }

  // Estilos adicionales
  static BoxDecoration get cardDecoration {
    return BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  static BoxDecoration get gradientDecoration {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primaryColor, primaryDark],
      ),
    );
  }
}
