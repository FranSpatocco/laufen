import 'package:flutter/material.dart';
import '../models/content_model.dart';
import '../services/content_service.dart';
import '../utils/constants.dart';
import '../utils/page_transitions.dart';
import '../utils/theme.dart';
import 'login_screen.dart';

/// Public landing page. Reads its copy from Firestore `content/landing`
/// (see CLAUDE.md > CMS) and falls back to the built-in AppStrings copy
/// while that document doesn't exist yet or hasn't loaded.
class LandingScreen extends StatelessWidget {
  final Stream<LandingContent?> contentStream;

  LandingScreen({super.key, Stream<LandingContent?>? contentStream})
      : contentStream = contentStream ?? ContentService().watchLandingContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<LandingContent?>(
          stream: contentStream,
          builder: (context, snapshot) {
            final content = snapshot.data;
            final heroTitle = content?.heroTitle.isNotEmpty == true
                ? content!.heroTitle
                : AppStrings.heroTitle;
            final heroSubtitle = content?.heroSubtitle.isNotEmpty == true
                ? content!.heroSubtitle
                : AppStrings.heroSubtitle;
            final sections = content?.sections ?? const [];

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 48),
                  Text(
                    AppStrings.appName,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accent,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    heroTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    heroSubtitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    onPressed: () => Navigator.of(context).push(
                      FadeSlideRoute(builder: (_) => const LoginScreen()),
                    ),
                    child: const Text('Empezar'),
                  ),
                  if (sections.isNotEmpty) ...[
                    const SizedBox(height: 56),
                    for (final section in sections) _LandingSectionCard(section: section),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
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
      padding: const EdgeInsets.only(bottom: 32),
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
