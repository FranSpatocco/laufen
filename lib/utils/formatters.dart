/// Shared formatting for run stats, used by live-run, history, detail and
/// dashboard screens so the numbers always read the same way.
class RunFormatters {
  static String duration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  static String distanceKm(double km) => '${km.toStringAsFixed(2)} km';

  /// avgPaceMinPerKm is a decimal number of minutes (e.g. 5.5 = 5:30 min/km).
  static String pace(double avgPaceMinPerKm) {
    if (!avgPaceMinPerKm.isFinite || avgPaceMinPerKm <= 0) return '--:--';
    // Round the total seconds first — rounding only the seconds part turns
    // e.g. 5.999 into "5:60" instead of "6:00".
    final totalSeconds = (avgPaceMinPerKm * 60).round();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')} /km';
  }
}
