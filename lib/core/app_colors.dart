import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette
  static const Color primary = Color(0xFF6366F1); // Modern Indigo
  static const Color secondary = Color(0xFF8B5CF6); // Modern Violet
  static const Color accent = Color(0xFF10B981); // Emerald Green
  
  // Neutral Palette
  static const Color background = Color(0xFF0F172A); // Slate 900
  static const Color surface = Color(0xFF1E293B); // Slate 800
  static const Color card = Color(0xFF334155); // Slate 700
  
  // Text Palette
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient glassGradient = LinearGradient(
    colors: [
      Color(0x1AFFFFFF),
      Color(0x05FFFFFF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
