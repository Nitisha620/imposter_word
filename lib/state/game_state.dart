import 'package:word_imposter/state/player_info.dart';
import 'package:word_imposter/state/room_state.dart';

import '../models/chat_message.dart';
import '../utils/enum.dart';

class GameState {
  final String roomCode;
  final String myId;
  final bool isHost;
  final GamePhase phase;
  final RoomState roomState;
  final List<ChatMessage> chatMessages;
  final bool isEliminated;
  String error;
  final bool isLoading;
  String loadingMessage = '';
  final String myName;

  GameState({
    required this.roomCode,
    required this.myId,
    required this.isHost,
    required this.phase,
    required this.roomState,
    required this.chatMessages,
    required this.isEliminated,
    required this.error,
    required this.isLoading,
    required this.loadingMessage,
    required this.myName,
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
    isLoading: false,
    loadingMessage: '',
    myName: '',
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
    bool? isLoading,
    String? loadingMessage,
    String? myName,
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
      isLoading: isLoading ?? this.isLoading,
      loadingMessage: loadingMessage ?? this.loadingMessage,
      myName: myName ?? this.myName,
    );
  }
}
