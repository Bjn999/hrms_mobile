import 'package:flutter/material.dart';

class AppColors {
  // Brand Primary & Accent (Indigo & Deep Sapphire)
  static const Color primary = Color(0xFF1E3A8A); // Deep Royal Blue
  static const Color primaryLight = Color(0xFF3B82F6); // Vibrant Blue
  static const Color primaryDark = Color(0xFF0F172A); // Midnight Slate
  static const Color accent = Color(0xFF0D9488); // Emerald Teal
  static const Color accentLight = Color(0xFF14B8A6);

  // Status & Badges
  static const Color success = Color(0xFF10B981); // Emerald Green
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color error = Color(0xFFEF4444); // Rose Red
  static const Color info = Color(0xFF0284C7); // Sky Blue

  // Neutrals & Surfaces
  static const Color background = Color(0xFFF8FAFC); // Clean Light Slate
  static const Color cardBackground = Colors.white;
  static const Color surface = Color(0xFFF1F5F9);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textLight = Colors.white;

  // Borders & Dividers
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderFocused = Color(0xFF3B82F6);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [
      Color(0xFF1E40AF),
      Color(0xFF1E3A8A),
      Color(0xFF0F172A),
    ],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF2563EB),
      Color(0xFF1D4ED8),
    ],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF10B981),
      Color(0xFF059669),
    ],
  );
}
