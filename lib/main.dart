import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'config/supabase_config.dart';
import 'services/connectivity_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Allow google_fonts runtime fetching for web (network usually available).
  // For native platforms, disable to avoid CDN timeout issues.
  GoogleFonts.config.allowRuntimeFetching = !_isNativeApp;

  await dotenv.load(fileName: '.env', mergeWith: {});

  // Check connectivity before trying to reach Supabase.
  final connectivity = ConnectivityService();
  final hasNetwork = await connectivity.checkNow();

  bool supabaseReady = false;

  if (hasNetwork && SupabaseConfig.isConfigured) {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
      );
      supabaseReady = true;
    } catch (e) {
      debugPrint('Supabase init failed: $e');
    }
  }

  runApp(
    App(
      isConfigured: SupabaseConfig.isConfigured,
      supabaseReady: supabaseReady,
      connectivity: connectivity,
    ),
  );
}

bool get _isNativeApp {
  try {
    return Platform.isAndroid ||
        Platform.isIOS ||
        Platform.isWindows ||
        Platform.isLinux ||
        Platform.isMacOS;
  } catch (e) {
    // If Platform check fails (e.g., on web), assume it's web
    return false;
  }
}
