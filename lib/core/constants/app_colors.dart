
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Brand (from "bg-gradient-to-br from-blue-600 to-indigo-700")
  static const Color primary = Color(0xFF2563EB);         // blue-600
  static const Color primaryDark = Color(0xFF4338CA);     // indigo-700
  static const Color primaryLight = Color(0xFFEFF6FF);    // blue-50

  // Background
  static const Color background = Color(0xFFF9FAFB);      // gray-50
  static const Color surface = Color(0xFFFFFFFF);         // white
  static const Color surfaceHover = Color(0xFFF3F4F6);    // gray-100

  // Text
  static const Color textPrimary = Color(0xFF1F2937);     // gray-800
  static const Color textSecondary = Color(0xFF4B5563);   // gray-600
  static const Color textHint = Color(0xFF9CA3AF);        // gray-400
  static const Color textDisabled = Color(0xFF6B7280);    // gray-500

  // Border
  static const Color border = Color(0xFFE5E7EB);          // gray-200
  static const Color borderFocus = Color(0xFF2563EB);     // blue-500

  // Status Colors
  static const Color success = Color(0xFF16A34A);         // green-600
  static const Color successLight = Color(0xFFDCFCE7);    // green-50
  static const Color successText = Color(0xFF166534);     // green-800

  static const Color error = Color(0xFFDC2626);           // red-600
  static const Color errorLight = Color(0xFFFEF2F2);      // red-50
  static const Color errorText = Color(0xFF991B1B);       // red-800

  static const Color warning = Color(0xFFF59E0B);         // amber-500
  static const Color warningLight = Color(0xFFFEF3C7);    // yellow-50 (approximately)
  static const Color warningText = Color(0xFF92400E);     // yellow-800

  static const Color info = Color(0xFF2563EB);            // blue-600
  static const Color infoLight = Color(0xFFEFF6FF);       // blue-50
  static const Color infoText = Color(0xFF1E40AF);        // blue-800

  // Accent Colors (for stat cards and tags)
  static const Color purple = Color(0xFF7C3AED);          // purple-600
  static const Color purpleLight = Color(0xFFF5F3FF);     // purple-50
  static const Color green = Color(0xFF16A34A);           // green-600
  static const Color greenLight = Color(0xFFDCFCE7);      // green-50
  static const Color orange = Color(0xFFEA580C);          // orange-600
  static const Color orangeLight = Color(0xFFFFF7ED);     // orange-50
  static const Color indigo = Color(0xFF4338CA);          // indigo-700
  static const Color indigoLight = Color(0xFFEEF2FF);     // indigo-50

  // Gradient (logo and hero sections)
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF2563EB), Color(0xFF4338CA)], // blue-600 to indigo-700
  );
}