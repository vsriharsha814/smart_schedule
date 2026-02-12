import 'package:shared_preferences/shared_preferences.dart';

/// Phase II: User settings persisted locally (key-value).
class SettingsStore {
  SettingsStore({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;
  static const _keyPrefix = 'smart_schedule_';

  Future<SharedPreferences> get _store async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<String?> getString(String key) async {
    return (await _store).getString(_keyPrefix + key);
  }

  Future<void> setString(String key, String value) async {
    await (await _store).setString(_keyPrefix + key, value);
  }

  Future<bool?> getBool(String key) async {
    return (await _store).getBool(_keyPrefix + key);
  }

  Future<void> setBool(String key, bool value) async {
    await (await _store).setBool(_keyPrefix + key, value);
  }

  Future<void> remove(String key) async {
    await (await _store).remove(_keyPrefix + key);
  }
}
