import 'package:flutter/material.dart';

import '../controllers/workspace_controller.dart';
import '../models/document_model.dart';
import '../services/connectivity_service.dart';
import '../widgets/document_list_tile.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_dialog.dart';
import 'home_screen.dart';
import 'mobile/mobile_editor_screen.dart';
import 'search_screen.dart';
import 'sessions/sessions_screen.dart';
import 'tablet/tablet_workspace_screen.dart';
import 'workspace_screen.dart';

const double kMobileBreakpoint = 600.0;
const double kTabletBreakpoint = 1024.0;

/// Root screen after authentication.
/// Holds the shared [WorkspaceController] and selects the appropriate
/// layout based on current screen width.
class WorkspaceHostScreen extends StatefulWidget {
  const WorkspaceHostScreen({super.key, required this.connectivity});

  final ConnectivityService connectivity;

  @override
  State<WorkspaceHostScreen> createState() => _WorkspaceHostScreenState();
}

class _WorkspaceHostScreenState extends State<WorkspaceHostScreen> {
  late final WorkspaceController _controller;
  bool _wasOnline = true;

  @override
  void initState() {
    super.initState();
    _controller = WorkspaceController();
    _wasOnline = widget.connectivity.isOnline;
    widget.connectivity.addListener(_onConnectivityChanged);
    _controller.addListener(_onControllerChange);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChange);
    widget.connectivity.removeListener(_onConnectivityChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChange() {
    final err = _controller.operationError;
    if (err != null && mounted) {
      showGlassSnackBar(context, err);
    }
  }

  void _onConnectivityChanged() {
    final isOnline = widget.connectivity.isOnline;

    if (!isOnline && _wasOnline) {
      // Just went offline — show snackbar.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text('Connection lost !'),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } else if (isOnline && !_wasOnline) {
      // Just came back online — dismiss any lingering snackbar and show recovery.
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.wifi_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text('Back online'),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
        // Reload data now that we're back.
        _controller.loadAll();
      }
    }

    _wasOnline = isOnline;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        // Show a single full-screen spinner until all data is fetched.
        // This prevents child layouts from rendering with empty/zero state
        // while the 3 Supabase queries (documents, templates, sessions) complete.
        if (_controller.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Show a clear error screen if ALL fetches failed (e.g. Supabase
        // tables missing, wrong API key, no network). Lets the user retry.
        if (_controller.loadError != null &&
            _controller.documents.isEmpty &&
            _controller.sessions.isEmpty &&
            _controller.templates.isEmpty) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cloud_off_outlined,
                      size: 56,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Could not connect to Supabase',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _controller.loadError!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _controller.loadAll,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _controller.signOut,
                      child: const Text('Sign out'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final width = MediaQuery.sizeOf(context).width;
        if (width < kMobileBreakpoint) {
          return _MobileLayout(controller: _controller);
        }
        if (width < kTabletBreakpoint) {
          return TabletWorkspaceScreen(controller: _controller);
        }
        return WorkspaceScreen(controller: _controller);
      },
    );
  }
}

// ─── Mobile Layout ────────────────────────────────────────────────────────────

/// Mobile layout: 4-tab BottomNavigationBar (Home, Docs, Sessions, Settings).
class _MobileLayout extends StatefulWidget {
  const _MobileLayout({required this.controller});

  final WorkspaceController controller;

  @override
  State<_MobileLayout> createState() => _MobileLayoutState();
}

class _MobileLayoutState extends State<_MobileLayout> {
  // Tab indices
  static const int _tabHome = 0;
  static const int _tabDocs = 1;
  static const int _tabSessions = 2;

  int _currentTab = _tabHome;

  WorkspaceController get _ws => widget.controller;

  void _openEditor() {
    if (_ws.selectedDocument == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MobileEditorScreen(
          controller: _ws,
          document: _ws.selectedDocument!,
        ),
      ),
    );
  }

  Future<void> _showCreateDocDialog() async {
    final titleCtrl = TextEditingController();
    SongType selectedType = SongType.song;
    final isMobile = MediaQuery.sizeOf(context).width < kMobileBreakpoint;

    final result =
        await (isMobile
            ? showGlassDialog
            : showDialog)<({String title, SongType type})>(
          context: context,
          builder: (ctx) => StatefulBuilder(
            builder: (ctx, setDialogState) => AlertDialog(
              title: const Text('New song'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleCtrl,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Song title',
                      hintText: 'Untitled',
                    ),
                    onSubmitted: (_) => Navigator.pop(ctx, (
                      title: titleCtrl.text,
                      type: selectedType,
                    )),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Type',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  RadioGroup<SongType>(
                    groupValue: selectedType,
                    onChanged: (v) {
                      if (v != null) setDialogState(() => selectedType = v);
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RadioListTile<SongType>(
                          title: const Text('Song'),
                          value: SongType.song,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                        RadioListTile<SongType>(
                          title: const Text('Medley'),
                          value: SongType.medley,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, (
                    title: titleCtrl.text,
                    type: selectedType,
                  )),
                  child: const Text('Create'),
                ),
              ],
            ),
          ),
        );

    if (result == null || result.title.trim().isEmpty) return;
    final ok = await _ws.createDocument(result.title, result.type);
    if (!mounted) return;
    if (ok && _ws.selectedDocument != null) {
      showGlassSnackBar(context, 'Song created');
      _openEditor();
    }
  }

  Future<void> _showCreateSessionDialog() async {
    final nameCtrl = TextEditingController();
    DateTime? selectedDate;
    final notesCtrl = TextEditingController();
    final isMobile = MediaQuery.sizeOf(context).width < kMobileBreakpoint;

    final result = await (isMobile ? showGlassDialog : showDialog)<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('New session'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Session name',
                    hintText: 'e.g. Friday rehearsal',
                  ),
                  onSubmitted: (_) => Navigator.pop(ctx, true),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        selectedDate != null
                            ? _formatDate(selectedDate!)
                            : 'No date selected',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final d = await showDatePicker(
                          context: ctx,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (d != null) {
                          setDialogState(() => selectedDate = d);
                        }
                      },
                      child: const Text('Pick date'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );

    if (result != true || nameCtrl.text.trim().isEmpty) return;
    final ok = await _ws.createSession(
      nameCtrl.text.trim(),
      selectedDate,
      notesCtrl.text,
    );
    if (ok && mounted) showGlassSnackBar(context, 'Session created');
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _ws,
      builder: (context, _) {
        return Scaffold(
          body: IndexedStack(
            index: _currentTab,
            children: [
              // 0 — Home
              HomeScreen(
                controller: _ws,
                onGoToDocuments: () => setState(() => _currentTab = _tabDocs),
                onGoToSessions: () =>
                    setState(() => _currentTab = _tabSessions),
                onShowTemplates: () => setState(() => _currentTab = _tabDocs),
              ),
              // 1 — Documents
              _MobileDocListTab(
                controller: _ws,
                onDocTap: () {
                  setState(() {});
                  _openEditor();
                },
                onCreateDoc: _showCreateDocDialog,
              ),
              // 2 — Sessions
              SessionsScreen(controller: _ws),
              // 3 — Settings
              _MobileSettingsTab(controller: _ws),
            ],
          ),
          floatingActionButton: _currentTab == _tabDocs
              ? FloatingActionButton.extended(
                  onPressed: _showCreateDocDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('New Song'),
                )
              : _currentTab == _tabSessions
              ? FloatingActionButton.extended(
                  onPressed: _showCreateSessionDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('New Session'),
                )
              : null,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentTab,
            onDestinationSelected: (i) => setState(() => _currentTab = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.music_note_outlined),
                selectedIcon: Icon(Icons.music_note),
                label: 'Songs',
              ),
              NavigationDestination(
                icon: Icon(Icons.event_outlined),
                selectedIcon: Icon(Icons.event),
                label: 'Sessions',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Settings',
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Mobile Tab: Document List ────────────────────────────────────────────────

class _MobileDocListTab extends StatelessWidget {
  const _MobileDocListTab({
    required this.controller,
    required this.onDocTap,
    required this.onCreateDoc,
  });

  final WorkspaceController controller;
  final VoidCallback onDocTap;
  final VoidCallback onCreateDoc;

  @override
  Widget build(BuildContext context) {
    final docs = controller.orderedDocuments();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Songs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_outlined),
            tooltip: 'Search',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    SearchScreen(controller: controller, onGoToSessions: () {}),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Refresh',
            onPressed: controller.loadAll,
          ),
        ],
      ),
      body: controller.loading
          ? const Center(child: CircularProgressIndicator())
          : docs.isEmpty
          ? EmptyState(
              icon: Icons.music_note_outlined,
              title: 'No songs yet',
              subtitle: 'Tap the button below to create your first song.',
              action: FilledButton.icon(
                onPressed: onCreateDoc,
                icon: const Icon(Icons.add),
                label: const Text('New song'),
              ),
            )
          : RefreshIndicator(
              onRefresh: controller.loadAll,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                itemCount: docs.length,
                separatorBuilder: (_, _) => const SizedBox(height: 4),
                itemBuilder: (ctx, i) {
                  final doc = docs[i];
                  return DocumentListTile(
                    document: doc,
                    isSelected: false,
                    onTap: () {
                      controller.selectDocument(doc);
                      onDocTap();
                    },
                  );
                },
              ),
            ),
    );
  }
}

// ─── Mobile Tab: Settings ─────────────────────────────────────────────────────

class _MobileSettingsTab extends StatelessWidget {
  const _MobileSettingsTab({required this.controller});

  final WorkspaceController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final email = controller.client.auth.currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  radius: 22,
                  backgroundColor: cs.primaryContainer,
                  child: Text(
                    email.isNotEmpty ? email[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    ),
                  ),
                ),
                title: const Text(
                  'Account',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(email),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: ListTile(
                leading: Icon(Icons.logout_outlined, color: cs.error),
                title: Text('Sign out', style: TextStyle(color: cs.error)),
                onTap: controller.signOut,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
