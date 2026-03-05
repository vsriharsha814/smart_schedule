import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class EventRecord {
  const EventRecord({
    this.id,
    required this.title,
    required this.description,
    required this.start,
    required this.end,
    this.location,
    required this.createdAt,
  });

  final int? id;
  final String title;
  final String description;
  final DateTime start;
  final DateTime end;
  final String? location;
  final DateTime createdAt;
}

/// Local log of events this app created in Google Calendar.
class EventsStore {
  EventsStore({Database? db}) : _db = db;

  Database? _db;

  static const _dbName = 'smart_schedule_events.db';
  static const _table = 'events';

  Future<Database> get _database async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    _db = await openDatabase(
      join(dir.path, _dbName),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_table (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT NOT NULL,
            start INTEGER NOT NULL,
            end INTEGER NOT NULL,
            location TEXT,
            created_at INTEGER NOT NULL
          )
        ''');
      },
    );
    return _db!;
  }

  Future<int> insert(EventRecord record) async {
    final db = await _database;
    return db.insert(_table, {
      'title': record.title,
      'description': record.description,
      'start': record.start.millisecondsSinceEpoch,
      'end': record.end.millisecondsSinceEpoch,
      'location': record.location,
      'created_at': record.createdAt.millisecondsSinceEpoch,
    });
  }

  Future<List<EventRecord>> getAll() async {
    final db = await _database;
    final rows = await db.query(
      _table,
      orderBy: 'start DESC',
    );
    return rows
        .map(
          (m) => EventRecord(
            id: m['id'] as int?,
            title: m['title'] as String,
            description: m['description'] as String,
            start: DateTime.fromMillisecondsSinceEpoch(m['start'] as int),
            end: DateTime.fromMillisecondsSinceEpoch(m['end'] as int),
            location: m['location'] as String?,
            createdAt:
                DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
          ),
        )
        .toList();
  }
}

