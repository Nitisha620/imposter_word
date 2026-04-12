import 'package:flutter_riverpod/legacy.dart';
import 'package:word_imposter/services/partykit_service.dart';
import 'package:word_imposter/services/session_service.dart';
import 'package:word_imposter/state/game_state.dart';
import 'package:word_imposter/state/room_state.dart';

import '../models/chat_message.dart';
import '../utils/enum.dart';

final gameProvider = StateNotifierProvider<GameController, GameState>((ref) {
  return GameController();
});

class GameController extends StateNotifier<GameState> {
  GameController() : super(GameState.initial()) {
    _restoreSession();
  }

  RoomSocket? _socket;

  // ── Session restore on app launch ────────────────────────────────────────
  // Mirrors the useEffect restoreSession() in App.jsx
  Future<void> _restoreSession() async {
    final session = await SessionService.restore();
    if (session == null) return;

    state = state.copyWith(
      myId: session.myId,
      isHost: session.isHost,
      roomCode: session.roomCode,
    );
    _connectSocket(session.roomCode, session.myId, session.isHost);
  }

  // ── Connect the persistent WebSocket ─────────────────────────────────────
  // Mirrors the useEffect connect() inside useRoom hook
  void _connectSocket(String roomCode, String myId, bool isHost) {
    _socket?.dispose();
    _socket = RoomSocket(roomCode);

    // onSync: update roomState and react to server-driven changes
    // Mirrors ws.onmessage in useRoom.js
    _socket!.onSync = (serverState) {
      // ... existing kicked and closed checks ...

      // Mirror: eliminatedIds.includes(myId) from App.jsx
      final eliminatedSoFar =
          (serverState['eliminatedSoFar'] as List<dynamic>? ?? []);
      final eliminatedIds = eliminatedSoFar
          .map((e) => (e as Map<String, dynamic>)['id']?.toString() ?? '')
          .toList();
      final isEliminated = eliminatedIds.contains(myId);

      final newRoomState = RoomState.fromJson(serverState);
      final newPhase = _parsePhase(serverState['phase'] as String? ?? 'lobby');

      // ── Kicked check — mirrors the kicked useEffect in App.jsx
      final kicked = (serverState['kicked'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList();
      if (kicked.contains(myId)) {
        SessionService.clear();
        state = GameState.initial().copyWith(
          error: 'You were removed from the room by the host.',
        );
        _socket?.dispose();
        return;
      }

      // ── Room closed check — mirrors the phase==="closed" useEffect
      if (newPhase == GamePhase.closed && !isHost) {
        SessionService.clear();
        state = GameState.initial().copyWith(
          error: 'The host closed the room.',
        );
        _socket?.dispose();
        return;
      }

      // ── Host transfer — mirrors the roomState.host === myId useEffect
      final newIsHost = serverState['host'] == myId;

      state = state.copyWith(
        roomState: newRoomState,
        phase: newPhase,
        isHost: newIsHost,
        isEliminated: isEliminated,
      );
    };

    _socket!.onChat = (msg) {
      final message = ChatMessage.fromJson(msg);
      state = state.copyWith(chatMessages: [...state.chatMessages, message]);
    };

    _socket!.connect();
  }

  // ── patch: the primary way to update server state ─────────────────────────
  // All game logic calls this — mirrors patch() from useRoom.js
  void patch(Map<String, dynamic> partial) {
    _socket?.patch(partial);
  }

  // ── createRoom ────────────────────────────────────────────────────────────
  // Mirrors handleCreate in App.jsx
  Future<void> createRoom(String name, String? mode) async {
    if (name.trim().isEmpty) {
      state = state.copyWith(error: 'Enter your name first!');
      return;
    }

    state = state.copyWith(error: '');

    final result = await createRoomPartyServiceKit(
      name.trim(),
      mode ?? 'knows',
    );
    // ^ calls partykit_service.dart createRoom() — HTTP POST

    await SessionService.save(
      id: result.myId,
      name: name.trim(),
      room: result.room['code'] as String,
      isHost: true,
    );

    state = state.copyWith(
      roomCode: result.room['code'] as String,
      myId: result.myId,
      isHost: true,
      // phase stays home until onSync fires with lobby
    );

    _connectSocket(result.room['code'] as String, result.myId, true);
  }

  // ── joinRoom ──────────────────────────────────────────────────────────────
  // Mirrors handleJoin in App.jsx
  Future<void> joinRoom(String code, String name) async {
    if (name.trim().isEmpty) {
      state = state.copyWith(error: 'Enter your name first!');
      return;
    }
    if (code.trim().isEmpty) {
      state = state.copyWith(error: 'Enter a room code!');
      return;
    }

    state = state.copyWith(error: '');

    final savedId = await SessionService.getSavedId();
    final savedRoom = await SessionService.getSavedRoom();

    final result = await joinRoomPartyKitService(
      // ^ calls partykit_service.dart joinRoom()
      code.trim(),
      name.trim(),
      savedId: savedId,
      savedRoom: savedRoom,
    );

    if (result.error != null) {
      state = state.copyWith(error: result.error!);
      return;
    }

    await SessionService.save(
      id: result.myId!,
      name: name.trim(),
      room: code.trim().toUpperCase(),
      isHost: false,
    );

    state = state.copyWith(
      roomCode: code.trim().toUpperCase(),
      myId: result.myId!,
      isHost: false,
    );

    _connectSocket(code.trim().toUpperCase(), result.myId!, false);

    // If not reclaimed, send join message — mirrors pendingJoin logic in App.jsx
    if (!result.reclaimed) {
      _socket?.join({
        'id': result.myId,
        'name': name.trim(),
        'joinedAt': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  // ── leave ─────────────────────────────────────────────────────────────────
  // Mirrors handleLeave in App.jsx
  Future<void> leave() async {
    _socket?.leave(state.myId, state.isHost);
    await SessionService.clear();
    await Future.delayed(const Duration(milliseconds: 200));
    _socket?.dispose();
    state = GameState.initial();
  }

  // ── sendChat ──────────────────────────────────────────────────────────────
  void sendChat(String text) {
    final myName = state.roomState.players[state.myId]?.name ?? '';
    _socket?.sendChat(text, state.myId, myName);
  }

  // ── All patch-based game actions below ────────────────────────────────────
  // These all mirror the handleX callbacks in App.jsx that call patch({...})

  void setImposterCount(int count) => patch({'imposterCount': count});
  void setTimer(int secs) => patch({'timerSecs': secs});
  void setMaxPlayers(int n) => patch({'maxPlayers': n});
  void setGameMode(String mode) => patch({'gameMode': mode});

  void kickPlayer(String playerId) {
    // Mirrors handleKickPlayer — remove from players map, add to kicked list
    final players = Map<String, dynamic>.from(
      state.roomState.players.map((k, v) => MapEntry(k, v.toJson())),
    );
    players.remove(playerId);
    final kicked = [...(state.roomState.kicked), playerId];
    patch({'players': players, 'kicked': kicked});
  }

  void startGame() {
    // Mirrors handleStart — validation + word assignment
    final players = state.roomState.players.values.toList();
    if (players.length < 3) {
      state = state.copyWith(error: 'Need at least 3 players!');
      return;
    }
    state = state.copyWith(error: '');
    // Word pair assignment and shuffle happen here — you can port
    // the full WORD_PAIRS + handleStart logic from App.jsx when ready.
    // For now patch phase to reveal:
    patch({'phase': 'reveal'});
  }

  void markReady() {
    final ready = Map<String, dynamic>.from(state.roomState.revealReady ?? {})
      ..[state.myId] = true;
    patch({'revealReady': ready});
  }

  // In GameController — confirm advancePhase() looks like this:
  void advancePhase() {
    // Mirrors handleRevealDone in App.jsx:
    // patch({ phase:"discussion", revealReady:{},
    //   discussionEnd: timerSecs > 0 ? Date.now() + timerSecs*1000 : null })
    final timerSecs = state.roomState.timerSecs;
    patch({
      'phase': 'discussion',
      'revealReady': {},
      'discussionEnd': timerSecs > 0
          ? DateTime.now().millisecondsSinceEpoch + timerSecs * 1000
          : null,
    });
  }

  void changeWord() => patch({'revealReady': {}});
  // Full word re-assignment logic from handleChangeWord can be ported here

  void backToLobby() {
    final players = state.roomState.players.map(
      (k, v) => MapEntry(k, {...v.toJson(), 'ready': false}),
    );
    patch({
      'phase': 'lobby',
      'assignments': null,
      'votes': {},
      'results': null,
      'revealReady': {},
      'tieVote': false,
      'eliminatedSoFar': [],
      'originalPlayers': null,
      'players': players,
    });
  }

  void startVote() =>
      patch({'phase': 'voting', 'eliminationAnnouncement': null});
  // In GameController — fix goToDiscussion():
  void goToDiscussion() {
    // Mirrors handleStartDiscussion in App.jsx:
    // patch({ phase:"discussion", eliminationAnnouncement:null, discussionEnd:... })
    final timerSecs = roomState.timerSecs;
    patch({
      'phase': 'discussion',
      'eliminationAnnouncement': null, // ← this was missing
      'discussionEnd': timerSecs > 0
          ? DateTime.now().millisecondsSinceEpoch + timerSecs * 1000
          : null,
    });
  }

  void castVote(String targetId) {
    final votes = {...(state.roomState.votes ?? {}), state.myId: targetId};
    patch({'votes': votes});
  }

  void finalizeVote() {
    final votes = roomState.votes ?? {};
    final eliminatedSoFar = roomState.eliminatedSoFar;
    final eliminatedIds = eliminatedSoFar
        .map((e) => e['id']?.toString() ?? '')
        .toList();
    final allImposters = roomState.allImposters;

    // Tally votes — mirrors: Object.values(votes).forEach(...)
    final tally = <String, int>{};
    for (final vid in votes.values) {
      tally[vid] = (tally[vid] ?? 0) + 1;
    }

    // Sort by count descending
    final sorted = tally.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topCount = sorted.isEmpty ? 0 : sorted.first.value;
    final topIds = sorted
        .where((e) => e.value == topCount)
        .map((e) => e.key)
        .toList();

    // Tie — mirrors: if (topIds.length > 1) patch({ phase:"discussion", tieVote:true })
    if (topIds.length > 1) {
      final timerSecs = roomState.timerSecs;
      patch({
        'phase': 'discussion',
        'votes': {},
        'tieVote': true,
        'discussionEnd': timerSecs > 0
            ? DateTime.now().millisecondsSinceEpoch + timerSecs * 1000
            : null,
      });
      return;
    }

    final eliminated = topIds.first;
    final eliminatedName = roomState.players[eliminated]?.name ?? 'Unknown';
    final imposterCaught = allImposters.contains(eliminated);

    // Build new eliminatedSoFar list
    final newEliminatedSoFar = [
      ...eliminatedSoFar,
      {'id': eliminated, 'name': eliminatedName},
    ];
    final newEliminatedIds = newEliminatedSoFar
        .map((e) => e['id']?.toString() ?? '')
        .toList();

    // Count remaining players after elimination
    final allPlayers = roomState.players.values.toList();
    final remaining = allPlayers
        .where((p) => !newEliminatedIds.contains(p.id))
        .toList();
    final remainingImposters = remaining
        .where((p) => allImposters.contains(p.id))
        .length;
    final remainingInnocents = remaining.length - remainingImposters;

    final innocentsWin = imposterCaught && remainingImposters == 0;
    final impostersWin = remainingImposters >= remainingInnocents;

    if (innocentsWin || impostersWin) {
      // Game over
      patch({
        'phase': 'results',
        'tieVote': false,
        'eliminatedSoFar': newEliminatedSoFar,
        'results': {
          'eliminated': eliminated,
          'eliminatedName': eliminatedName,
          'imposterCaught': imposterCaught,
          'innocentsWin': innocentsWin,
          'remainingImposters': remainingImposters,
          'remainingInnocents': remainingInnocents,
          'tally': tally,
          'imposters': allImposters,
          'topIds': topIds,
        },
      });
    } else {
      // Game continues — announce elimination, go back to voting
      patch({
        'phase': 'voting',
        'votes': {},
        'tieVote': false,
        'eliminatedSoFar': newEliminatedSoFar,
        'eliminationAnnouncement': {
          'id': eliminated,
          'name': eliminatedName,
          'imposterCaught': imposterCaught,
        },
        'revealReady': {},
      });
    }
  }

  // Convenience getter used inside finalizeVote
  RoomState get roomState => state.roomState;

  void reset() {
    final base = state.roomState.originalPlayers ?? state.roomState.players;
    final players = base.map(
      (k, v) => MapEntry(k, {...v.toJson(), 'ready': false}),
    );
    patch({
      'phase': 'lobby',
      'assignments': null,
      'votes': {},
      'results': null,
      'revealReady': {},
      'tieVote': false,
      'eliminatedSoFar': [],
      'originalPlayers': null,
      'players': players,
    });
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  GamePhase _parsePhase(String s) {
    switch (s) {
      case 'lobby':
        return GamePhase.lobby;
      case 'reveal':
        return GamePhase.reveal;
      case 'discussion':
        return GamePhase.discussion;
      case 'voting':
        return GamePhase.voting;
      case 'results':
        return GamePhase.results;
      case 'closed':
        return GamePhase.closed;
      default:
        return GamePhase.home;
    }
  }

  @override
  void dispose() {
    _socket?.dispose();
    super.dispose();
  }
}
