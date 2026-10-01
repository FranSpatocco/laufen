import '../models/interval_plan.dart';
import 'run_cues_io.dart' if (dart.library.js_interop) 'run_cues_web.dart' as platform;

/// Physical cues during a run — felt, not looked at: a strong vibration
/// (+ beep on Android) when tracking starts and on every interval change.
///
/// Patterns are lists of alternating on/off durations in ms, starting with
/// "on". Each platform implementation maps them to its own API: a native
/// Vibrator over a platform channel on Android (MainActivity.kt), system
/// haptics on iOS and navigator.vibrate on the web (Chrome on Android).
class RunCues {
  /// Long buzz: "you're live, the clock is running".
  static void runStarted() => platform.cue(const [700], beepMs: 300);

  /// Running: three short pulses (energetic). Walking: one long buzz
  /// (calm). Different on purpose, so the phase is clear without looking.
  static void phaseChanged(IntervalPhase phase) => phase == IntervalPhase.run
      ? platform.cue(const [220, 120, 220, 120, 220], beepMs: 180)
      : platform.cue(const [900], beepMs: 450);
}
