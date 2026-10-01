package com.laufen.laufen

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.ToneGenerator
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.VibrationAttributes
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Exposes the real system vibrator + a short beep to Dart over a platform
 * channel ("laufen/run_cues", see lib/services/run_cues.dart).
 *
 * Flutter's HapticFeedback only fires the few-millisecond touch "tick" of
 * a button press: Samsung turns it off with the system touch-feedback
 * setting, it needs a visible view (nothing happens with the screen off)
 * and it's impossible to feel while running. SystemSound.alert is a no-op
 * on Android. Doing it natively avoids adding a plugin dependency for two
 * calls.
 */
class MainActivity : FlutterActivity() {
    private val toneHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "laufen/run_cues")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "vibrate" -> {
                        val pattern = call.argument<List<Int>>("pattern") ?: listOf(0, 400)
                        vibrate(pattern.map { it.toLong() }.toLongArray())
                        result.success(null)
                    }
                    "beep" -> {
                        beep(call.argument<Int>("durationMs") ?: 250)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun vibrator(): Vibrator =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            (getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager).defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }

    /** [pattern]: off/on durations in ms, starting with a delay (Android's convention). */
    private fun vibrate(pattern: LongArray) {
        val vibrator = vibrator()
        if (!vibrator.hasVibrator()) return
        val effect = VibrationEffect.createWaveform(pattern, -1)
        // "Alarm" usage so the cue still goes through with the screen off
        // and with touch feedback disabled — the whole point is to notice
        // it mid-run without looking at the phone.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            vibrator.vibrate(effect, VibrationAttributes.createForUsage(VibrationAttributes.USAGE_ALARM))
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(
                effect,
                AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_ALARM).build(),
            )
        }
    }

    private fun beep(durationMs: Int) {
        val tone = ToneGenerator(AudioManager.STREAM_NOTIFICATION, 90)
        tone.startTone(ToneGenerator.TONE_PROP_BEEP2, durationMs)
        // ToneGenerator holds a native audio resource: free it once played.
        toneHandler.postDelayed({ tone.release() }, durationMs + 200L)
    }
}
