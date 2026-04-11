import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'state/game_controller.dart';
import 'state/game_state.dart';
import 'screens/home_screen.dart';
import 'screens/lobby_screen.dart';
import 'screens/reveal_screen.dart';
import 'screens/discussion_screen.dart';
import 'screens/voting_screen.dart';
import 'screens/result_screen.dart';

class AppView extends ConsumerWidget {
  const AppView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);

    switch (state.phase) {
      case GamePhase.home:
        return HomeScreen();

      // In AppView, replace the lobby case:
      case GamePhase.lobby:
        return LobbyScreen(
          roomCode: state.roomCode,
          myId: state.myId,
          isHost: state.isHost,
          roomState: state.roomState,
          // These two were hardcoded before — now read from state
          error: state.error.isEmpty ? null : state.error,
          chatMessages: state.chatMessages,
          onStart: () => ref.read(gameProvider.notifier).startGame(),
          onImposterCount: (n) =>
              ref.read(gameProvider.notifier).setImposterCount(n),
          onKick: (id) => ref.read(gameProvider.notifier).kickPlayer(id),
          onTimerChange: (s) => ref.read(gameProvider.notifier).setTimer(s),
          onPlayerCount: (n) =>
              ref.read(gameProvider.notifier).setMaxPlayers(n),
          onGameMode: (m) => ref.read(gameProvider.notifier).setGameMode(m),
          onSendChat: (t) => ref.read(gameProvider.notifier).sendChat(t),
          onLeave: () => ref.read(gameProvider.notifier).leave(),
        );

      case GamePhase.reveal:
        return RevealScreen(
          roomState: state.roomState,
          myId: state.myId,
          isHost: state.isHost,
          onDone: () => ref.read(gameProvider.notifier).advancePhase(),
          onMarkReady: () => ref.read(gameProvider.notifier).markReady(),
          onChangeWord: () => ref.read(gameProvider.notifier).changeWord(),
          onBackToLobby: () => ref.read(gameProvider.notifier).backToLobby(),
        );

      case GamePhase.discussion:
        return DiscussionScreen(
          roomState: state.roomState,
          myId: state.myId,
          isHost: state.isHost,
          isEliminated: state.isEliminated,
          chatMessages: state.chatMessages,
          onSendChat: (t) => ref.read(gameProvider.notifier).sendChat(t),
          onStartVote: () => ref.read(gameProvider.notifier).startVote(),
        );

      case GamePhase.voting:
        return VotingScreen(
          roomState: state.roomState,
          myId: state.myId,
          isHost: state.isHost,
          isEliminated: state.isEliminated,
          onCastVote: (id) => ref.read(gameProvider.notifier).castVote(id),
          onFinalize: () => ref.read(gameProvider.notifier).finalizeVote(),
          onStartDiscussion: () =>
              ref.read(gameProvider.notifier).goToDiscussion(),
        );

      case GamePhase.results:
        return ResultsScreen(
          roomState: state.roomState,
          isHost: state.isHost,
          onPlayAgain: () => ref.read(gameProvider.notifier).reset(),
          onLeave: () => ref.read(gameProvider.notifier).reset(),
        );

      default:
        return const HomeScreen();
    }
  }
}
