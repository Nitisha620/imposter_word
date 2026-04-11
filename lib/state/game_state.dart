import 'package:word_imposter/screens/discussion_screen.dart';
import 'package:word_imposter/state/player_info.dart';
import 'package:word_imposter/state/room_state.dart';

import '../models/chat_message.dart';

enum GamePhase { home, lobby, reveal, discussion, voting, results, closed }

class GameState {
  final String roomCode;
  final String myId;
  final bool isHost;
  final GamePhase phase;
  final RoomState roomState;
  final List<ChatMessage> chatMessages;
  final bool isEliminated;
  String error;

  GameState({
    required this.roomCode,
    required this.myId,
    required this.isHost,
    required this.phase,
    required this.roomState,
    required this.chatMessages,
    required this.isEliminated,
    required this.error,
  });

  factory GameState.initial() => GameState(
    roomCode: '',
    myId: '',
    isHost: false,
    phase: GamePhase.home,
    roomState: RoomState(
      players: {"1": PlayerInfo(id: "1", name: "Law", joinedAt: 1)},
      host: "Nitisha",
    ),
    chatMessages: [],
    isEliminated: false,
    error: '',
  );

  GameState copyWith({
    String? roomCode,
    String? myId,
    bool? isHost,
    GamePhase? phase,
    RoomState? roomState,
    List<ChatMessage>? chatMessages,
    bool? isEliminated,
    String? error,
  }) {
    return GameState(
      roomCode: roomCode ?? this.roomCode,
      myId: myId ?? this.myId,
      isHost: isHost ?? this.isHost,
      phase: phase ?? this.phase,
      roomState: roomState ?? this.roomState,
      chatMessages: chatMessages ?? this.chatMessages,
      isEliminated: isEliminated ?? this.isEliminated,
      error: error ?? this.error,
    );
  }
}
