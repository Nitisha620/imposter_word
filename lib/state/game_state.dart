enum GamePhase { home, lobby, reveal, discussion, voting, results, closed }

class GameState {
  final String roomCode;
  final String myId;
  final bool isHost;
  final GamePhase phase;

  GameState({
    required this.roomCode,
    required this.myId,
    required this.isHost,
    required this.phase,
  });

  factory GameState.initial() => GameState(
        roomCode: '',
        myId: '',
        isHost: false,
        phase: GamePhase.home,
      );

  GameState copyWith({
    String? roomCode,
    String? myId,
    bool? isHost,
    GamePhase? phase,
  }) {
    return GameState(
      roomCode: roomCode ?? this.roomCode,
      myId: myId ?? this.myId,
      isHost: isHost ?? this.isHost,
      phase: phase ?? this.phase,
    );
  }
}