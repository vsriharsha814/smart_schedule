import 'dart:convert';

import 'package:http/http.dart' as http;

import '../identity/auth_service.dart';
import '../nlp/event_intent.dart';

/// Phase V: Direct Google Calendar integration using client-side HTTP.
class GoogleCalendarClient {
  GoogleCalendarClient(this._auth);

  final AuthService _auth;
  static const _baseUrl = 'https://www.googleapis.com/calendar/v3';

  Future<void> createEvent(EventIntent intent) async {
    final accessToken = await _auth.getAccessToken();
    if (accessToken == null) {
      throw StateError('No Google access token available.');
    }

    final now = DateTime.now();
    final start = intent.start ?? now;
    final end = intent.end ?? start.add(const Duration(hours: 1));

    final body = <String, dynamic>{
      'summary': intent.title ?? 'Untitled',
      'description': intent.description ?? intent.rawText,
      if (intent.location != null) 'location': intent.location,
      'start': {
        'dateTime': start.toUtc().toIso8601String(),
        'timeZone': 'UTC',
      },
      'end': {
        'dateTime': end.toUtc().toIso8601String(),
        'timeZone': 'UTC',
      },
    };

    final resp = await http.post(
      Uri.parse('$_baseUrl/calendars/primary/events'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (resp.statusCode >= 300) {
      throw StateError(
        'Calendar API error ${resp.statusCode}: ${resp.body}',
      );
    }
  }
}

