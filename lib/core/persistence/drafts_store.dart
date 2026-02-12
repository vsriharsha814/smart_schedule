import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'event_draft.dart';

/// Phase II: SQLite persistence for pending event drafts.
/// Ensures data remains intact if process is interrupted (e.g. during NLP).
class DraftsStore {
  DraftsStore({Database? db}) : _db = db;

  Database? _db;
  static const _dbName = 'smart_schedule_drafts.db';
  static const _table = 'drafts';

  Future<Database> get _database async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    _db = await openDatabase(
      join(dir.path, _dbName),
      version: 1,
      onCreate: _onCreate,
    );
    return _db!;
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_table (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        source TEXT NOT NULL,
        title TEXT,
        body TEXT,
        attachment_path TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER
      )
    ''');
  }

  Future<int> insert(EventDraft draft) async {
    final db = await _database;
    return db.insert(
      _table,
      _draftToMap(draft),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> update(EventDraft draft) async {
    if (draft.id == null) return 0;
    final db = await _database;
    return db.update(
      _table,
      _draftToMap(draft.copyWith(updatedAt: DateTime.now())),
      where: 'id = ?',
      whereArgs: [draft.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _database;
    return db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<EventDraft?> get(int id) async {
    final db = await _database;
    final maps = await db.query(_table, where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return _mapToDraft(maps.first);
  }

  Future<List<EventDraft>> getAll() async {
    final db = await _database;
    final maps = await db.query(_table, orderBy: 'updated_at DESC, created_at DESC');
    return maps.map(_mapToDraft).toList();
  }

  /// Stream of all drafts; yields current list. Callers can refresh and re-listen.
  Stream<List<EventDraft>> watchAll() async* {
    yield await getAll();
  }

  static Map<String, Object?> _draftToMap(EventDraft d) {
    return {
      'id': d.id,
      'source': EventDraft.sourceToString(d.source),
      'title': d.title,
      'body': d.body,
      'attachment_path': d.attachmentPath,
      'created_at': d.createdAt.millisecondsSinceEpoch,
      'updated_at': d.updatedAt?.millisecondsSinceEpoch,
    };
  }

  static EventDraft _mapToDraft(Map<String, Object?> m) {
    return EventDraft(
      id: m['id'] as int?,
      source: EventDraft.sourceFromString(m['source'] as String?),
      title: m['title'] as String?,
      body: m['body'] as String?,
      attachmentPath: m['attachment_path'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
      updatedAt: m['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(m['updated_at'] as int)
          : null,
    );
  }
}
