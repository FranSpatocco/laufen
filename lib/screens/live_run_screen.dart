import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/run_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../utils/formatters.dart';
import '../utils/theme.dart';
import '../widgets/stat_display.dart';
import 'run_detail_screen.dart';

enum _PermissionStatus { checking, granted, denied }

/// Live run: GPS tracking on a map with a running timer, distance and
/// pace, saved to Firestore on finish (see CLAUDE.md > Funcionalidad core).
class LiveRunScreen extends StatefulWidget {
  const LiveRunScreen({super.key});

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
  bool _isTracking = false;
  bool _isSaving = false;

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

  void _startRun() {
    _stopwatch.start();
    _uiTicker = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
    _positionSub = _locationService.positionStream().listen(_onPosition);
    setState(() => _isTracking = true);
  }

  void _onPosition(Position position) {
    // Reject low-accuracy fixes (e.g. weak GPS signal indoors, falling back
    // to network/wifi positioning) — a single bad reading can jump the
    // route hundreds of km and wreck both the map and the distance math.
    if (position.accuracy > 30) return;

    final point = LatLng(position.latitude, position.longitude);
    if (_lastPosition != null) {
      _distanceMeters += Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        position.latitude,
        position.longitude,
      );
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

    setState(() => _isSaving = true);

    final run = RunModel(
      date: DateTime.now(),
      distanceKm: _distanceKm,
      durationSeconds: _stopwatch.elapsed.inSeconds,
      avgPaceMinPerKm: _avgPaceMinPerKm,
      route: _route,
    );

    final uid = AuthService().currentUser!.uid;
    await FirestoreService().saveRun(uid, run);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => RunDetailScreen(run: run)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Carrera en vivo')),
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
          options: MapOptions(
            initialCenter: _currentPosition!,
            initialZoom: 17,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.laufen.laufen',
            ),
            PolylineLayer(polylines: [
              // flutter_map asserts on an empty point list when computing
              // bounds for culling, so only draw once there's a real line.
              if (_route.length >= 2)
                Polyline(points: _route, strokeWidth: 4, color: AppTheme.accentOrange),
            ]),
            MarkerLayer(markers: [
              Marker(
                point: _currentPosition!,
                width: 20,
                height: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.accentOrange,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ]),
          ],
        ),
        if (_isTracking)
          Positioned(
            top: 16 + viewPadding.top,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    StatDisplay(
                      value: RunFormatters.duration(_stopwatch.elapsed.inSeconds),
                      label: 'Tiempo',
                    ),
                    StatDisplay(value: RunFormatters.distanceKm(_distanceKm), label: 'Distancia'),
                    StatDisplay(value: RunFormatters.pace(_avgPaceMinPerKm), label: 'Pace'),
                  ],
                ),
              ),
            ),
          ),
        Positioned(
          bottom: 24 + viewPadding.bottom,
          left: 24,
          right: 24,
          child: _isTracking
              ? FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  onPressed: _isSaving ? null : _finishRun,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Finalizar'),
                )
              : FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.accentOrange,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  onPressed: _startRun,
                  child: const Text('Iniciar carrera'),
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
            const Text(
              'Laufen necesita acceso a tu ubicación para trackear la carrera.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
