/// Phase II: Pending event draft for local persistence.
/// Survives process interruption (e.g. during NLP extraction).
enum DraftSource { manual, camera, voice }

class EventDraft {
  const EventDraft({
    this.id,
    required this.source,
    this.title,
    this.body,
    this.attachmentPath,
    required this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final DraftSource source;
  final String? title;
  final String? body;
  /// Local file path for camera image or voice recording.
  final String? attachmentPath;
  final DateTime createdAt;
  final DateTime? updatedAt;

  EventDraft copyWith({
    int? id,
    DraftSource? source,
    String? title,
    String? body,
    String? attachmentPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EventDraft(
      id: id ?? this.id,
      source: source ?? this.source,
      title: title ?? this.title,
      body: body ?? this.body,
      attachmentPath: attachmentPath ?? this.attachmentPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DraftSource sourceFromString(String? s) {
    switch (s) {
      case 'camera':
        return DraftSource.camera;
      case 'voice':
        return DraftSource.voice;
      default:
        return DraftSource.manual;
    }
  }

  static String sourceToString(DraftSource s) {
    switch (s) {
      case DraftSource.camera:
        return 'camera';
      case DraftSource.voice:
        return 'voice';
      case DraftSource.manual:
        return 'manual';
    }
  }
}
