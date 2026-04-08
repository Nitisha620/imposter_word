import 'player_info.dart';

class RoomState {
  final Map<String, PlayerInfo> players;
  final String host;
  final int imposterCount;
  final int timerSecs;
  final int maxPlayers;
  final String gameMode;
  final Map<String, Assignment>? assignments;
  final Map<String, bool>? revealReady;

  const RoomState({
    required this.players,
    required this.host,
    this.imposterCount = 1,
    this.timerSecs = 120,
    this.maxPlayers = 8,
    this.gameMode = 'knows',
    this.assignments,
    this.revealReady,
  });
}

class Assignment {
  final String role, word;
  const Assignment({required this.role, required this.word});
}