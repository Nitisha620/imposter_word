import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/game_controller.dart';

class DiscussionScreen extends ConsumerWidget {
  const DiscussionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Discussion Screen"),

            ElevatedButton(
              onPressed: () {
                ref.read(gameProvider.notifier).createRoom("Nitisha");
              },
              child: const Text("Create Room"),
            ),

            ElevatedButton(
              onPressed: () {
                ref.read(gameProvider.notifier).joinRoom("ABC123", "Guest");
              },
              child: const Text("Join Room"),
            ),
          ],
        ),
      ),
    );
  }
}
