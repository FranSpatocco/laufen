import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/content_model.dart';

/// Reads the landing page's CMS document (see CLAUDE.md > CMS). Widgets
/// never call Firestore directly — this is the only place that knows
/// about the `content/landing` document shape.
class ContentService {
  // A getter (not a field initializer) so constructing a ContentService
  // never touches Firebase — needed to keep LandingScreen testable without
  // initializing Firebase in widget tests (see test/widget_test.dart).
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// Emits null while the document doesn't exist yet, so the UI can fall
  /// back to its built-in copy instead of showing a blank page.
  Stream<LandingContent?> watchLandingContent() {
    return _db.collection('content').doc('landing').snapshots().map(
          (doc) => doc.exists ? LandingContent.fromMap(doc.data()!) : null,
        );
  }
}
