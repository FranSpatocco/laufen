import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Wraps geolocator's permission handling and live position stream
/// used by the live-run screen (see CLAUDE.md > Funcionalidad core).
class LocationService {
  /// Returns true if permission is granted and location services are on.
  Future<bool> ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }

  Stream<Position> positionStream() {
    return Geolocator.getPositionStream(locationSettings: _runSettings());
  }

  /// A run lasts far longer than the screen timeout, and the OS stops
  /// delivering GPS to a backgrounded app — the timer kept going while the
  /// distance froze. Each platform needs its own opt-in to keep tracking
  /// with the screen off; web can't do it at all (the tab must stay open).
  LocationSettings _runSettings() {
    const accuracy = LocationAccuracy.best;
    const distanceFilter = 5;

    if (kIsWeb) {
      return const LocationSettings(accuracy: accuracy, distanceFilter: distanceFilter);
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // A foreground service (with its mandatory notification) is what
        // Android requires to keep location flowing in the background. The
        // wake lock keeps the CPU running so the Dart side can process fixes.
        return AndroidSettings(
          accuracy: accuracy,
          distanceFilter: distanceFilter,
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationTitle: 'Laufen está registrando tu carrera',
            notificationText: 'La distancia y el ritmo siguen contando con la pantalla apagada.',
            notificationChannelName: 'Carrera en curso',
            enableWakeLock: true,
            setOngoing: true,
          ),
        );
      case TargetPlatform.iOS:
        // Needs UIBackgroundModes=location in Info.plist. Works with the
        // "while in use" permission because tracking starts in foreground.
        return AppleSettings(
          accuracy: accuracy,
          distanceFilter: distanceFilter,
          activityType: ActivityType.fitness,
          pauseLocationUpdatesAutomatically: false,
          allowBackgroundLocationUpdates: true,
          showBackgroundLocationIndicator: true,
        );
      default:
        return const LocationSettings(accuracy: accuracy, distanceFilter: distanceFilter);
    }
  }
}
