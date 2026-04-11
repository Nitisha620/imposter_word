import 'package:shared_preferences/shared_preferences.dart';

// Mirrors restoreSession() and clearSession() from useRoom.js
class SessionService {
  static const _kId = 'iwg_id';
  static const _kName = 'iwg_name';
  static const _kRoom = 'iwg_room';
  static const _kHost = 'iwg_host';

  static Future<void> save({
    required String id,
    required String name,
    required String room,
    required bool isHost,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kId, id);
    await prefs.setString(_kName, name);
    await prefs.setString(_kRoom, room);
    await prefs.setBool(_kHost, isHost);
  }

  // Returns null if nothing saved — same as React's restoreSession returning null
  static Future<({String myId, String myName, String roomCode, bool isHost})?>
  restore() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_kId);
    final name = prefs.getString(_kName);
    final room = prefs.getString(_kRoom);
    final host = prefs.getBool(_kHost) ?? false;
    if (id != null && name != null && room != null) {
      return (myId: id, myName: name, roomCode: room, isHost: host);
    }
    return null;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kId);
    await prefs.remove(_kName);
    await prefs.remove(_kRoom);
    await prefs.remove(_kHost);
  }

  static Future<String?> getSavedId() async =>
      (await SharedPreferences.getInstance()).getString(_kId);
  static Future<String?> getSavedRoom() async =>
      (await SharedPreferences.getInstance()).getString(_kRoom);
}
