import 'player_info.dart';

class RoomState {
  final Map<String, PlayerInfo> players;
  final String host;
  final int imposterCount;
  final int timerSecs;
  final int maxPlayers;
  final String gameMode;
  final String phase;

  // Word assignment per player — null before game starts
  final Map<String, Assignment>? assignments;

  // Tracks which players have tapped "Ready" on reveal screen
  final Map<String, bool>? revealReady;

  // The correct word and the imposter's word
  final String? mainWord;
  final String? imposterWord;

  // { voterId: targetId }
  final Map<String, String>? votes;

  // All player IDs who are imposters this round
  final List<String> allImposters;

  // Players eliminated so far this round: [{id, name}]
  final List<Map<String, dynamic>> eliminatedSoFar;

  // Set when one player is eliminated mid-round (shown before next vote)
  final Map<String, dynamic>? eliminationAnnouncement;

  // Final round result — set when game ends
  final RoundResult? results;

  // Unix ms — when discussion timer ends (null = no timer)
  final int? discussionEnd;

  // Players who were kicked (their IDs)
  final List<String> kicked;

  // Whether the last vote was a tie
  final bool tieVote;

  // Snapshot of players at game start (used for Play Again)
  final Map<String, PlayerInfo>? originalPlayers;

  const RoomState({
    required this.players,
    required this.host,
    this.imposterCount = 1,
    this.timerSecs = 120,
    this.maxPlayers = 8,
    this.gameMode = 'knows',
    this.phase = 'lobby',
    this.assignments,
    this.revealReady,
    this.mainWord,
    this.imposterWord,
    this.votes,
    this.allImposters = const [],
    this.eliminatedSoFar = const [],
    this.eliminationAnnouncement,
    this.results,
    this.discussionEnd,
    this.kicked = const [],
    this.tieVote = false,
    this.originalPlayers,
  });

  // ── fromJson ─────────────────────────────────────────────────────────────
  // Called every time a `sync` message arrives from PartyKit
  factory RoomState.fromJson(Map<String, dynamic> j) {
    // players map — { id: { id, name, joinedAt } }
    final rawPlayers = j['players'] as Map<String, dynamic>? ?? {};
    final players = rawPlayers.map(
      (k, v) => MapEntry(k, PlayerInfo.fromJson(v as Map<String, dynamic>)),
    );

    // originalPlayers — same shape as players
    final rawOriginal = j['originalPlayers'] as Map<String, dynamic>?;
    final originalPlayers = rawOriginal?.map(
      (k, v) => MapEntry(k, PlayerInfo.fromJson(v as Map<String, dynamic>)),
    );

    // assignments — { playerId: { role, word, name } }
    final rawAssign = j['assignments'] as Map<String, dynamic>?;
    final assignments = rawAssign?.map(
      (k, v) => MapEntry(k, Assignment.fromJson(v as Map<String, dynamic>)),
    );

    // revealReady — { playerId: true }
    final rawReady = j['revealReady'] as Map<String, dynamic>?;
    final revealReady = rawReady?.map((k, v) => MapEntry(k, v == true));

    // votes — { voterId: targetId }
    final rawVotes = j['votes'] as Map<String, dynamic>?;
    final votes = rawVotes?.map((k, v) => MapEntry(k, v.toString()));

    // allImposters — list of player IDs
    final allImposters = (j['allImposters'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();

    // eliminatedSoFar — list of { id, name }
    final eliminatedSoFar = (j['eliminatedSoFar'] as List<dynamic>? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    // kicked — list of player IDs
    final kicked = (j['kicked'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();

    // eliminationAnnouncement — { id, name, imposterCaught }
    final rawAnnounce = j['eliminationAnnouncement'];
    final eliminationAnnouncement = (rawAnnounce == null || rawAnnounce is! Map)
        ? null
        : Map<String, dynamic>.from(rawAnnounce);

    // results
    final rawResults = j['results'];
    final results = rawResults is Map
        ? RoundResult.fromJson(Map<String, dynamic>.from(rawResults))
        : null;

    return RoomState(
      players: players,
      host: j['host']?.toString() ?? '',
      imposterCount: (j['imposterCount'] as num?)?.toInt() ?? 1,
      timerSecs: (j['timerSecs'] as num?)?.toInt() ?? 120,
      maxPlayers: (j['maxPlayers'] as num?)?.toInt() ?? 8,
      gameMode: j['gameMode']?.toString() ?? 'knows',
      phase: j['phase']?.toString() ?? 'lobby',
      assignments: assignments,
      revealReady: revealReady,
      mainWord: j['mainWord']?.toString(),
      imposterWord: j['imposterWord']?.toString(),
      votes: votes,
      allImposters: allImposters,
      eliminatedSoFar: eliminatedSoFar,
      eliminationAnnouncement: eliminationAnnouncement,
      results: results,
      discussionEnd: (j['discussionEnd'] as num?)?.toInt(),
      kicked: kicked,
      tieVote: j['tieVote'] == true,
      originalPlayers: originalPlayers,
    );
  }

  // ── toJson ────────────────────────────────────────────────────────────────
  // Used when patching — converts back to the shape PartyKit expects
  Map<String, dynamic> toJson() => {
    'players': players.map((k, v) => MapEntry(k, v.toJson())),
    'host': host,
    'imposterCount': imposterCount,
    'timerSecs': timerSecs,
    'maxPlayers': maxPlayers,
    'gameMode': gameMode,
    'phase': phase,
    if (assignments != null)
      'assignments': assignments!.map((k, v) => MapEntry(k, v.toJson())),
    if (revealReady != null) 'revealReady': revealReady,
    if (mainWord != null) 'mainWord': mainWord,
    if (imposterWord != null) 'imposterWord': imposterWord,
    if (votes != null) 'votes': votes,
    'allImposters': allImposters,
    'eliminatedSoFar': eliminatedSoFar,
    if (eliminationAnnouncement != null)
      'eliminationAnnouncement': eliminationAnnouncement,
    if (results != null) 'results': results!.toJson(),
    if (discussionEnd != null) 'discussionEnd': discussionEnd,
    'kicked': kicked,
    'tieVote': tieVote,
    if (originalPlayers != null)
      'originalPlayers': originalPlayers!.map(
        (k, v) => MapEntry(k, v.toJson()),
      ),
  };
}

// ── Assignment ────────────────────────────────────────────────────────────────

class Assignment {
  final String role; // "innocent" | "imposter"
  final String word;
  final String name; // player display name (stored by server)

  const Assignment({required this.role, required this.word, this.name = ''});

  factory Assignment.fromJson(Map<String, dynamic> j) => Assignment(
    role: j['role']?.toString() ?? 'innocent',
    word: j['word']?.toString() ?? '',
    name: j['name']?.toString() ?? '',
  );

  Map<String, dynamic> toJson() => {'role': role, 'word': word, 'name': name};
}

// ── RoundResult ───────────────────────────────────────────────────────────────
// Mirrors the `results` object built inside handleFinalizeVote in App.jsx

class RoundResult {
  final String eliminated;
  final String eliminatedName;
  final bool imposterCaught;
  final bool innocentsWin;
  final int remainingImposters;
  final int remainingInnocents;
  final Map<String, int> tally; // { playerId: voteCount }
  final List<String> imposters; // all imposter IDs
  final List<String> topIds; // IDs that got most votes

  const RoundResult({
    required this.eliminated,
    required this.eliminatedName,
    required this.imposterCaught,
    required this.innocentsWin,
    required this.remainingImposters,
    required this.remainingInnocents,
    required this.tally,
    required this.imposters,
    required this.topIds,
  });

  factory RoundResult.fromJson(Map<String, dynamic> j) => RoundResult(
    eliminated: j['eliminated']?.toString() ?? '',
    eliminatedName: j['eliminatedName']?.toString() ?? '',
    imposterCaught: j['imposterCaught'] == true,
    innocentsWin: j['innocentsWin'] == true,
    remainingImposters: (j['remainingImposters'] as num?)?.toInt() ?? 0,
    remainingInnocents: (j['remainingInnocents'] as num?)?.toInt() ?? 0,
    tally: (j['tally'] as Map<String, dynamic>? ?? {}).map(
      (k, v) => MapEntry(k, (v as num).toInt()),
    ),
    imposters: (j['imposters'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList(),
    topIds: (j['topIds'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'eliminated': eliminated,
    'eliminatedName': eliminatedName,
    'imposterCaught': imposterCaught,
    'innocentsWin': innocentsWin,
    'remainingImposters': remainingImposters,
    'remainingInnocents': remainingInnocents,
    'tally': tally,
    'imposters': imposters,
    'topIds': topIds,
  };
}
