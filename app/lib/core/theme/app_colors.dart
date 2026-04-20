import 'package:flutter/material.dart';

class AppColors {
  // Background scale
  static const Color bg900 = Color(0xFF0A0C10); // Primary background
  static const Color bg700 = Color(0xFF141820); // Surface
  static const Color bg500 = Color(0xFF1E2530); // Elevated surface
  static const Color bg400 = Color(0xFF2A3040); // Border

  // Accent
  static const Color accent = Color(0xFF00E5FF); // Electric cyan
  static const Color accentDim = Color(0xFF0097A7);

  // Semantic
  static const Color danger  = Color(0xFFFF5C6B); // Coral
  static const Color warning = Color(0xFFFFD600); // Yellow
  static const Color success = Color(0xFF00E676); // Green

  // Text
  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8A95A3);
  static const Color textMuted     = Color(0xFF4A5568);

  // Heatmap density
  static const Color densityEmpty    = Color(0xFF1E2530);
  static const Color densityLow      = Color(0xFF1A4A3A);
  static const Color densityModerate = Color(0xFF2D5A1A);
  static const Color densityHigh     = Color(0xFF5A3A00);
  static const Color densityCritical = Color(0xFF5A1A1A);

  // Alert type colors
  static const Color alertFood   = Color(0xFF00E676);
  static const Color alertTiming = Color(0xFF00E5FF);
  static const Color alertExit   = Color(0xFFFF5C6B);
  static const Color alertView   = Color(0xFFFFD600);

  // Transparency
  static Color accentAlpha(double opacity) => accent.withValues(alpha: opacity);
  static Color dangerAlpha(double opacity) => danger.withValues(alpha: opacity);
}
