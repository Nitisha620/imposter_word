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
        return const HomeScreen();

      case GamePhase.lobby:
        return const LobbyScreen();

      case GamePhase.reveal:
        return const RevealScreen();

      case GamePhase.discussion:
        return const DiscussionScreen();

      case GamePhase.voting:
        return const VotingScreen();

      case GamePhase.results:
        return const ResultScreen();

      default:
        return const HomeScreen();
    }
  }
}