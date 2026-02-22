import 'package:flutter/material.dart';

import '../controllers/workspace_controller.dart';
import '../widgets/document_list_tile.dart';
import '../widgets/feature_card.dart';
import '../widgets/stat_card.dart';
import 'mobile/mobile_editor_screen.dart';
import 'search_screen.dart';
import 'sessions/session_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.controller,
    required this.onGoToDocuments,
    required this.onGoToSessions,
    this.onShowTemplates,
  });

  final WorkspaceController controller;
  final VoidCallback onGoToDocuments;
  final VoidCallback onGoToSessions;
  final VoidCallback? onShowTemplates;

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _userName() {
    final email = controller.client.auth.currentUser?.email ?? '';
    final name = email.split('@').first;
    if (name.isEmpty) return '';
    return ', ${name[0].toUpperCase()}${name.substring(1)}';
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 1024;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_outlined),
            tooltip: 'Search',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SearchScreen(
                  controller: controller,
                  onGoToSessions: onGoToSessions,
                ),
              ),
            ),
          ),
        ],
      ),
      body: isWide
          ? _WideBody(
              controller: controller,
              greeting: _greeting(),
              userName: _userName(),
              onGoToDocuments: onGoToDocuments,
              onGoToSessions: onGoToSessions,
              onShowTemplates: onShowTemplates,
              formatDate: _formatDate,
            )
          : _NarrowBody(
              controller: controller,
              greeting: _greeting(),
              userName: _userName(),
              onGoToDocuments: onGoToDocuments,
              onGoToSessions: onGoToSessions,
              onShowTemplates: onShowTemplates,
              formatDate: _formatDate,
            ),
    );
  }
}

// ─── Narrow (Mobile / Tablet) Layout ──────────────────────────────────────────

class _NarrowBody extends StatelessWidget {
  const _NarrowBody({
    required this.controller,
    required this.greeting,
    required this.userName,
    required this.onGoToDocuments,
    required this.onGoToSessions,
    required this.formatDate,
    this.onShowTemplates,
  });

  final WorkspaceController controller;
  final String greeting;
  final String userName;
  final VoidCallback onGoToDocuments;
  final VoidCallback onGoToSessions;
  final VoidCallback? onShowTemplates;
  final String Function(DateTime) formatDate;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final docs = controller.documents;
    final recentDocs = docs.length > 5 ? docs.sublist(0, 5) : docs;
    final upcoming = controller.upcomingSessions;
    final nextSessions = upcoming.length > 3 ? upcoming.sublist(0, 3) : upcoming;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          Text(
            '$greeting$userName!',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            controller.client.auth.currentUser?.email ?? '',
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 24),

          // Stats row
          Row(
            children: [
              StatCard(
                count: controller.documents.length,
                label: 'Docs',
                icon: Icons.description_outlined,
              ),
              const SizedBox(width: 10),
              StatCard(
                count: controller.sessions.length,
                label: 'Sessions',
                icon: Icons.event_outlined,
              ),
              const SizedBox(width: 10),
              StatCard(
                count: controller.templates.length,
                label: 'Templates',
                icon: Icons.layers_outlined,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Features section
          _SectionHeader(label: 'FEATURES'),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.1,
            children: [
              FeatureCard(
                title: 'Documents',
                subtitle: '${controller.documents.length} songs',
                icon: Icons.edit_document,
                accentColor: const Color(0xFF3730A3),
                onTap: onGoToDocuments,
              ),
              FeatureCard(
                title: 'Sessions',
                subtitle: '${controller.sessions.length} sessions',
                icon: Icons.event,
                accentColor: const Color(0xFF7C3AED),
                onTap: onGoToSessions,
              ),
              FeatureCard(
                title: 'Templates',
                subtitle: '${controller.templates.length} views',
                icon: Icons.layers,
                accentColor: const Color(0xFF0D9488),
                onTap: onShowTemplates ?? onGoToDocuments,
              ),
              FeatureCard(
                title: 'Search',
                subtitle: 'Find anything',
                icon: Icons.search,
                accentColor: const Color(0xFFD97706),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SearchScreen(
                      controller: controller,
                      onGoToSessions: onGoToSessions,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Recent documents
          Row(
            children: [
              _SectionHeader(label: 'RECENT DOCUMENTS'),
              const Spacer(),
              TextButton(
                onPressed: onGoToDocuments,
                child: const Text('See all'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (recentDocs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No documents yet',
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
            )
          else
            ...recentDocs.map((doc) => DocumentListTile(
                  document: doc,
                  isSelected: false,
                  onTap: () {
                    controller.selectDocument(doc);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MobileEditorScreen(
                          controller: controller,
                          document: doc,
                        ),
                      ),
                    );
                  },
                )),
          const SizedBox(height: 24),

          // Upcoming sessions
          Row(
            children: [
              _SectionHeader(label: 'UPCOMING SESSIONS'),
              const Spacer(),
              TextButton(
                onPressed: onGoToSessions,
                child: const Text('See all'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (nextSessions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No upcoming sessions',
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
            )
          else
            ...nextSessions.map((s) => _SessionListItem(
                  session: s,
                  controller: controller,
                  formatDate: formatDate,
                )),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─── Wide (Desktop) Layout ────────────────────────────────────────────────────

class _WideBody extends StatelessWidget {
  const _WideBody({
    required this.controller,
    required this.greeting,
    required this.userName,
    required this.onGoToDocuments,
    required this.onGoToSessions,
    required this.formatDate,
    this.onShowTemplates,
  });

  final WorkspaceController controller;
  final String greeting;
  final String userName;
  final VoidCallback onGoToDocuments;
  final VoidCallback onGoToSessions;
  final VoidCallback? onShowTemplates;
  final String Function(DateTime) formatDate;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final docs = controller.documents;
    final recentDocs = docs.length > 5 ? docs.sublist(0, 5) : docs;
    final upcoming = controller.upcomingSessions;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left column (60%)
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting$userName!',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  controller.client.auth.currentUser?.email ?? '',
                  style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 28),

                // Stats row
                Row(
                  children: [
                    StatCard(
                      count: controller.documents.length,
                      label: 'Docs',
                      icon: Icons.description_outlined,
                    ),
                    const SizedBox(width: 12),
                    StatCard(
                      count: controller.sessions.length,
                      label: 'Sessions',
                      icon: Icons.event_outlined,
                    ),
                    const SizedBox(width: 12),
                    StatCard(
                      count: controller.templates.length,
                      label: 'Templates',
                      icon: Icons.layers_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Feature cards
                _SectionHeader(label: 'FEATURES'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 110,
                        child: FeatureCard(
                          title: 'Documents',
                          subtitle: '${controller.documents.length} songs',
                          icon: Icons.edit_document,
                          accentColor: const Color(0xFF3730A3),
                          onTap: onGoToDocuments,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 110,
                        child: FeatureCard(
                          title: 'Sessions',
                          subtitle: '${controller.sessions.length} sessions',
                          icon: Icons.event,
                          accentColor: const Color(0xFF7C3AED),
                          onTap: onGoToSessions,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 110,
                        child: FeatureCard(
                          title: 'Templates',
                          subtitle: '${controller.templates.length} views',
                          icon: Icons.layers,
                          accentColor: const Color(0xFF0D9488),
                          onTap: onShowTemplates ?? onGoToDocuments,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 110,
                        child: FeatureCard(
                          title: 'Search',
                          subtitle: 'Find anything',
                          icon: Icons.search,
                          accentColor: const Color(0xFFD97706),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SearchScreen(
                                controller: controller,
                                onGoToSessions: onGoToSessions,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Recent documents
                Row(
                  children: [
                    _SectionHeader(label: 'RECENT DOCUMENTS'),
                    const Spacer(),
                    TextButton(
                      onPressed: onGoToDocuments,
                      child: const Text('See all'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (recentDocs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'No documents yet',
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  ...recentDocs.map((doc) => DocumentListTile(
                        document: doc,
                        isSelected: false,
                        onTap: () => controller.selectDocument(doc),
                      )),
              ],
            ),
          ),

          const SizedBox(width: 40),

          // Right column (40%)
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 80), // align below greeting
                Row(
                  children: [
                    _SectionHeader(label: 'UPCOMING SESSIONS'),
                    const Spacer(),
                    TextButton(
                      onPressed: onGoToSessions,
                      child: const Text('See all'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (upcoming.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'No upcoming sessions',
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  ...upcoming.map((s) => _SessionListItem(
                        session: s,
                        controller: controller,
                        formatDate: formatDate,
                      )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _SessionListItem extends StatelessWidget {
  const _SessionListItem({
    required this.session,
    required this.controller,
    required this.formatDate,
  });

  final dynamic session;
  final WorkspaceController controller;
  final String Function(DateTime) formatDate;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const accent = Color(0xFF7C3AED); // violet
    final dateStr = session.sessionDate != null
        ? formatDate(session.sessionDate as DateTime)
        : 'No date';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isDark ? 0.09 : 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accent.withValues(alpha: isDark ? 0.35 : 0.22),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          splashColor: accent.withValues(alpha: 0.10),
          highlightColor: accent.withValues(alpha: 0.07),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SessionDetailScreen(
                controller: controller,
                session: session,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: isDark ? 0.20 : 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: accent.withValues(alpha: isDark ? 0.40 : 0.25),
                    ),
                  ),
                  child: Icon(Icons.event, color: accent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.name as String,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
