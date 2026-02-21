import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'config/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Allow google_fonts runtime fetching for web (network usually available).
  // For native platforms, disable to avoid CDN timeout issues.
  GoogleFonts.config.allowRuntimeFetching = !_isNativeApp;

  await dotenv.load(fileName: '.env', mergeWith: {});

  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  }

  runApp(App(isConfigured: SupabaseConfig.isConfigured));
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
