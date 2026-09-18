/// Landing page copy, read from Firestore `content/landing` (see CLAUDE.md > CMS).
class LandingSection {
  final String title;
  final String body;
  final String imageUrl;

  const LandingSection({required this.title, required this.body, this.imageUrl = ''});

  factory LandingSection.fromMap(Map<String, dynamic> map) => LandingSection(
        title: map['title'] as String? ?? '',
        body: map['body'] as String? ?? '',
        imageUrl: map['image_url'] as String? ?? '',
      );
}

class LandingContent {
  final String heroTitle;
  final String heroSubtitle;
  final List<LandingSection> sections;

  const LandingContent({
    required this.heroTitle,
    required this.heroSubtitle,
    this.sections = const [],
  });

  factory LandingContent.fromMap(Map<String, dynamic> map) {
    final rawSections = (map['sections'] as List?) ?? const [];
    return LandingContent(
      heroTitle: map['hero_title'] as String? ?? '',
      heroSubtitle: map['hero_subtitle'] as String? ?? '',
      sections: rawSections
          .map((s) => LandingSection.fromMap(Map<String, dynamic>.from(s as Map)))
          .toList(),
    );
  }
}
