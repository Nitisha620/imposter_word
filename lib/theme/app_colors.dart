import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Backgrounds ──────────────────────────────────────────────
  static const bg           = Color(0xFF0B0F1A);
  static const surface      = Color(0xFF13111F);
  static const surfaceAlt   = Color(0xFF1A1730);
  static const card         = Color(0xFF111827);
  static const inputBg      = Color(0xFF0E1422);

  // ── Borders ───────────────────────────────────────────────────
  static const border       = Color(0xFF1E2740);
  static const borderAlt    = Color(0xFF2E2A45);

  // ── Brand ─────────────────────────────────────────────────────
  static const accent       = Color(0xFF9B8FFF);   // reveal/discussion purple
  static const accentSoft   = Color(0xFF6D5FFD);
  static const purple       = Color(0xFF7C6EF5);   // lobby/home purple
  static const purpleDim    = Color(0xFF4B44A0);

  // ── Semantic ──────────────────────────────────────────────────
  static const green        = Color(0xFF34D399);
  static const amber        = Color(0xFFFBBF24);
  static const red          = Color(0xFFF87171);
  static const errorRed     = Color(0xFFE53935);
  static const pink         = Color(0xFFE879F9);

  // ── Text ──────────────────────────────────────────────────────
  static const textPrimary  = Color(0xFFE8E4FF);
  static const textMuted    = Color(0xFF8B86A8);
  static const white70      = Color(0xB3FFFFFF);
  static const white38      = Color(0x61FFFFFF);
  static const white12      = Color(0x1FFFFFFF);

  // ── Avatars ───────────────────────────────────────────────────
  static const avatarColors = [
    Color(0xFF6D62F5),
    Color(0xFFF87171),
    Color(0xFF34D399),
    Color(0xFFFBBF24),
    Color(0xFF38BDF8),
    Color(0xFFF472B6),
    Color(0xFFA3E635),
    Color(0xFFFB923C),
    Color(0xFFE879F9),
    Color(0xFF2DD4BF),
  ];

  // ── Helper ────────────────────────────────────────────────────
  static Color avatarAt(int index) =>
      avatarColors[index % avatarColors.length];
}