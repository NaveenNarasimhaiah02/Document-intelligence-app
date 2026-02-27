import 'package:flutter/material.dart';

class AC {
  // Backgrounds
  static const bg      = Color(0xFFF0F2F8);   // light grey-blue page bg
  static const surface = Color(0xFFFFFFFF);   // white cards
  static const header1 = Color(0xFF3B1FA8);   // gradient start (deep purple)
  static const header2 = Color(0xFF7C3AED);   // gradient end (violet)

  // Text
  static const textH   = Color(0xFFFFFFFF);   // header text
  static const textP   = Color(0xFF1A1A2E);   // primary body text
  static const textS   = Color(0xFF6B7280);   // secondary / caption text

  // Borders & dividers
  static const border  = Color(0xFFE5E7EB);
  static const shadow  = Color(0x14000000);   // very light shadow

  // Accent (amounts, links)
  static const accent  = Color(0xFF7C3AED);

  // Per-type colours
  static const tInvoice      = Color(0xFFD97706); // amber-700
  static const tPrescription = Color(0xFF059669); // emerald-600
  static const tLabReport    = Color(0xFFDC2626); // red-600
  static const tIdProof      = Color(0xFF0284C7); // sky-600
  static const tInsurance    = Color(0xFF7C3AED); // violet-600
  static const tOther        = Color(0xFF6B7280); // grey-500

  static Color forType(String t) {
    switch (t) {
      case 'Invoice/Bill'  : return tInvoice;
      case 'Prescription'  : return tPrescription;
      case 'Lab Report'    : return tLabReport;
      case 'ID Proof'      : return tIdProof;
      case 'Insurance'     : return tInsurance;
      default              : return tOther;
    }
  }

  static IconData iconForType(String t) {
    switch (t) {
      case 'Invoice/Bill'  : return Icons.receipt_long_rounded;
      case 'Prescription'  : return Icons.medication_rounded;
      case 'Lab Report'    : return Icons.biotech_rounded;
      case 'ID Proof'      : return Icons.badge_rounded;
      case 'Insurance'     : return Icons.health_and_safety_rounded;
      default              : return Icons.description_rounded;
    }
  }

  static Color tint(Color c, double a) => c.withAlpha((a * 255).round());
}
