import 'package:flutter/material.dart';

/// Fade + slide-up entrance with an optional delay — the building block for
/// the staggered ("GSAP-style") entrances on Inicio, Entrenar and Perfil.
///
/// The delay is folded into the controller itself (an [Interval] that only
/// starts moving after `delay`) instead of a `Future.delayed`: no pending
/// timers, so widget tests don't fail on leftover timers, and disposing
/// mid-delay is free.
class Reveal extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offsetY;

  const Reveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 520),
    this.offsetY = 24,
  });

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    final total = widget.delay + widget.duration;
    _controller = AnimationController(vsync: this, duration: total)..forward();
    final start = total.inMicroseconds == 0 ? 0.0 : widget.delay.inMicroseconds / total.inMicroseconds;
    _progress = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, 1, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _progress.value,
        child: Transform.translate(
          offset: Offset(0, widget.offsetY * (1 - _progress.value)),
          child: child,
        ),
      ),
    );
  }
}
