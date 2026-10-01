import 'package:flutter/material.dart';
import '../models/run_model.dart';
import '../services/firestore_service.dart';
import '../utils/formatters.dart';

/// Shared "delete a run" flow for Historial (menu + swipe) and the run
/// detail screen, so both ask the same question and offer the same undo.
class RunDelete {
  static Future<bool> confirm(BuildContext context, RunModel run) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar esta carrera?'),
        content: Text(
          '${run.type.label} de ${RunFormatters.distanceKm(run.distanceKm)} del '
          '${RunFormatters.date(run.date)}. Se borra el mapa, los parciales y sus stats.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    return result == true;
  }

  /// Deletes right away and shows an undo snackbar. Uses the app-level
  /// ScaffoldMessenger, so the snackbar survives popping the detail screen.
  static void deleteWithUndo(BuildContext context, String uid, RunModel run, {VoidCallback? onUndo}) {
    final service = FirestoreService();
    final messenger = ScaffoldMessenger.of(context);
    // Full-width snackbars look stretched on desktop and cover the pager.
    final wide = MediaQuery.sizeOf(context).width >= 600;
    service.deleteRun(uid, run.id!);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Carrera eliminada'),
          behavior: SnackBarBehavior.floating,
          width: wide ? 420 : null,
          action: SnackBarAction(
            label: 'Deshacer',
            onPressed: () {
              service.restoreRun(uid, run);
              onUndo?.call();
            },
          ),
        ),
      );
  }
}
