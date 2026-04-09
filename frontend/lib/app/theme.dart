import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Obsidian 深色主题系统
/// 基于 UI 设计代码的配色方案
class AppTheme {
  AppTheme._();

  // 核心颜色 (来自参考 UI)
  static const Color background = Color(0xFF111417);
  static const Color surface = Color(0xFF1A1D21);
  static const Color surfaceLight = Color(0xFF22262B);
  static const Color surfaceHigh = Color(0xFF272A2E);
  static const Color surfaceHighest = Color(0xFF323538);
  static const Color border = Color(0xFF2A2E33);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8B8F95);
  static const Color textOnSurface = Color(0xFFE1E2E7);
  static const Color textOnSurfaceVariant = Color(0xFFBBC9CF);
  
  // 强调色
  static const Color accent = Color(0xFF3B82F6);
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color primary = Color(0xFFA4E6FF);
  static const Color primaryContainer = Color(0xFF00D1FF);
  static const Color primaryFixed = Color(0xFFB7EAFF);
  static const Color primaryFixedDim = Color(0xFF4CD6FF);
  static const Color onPrimaryContainer = Color(0xFF00566A);
  
  // 功能色
  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0xFF46FE95);
  static const Color successContainer = Color(0xFF04E07B);
  static const Color danger = Color(0xFFEF4444);
  static const Color error = Color(0xFFFFB4AB);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color tertiary = Color(0xFFCDDEF0);
  static const Color tertiaryContainer = Color(0xFFB2C2D4);
  
  // 轮廓色
  static const Color outline = Color(0xFF859399);
  static const Color outlineVariant = Color(0xFF3C494E);
  static const Color inverseSurface = Color(0xFFE1E2E7);

  /// 深色主题
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        onPrimary: Color(0xFF003543),
        primaryContainer: primaryContainer,
        onPrimaryContainer: onPrimaryContainer,
        secondary: successLight,
        onSecondary: Color(0xFF00391B),
        secondaryContainer: successContainer,
        onSecondaryContainer: Color(0xFF005D30),
        tertiary: tertiary,
        onTertiary: Color(0xFF223240),
        tertiaryContainer: tertiaryContainer,
        onTertiaryContainer: Color(0xFF40505F),
        error: error,
        onError: Color(0xFF690005),
        errorContainer: errorContainer,
        onErrorContainer: Color(0xFFFFDAD6),
        surface: surface,
        onSurface: textOnSurface,
        surfaceContainerHighest: surfaceHighest,
        onSurfaceVariant: textOnSurfaceVariant,
        outline: outline,
        outlineVariant: outlineVariant,
        inverseSurface: inverseSurface,
        inversePrimary: Color(0xFF00677F),
        surfaceTint: primaryFixedDim,
      ),
      
      // 字体配置
      textTheme: _textTheme,
      
      // AppBar 主题
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: background.withAlpha(204),
        foregroundColor: textOnSurface,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textOnSurface,
          letterSpacing: -0.5,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
      
      // 卡片主题
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: EdgeInsets.zero,
      ),
      
      // 输入框主题
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceHighest.withAlpha(128),
        hintStyle: TextStyle(
          color: outline.withAlpha(128),
          fontSize: 14,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: primaryContainer,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: error,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: error,
            width: 1.5,
          ),
        ),
      ),
      
      // 按钮主题
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primaryContainer,
          foregroundColor: onPrimaryContainer,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // 文本按钮主题
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      
      // 底部导航栏主题
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: background.withAlpha(242),
        elevation: 0,
        selectedItemColor: accentCyan,
        unselectedItemColor: textSecondary,
        selectedLabelStyle: GoogleFonts.spaceGrotesk(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
        unselectedLabelStyle: GoogleFonts.spaceGrotesk(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
      
      // 浮动按钮主题
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryContainer,
        foregroundColor: onPrimaryContainer,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // 分割线主题
      dividerTheme: DividerThemeData(
        color: outlineVariant.withAlpha(77),
        thickness: 1,
        space: 1,
      ),
      
      // 列表瓦片主题
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        selectedTileColor: surfaceLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textOnSurface,
        ),
        subtitleTextStyle: GoogleFonts.inter(
          fontSize: 12,
          color: textOnSurfaceVariant,
        ),
      ),
      
      // 开关主题
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryContainer;
          }
          return outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return onPrimaryContainer.withAlpha(128);
          }
          return surfaceHighest;
        }),
      ),
      
      // Chip 主题
      chipTheme: ChipThemeData(
        backgroundColor: surfaceLight,
        selectedColor: primaryContainer.withAlpha(51),
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textOnSurface,
        ),
        secondaryLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: primaryContainer,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// 文本主题
  static TextTheme get _textTheme {
    return TextTheme(
      // 大标题
      displayLarge: GoogleFonts.spaceGrotesk(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        color: textOnSurface,
        letterSpacing: -1,
      ),
      displayMedium: GoogleFonts.spaceGrotesk(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: textOnSurface,
        letterSpacing: -0.5,
      ),
      displaySmall: GoogleFonts.spaceGrotesk(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: textOnSurface,
        letterSpacing: -0.5,
      ),
      
      // 标题
      headlineLarge: GoogleFonts.spaceGrotesk(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: textOnSurface,
        letterSpacing: -0.5,
      ),
      headlineMedium: GoogleFonts.spaceGrotesk(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textOnSurface,
        letterSpacing: -0.5,
      ),
      headlineSmall: GoogleFonts.spaceGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textOnSurface,
        letterSpacing: -0.5,
      ),
      
      // 副标题
      titleLarge: GoogleFonts.spaceGrotesk(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textOnSurface,
        letterSpacing: -0.2,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textOnSurface,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textOnSurface,
        letterSpacing: 0.1,
      ),
      
      // 正文
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textOnSurface,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textOnSurface,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textOnSurfaceVariant,
        height: 1.4,
      ),
      
      // 标签
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textOnSurface,
        letterSpacing: 0.1,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textOnSurfaceVariant,
        letterSpacing: 0.5,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: textOnSurfaceVariant,
        letterSpacing: 0.5,
      ),
    );
  }
}
