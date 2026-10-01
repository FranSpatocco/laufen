import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../utils/formatters.dart';
import '../utils/theme.dart';

/// Landing hero visual: a stylized map where a run's route draws itself and
/// a runner dot travels along it while the stats count up — a preview of
/// what the live-run screen does, playing on a loop.
///
/// It's the Flutter take on GSAP's DrawSVG + MotionPath: the route is a
/// [Path], and each frame we paint only the first `progress` fraction of it
/// with [PathMetric.extractPath], placing the dot at that point's tangent.
/// No animation package — just an AnimationController and a CustomPainter.
class AnimatedRouteCard extends StatefulWidget {
  /// Played once before the loop starts, so the card fades in as part of
  /// the landing's intro timeline instead of popping in.
  final Animation<double> entrance;

  const AnimatedRouteCard({super.key, required this.entrance});

  @override
  State<AnimatedRouteCard> createState() => _AnimatedRouteCardState();
}

class _AnimatedRouteCardState extends State<AnimatedRouteCard> with SingleTickerProviderStateMixin {
  // Each loop: draw the route (0 → 0.75), hold the finished run, then restart.
  late final AnimationController _loop =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 6000))..repeat();

  late final Animation<double> _draw = CurvedAnimation(
    parent: _loop,
    curve: const Interval(0, 0.75, curve: Curves.easeInOutSine),
  );

  // Mouse-driven tilt on desktop: the target comes from hover position and
  // TweenAnimationBuilder eases towards it, so the card never jumps.
  Offset _tilt = Offset.zero;

  static const _sampleKm = 5.21;
  static const _sampleSeconds = 1705;

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entrance = CurvedAnimation(parent: widget.entrance, curve: Curves.easeOutCubic);

    return MouseRegion(
      onHover: (event) {
        final size = context.size;
        if (size == null) return;
        setState(() {
          _tilt = Offset(
            (event.localPosition.dx / size.width - 0.5) * 2,
            (event.localPosition.dy / size.height - 0.5) * 2,
          );
        });
      },
      onExit: (_) => setState(() => _tilt = Offset.zero),
      child: AnimatedBuilder(
        animation: entrance,
        builder: (context, child) => Opacity(
          opacity: entrance.value,
          child: Transform.scale(scale: 0.92 + 0.08 * entrance.value, child: child),
        ),
        child: TweenAnimationBuilder<Offset>(
          tween: Tween(end: _tilt),
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
          builder: (context, tilt, child) => Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateX(-tilt.dy * 0.08)
              ..rotateY(tilt.dx * 0.08),
            child: child,
          ),
          child: _buildCard(context),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFBF8F2),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentDark.withValues(alpha: 0.18),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: AnimatedBuilder(
        animation: _draw,
        builder: (context, _) {
          final progress = _draw.value;
          return Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: _RoutePainter(progress: progress))),
              Positioned(
                top: 16,
                left: 16,
                child: _LivePill(finished: progress >= 1),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: _StatsStrip(
                  km: _sampleKm * progress,
                  seconds: (_sampleSeconds * progress).round(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LivePill extends StatelessWidget {
  final bool finished;

  const _LivePill({required this.finished});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: finished ? AppTheme.accentDark : Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            finished ? Icons.check_circle : Icons.circle,
            size: finished ? 14 : 9,
            color: finished ? Colors.white : Colors.red.shade500,
          ),
          const SizedBox(width: 6),
          Text(
            finished ? 'Carrera guardada' : 'En vivo',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: finished ? Colors.white : AppTheme.accentDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsStrip extends StatelessWidget {
  final double km;
  final int seconds;

  const _StatsStrip({required this.km, required this.seconds});

  @override
  Widget build(BuildContext context) {
    final pace = km > 0.05 ? (seconds / 60) / km : 0.0;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          _MiniStat(value: km.toStringAsFixed(2), label: 'km'),
          _MiniStat(value: RunFormatters.duration(seconds), label: 'tiempo'),
          _MiniStat(value: RunFormatters.pace(pace).replaceAll(' /km', ''), label: 'min/km'),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String value;
  final String label;

  const _MiniStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2B211B),
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

/// Paints a minimal "map" (blocks, a park, a river) and the route on top.
/// Everything is laid out in a 0..1 unit square and scaled to the canvas,
/// so it looks the same on a phone and on a wide desktop card.
class _RoutePainter extends CustomPainter {
  final double progress;

  _RoutePainter({required this.progress});

  // A loop around a park, roughly the shape of a real 5 km run.
  static const _points = [
    Offset(0.22, 0.62),
    Offset(0.18, 0.44),
    Offset(0.26, 0.27),
    Offset(0.42, 0.20),
    Offset(0.58, 0.24),
    Offset(0.70, 0.18),
    Offset(0.82, 0.28),
    Offset(0.80, 0.45),
    Offset(0.70, 0.56),
    Offset(0.74, 0.66),
    Offset(0.60, 0.72),
    Offset(0.44, 0.66),
    Offset(0.32, 0.71),
    Offset(0.22, 0.62),
  ];

  Path _routePath(Size size) {
    Offset p(Offset o) => Offset(o.dx * size.width, o.dy * size.height);
    final path = Path()..moveTo(p(_points[0]).dx, p(_points[0]).dy);
    // Quadratic curves through midpoints: a smooth line that still passes
    // near every control point, like a GPS track after smoothing.
    for (var i = 1; i < _points.length - 1; i++) {
      final control = p(_points[i]);
      final mid = Offset.lerp(control, p(_points[i + 1]), 0.5)!;
      path.quadraticBezierTo(control.dx, control.dy, mid.dx, mid.dy);
    }
    final last = p(_points.last);
    path.lineTo(last.dx, last.dy);
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    _paintMap(canvas, size);

    final route = _routePath(size);
    final metric = route.computeMetrics().first;
    final width = math.max(4.0, size.shortestSide * 0.018);

    // Faint full route underneath, so the shape reads before it's drawn.
    canvas.drawPath(
      route,
      Paint()
        ..color = AppTheme.accent.withValues(alpha: 0.14)
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final drawn = metric.extractPath(0, metric.length * progress);
    canvas.drawPath(
      drawn,
      Paint()
        ..color = AppTheme.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Start marker.
    final start = metric.getTangentForOffset(0)!.position;
    canvas.drawCircle(start, width * 1.4, Paint()..color = Colors.white);
    canvas.drawCircle(start, width * 0.9, Paint()..color = AppTheme.accentDark);

    // Runner dot with a pulsing halo at the tip of the drawn line.
    final tip = metric.getTangentForOffset(metric.length * progress)!.position;
    final pulse = (math.sin(progress * math.pi * 24) + 1) / 2;
    canvas.drawCircle(
      tip,
      width * (2.4 + pulse * 1.4),
      Paint()..color = AppTheme.accent.withValues(alpha: 0.18 + 0.1 * (1 - pulse)),
    );
    canvas.drawCircle(tip, width * 1.5, Paint()..color = Colors.white);
    canvas.drawCircle(tip, width * 1.05, Paint()..color = AppTheme.accent);
  }

  void _paintMap(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Street grid.
    final street = Paint()
      ..color = const Color(0xFFE9E1D3)
      ..strokeWidth = math.max(2, size.shortestSide * 0.012);
    for (var i = 1; i < 6; i++) {
      final x = w * i / 6 + (i.isEven ? 6 : -4);
      canvas.drawLine(Offset(x, 0), Offset(x - w * 0.06, h), street);
      final y = h * i / 6 + (i.isOdd ? 5 : -3);
      canvas.drawLine(Offset(0, y), Offset(w, y + h * 0.04), street);
    }

    // Park in the middle of the loop.
    final park = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.32, h * 0.32, w * 0.66, h * 0.58),
      Radius.circular(size.shortestSide * 0.08),
    );
    canvas.drawRRect(park, Paint()..color = const Color(0xFFDDE5CC));

    // River crossing the corner.
    final river = Path()
      ..moveTo(w * 0.62, h)
      ..quadraticBezierTo(w * 0.86, h * 0.78, w, h * 0.8);
    canvas.drawPath(
      river,
      Paint()
        ..color = const Color(0xFFCFDDE3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.shortestSide * 0.07,
    );
  }

  @override
  bool shouldRepaint(_RoutePainter oldDelegate) => oldDelegate.progress != progress;
}
