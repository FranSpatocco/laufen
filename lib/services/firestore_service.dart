import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/run_model.dart';

/// All Firestore reads/writes for a user's runs (see CLAUDE.md > services/).
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> saveRun(String uid, RunModel run) {
    return _db.collection('users').doc(uid).collection('runs').add(run.toMap());
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
