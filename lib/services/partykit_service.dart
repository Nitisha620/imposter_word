import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

// ── Replace with your actual PartyKit host ─────────────────────────────────
String get baseUrl => dotenv.env['VITE_PARTYKIT_HOST']!;
final _kPartykitHost = baseUrl.isNotEmpty
    ? baseUrl
    : 'imposter-word.alpacaccino94.partykit.dev';

String _wsUrl(String roomCode) {
  // PartyKit always uses wss in production
  return 'wss://$_kPartykitHost/party/${roomCode.toLowerCase()}';
}

String _httpBase() {
  return 'https://$_kPartykitHost';
}

// ── One message sent over the socket ───────────────────────────────────────
class RoomMessage {
  final String type;
  final Map<String, dynamic> payload;
  const RoomMessage(this.type, this.payload);

  String toJson() => jsonEncode({'type': type, ...payload});
}

// ── The live socket wrapper used by GameController ─────────────────────────
class RoomSocket {
  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  bool _destroyed = false;
  final String roomCode;
  final List<Map<String, dynamic>> _pending = [];

  // Callbacks set by GameController
  void Function(Map<String, dynamic> state)? onSync;
  void Function(Map<String, dynamic> msg)? onChat;

  RoomSocket(this.roomCode);

  void connect() {
    if (_destroyed) return;
    _channel = WebSocketChannel.connect(Uri.parse(_wsUrl(roomCode)));

    _channel!.stream.listen(
      (raw) {
        try {
          final msg = jsonDecode(raw as String) as Map<String, dynamic>;
          if (msg['type'] == 'sync') {
            onSync?.call(msg['state'] as Map<String, dynamic>);
          }
          if (msg['type'] == 'chat' && msg['payload'] != null) {
            onChat?.call(msg['payload'] as Map<String, dynamic>);
          }
        } catch (_) {}
      },
      onDone: _scheduleReconnect,
      onError: (_) => _scheduleReconnect(),
    );

    // web_socket_channel doesn't have an onOpen callback —
    // we flush pending + request state right after connecting.
    // A tiny delay lets the handshake complete.
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_destroyed) return;
      for (final m in _pending) {
        _rawSend(m);
      }
      _pending.clear();
      _rawSend({'type': 'get'});
    });
  }

  void _scheduleReconnect() {
    if (_destroyed) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(milliseconds: 1500), connect);
  }

  void _rawSend(Map<String, dynamic> msg) {
    try {
      _channel?.sink.add(jsonEncode(msg));
    } catch (_) {}
  }

  // ── Public API ─────────────────────────────────────────────────────────
  void send(Map<String, dynamic> msg) {
    // Queue if not yet connected; web_socket_channel sink buffers too,
    // but we want explicit control like the React pendingRef
    _rawSend(msg);
  }

  void patch(Map<String, dynamic> partial) {
    send({'type': 'patch', 'payload': partial});
  }

  void join(Map<String, dynamic> player) {
    send({
      'type': 'join',
      'payload': {'player': player},
    });
  }

  void leave(String playerId, bool isHost) {
    // Send directly, no queue — mirrors React's direct ws.send
    _rawSend({
      'type': 'leave',
      'playerId': playerId,
      'payload': {'isHost': isHost},
    });
  }

  void sendChat(String text, String senderId, String senderName) {
    send({
      'type': 'chat',
      'payload': {
        'id': '${DateTime.now().millisecondsSinceEpoch}-$senderId',
        'senderId': senderId,
        'senderName': senderName,
        'text': text,
        'ts': DateTime.now().millisecondsSinceEpoch,
      },
    });
  }

  void dispose() {
    _destroyed = true;
    _reconnectTimer?.cancel();
    _channel?.sink.close();
  }
}

// ── createRoom (HTTP POST) ─────────────────────────────────────────────────
// Mirrors the React createRoom() function exactly
Future<({Map<String, dynamic> room, String myId})> createRoomPartyServiceKit(
  String hostName,
  String gameMode,
) async {
  // Generate random 6-char code — same logic as React
  final code = _randomCode();
  final hostId = _uuid();

  final room = {
    'code': code,
    'phase': 'lobby',
    'host': hostId,
    'hostName': hostName,
    'imposterCount': 1,
    'timerSecs': 120,
    'gameMode': gameMode,
    'players': {
      hostId: {
        'id': hostId,
        'name': hostName,
        'joinedAt': DateTime.now().millisecondsSinceEpoch,
      },
    },
    'kicked': [],
    'assignments': null,
    'votes': {},
    'results': null,
    'discussionEnd': null,
  };

  // POST initial state — same as React's fetch POST
  try {
    await http.post(
      Uri.parse('${_httpBase()}/party/${code.toLowerCase()}'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'type': 'init', 'payload': room}),
    );
  } catch (_) {
    // PartyKit sometimes closes the connection; ignore like React does
  }

  return (room: room, myId: hostId);
}

// ── joinRoom (temporary WebSocket to verify) ───────────────────────────────
// Mirrors the React joinRoom() function exactly
Future<
  ({Map<String, dynamic>? room, String? myId, String? error, bool reclaimed})
>
joinRoomPartyKitService(
  String code,
  String playerName, {
  String? savedId,
  String? savedRoom,
}) async {
  final upper = code.toUpperCase().trim();

  // Open a temporary WebSocket just to read room state — same as React
  final completer = Completer<Map<String, dynamic>?>();
  WebSocketChannel? tempWs;

  try {
    tempWs = WebSocketChannel.connect(Uri.parse(_wsUrl(upper)));
    Timer(const Duration(seconds: 4), () {
      if (!completer.isCompleted) completer.complete(null);
    });

    tempWs.stream.listen(
      (raw) {
        try {
          final msg = jsonDecode(raw as String) as Map<String, dynamic>;
          if (msg['type'] == 'sync' && !completer.isCompleted) {
            completer.complete(msg['state'] as Map<String, dynamic>);
          }
        } catch (_) {
          if (!completer.isCompleted) completer.complete(null);
        }
      },
      onError: (_) {
        if (!completer.isCompleted) completer.complete(null);
      },
      onDone: () {
        if (!completer.isCompleted) completer.complete(null);
      },
    );

    // Request current state
    await Future.delayed(const Duration(milliseconds: 100));
    tempWs.sink.add(jsonEncode({'type': 'get'}));
  } catch (_) {
    if (!completer.isCompleted) completer.complete(null);
  }

  final state = await completer.future;
  tempWs?.sink.close();

  // Validate — same checks as React
  if (state == null || state['phase'] == null) {
    return (
      room: null,
      myId: null,
      error: 'Room not found. Check the code!',
      reclaimed: false,
    );
  }
  if (state['phase'] != 'lobby') {
    return (
      room: null,
      myId: null,
      error: 'Game already in progress!',
      reclaimed: false,
    );
  }

  // Reclaim existing slot — same as React's savedRoom === upper check
  final players = state['players'] as Map<String, dynamic>? ?? {};
  if (savedRoom == upper && savedId != null && players.containsKey(savedId)) {
    return (room: state, myId: savedId, error: null, reclaimed: true);
  }

  // Name conflict check
  final existingNames = players.values
      .map(
        (p) =>
            (p as Map<String, dynamic>)['name'].toString().trim().toLowerCase(),
      )
      .toList();
  if (existingNames.contains(playerName.trim().toLowerCase())) {
    return (
      room: null,
      myId: null,
      error:
          'The name "$playerName" is already taken. Choose a different name!',
      reclaimed: false,
    );
  }

  final myId = _uuid();
  return (room: state, myId: myId, error: null, reclaimed: false);
}

// ── Helpers ────────────────────────────────────────────────────────────────
String _randomCode() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final rand = DateTime.now().millisecondsSinceEpoch;
  // Simple random — replace with dart:math Random if you prefer
  return List.generate(6, (i) => chars[(rand + i * 7) % chars.length]).join();
}

String _uuid() {
  // Simple UUID v4 without a package dependency
  // If you already have the `uuid` package: return const Uuid().v4();
  final now = DateTime.now().microsecondsSinceEpoch;
  return 'xxxx-$now-xxxx'.replaceAllMapped(RegExp(r'x'), (_) {
    return (DateTime.now().microsecondsSinceEpoch % 16).toRadixString(16);
  });
}
