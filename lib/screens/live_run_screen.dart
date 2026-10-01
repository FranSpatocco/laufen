import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/gps_calibration.dart';
import '../models/interval_plan.dart';
import '../models/km_split.dart';
import '../models/run_model.dart';
import '../models/training_type.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../services/run_cues.dart';
import '../utils/formatters.dart';
import '../utils/page_transitions.dart';
import '../utils/theme.dart';
import '../widgets/stat_display.dart';
import 'login_screen.dart';
import 'run_detail_screen.dart';

enum _PermissionStatus { checking, granted, denied }

/// Live run: GPS tracking on a map with a running timer, distance and
/// pace (see CLAUDE.md > Funcionalidad core). On finish the user chooses
/// whether to save it; saving needs an account, so a guest is sent to log
/// in first and the run is saved as soon as they come back signed in.
///
/// With an [intervalPlan] (TrainingType.intervals) it also shows a big
/// "CORRÉ / CAMINÁ" banner with the countdown of the current stretch, and
/// buzzes + beeps on every change so the runner doesn't need to look.
class LiveRunScreen extends StatefulWidget {
  final TrainingType trainingType;
  final IntervalPlan? intervalPlan;

  const LiveRunScreen({super.key, this.trainingType = TrainingType.freeRun, this.intervalPlan});

  @override
  State<LiveRunScreen> createState() => _LiveRunScreenState();
}

class _LiveRunScreenState extends State<LiveRunScreen> {
  final _locationService = LocationService();
  final _mapController = MapController();
  final _stopwatch = Stopwatch();

  StreamSubscription<Position>? _positionSub;
  Timer? _uiTicker;

  _PermissionStatus _status = _PermissionStatus.checking;
  LatLng? _currentPosition;
  final List<LatLng> _route = [];
  Position? _lastPosition;
  double _distanceMeters = 0;
  final _splitTracker = KmSplitTracker();
  bool _isTracking = false;
  bool _isFinished = false;
  IntervalPhase? _lastPhase;

  /// Between tapping "Iniciar" and the run actually starting: waiting for
  /// a precise GPS fix (see GpsCalibration). The stopwatch isn't running.
  bool _isCalibrating = false;
  GpsCalibration? _calibration;
  final _calibrationClock = Stopwatch();
  Position? _lastCalibrationFix;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _uiTicker?.cancel();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    setState(() => _status = _PermissionStatus.checking);
    final granted = await _locationService.ensurePermission();
    if (!granted) {
      setState(() => _status = _PermissionStatus.denied);
      return;
    }
    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _status = _PermissionStatus.granted;
      _currentPosition = LatLng(position.latitude, position.longitude);
    });
  }

  /// "Iniciar": listen to the GPS but don't start the clock until the
  /// signal is precise — otherwise the first seconds of a run (and its
  /// first km split) are built on a fix that can be 50+ m off.
  void _startCalibration() {
    _calibration = GpsCalibration(requiredGoodFixes: kIsWeb ? 1 : 2);
    _calibrationClock
      ..reset()
      ..start();
    _positionSub = _locationService.calibrationStream().listen(_onPosition);
    // Also re-checks readiness while no new fix arrives (the minimum time
    // can pass between two fixes).
    _uiTicker = Timer.periodic(const Duration(milliseconds: 250), (_) => _checkCalibration());
    setState(() => _isCalibrating = true);
  }

  void _cancelCalibration() {
    _positionSub?.cancel();
    _uiTicker?.cancel();
    _calibrationClock.stop();
    setState(() => _isCalibrating = false);
  }

  void _checkCalibration() {
    if (!_isCalibrating) return;
    if (_calibration!.isReady(_calibrationClock.elapsed)) {
      _beginTracking();
    } else {
      setState(() {});
    }
  }

  /// Calibrated (or "Empezar igual"): start the clock and confirm with a
  /// buzz, so the runner knows it's live without looking at the screen.
  void _beginTracking() {
    _uiTicker?.cancel();
    _calibrationClock.stop();
    // Swap the unfiltered calibration stream for the tracking one (5 m
    // distance filter + screen-off/background setup).
    _positionSub?.cancel();
    _positionSub = _locationService.positionStream().listen(_onPosition);
    // Seed the route with the last calibration fix, if it's usable, so the
    // first segment counts from where the runner actually started.
    final seed = _lastCalibrationFix;
    if (seed != null && seed.accuracy <= _maxUsableAccuracyMeters) {
      _lastPosition = seed;
      _route.add(LatLng(seed.latitude, seed.longitude));
    }
    _stopwatch.start();
    _lastPhase = widget.intervalPlan?.statusAt(0).phase;
    _uiTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      _cueIntervalChange();
      setState(() {});
    });
    RunCues.runStarted();
    setState(() {
      _isCalibrating = false;
      _isTracking = true;
    });
  }

  void _cueIntervalChange() {
    final plan = widget.intervalPlan;
    if (plan == null) return;
    final phase = plan.statusAt(_stopwatch.elapsed.inSeconds).phase;
    if (_lastPhase != null && phase != _lastPhase) RunCues.phaseChanged(phase);
    _lastPhase = phase;
  }

  /// Fixes worse than this are dropped while tracking (see _onPosition).
  static const _maxUsableAccuracyMeters = 30.0;

  /// No recreational runner sustains this — a jump faster than this between
  /// two fixes is a GPS glitch, not real movement.
  static const _maxPlausibleSpeedMetersPerSecond = 8.0;

  void _onPosition(Position position) {
    if (_isCalibrating) {
      // On a phone, the first fix of a new stream can be a cached,
      // minutes-old one — it says nothing about the signal right now. Not
      // on the web: browsers re-report a still position with the time it
      // was first obtained, so this check would drop every valid fix.
      if (!kIsWeb && DateTime.now().difference(position.timestamp) > const Duration(seconds: 10)) return;
      _calibration!.addFix(position.accuracy);
      _lastCalibrationFix = position;
      final point = LatLng(position.latitude, position.longitude);
      _currentPosition = point;
      _mapController.move(point, _mapController.camera.zoom);
      _checkCalibration();
      return;
    }

    // Reject low-accuracy fixes (e.g. weak GPS signal indoors, falling back
    // to network/wifi positioning) — a single bad reading can jump the
    // route hundreds of km and wreck both the map and the distance math.
    if (position.accuracy > _maxUsableAccuracyMeters) return;

    final point = LatLng(position.latitude, position.longitude);
    if (_lastPosition != null) {
      final segmentMeters = Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        position.latitude,
        position.longitude,
      );
      final elapsedSeconds = position.timestamp.difference(_lastPosition!.timestamp).inMilliseconds / 1000;

      // A "good accuracy" GPS fix can still be a wild outlier (a jump to a
      // wrong spot far away) — occasionally seen with real GPS hardware.
      // Catch that by rejecting implausible speed instead of trusting
      // accuracy alone, and don't let the bad fix become the new reference
      // point for the next comparison.
      if (elapsedSeconds > 0 && segmentMeters / elapsedSeconds > _maxPlausibleSpeedMetersPerSecond) {
        return;
      }

      _distanceMeters += segmentMeters;
      // Split timing uses the stopwatch (not the GPS timestamp) so the
      // splits always add up to the run's total duration.
      _splitTracker.addSegment(segmentMeters, _stopwatch.elapsedMilliseconds / 1000);
    }
    _lastPosition = position;
    _route.add(point);
    setState(() => _currentPosition = point);
    _mapController.move(point, _mapController.camera.zoom);
  }

  double get _distanceKm => _distanceMeters / 1000;

  double get _avgPaceMinPerKm {
    if (_distanceKm <= 0) return 0;
    return (_stopwatch.elapsed.inSeconds / 60) / _distanceKm;
  }

  Future<void> _finishRun() async {
    _positionSub?.cancel();
    _uiTicker?.cancel();
    _stopwatch.stop();

    setState(() => _isFinished = true);

    final run = RunModel(
      date: DateTime.now(),
      distanceKm: _distanceKm,
      durationSeconds: _stopwatch.elapsed.inSeconds,
      avgPaceMinPerKm: _avgPaceMinPerKm,
      route: _route,
      type: widget.trainingType,
      splits: _splitTracker.finish(_stopwatch.elapsedMilliseconds / 1000),
      intervals: widget.intervalPlan,
    );

    await _askToSave(run);
  }

  /// Loops until the user either saves (signed in) or discards: backing
  /// out of the login screen returns to the question instead of silently
  /// losing the run.
  Future<void> _askToSave(RunModel run) async {
    final authService = AuthService();
    while (mounted) {
      final save = await showModalBottomSheet<bool>(
        context: context,
        isDismissible: false,
        enableDrag: false,
        // Bottom sheets stretch edge to edge by default — cap it on desktop.
        constraints: const BoxConstraints(maxWidth: 560),
        builder: (_) => _SaveRunSheet(run: run, isGuest: authService.currentUser == null),
      );
      if (!mounted) return;
      if (save != true) {
        Navigator.of(context).pop();
        return;
      }

      if (authService.currentUser == null) {
        await Navigator.of(context).push<bool>(
          FadeSlideRoute(
            builder: (_) => const LoginScreen(reason: 'Iniciá sesión o creá una cuenta para guardar tu carrera.'),
          ),
        );
        if (!mounted) return;
        if (authService.currentUser == null) continue;
      }

      final id = FirestoreService().saveRun(authService.currentUser!.uid, run);
      Navigator.of(context).pushReplacement(FadeSlideRoute(builder: (_) => RunDetailScreen(run: run.withId(id))));
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.trainingType.label)),
      body: switch (_status) {
        _PermissionStatus.checking => const Center(child: CircularProgressIndicator()),
        _PermissionStatus.denied => _PermissionDeniedView(onRetry: _checkPermission),
        _PermissionStatus.granted => _buildTrackingView(),
      },
    );
  }

  Widget _buildTrackingView() {
    // The map stays edge-to-edge, but overlays need to steer clear of the
    // status bar / gesture nav bar — Positioned ignores SafeArea, so we add
    // the system insets to its offsets by hand instead.
    final viewPadding = MediaQuery.of(context).padding;

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(initialCenter: _currentPosition!, initialZoom: 17),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.laufen.laufen',
            ),
            PolylineLayer(
              polylines: [
                // flutter_map asserts on an empty point list when computing
                // bounds for culling, so only draw once there's a real line.
                if (_route.length >= 2) Polyline(points: _route, strokeWidth: 4, color: AppTheme.accent),
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: _currentPosition!,
                  width: 20,
                  height: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        if (_isCalibrating)
          Positioned(
            top: 16 + viewPadding.top,
            left: 16,
            right: 16,
            child: _CalibrationCard(calibration: _calibration!, elapsed: _calibrationClock.elapsed),
          ),
        if (_isTracking)
          Positioned(
            top: 16 + viewPadding.top,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        StatDisplay(value: RunFormatters.duration(_stopwatch.elapsed.inSeconds), label: 'Tiempo'),
                        StatDisplay(value: RunFormatters.distanceKm(_distanceKm), label: 'Distancia'),
                        StatDisplay(value: RunFormatters.pace(_avgPaceMinPerKm), label: 'Pace'),
                      ],
                    ),
                    if (_splitTracker.completed.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Km ${_splitTracker.completed.length}: '
                        '${RunFormatters.pace(_splitTracker.completed.last.paceMinPerKm)}',
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(color: AppTheme.accentDark, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        if (widget.intervalPlan != null)
          Positioned(
            bottom: 96 + viewPadding.bottom,
            left: 24,
            right: 24,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: _IntervalBanner(
                  plan: widget.intervalPlan!,
                  // Before starting, preview the first stretch at 0:00.
                  status: widget.intervalPlan!.statusAt(_stopwatch.elapsed.inSeconds),
                  started: _isTracking,
                ),
              ),
            ),
          ),
        Positioned(
          bottom: 24 + viewPadding.bottom,
          left: 24,
          right: 24,
          child: _isCalibrating
              ? _CalibrationButtons(
                  canStartAnyway: _calibration!.canStartAnyway(_calibrationClock.elapsed),
                  onCancel: _cancelCalibration,
                  onStartAnyway: _beginTracking,
                )
              : _isTracking
              ? FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  onPressed: _isFinished ? null : _finishRun,
                  child: const Text('Finalizar'),
                )
              : FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  onPressed: _startCalibration,
                  child: Text(widget.intervalPlan != null ? 'Iniciar intervalos' : 'Iniciar carrera'),
                ),
        ),
      ],
    );
  }
}

class _PermissionDeniedView extends StatelessWidget {
  final VoidCallback onRetry;

  const _PermissionDeniedView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Laufen necesita acceso a tu ubicación para trackear la carrera.', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

class _SaveRunSheet extends StatelessWidget {
  final RunModel run;
  final bool isGuest;

  const _SaveRunSheet({required this.run, required this.isGuest});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '¡Buen entrenamiento!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                StatDisplay(value: RunFormatters.distanceKm(run.distanceKm), label: 'Distancia'),
                StatDisplay(value: RunFormatters.duration(run.durationSeconds), label: 'Tiempo'),
                StatDisplay(value: RunFormatters.pace(run.avgPaceMinPerKm), label: 'Pace'),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              '¿Querés guardar esta carrera?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (isGuest) ...[
              const SizedBox(height: 6),
              Text(
                'Para guardarla necesitás una cuenta: es gratis y te lleva un minuto.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.accent,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              icon: Icon(isGuest ? Icons.login : Icons.save_outlined),
              label: Text(isGuest ? 'Iniciar sesión y guardar' : 'Guardar carrera'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
              child: const Text('Descartar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntervalBanner extends StatelessWidget {
  final IntervalPlan plan;
  final IntervalStatus status;
  final bool started;

  const _IntervalBanner({required this.plan, required this.status, required this.started});

  @override
  Widget build(BuildContext context) {
    final running = status.phase == IntervalPhase.run;
    final color = running ? AppTheme.accent : AppTheme.walk;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 6))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(running ? Icons.directions_run : Icons.directions_walk, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // AnimatedSwitcher so the word itself swaps with a fade.
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        running ? 'CORRÉ' : 'CAMINÁ',
                        key: ValueKey(running),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    Text(
                      started
                          ? 'Ronda ${status.round}'
                          : '${RunFormatters.clock(plan.runSeconds)} correr · '
                                '${RunFormatters.clock(plan.walkSeconds)} caminar',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Text(
                RunFormatters.clock(status.remainingSeconds),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: started ? status.progress : 0,
              minHeight: 6,
              color: Colors.white,
              backgroundColor: Colors.white24,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalibrationCard extends StatelessWidget {
  final GpsCalibration calibration;
  final Duration elapsed;

  const _CalibrationCard({required this.calibration, required this.elapsed});

  @override
  Widget build(BuildContext context) {
    final accuracy = calibration.lastAccuracyMeters;
    final weak = calibration.canStartAnyway(elapsed);
    final quality = calibration.quality;
    final color = Color.lerp(Colors.red.shade400, AppTheme.walk, quality)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Calibrando GPS…',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  accuracy == null ? 'Buscando señal' : '± ${accuracy.round()} m',
                  style: TextStyle(fontWeight: FontWeight.w800, color: color),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: quality,
                minHeight: 6,
                color: color,
                backgroundColor: color.withValues(alpha: 0.15),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              weak
                  ? 'La señal está débil. Podés empezar igual: la distancia puede ser menos precisa.'
                  : 'Quedate quieto unos segundos, mejor al aire libre. La carrera arranca sola y el '
                        'celular vibra para avisarte.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalibrationButtons extends StatelessWidget {
  final bool canStartAnyway;
  final VoidCallback onCancel;
  final VoidCallback onStartAnyway;

  const _CalibrationButtons({required this.canStartAnyway, required this.onCancel, required this.onStartAnyway});

  @override
  Widget build(BuildContext context) {
    const padding = EdgeInsets.symmetric(vertical: 18);
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(padding: padding, backgroundColor: Colors.white),
            onPressed: onCancel,
            child: const Text('Cancelar'),
          ),
        ),
        if (canStartAnyway) ...[
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppTheme.accent, padding: padding),
              onPressed: onStartAnyway,
              child: const Text('Empezar igual'),
            ),
          ),
        ],
      ],
    );
  }
}
