import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/run_model.dart';
import '../models/user_profile.dart';

/// All Firestore reads/writes for a user's runs and profile
/// (see CLAUDE.md > services/).
///
/// Writes are deliberately not awaited: they land in Firestore's local
/// cache right away (so the UI updates immediately) and sync when there's
/// signal. Awaiting them waits for the server ack, which hung "Finalizar"
/// forever when a run ended without connectivity.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _runs(String uid) =>
      _db.collection('users').doc(uid).collection('runs');

  void _logErrors(Future<void> write, String what) {
    write.then<void>((_) {}, onError: (Object e) => debugPrint('$what failed: $e'));
  }

  /// Returns the new run's id. The id is generated client-side (`doc()`
  /// with no path), so it's known immediately even offline — the detail
  /// screen shown right after a run can already offer "Eliminar".
  String saveRun(String uid, RunModel run) {
    final ref = _runs(uid).doc();
    _logErrors(ref.set(run.toMap()), 'saveRun');
    return ref.id;
  }

  /// Puts a just-deleted run back under its original id ("Deshacer").
  void restoreRun(String uid, RunModel run) {
    _logErrors(_runs(uid).doc(run.id).set(run.toMap()), 'restoreRun');
  }

  void deleteRun(String uid, String runId) {
    _logErrors(_runs(uid).doc(runId).delete(), 'deleteRun');
  }

  Stream<List<RunModel>> watchRuns(String uid) {
    return _runs(uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => RunModel.fromMap(d.id, d.data())).toList());
  }

  /// Emits null until the user saves their profile for the first time.
  Stream<UserProfile?> watchProfile(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      final raw = doc.data()?['profile'];
      return raw == null ? null : UserProfile.fromMap(Map<String, dynamic>.from(raw as Map));
    });
  }

  void saveProfile(String uid, UserProfile profile) {
    // merge: keep any other fields that may live on the user doc later.
    _logErrors(
      _db.collection('users').doc(uid).set({'profile': profile.toMap()}, SetOptions(merge: true)),
      'saveProfile',
    );
  }
}
