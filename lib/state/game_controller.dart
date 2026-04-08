import 'package:flutter_riverpod/legacy.dart';
import 'game_state.dart';

final gameProvider = StateNotifierProvider<GameController, GameState>((ref) {
  return GameController();
});

class GameController extends StateNotifier<GameState> {
  GameController() : super(GameState.initial());

  void createRoom(String name) {
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
}
