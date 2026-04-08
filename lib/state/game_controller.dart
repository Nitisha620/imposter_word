import 'package:flutter_riverpod/legacy.dart';
import 'game_state.dart';

final gameProvider = StateNotifierProvider<GameController, GameState>((ref) {
  return GameController();
});

class GameController extends StateNotifier<GameState> {
  GameController() : super(GameState.initial());

  void createRoom(String name, String? mode) {
    state = state.copyWith(
      roomCode: "ABC123",
      myId: "user1",
      isHost: true,
      phase: GamePhase.lobby,
    );
  }

  void joinRoom(String code, String name) {
    state = state.copyWith(
      roomCode: code,
      myId: "user2",
      isHost: false,
      phase: GamePhase.lobby,
    );
  }

  void startGame() {
    state = state.copyWith(phase: GamePhase.reveal);
  }

  void goToDiscussion() {
    state = state.copyWith(phase: GamePhase.discussion);
  }

  void startVoting() {
    state = state.copyWith(phase: GamePhase.voting);
  }

  void showResults() {
    state = state.copyWith(phase: GamePhase.results);
  }

  void reset() {
    state = GameState.initial();
  }

  void setImposterCount(int count) {}

  void kickPlayer(String playerId) {}

  void setTimer(int time) {}

  void setMaxPlayers(int maxPlayerCount) {}

  void setGameMode(String mode) {}

  void sendChat(String text) {}

  void advancePhase() {}

  void markReady() {
    state = state.copyWith(phase: GamePhase.discussion);
  }

  void changeWord() {}

  void backToLobby() {}

  void startVote() {
    state = state.copyWith(phase: GamePhase.voting);
  }

  void castVote(String id) {}

  void finalizeVote() {
    state = state.copyWith(phase: GamePhase.results);
  }
}
