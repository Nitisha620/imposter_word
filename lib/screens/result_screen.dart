import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:word_imposter/state/room_state.dart';

import '../state/player_info.dart';

// ─── Colours ──────────────────────────────────────────────────────────────────
const _bg = Color(0xFF0B0F1A);
const _card = Color(0xFF111827);
const _border = Color(0xFF1E2740);
const _purple = Color(0xFF7C6EF5);
const _red = Color(0xFFEF4444);
const _white70 = Color(0xB3FFFFFF);
const _white38 = Color(0x61FFFFFF);
const _white12 = Color(0x1FFFFFFF);

const _avatarColors = [
  Color(0xFF6D62F5),
  Color(0xFFF87171),
  Color(0xFF34D399),
  Color(0xFFFBBF24),
  Color(0xFF38BDF8),
  Color(0xFFF472B6),
  Color(0xFFA3E635),
  Color(0xFFFB923C),
];

// ─── Minimal models (match your game_state.dart) ──────────────────────────────

class ResultData {
  final String? eliminated;
  final bool imposterCaught;
  final bool innocentsWin;
  final int remainingImposters;
  final Map<String, int> tally;
  final List<String> imposters;

  const ResultData({
    this.eliminated,
    this.imposterCaught = false,
    this.innocentsWin = false,
    this.remainingImposters = 0,
    this.tally = const {},
    this.imposters = const [],
  });
}

class EliminatedEntry {
  final String id;
  final String name;
  const EliminatedEntry({required this.id, required this.name});
}

// ─── ResultsScreen ────────────────────────────────────────────────────────────

class ResultsScreen extends StatelessWidget {
  final RoomState roomState; // your RoomState
  final bool isHost;
  final VoidCallback onPlayAgain;
  final VoidCallback onLeave;

  const ResultsScreen({
    super.key,
    required this.roomState,
    required this.isHost,
    required this.onPlayAgain,
    required this.onLeave,
  });

  // ── derived ────────────────────────────────────────────────────────────────

  ResultData get _results {
    // Was: final r = null;
    final r = roomState.results;
    if (r == null) return const ResultData();
    return ResultData(
      eliminated: r.eliminated.isEmpty ? null : r.eliminated,
      imposterCaught: r.imposterCaught,
      innocentsWin: r.innocentsWin,
      remainingImposters: r.remainingImposters,
      tally: r.tally,
      imposters: r.imposters,
    );
  }

  List<PlayerInfo> get _players =>
      // Mirrors: Object.values(roomState?.players||{}).sort((a,b)=>a.joinedAt-b.joinedAt)
      roomState.players.values.toList()
        ..sort((a, b) => a.joinedAt.compareTo(b.joinedAt));

  List<EliminatedEntry> get _eliminatedSoFar =>
      // Mirrors: (roomState?.eliminatedSoFar || []).map(entry => ...)
      roomState.eliminatedSoFar
          .map(
            (e) => EliminatedEntry(
              id: e['id']?.toString() ?? '',
              name: e['name']?.toString() ?? 'Unknown',
            ),
          )
          .toList();

  String _imposterName(String id, int fallbackIdx, List<PlayerInfo> players) {
    // Mirrors: roomState?.players?.[id]?.name || roomState?.assignments?.[id]?.name || eliminatedSoFar.find(...)?.name
    final p = roomState.players[id];
    if (p != null) return p.name;

    final a = roomState.assignments?[id];
    if (a != null) return a.name;

    return _eliminatedSoFar
        .firstWhere(
          (e) => e.id == id,
          orElse: () => EliminatedEntry(id: id, name: '?'),
        )
        .name;
  }

  Color _avatarColor(int idx) => _avatarColors[idx % _avatarColors.length];

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final results = _results;
    final players = _players;
    final elims = _eliminatedSoFar;
    final tally = results.tally;
    final imposters = results.imposters;

    // In sortedPlayers sort and the eliminatedName lookup — these now work
    // type-safely because PlayerInfo has .id, .name, .joinedAt fields:
    final eliminatedName = results.eliminated != null
        ? roomState.players[results.eliminated]?.name ??
              'Unknown' // was unsafe cast
        : null;

    // outcome strings
    final outcomeIcon = results.innocentsWin ? '🎉' : '😈';
    final outcomeTitle = results.innocentsWin
        ? 'INNOCENTS WIN!'
        : 'IMPOSTERS WIN!';
    final outcomeDesc = eliminatedName != null
        ? results.imposterCaught
              ? results.remainingImposters > 0
                    ? '$eliminatedName was an imposter — but ${results.remainingImposters} remain.'
                    : '$eliminatedName was the last imposter. Innocents win!'
              : '$eliminatedName was innocent — imposters win!'
        : "It was a tie — no one eliminated. Imposters win!";

    // sorted by votes for vote-breakdown
    final sortedPlayers = [...players]
      ..sort((a, b) => (tally[b.id] ?? 0).compareTo(tally[a.id] ?? 0));
    final maxTally = tally.values.isEmpty
        ? 1
        : tally.values.reduce((a, b) => a > b ? a : b);

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── scrollable body ──────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Outcome banner
                    _buildBanner(
                      outcomeIcon: outcomeIcon,
                      outcomeTitle: outcomeTitle,
                      outcomeDesc: outcomeDesc,
                      innocentsWin: results.innocentsWin,
                    ),
                    const SizedBox(height: 14),

                    // Word cards row
                    _buildWordCards(),
                    const SizedBox(height: 14),

                    // Imposters + eliminated panel
                    _buildImpostersPanel(
                      imposters: imposters,
                      players: players,
                      elims: elims,
                      results: results,
                    ),
                    const SizedBox(height: 14),

                    // Vote breakdown
                    _buildVoteBreakdown(
                      sortedPlayers: sortedPlayers,
                      players: players,
                      tally: tally,
                      maxTally: maxTally,
                      imposters: imposters,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // ── sticky action bar ────────────────────────────────────────
            _buildActionBar(),
          ],
        ),
      ),
    );
  }

  // ── OUTCOME BANNER ─────────────────────────────────────────────────────────

  Widget _buildBanner({
    required String outcomeIcon,
    required String outcomeTitle,
    required String outcomeDesc,
    required bool innocentsWin,
  }) {
    final borderColor = innocentsWin ? const Color(0xFF4ADE80) : _purple;
    final bgColor = innocentsWin
        ? const Color(0xFF052E16)
        : const Color(0xFF1A1040);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withOpacity(0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(outcomeIcon, style: const TextStyle(fontSize: 34)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  outcomeTitle,
                  style: GoogleFonts.barlow(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  outcomeDesc,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: _white70,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── WORD CARDS ─────────────────────────────────────────────────────────────

  Widget _buildWordCards() {
    // Was: final mainWord = "--";
    // Was: final imposterWord = "-";
    // Mirrors: roomState?.mainWord and roomState?.gameMode === "blind" check
    final mainWord = roomState.mainWord ?? '—';
    final imposterWord = roomState.gameMode == 'blind'
        ? '—'
        : (roomState.imposterWord ?? '—');

    return Row(
      children: [
        Expanded(
          child: _WordCard(label: 'INNOCENT WORD', word: mainWord, red: false),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _WordCard(
            label: 'IMPOSTER WORD',
            word: imposterWord,
            red: true,
          ),
        ),
      ],
    );
  }

  // ── IMPOSTERS + ELIMINATED PANEL ──────────────────────────────────────────

  Widget _buildImpostersPanel({
    required List<String> imposters,
    required List<PlayerInfo> players,
    required List<EliminatedEntry> elims,
    required ResultData results,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imposters section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionLabel('THE IMPOSTERS WERE'),
                const SizedBox(height: 10),
                ...imposters.asMap().entries.map((e) {
                  final id = e.value;
                  final name = _imposterName(id, e.key, players);
                  final idx = players.indexWhere((p) => p.id == id);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _PlayerRow(
                      name: name,
                      avatarColor: _avatarColor(idx >= 0 ? idx : e.key),
                      badge: 'IMPOSTER',
                      badgeRed: true,
                      trailingIcon: '😈',
                    ),
                  );
                }),
              ],
            ),
          ),

          if (elims.isNotEmpty) ...[
            Divider(color: _border, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel('ELIMINATED THIS GAME'),
                  const SizedBox(height: 10),
                  ...elims.asMap().entries.map((e) {
                    final entry = e.value;
                    final wasImp =
                        (results.imposters).contains(entry.id) ||
                        ((roomState.allImposters as List?) ?? []).contains(
                          entry.id,
                        );
                    final idx = players.indexWhere((p) => p.id == entry.id);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _PlayerRow(
                        name: entry.name,
                        avatarColor: _avatarColor(idx >= 0 ? idx : e.key),
                        badge: wasImp ? 'IMPOSTER' : 'ELIMINATED',
                        badgeRed: wasImp,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── VOTE BREAKDOWN ─────────────────────────────────────────────────────────

  Widget _buildVoteBreakdown({
    required List<PlayerInfo> sortedPlayers,
    required List<PlayerInfo> players,
    required Map<String, int> tally,
    required int maxTally,
    required List<String> imposters,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  'VOTE BREAKDOWN',
                  style: GoogleFonts.barlow(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                Text(
                  'Final tally results',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: _white38,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // rows
          ...sortedPlayers.map((p) {
            final idx = players.indexWhere((x) => x.id == p.id);
            final count = tally[p.id] ?? 0;
            final isImp = imposters.contains(p.id);
            final barClr = isImp ? _red : _avatarColor(idx >= 0 ? idx : 0);
            final frac = maxTally > 0 ? count / maxTally : 0.0;

            return Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isImp
                    ? _red.withOpacity(0.06)
                    : Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isImp ? _red.withOpacity(0.2) : _border,
                ),
              ),
              child: Row(
                children: [
                  // avatar
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: _avatarColor(idx >= 0 ? idx : 0),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      (p.name)[0].toUpperCase(),
                      style: GoogleFonts.barlow(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // name + bar
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              p.name,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            if (isImp) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _red.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(
                                    color: _red.withOpacity(0.4),
                                  ),
                                ),
                                child: Text(
                                  'IMPOSTER',
                                  style: GoogleFonts.barlow(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: _red,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        // bar track
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: Stack(
                            children: [
                              Container(
                                height: 5,
                                color: Colors.white.withOpacity(0.06),
                              ),
                              FractionallySizedBox(
                                widthFactor: frac.clamp(0.0, 1.0),
                                child: Container(
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: barClr,
                                    boxShadow: [
                                      BoxShadow(
                                        color: barClr.withOpacity(0.5),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  // vote count
                  SizedBox(
                    width: 18,
                    child: Text(
                      '$count',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.barlow(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: count > 0 ? Colors.white : _white38,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 6),
        ],
      ),
    );
  }

  // ── ACTION BAR ─────────────────────────────────────────────────────────────

  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: _bg,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: isHost
          ? Row(
              children: [
                Expanded(
                  child: _ActionBtn(
                    label: 'PLAY AGAIN →',
                    filled: true,
                    onTap: onPlayAgain,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionBtn(
                    label: 'LEAVE ROOM',
                    filled: false,
                    onTap: onLeave,
                  ),
                ),
              ],
            )
          : _ActionBtn(label: 'LEAVE ROOM', filled: false, onTap: onLeave),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

/// Word card (innocent / imposter).
class _WordCard extends StatelessWidget {
  final String label;
  final String word;
  final bool red;

  const _WordCard({required this.label, required this.word, required this.red});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.barlow(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: _white38,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            word,
            style: GoogleFonts.barlow(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: red ? const Color(0xFFF87171) : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Section label inside panels.
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.barlow(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: _white38,
        letterSpacing: 1.5,
      ),
    );
  }
}

/// Player row inside imposters / eliminated sections.
class _PlayerRow extends StatelessWidget {
  final String name;
  final Color avatarColor;
  final String badge;
  final bool badgeRed;
  final String? trailingIcon;

  const _PlayerRow({
    required this.name,
    required this.avatarColor,
    required this.badge,
    required this.badgeRed,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: avatarColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              name[0].toUpperCase(),
              style: GoogleFonts.barlow(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: badgeRed ? _red.withOpacity(0.2) : _white12,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: badgeRed
                          ? _red.withOpacity(0.4)
                          : const Color(0xFF374151),
                    ),
                  ),
                  child: Text(
                    badge,
                    style: GoogleFonts.barlow(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: badgeRed ? _red : _white38,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (trailingIcon != null)
            Text(trailingIcon!, style: const TextStyle(fontSize: 20)),
        ],
      ),
    );
  }
}

/// PLAY AGAIN / LEAVE ROOM button.
class _ActionBtn extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: filled ? _purple.withOpacity(0.85) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: filled ? _purple : const Color(0xFF374151)),
          boxShadow: filled
              ? [BoxShadow(color: _purple.withOpacity(0.35), blurRadius: 18)]
              : [],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.barlow(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: filled ? Colors.white : _white70,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}
