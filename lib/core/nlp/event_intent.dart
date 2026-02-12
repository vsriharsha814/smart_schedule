class EventIntent {
  final String rawText;
  final String? title;
  final String? description;
  final DateTime? start;
  final DateTime? end;
  final bool allDay;
  final String? location;
  final bool locationRequired;

  const EventIntent({
    required this.rawText,
    this.title,
    this.description,
    this.start,
    this.end,
    this.allDay = false,
    this.location,
    this.locationRequired = false,
  });

  EventIntent copyWith({
    String? rawText,
    String? title,
    String? description,
    DateTime? start,
    DateTime? end,
    bool? allDay,
    String? location,
    bool? locationRequired,
  }) {
    return EventIntent(
      rawText: rawText ?? this.rawText,
      title: title ?? this.title,
      description: description ?? this.description,
      start: start ?? this.start,
      end: end ?? this.end,
      allDay: allDay ?? this.allDay,
      location: location ?? this.location,
      locationRequired: locationRequired ?? this.locationRequired,
    );
  }
}

