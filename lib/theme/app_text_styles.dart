import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // ── Display ───────────────────────────────────────────────────
  static TextStyle heroTitle = GoogleFonts.barlow(
    fontSize: 38,
    fontWeight: FontWeight.w900,
    color: Colors.white,
    letterSpacing: 2,
  );

  static TextStyle screenTitle = GoogleFonts.barlow(
    fontSize: 28,
    fontWeight: FontWeight.w900,
    color: Colors.white,
    letterSpacing: 1,
  );

  static TextStyle dialogTitle = GoogleFonts.barlow(
    fontSize: 19,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  // ── Labels ────────────────────────────────────────────────────
  static TextStyle sectionLabel = GoogleFonts.barlow(
    fontSize: 11,
    fontWeight: FontWeight.w800,
    color: AppColors.white38,
    letterSpacing: 1.5,
  );

  static TextStyle cardTitle = GoogleFonts.barlow(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  static TextStyle pill = GoogleFonts.barlow(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.3,
  );

  static TextStyle badge = GoogleFonts.barlow(
    fontSize: 9,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.8,
    color: Colors.white,
  );

  static TextStyle actionButton = GoogleFonts.barlow(
    fontSize: 15,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.5,
    color: Colors.white,
  );

  // ── Body ──────────────────────────────────────────────────────
  static TextStyle bodyMd = GoogleFonts.inter(
    fontSize: 13.5,
    color: AppColors.white70,
    height: 1.5,
  );

  static TextStyle bodySm = GoogleFonts.inter(
    fontSize: 12.5,
    color: AppColors.white70,
    height: 1.5,
  );

  static TextStyle bodyXs = GoogleFonts.inter(
    fontSize: 11,
    color: AppColors.textMuted,
  );

  // ── Chat ──────────────────────────────────────────────────────
  static TextStyle chatText = GoogleFonts.inter(
    fontSize: 13.5,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static TextStyle chatSender = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w700,
  );

  // ── Input ─────────────────────────────────────────────────────
  static TextStyle inputText = GoogleFonts.inter(
    color: Colors.white,
    fontSize: 14,
  );

  static TextStyle inputHint = GoogleFonts.inter(
    color: AppColors.white38,
    fontSize: 13,
  );

  static TextStyle roomCode = GoogleFonts.inter(
    color: Colors.white,
    fontSize: 13,
    letterSpacing: 2,
    fontWeight: FontWeight.w600,
  );

  // ── =Error ─────────────────────────────────────────────────────
  static TextStyle errorText = GoogleFonts.inter(
    color: AppColors.errorRed,
    fontSize: 13,
  );
}
