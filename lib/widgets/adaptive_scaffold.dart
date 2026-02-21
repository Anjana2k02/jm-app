import 'package:flutter/material.dart';

import '../controllers/workspace_controller.dart';
import '../screens/tablet/tablet_workspace_screen.dart';
import '../screens/workspace_screen.dart';

/// Breakpoint constants matching Material Design 3 adaptive layout guidelines.
const double kMobileBreakpoint = 600.0;
const double kTabletBreakpoint = 1024.0;

/// Reads [MediaQuery] width and renders the appropriate layout shell:
/// - < 600dp  → mobile (bottom nav + FAB, managed by go_router ShellRoute)
/// - 600–1024 → tablet (NavigationRail + split pane)
/// - > 1024   → desktop (sidebar + centered editor)
///
/// On mobile the [mobileChild] (go_router's shell body) is used directly.
/// On tablet/desktop the full workspace is rendered inline.
class AdaptiveScaffold extends StatefulWidget {
  const AdaptiveScaffold({
    super.key,
    this.mobileChild,
  });

  /// The body provided by go_router's ShellRoute on mobile.
  final Widget? mobileChild;

  @override
  State<AdaptiveScaffold> createState() => _AdaptiveScaffoldState();
}

class _AdaptiveScaffoldState extends State<AdaptiveScaffold> {
  late final WorkspaceController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WorkspaceController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    if (width < kMobileBreakpoint) {
      // Mobile: go_router shell handles the nav bar; we just pass through.
      return widget.mobileChild ?? _fallbackMobileView();
    }

    if (width < kTabletBreakpoint) {
      return TabletWorkspaceScreen(controller: _controller);
    }

    return WorkspaceScreen(controller: _controller);
  }

  Widget _fallbackMobileView() {
    // Shown when AdaptiveScaffold is used outside of go_router shell context.
    return WorkspaceScreen(controller: _controller);
  }
}
