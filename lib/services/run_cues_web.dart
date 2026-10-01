import 'dart:js_interop';

/// Web side of RunCues (see run_cues.dart): the Vibration API. Works in
/// Chrome on Android; desktop browsers and iOS Safari simply ignore it.
/// Uses dart:js_interop directly instead of adding package:web for one call.
@JS('navigator.vibrate')
external JSBoolean? _vibrate(JSArray<JSNumber> pattern);

void cue(List<int> pulses, {required int beepMs}) {
  try {
    _vibrate([for (final ms in pulses) ms.toJS].toJS);
  } catch (_) {
    // Not supported by this browser — nothing to do.
  }
}
