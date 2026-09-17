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
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5,
      ),
    );
  }
}
