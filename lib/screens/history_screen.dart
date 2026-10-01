import 'package:flutter/material.dart';
import '../models/run_model.dart';
import '../services/runs_service.dart';
import '../utils/formatters.dart';
import '../utils/page_transitions.dart';
import '../utils/theme.dart';
import '../widgets/reveal.dart';
import '../widgets/run_delete.dart';
import 'login_screen.dart';
import 'run_detail_screen.dart';

/// "Historial" tab: the user's runs, most recent first, [_pageSize] per
/// page (see CLAUDE.md > Historial). Embedded directly in MainShell, so it
/// has no Scaffold/AppBar of its own. A guest ([uid] null) sees the
/// example run plus a nudge to sign in and keep their own.
///
/// Pagination is client-side on purpose: the dashboard already streams the
/// whole runs collection for its totals, so the data is in memory anyway —
/// paging here is about not rendering a never-ending list, not about
/// Firestore reads. It also stays correct for free when a run is deleted
/// or restored (a cursor-based Firestore page would shift under the user).
class HistoryScreen extends StatefulWidget {
  final String? uid;

  const HistoryScreen({super.key, required this.uid});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const _pageSize = 8;

  late final Stream<List<RunModel>> _runs = RunsService().watchRuns(widget.uid);
  int _page = 0;

  /// Runs deleted from this screen, hidden right away: a swiped-away
  /// Dismissible must leave the tree on the very next build, and the
  /// Firestore snapshot without that run arrives a moment later.
  final _hiddenIds = <String>{};

  void _delete(RunModel run) {
    setState(() => _hiddenIds.add(run.id!));
    RunDelete.deleteWithUndo(
      context,
      widget.uid!,
      run,
      onUndo: () {
        if (mounted) setState(() => _hiddenIds.remove(run.id));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = widget.uid;
    final isGuest = uid == null;

    return StreamBuilder<List<RunModel>>(
      stream: _runs,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final runs = (snapshot.data ?? const <RunModel>[]).where((r) => !_hiddenIds.contains(r.id)).toList();
        if (runs.isEmpty) {
          return const _EmptyHistory();
        }

        final pageCount = (runs.length / _pageSize).ceil();
        // Deleting the last run of the last page would leave us past the end.
        final page = _page.clamp(0, pageCount - 1);
        final pageRuns = runs.skip(page * _pageSize).take(_pageSize).toList();

        return Column(
          children: [
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: ListView(
                  // New key per page: fresh scroll position + entrance anim.
                  key: ValueKey(page),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  children: [
                    if (isGuest) ...[const _GuestBanner(), const SizedBox(height: 10)],
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                      child: Text(
                        runs.length == 1 ? '1 carrera' : '${runs.length} carreras',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey.shade700),
                      ),
                    ),
                    for (var i = 0; i < pageRuns.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Reveal(
                          delay: Duration(milliseconds: 40 * i),
                          offsetY: 14,
                          child: _RunTile(run: pageRuns[i], canDelete: !isGuest, onDelete: _delete),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (pageCount > 1)
              _PageBar(
                page: page,
                pageCount: pageCount,
                onPageChanged: (p) => setState(() => _page = p),
              ),
          ],
        );
      },
    );
  }
}

class _RunTile extends StatelessWidget {
  final RunModel run;

  /// False for a guest — their only run is the example, which can't be deleted.
  final bool canDelete;
  final ValueChanged<RunModel> onDelete;

  const _RunTile({required this.run, required this.canDelete, required this.onDelete});

  bool get _canDelete => canDelete && run.id != null && !run.isSample;

  @override
  Widget build(BuildContext context) {
    final tile = Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.only(left: 16, right: 4),
        leading: CircleAvatar(
          backgroundColor: AppTheme.accent.withValues(alpha: 0.12),
          child: Icon(run.type.icon, color: AppTheme.accentDark),
        ),
        title: Text(RunFormatters.distanceKm(run.distanceKm)),
        subtitle: Text(
          '${run.isSample ? 'Ejemplo · ' : ''}${run.type.label} · ${RunFormatters.date(run.date)} · '
          '${RunFormatters.duration(run.durationSeconds)} · ${RunFormatters.pace(run.avgPaceMinPerKm)}',
        ),
        // A visible menu (not only swipe-to-delete) so deleting is
        // discoverable with a mouse on desktop too.
        trailing: _canDelete
            ? PopupMenuButton<String>(
                tooltip: 'Opciones',
                onSelected: (_) async {
                  if (await RunDelete.confirm(context, run)) onDelete(run);
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red.shade600),
                        const SizedBox(width: 10),
                        const Text('Eliminar'),
                      ],
                    ),
                  ),
                ],
              )
            : const Padding(padding: EdgeInsets.only(right: 12), child: Icon(Icons.chevron_right)),
        onTap: () => Navigator.of(context).push(
          FadeSlideRoute(builder: (_) => RunDetailScreen(run: run)),
        ),
      ),
    );

    if (!_canDelete) return tile;

    return Dismissible(
      key: ValueKey(run.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => RunDelete.confirm(context, run),
      onDismissed: (_) => onDelete(run),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(color: Colors.red.shade600, borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: tile,
    );
  }
}

class _PageBar extends StatelessWidget {
  final int page;
  final int pageCount;
  final ValueChanged<int> onPageChanged;

  const _PageBar({required this.page, required this.pageCount, required this.onPageChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton.filledTonal(
            tooltip: 'Página anterior',
            onPressed: page > 0 ? () => onPageChanged(page - 1) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          const SizedBox(width: 8),
          // Page dots for a handful of pages; plain "x de y" beyond that.
          if (pageCount <= 6)
            for (var i = 0; i < pageCount; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => onPageChanged(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == page ? AppTheme.accent : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: i == page ? Colors.white : AppTheme.accentDark,
                      ),
                    ),
                  ),
                ),
              )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('Página ${page + 1} de $pageCount', style: Theme.of(context).textTheme.titleSmall),
            ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            tooltip: 'Página siguiente',
            onPressed: page < pageCount - 1 ? () => onPageChanged(page + 1) : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_run, size: 48, color: AppTheme.accent.withValues(alpha: 0.6)),
            const SizedBox(height: 12),
            const Text('Todavía no registraste ninguna carrera.', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _GuestBanner extends StatelessWidget {
  const _GuestBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_upload_outlined, color: AppTheme.accentDark),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Esta es una carrera de ejemplo. Iniciá sesión para guardar las tuyas.'),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => Navigator.of(context).push(
              FadeSlideRoute(builder: (_) => const LoginScreen()),
            ),
            child: const Text('Iniciar sesión'),
          ),
        ],
      ),
    );
  }
}
