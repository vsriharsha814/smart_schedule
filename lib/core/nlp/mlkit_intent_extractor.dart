import 'package:google_mlkit_entity_extraction/google_mlkit_entity_extraction.dart';

import 'event_intent.dart';

/// Phase IV: Basic on-device intent extraction using ML Kit Entity Extractor.
class MlkitIntentExtractor {
  MlkitIntentExtractor._();

  static final MlkitIntentExtractor instance = MlkitIntentExtractor._();

  final EntityExtractor _extractor =
      EntityExtractor(language: EntityExtractorLanguage.english);
  final EntityExtractorModelManager _modelManager =
      EntityExtractorModelManager();

  Future<void> _ensureModel() async {
    final modelTag = EntityExtractorLanguage.english.name;
    final isDownloaded = await _modelManager.isModelDownloaded(modelTag);
    if (!isDownloaded) {
      await _modelManager.downloadModel(modelTag);
    }
  }

  /// Extracts an [EventIntent] from free-form text.
  Future<EventIntent> extract(String rawText) async {
    await _ensureModel();
    final trimmed = rawText.trim();
    if (trimmed.isEmpty) {
      return EventIntent(rawText: '');
    }

    DateTime? start;
    DateTime? end;
    String? location;

    final annotations = await _extractor.annotateText(trimmed);
    for (final a in annotations) {
      for (final e in a.entities) {
        switch (e.type) {
          case EntityType.dateTime:
            // Very naive: try to parse the raw value as ISO-like.
            final value = e.rawValue;
            if (value != null) {
              final parsed = DateTime.tryParse(value);
              if (parsed != null) {
                start ??= parsed;
                end ??= parsed.add(const Duration(hours: 1));
              }
            }
            break;
          case EntityType.address:
            location ??= e.rawValue;
            break;
          default:
            break;
        }
      }
    }

    // Simple title: first non-empty line.
    final lines = trimmed.split('\n').map((e) => e.trim()).toList();
    final title = lines.firstWhere(
      (l) => l.isNotEmpty,
      orElse: () => '',
    );

    return EventIntent(
      rawText: trimmed,
      title: title.isEmpty ? null : title,
      description: trimmed,
      start: start,
      end: end,
      allDay: false,
      location: location,
      locationRequired: location != null,
    );
  }
}

