import 'package:flutter/material.dart';

// --- Seed colors for Material 3 ColorScheme generation ---
const Color kSeedPrimary = Color(0xFF3730A3); // deep indigo-700
const Color kSeedSecondary = Color(0xFF7C3AED); // violet-600
const Color kSeedTertiary = Color(0xFFD97706); // amber-600 (FAB, CTAs)
const Color kAccentTeal = Color(0xFF0D9488); // teal-600 (Templates)

// --- Feature card accent colors ---
const Color kFeatureDocuments = kSeedPrimary; // indigo
const Color kFeatureSessions = kSeedSecondary; // violet
const Color kFeatureTemplates = kAccentTeal; // teal
const Color kFeatureSearch = kSeedTertiary; // amber

// --- Light mode surface overrides ---
const Color kSurfaceLight = Color(0xFFFAFAFC);
const Color kSidebarLight = Color(0xFFF1F0F7); // lavender tint
const Color kSidebarBorderLight = Color(0xFFE2E0F0);
const Color kDocTileSelectedLight = Color(0xFFEDE9FE); // violet-100

// --- Dark mode surface overrides ---
const Color kSurfaceDark = Color(0xFF0F0F14);
const Color kSidebarDark = Color(0xFF16161F);
const Color kSidebarBorderDark = Color(0xFF2A2A3A);
const Color kDocTileSelectedDark = Color(0xFF2D2B52);

// --- Glass / Liquid glass effect tokens ---
const double kGlassSigma = 16.0;

// Dark mode glass tints
const Color kGlassDarkBg = Color(0x0FFFFFFF); // white @ 6%
const Color kGlassDarkBorder = Color(0x1AFFFFFF); // white @ 10%

// Light mode glass tints
const Color kGlassLightBg = Color(0xB8FFFFFF); // white @ 72%
const Color kGlassLightBorder = Color(0x80FFFFFF); // white @ 50%

// Fallback (non-blur) backgrounds when kEnableGlass is false
const Color kGlassFallbackDark = Color(0xFF1E1E2C);
const Color kGlassFallbackLight = Color(0xFFF5F4FF);

// Global kill-switch — set to false to disable blur on low-end/Android devices
const bool kEnableGlass = true;
