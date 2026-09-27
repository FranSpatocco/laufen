import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/run_model.dart';

/// All Firestore reads/writes for a user's runs (see CLAUDE.md > services/).
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Deliberately not awaited: the write lands in Firestore's local cache
  /// right away (so History shows it immediately) and syncs when there's
  /// signal. Awaiting it waits for the server ack, which hung "Finalizar"
  /// forever when a run ended without connectivity.
  void saveRun(String uid, RunModel run) {
    _db
        .collection('users')
        .doc(uid)
        .collection('runs')
        .add(run.toMap())
        .then<void>((_) {}, onError: (Object e) => debugPrint('saveRun failed: $e'));
  }

  Stream<List<RunModel>> watchRuns(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('runs')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => RunModel.fromMap(d.id, d.data())).toList());
  }
}
