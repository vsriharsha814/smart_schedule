/// Phase II: Pending event draft for local persistence.
/// Survives process interruption (e.g. during NLP extraction).
enum DraftSource { manual, camera }

class EventDraft {
  const EventDraft({
    this.id,
    required this.source,
    this.title,
    this.body,
    this.attachmentPath,
    this.location,
    this.startAt,
    this.endAt,
    required this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final DraftSource source;
  final String? title;
  final String? body;
  /// Local file path for camera image.
  final String? attachmentPath;
  final String? location;
  final DateTime? startAt;
  final DateTime? endAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  EventDraft copyWith({
    int? id,
    DraftSource? source,
    String? title,
    String? body,
    String? attachmentPath,
    String? location,
    DateTime? startAt,
    DateTime? endAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EventDraft(
      id: id ?? this.id,
      source: source ?? this.source,
      title: title ?? this.title,
      body: body ?? this.body,
      attachmentPath: attachmentPath ?? this.attachmentPath,
      location: location ?? this.location,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DraftSource sourceFromString(String? s) {
    switch (s) {
      case 'camera':
        return DraftSource.camera;
      default:
        return DraftSource.manual;
    }
  }

  static String sourceToString(DraftSource s) {
    switch (s) {
      case DraftSource.camera:
        return 'camera';
      case DraftSource.manual:
        return 'manual';
    }
  }
}
