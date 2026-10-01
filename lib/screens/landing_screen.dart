import 'package:flutter/material.dart';
import '../models/content_model.dart';
import '../services/content_service.dart';
import '../utils/constants.dart';
import '../utils/page_transitions.dart';
import '../utils/theme.dart';
import '../widgets/animated_route_card.dart';
import '../widgets/laufen_wordmark.dart';
import 'login_screen.dart';

/// Public landing page. Reads its copy from Firestore `content/landing`
/// (see CLAUDE.md > CMS) and falls back to the built-in AppStrings copy
/// while that document doesn't exist yet or hasn't loaded.
///
/// "Empezar" goes straight into the app as a guest — no login wall, so a
/// visitor sees the product in one click. Signing in is offered later,
/// when there's something worth saving (see live_run_screen.dart).
class LandingScreen extends StatefulWidget {
  final Stream<LandingContent?>? contentStream;
  final VoidCallback onStart;

  const LandingScreen({super.key, this.contentStream, required this.onStart});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

/// Above this width the hero splits into text + animated map side by side.
const _wideBreakpoint = 900.0;

class _LandingScreenState extends State<LandingScreen> with SingleTickerProviderStateMixin {
  late final Stream<LandingContent?> _content =
      widget.contentStream ?? ContentService().watchLandingContent();

  /// One controller drives the whole intro, like a GSAP timeline: every
  /// element gets its own [Interval] slice of it, so the stagger/overlap
  /// between elements is declared in one place and stays in sync.
  late final AnimationController _intro =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..forward();

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  Animation<double> _slice(double begin, double end, [Curve curve = Curves.easeOutCubic]) {
    // Clamped so a long CMS title (many words) can't push a slice past the
    // end of the timeline or collapse it to zero length.
    final b = begin.clamp(0.0, 0.9);
    final e = end.clamp(b + 0.05, 1.0);
    return CurvedAnimation(parent: _intro, curve: Interval(b, e, curve: curve));
  }

  Future<void> _openLogin() async {
    final loggedIn = await Navigator.of(context).push<bool>(
      FadeSlideRoute(builder: (_) => const LoginScreen()),
    );
    if (loggedIn == true) widget.onStart();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.7, -0.6),
            radius: 1.3,
            colors: [Color(0xFFF7E9D9), Color(0xFFF3EEE4)],
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<LandingContent?>(
            stream: _content,
            builder: (context, snapshot) {
              final content = snapshot.data;
              final heroTitle = content?.heroTitle.isNotEmpty == true
                  ? content!.heroTitle
                  : AppStrings.heroTitle;
              final heroSubtitle = content?.heroSubtitle.isNotEmpty == true
                  ? content!.heroSubtitle
                  : AppStrings.heroSubtitle;
              final sections = content?.sections ?? const [];

              return LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= _wideBreakpoint;
                  final hero = wide
                      ? _buildWideHero(context, heroTitle, heroSubtitle)
                      : _buildNarrowHero(context, heroTitle, heroSubtitle);

                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(minHeight: constraints.maxHeight),
                          child: Center(child: hero),
                        ),
                        if (sections.isNotEmpty) ...[
                          for (final section in sections) _LandingSectionCard(section: section),
                          const SizedBox(height: 24),
                        ],
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildWideHero(BuildContext context, String title, String subtitle) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1200),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 40),
        child: Row(
          children: [
            Expanded(
              flex: 11,
              child: _HeroText(
                title: title,
                subtitle: subtitle,
                wide: true,
                slice: _slice,
                intro: _intro,
                onStart: widget.onStart,
                onLogin: _openLogin,
              ),
            ),
            const SizedBox(width: 56),
            Expanded(
              flex: 10,
              child: AspectRatio(
                aspectRatio: 0.95,
                child: AnimatedRouteCard(entrance: _slice(0.3, 0.75)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNarrowHero(BuildContext context, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          children: [
            _HeroText(
              title: title,
              subtitle: subtitle,
              wide: false,
              slice: _slice,
              intro: _intro,
              onStart: widget.onStart,
              onLogin: _openLogin,
            ),
            const SizedBox(height: 28),
            // On phones the animated card goes right under the CTA (above
            // the feature chips) so it's visible without scrolling.
            SizedBox(
              height: 260,
              child: AnimatedRouteCard(entrance: _slice(0.45, 0.85)),
            ),
            const SizedBox(height: 24),
            _FeatureChips(wide: false, slice: _slice),
          ],
        ),
      ),
    );
  }
}

class _HeroText extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool wide;
  final Animation<double> Function(double begin, double end, [Curve curve]) slice;
  final AnimationController intro;
  final VoidCallback onStart;
  final VoidCallback onLogin;

  const _HeroText({
    required this.title,
    required this.subtitle,
    required this.wide,
    required this.slice,
    required this.intro,
    required this.onStart,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    final align = wide ? CrossAxisAlignment.start : CrossAxisAlignment.center;
    final textAlign = wide ? TextAlign.start : TextAlign.center;
    final wrapAlign = wide ? WrapAlignment.start : WrapAlignment.center;
    final words = title.split(' ').where((w) => w.isNotEmpty).toList();
    final titleStyle = (wide
            ? Theme.of(context).textTheme.displayMedium
            : Theme.of(context).textTheme.headlineLarge)
        ?.copyWith(fontWeight: FontWeight.w800, height: 1.08, color: const Color(0xFF2B211B));

    return Column(
      crossAxisAlignment: align,
      children: [
        LaufenWordmark(
          fontSize: wide ? 64 : 48,
          color: AppTheme.accent,
          reveal: slice(0, 0.45),
        ),
        SizedBox(height: wide ? 28 : 20),
        // Word-by-word stagger, each word on its own slice of the timeline.
        Wrap(
          alignment: wrapAlign,
          children: [
            for (var i = 0; i < words.length; i++)
              _SlideUp(
                animation: slice(0.22 + i * 0.07, 0.52 + i * 0.07),
                offsetY: 28,
                child: Text(
                  i == words.length - 1 ? words[i] : '${words[i]} ',
                  style: i == words.length - 1 ? titleStyle?.copyWith(color: AppTheme.accent) : titleStyle,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _SlideUp(
          animation: slice(0.42, 0.72),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Text(
              subtitle,
              textAlign: textAlign,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF5C4A3E),
                    height: 1.45,
                    fontWeight: FontWeight.w400,
                  ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        _PopIn(
          animation: slice(0.52, 0.86, Curves.easeOutBack),
          child: Wrap(
            alignment: wrapAlign,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              _StartButton(onPressed: onStart),
              TextButton(
                onPressed: onLogin,
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.accentDark,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                ),
                child: const Text('Ya tengo cuenta'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _SlideUp(
          animation: slice(0.62, 0.9),
          offsetY: 8,
          child: Text(
            'Sin registro: probala ya, guardá tus carreras cuando quieras.',
            textAlign: textAlign,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
          ),
        ),
        if (wide) ...[
          const SizedBox(height: 40),
          _FeatureChips(wide: true, slice: slice),
        ],
      ],
    );
  }
}

class _FeatureChips extends StatelessWidget {
  final bool wide;
  final Animation<double> Function(double begin, double end, [Curve curve]) slice;

  const _FeatureChips({required this.wide, required this.slice});

  static const _features = [
    (Icons.map_outlined, 'Mapa en vivo'),
    (Icons.timer_outlined, 'Ritmo por km'),
    (Icons.insights_outlined, 'Historial y récords'),
    (Icons.devices_outlined, 'Web · Android · iOS'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: wide ? WrapAlignment.start : WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < _features.length; i++)
          _SlideUp(
            animation: slice(0.66 + i * 0.06, 0.92 + i * 0.06),
            offsetY: 14,
            child: Chip(
              avatar: Icon(_features[i].$1, size: 18, color: AppTheme.accentDark),
              label: Text(_features[i].$2),
              backgroundColor: Colors.white.withValues(alpha: 0.75),
              side: BorderSide.none,
              shape: const StadiumBorder(),
            ),
          ),
      ],
    );
  }
}

/// Primary CTA with a hover lift on desktop — small, but it's what makes a
/// web page feel "alive" under the mouse.
class _StartButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _StartButton({required this.onPressed});

  @override
  State<_StartButton> createState() => _StartButtonState();
}

class _StartButtonState extends State<_StartButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        scale: _hover ? 1.04 : 1,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.accent,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            elevation: _hover ? 6 : 0,
            shadowColor: AppTheme.accent,
          ),
          onPressed: widget.onPressed,
          iconAlignment: IconAlignment.end,
          icon: AnimatedSlide(
            offset: Offset(_hover ? 0.25 : 0, 0),
            duration: const Duration(milliseconds: 180),
            child: const Icon(Icons.arrow_forward),
          ),
          label: const Text('Empezar'),
        ),
      ),
    );
  }
}

class _SlideUp extends StatelessWidget {
  final Animation<double> animation;
  final double offsetY;
  final Widget child;

  const _SlideUp({required this.animation, required this.child, this.offsetY = 20});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) => Opacity(
        opacity: animation.value.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(0, offsetY * (1 - animation.value)), child: child),
      ),
    );
  }
}

class _PopIn extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _PopIn({required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) => Opacity(
        opacity: animation.value.clamp(0.0, 1.0),
        child: Transform.scale(scale: 0.85 + 0.15 * animation.value, child: child),
      ),
    );
  }
}

class _LandingSectionCard extends StatelessWidget {
  final LandingSection section;

  const _LandingSectionCard({required this.section});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          children: [
            if (section.imageUrl.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    section.imageUrl,
                    errorBuilder: (context, error, stackTrace) => const SizedBox(),
                  ),
                ),
              ),
            Text(
              section.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              section.body,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
