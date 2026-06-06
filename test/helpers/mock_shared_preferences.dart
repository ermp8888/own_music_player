/// Mock SharedPreferences for testing settings persistence.
///
/// Implements the same interface as SharedPreferences using an in-memory map.
/// Pre-populated with DownTune default filter values.
library;

/// In-memory mock of SharedPreferences for testing.
class MockSharedPreferences {
  final Map<String, Object> _data = {};

  /// Create with default filter settings.
  factory MockSharedPreferences.withDefaults() {
    final mock = MockSharedPreferences();
    // Default filter values matching Part 3 spec
    mock._data['filter_devotional'] = true;
    mock._data['filter_karaoke'] = true;
    mock._data['filter_remixes'] = false;
    mock._data['filter_instrumentals'] = false;
    mock._data['filter_shorts'] = true;
    return mock;
  }

  MockSharedPreferences();

  // ── String ──

  Future<bool> setString(String key, String value) async {
    _data[key] = value;
    return true;
  }

  String? getString(String key) => _data[key] as String?;

  // ── Bool ──

  Future<bool> setBool(String key, bool value) async {
    _data[key] = value;
    return true;
  }

  bool? getBool(String key) => _data[key] as bool?;

  // ── Int ──

  Future<bool> setInt(String key, int value) async {
    _data[key] = value;
    return true;
  }

  int? getInt(String key) => _data[key] as int?;

  // ── Double ──

  Future<bool> setDouble(String key, double value) async {
    _data[key] = value;
    return true;
  }

  double? getDouble(String key) => _data[key] as double?;

  // ── StringList ──

  Future<bool> setStringList(String key, List<String> value) async {
    _data[key] = value;
    return true;
  }

  List<String>? getStringList(String key) => _data[key] as List<String>?;

  // ── General ──

  bool containsKey(String key) => _data.containsKey(key);

  Future<bool> remove(String key) async {
    _data.remove(key);
    return true;
  }

  Future<bool> clear() async {
    _data.clear();
    return true;
  }

  Set<String> getKeys() => _data.keys.toSet();

  /// Simulate a write failure for error testing.
  /// When enabled, all set* methods throw.
  bool simulateWriteFailure = false;

  Future<bool> _guardedWrite(String key, Object value) async {
    if (simulateWriteFailure) {
      throw Exception('SharedPreferences write failed (simulated)');
    }
    _data[key] = value;
    return true;
  }
}
