import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Android/iOS side of RunCues (see run_cues.dart).
const _channel = MethodChannel('laufen/run_cues');

void cue(List<int> pulses, {required int beepMs}) {
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      // Android's waveform format starts with an initial delay, hence the 0.
      _invoke('vibrate', {'pattern': [0, ...pulses]});
      _invoke('beep', {'durationMs': beepMs});
    case TargetPlatform.iOS:
      // iOS doesn't allow custom vibration lengths without Core Haptics;
      // a heavy impact per pulse + the system alert sound is the closest.
      for (var i = 0; i < pulses.length; i += 2) {
        Future.delayed(
          Duration(milliseconds: pulses.take(i).fold(0, (a, b) => a + b)),
          HapticFeedback.heavyImpact,
        );
      }
      SystemSound.play(SystemSoundType.alert);
    default:
      break;
  }
}

void _invoke(String method, Map<String, Object> args) {
  // A missing cue must never break a run (e.g. widget tests, where no
  // platform side is registered) — log and move on.
  _channel.invokeMethod<void>(method, args).catchError((Object e) => debugPrint('run cue failed: $e'));
}
