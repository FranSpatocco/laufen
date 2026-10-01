import '../models/run_model.dart';
import '../models/sample_run.dart';
import 'firestore_service.dart';

/// Single source of "which runs does this screen show": the user's own
/// runs from Firestore when signed in, or the built-in example run for a
/// guest. Keeps the guest/signed-in branching out of the widgets.
class RunsService {
  Stream<List<RunModel>> watchRuns(String? uid) {
    if (uid == null) return Stream.value([SampleRun.run]);
    return FirestoreService().watchRuns(uid);
  }
}
