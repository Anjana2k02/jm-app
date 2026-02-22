import 'package:flutter/material.dart';

import '../../controllers/workspace_controller.dart';
import '../../models/session_model.dart';
import '../../widgets/create_session_modal.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_dialog.dart';
import 'session_detail_screen.dart';

class SessionsScreen extends StatelessWidget {
  const SessionsScreen({super.key, required this.controller});

  final WorkspaceController controller;

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

  Future<void> _createSession(BuildContext context) async {
    final result = await showGlassDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const CreateSessionModal(),
    );

    if (result != null) {
      await controller.createSession(
        result['name'] as String,
        result['sessionDate'] as DateTime?,
        result['notes'] as String? ?? '',
      );

      if (context.mounted) {
        showGlassSnackBar(context, 'Session created');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessions = controller.sessions;

    return Scaffold(
      appBar: AppBar(title: const Text('Sessions')),
      body: sessions.isEmpty
          ? EmptyState(
              icon: Icons.event_outlined,
              title: 'No sessions yet',
              subtitle: 'Create your first practice or jam session.',
              action: FilledButton.icon(
                onPressed: () => _createSession(context),
                icon: const Icon(Icons.add),
                label: const Text('New Session'),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sessions.length,
              itemBuilder: (ctx, i) => _SessionCard(
                session: sessions[i],
                controller: controller,
                formatDate: _formatDate,
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createSession(context),
        icon: const Icon(Icons.add),
        label: const Text('New Session'),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.session,
    required this.controller,
    required this.formatDate,
  });

  final JamSession session;
  final WorkspaceController controller;
  final String Function(DateTime) formatDate;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const accent = Color(0xFF7C3AED); // violet
    final dateStr = session.sessionDate != null
        ? formatDate(session.sessionDate!)
        : 'No date set';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(bottom: 10),
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
              builder: (_) =>
                  SessionDetailScreen(controller: controller, session: session),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: isDark ? 0.20 : 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: accent.withValues(alpha: isDark ? 0.40 : 0.25),
                    ),
                  ),
                  child: Icon(Icons.event, color: accent, size: 22),
                ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
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
