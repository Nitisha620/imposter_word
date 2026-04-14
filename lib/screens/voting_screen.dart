import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:word_imposter/state/room_state.dart';

import '../state/player_info.dart';

// ─── Colours ─────────────────────────────────────────────────────────────────
const _bg = Color(0xFF0B0F1A);
const _card = Color(0xFF131929);
const _border = Color(0xFF1E2740);
const _purple = Color(0xFF7C6EF5);
const _purpleDim = Color(0xFF4B44A0);
const _white70 = Color(0xB3FFFFFF);
const _white38 = Color(0x61FFFFFF);
const _white12 = Color(0x1FFFFFFF);
const _green = Color(0xFF34D399);

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

// ─── Elimination announcement model ─────────────────────────────────────────
class EliminationAnnouncement {
  final String name;
  final bool imposterCaught;
  const EliminationAnnouncement({
    required this.name,
    required this.imposterCaught,
  });
}

// ─── VotingScreen ─────────────────────────────────────────────────────────────
class VotingScreen extends StatelessWidget {
  final RoomState roomState;
  final String myId;
  final bool isHost;
  final bool isEliminated;

  final void Function(String playerId) onCastVote;
  final VoidCallback onFinalize;
  final VoidCallback onStartDiscussion;

  const VotingScreen({
    super.key,
    required this.roomState,
    required this.myId,
    required this.isHost,
    required this.isEliminated,
    required this.onCastVote,
    required this.onFinalize,
    required this.onStartDiscussion,
  });

  // ── derived helpers ────────────────────────────────────────────────────────

  List<String> get _eliminatedIds =>
      // Mirrors: (roomState?.eliminatedSoFar || []).map(e => typeof e === "object" ? e.id : e)
      roomState.eliminatedSoFar.map((e) => e['id']?.toString() ?? '').toList();

  List<PlayerInfo> get _allPlayers =>
      // Mirrors: Object.values(roomState?.players || {}).sort((a,b) => a.joinedAt - b.joinedAt)
      roomState.players.values.toList()
        ..sort((a, b) => a.joinedAt.compareTo(b.joinedAt));

  List<PlayerInfo> get _players =>
      // Mirrors: allPlayers.filter(p => !eliminatedIds.includes(p.id))
      _allPlayers.where((p) => !_eliminatedIds.contains(p.id)).toList();

  Map<String, String> get _votes =>
      // Mirrors: roomState?.votes || {}
      roomState.votes ?? {};

  String? get _myVote => _votes[myId];

  int get _totalVoted =>
      // Mirrors: Object.keys(votes).filter(id => !eliminatedIds.includes(id)).length
      _votes.keys.where((id) => !_eliminatedIds.contains(id)).length;

  Map<String, int> get _tally {
    // Mirrors: Object.values(votes).forEach(vid => { tally[vid] = (tally[vid]||0)+1 })
    final t = <String, int>{};
    for (final vid in _votes.values) {
      t[vid] = (t[vid] ?? 0) + 1;
    }
    return t;
  }

  EliminationAnnouncement? get _announcement {
    // Mirrors: roomState?.eliminationAnnouncement || null
    final a = roomState.eliminationAnnouncement;
    if (a == null) return null;
    return EliminationAnnouncement(
      name: a['name']?.toString() ?? '',
      imposterCaught: a['imposterCaught'] == true,
    );
  }

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final players = _players;
    final total = players.length;
    final totalVoted = _totalVoted;
    final tally = _tally;
    final myVote = _myVote;
    final announcement = _announcement;

    final statusText = isEliminated
        ? 'Spectating — you were eliminated'
        : myVote != null
        ? 'Vote cast — waiting for ${total - totalVoted} more'
        : 'Tap a player to cast your vote';

    final progress = total > 0 ? totalVoted / total : 0.0;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── HEADER ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              child: Column(
                children: [
                  Text(
                    'VOTE',
                    style: GoogleFonts.barlow(
                      fontSize: 52,
                      fontWeight: FontWeight.w900,
                      color: _purple,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusText,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 13.5, color: _white70),
                  ),
                  const SizedBox(height: 14),
                  // Progress bar
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 5,
                            backgroundColor: _white12,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              _purple,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '$totalVoted / $total voted',
                        style: GoogleFonts.barlow(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _white38,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── GRID ────────────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: _border),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.88,
                        ),
                    itemCount: players.length,
                    itemBuilder: (context, i) {
                      final p = players[i];
                      final allIdx = _allPlayers.indexWhere(
                        (x) => x.id == p.id,
                      );
                      final isSelf = p.id == myId;
                      final isVotedFor = myVote == p.id;
                      final hasVoted = _votes.containsValue(p.id);
                      final canVote =
                          !isEliminated && !isSelf && announcement == null;
                      final count = tally[p.id] ?? 0;
                      final color =
                          _avatarColors[(allIdx >= 0 ? allIdx : i) %
                              _avatarColors.length];

                      return _VoteCard(
                        name: p.name,
                        avatarColor: color,
                        isSelf: isSelf,
                        isVotedFor: isVotedFor,
                        hasVoted: hasVoted,
                        canVote: canVote,
                        voteCount: count,
                        onTap: canVote ? () => onCastVote(p.id) : null,
                      );
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── BOTTOM ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: announcement != null
                  ? _buildAnnouncement(announcement)
                  : isHost
                  ? _buildRevealBtn(totalVoted > 0)
                  : _buildWaitingPill(
                      isEliminated
                          ? 'Waiting for results…'
                          : 'Waiting for host to reveal results…',
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── ANNOUNCEMENT ──────────────────────────────────────────────────────────
  Widget _buildAnnouncement(EliminationAnnouncement a) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              const Text('💀', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${a.name} was eliminated',
                      style: GoogleFonts.barlow(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      a.imposterCaught
                          ? '😈 They were an imposter!'
                          : '😇 They were innocent…',
                      style: GoogleFonts.inter(fontSize: 13, color: _white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        isHost
            ? _buildActionBtn('START DISCUSSION →', onStartDiscussion)
            : _buildWaitingPill('Waiting for host to start discussion…'),
      ],
    );
  }

  /* Widget _buildRevealBtn(bool enabled) => */
  /*     _buildActionBtn('REVEAL RESULTS →', true ? onFinalize : null); */

  // NEW — mirrors React's disabled={totalVoted === 0}:
  Widget _buildRevealBtn(bool enabled) =>
      _buildActionBtn('REVEAL RESULTS →', enabled ? onFinalize : null);

  Widget _buildActionBtn(String label, VoidCallback? onTap) {
    final active = onTap != null;
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 17),
          decoration: BoxDecoration(
            color: active ? _purpleDim : _purpleDim.withOpacity(0.3),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active ? _purple.withOpacity(0.7) : _border,
            ),
            boxShadow: active
                ? [BoxShadow(color: _purple.withOpacity(0.3), blurRadius: 20)]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.barlow(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: active ? Colors.white : _white38,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWaitingPill(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: _white12,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PulseDot(),
          const SizedBox(width: 10),
          Text(text, style: GoogleFonts.inter(fontSize: 13, color: _white70)),
        ],
      ),
    );
  }
}

// ─── Vote card ────────────────────────────────────────────────────────────────
class _VoteCard extends StatelessWidget {
  final String name;
  final Color avatarColor;
  final bool isSelf;
  final bool isVotedFor;
  final bool hasVoted;
  final bool canVote;
  final int voteCount;
  final VoidCallback? onTap;

  const _VoteCard({
    required this.name,
    required this.avatarColor,
    required this.isSelf,
    required this.isVotedFor,
    required this.hasVoted,
    required this.canVote,
    required this.voteCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: isSelf
              ? const Color(0xFF1A1F35)
              : isVotedFor
              ? _purple.withOpacity(0.15)
              : const Color(0xFF131929),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isVotedFor
                ? _purple
                : isSelf
                ? _purple.withOpacity(0.3)
                : const Color(0xFF1E2740),
            width: isVotedFor ? 1.5 : 1,
          ),
          boxShadow: isVotedFor
              ? [BoxShadow(color: _purple.withOpacity(0.25), blurRadius: 14)]
              : [],
        ),
        child: Stack(
          children: [
            // ── tick badge ─────────────────────────────────────────────────
            Positioned(
              top: 10,
              right: 10,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hasVoted
                      ? _green.withOpacity(0.25)
                      : Colors.white.withOpacity(0.06),
                  border: Border.all(
                    color: hasVoted ? _green : const Color(0xFF1E2740),
                  ),
                ),
                alignment: Alignment.center,
                child: hasVoted
                    ? const Text(
                        '✓',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _green,
                        ),
                      )
                    : null,
              ),
            ),

            // ── main content ───────────────────────────────────────────────
            Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Avatar
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: avatarColor,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      name[0].toUpperCase(),
                      style: GoogleFonts.barlow(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Name
                  Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  // YOU badge
                  if (isSelf) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _purple.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _purple.withOpacity(0.4)),
                      ),
                      child: Text(
                        'YOU',
                        style: GoogleFonts.barlow(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: _purple,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 6),

                  // Vote count
                  Text(
                    '$voteCount ${voteCount == 1 ? 'vote' : 'votes'}',
                    style: GoogleFonts.barlow(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: voteCount > 0 ? Colors.white : _white38,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Pulsing dot ──────────────────────────────────────────────────────────────
class _PulseDot extends StatefulWidget {
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  late final Animation<double> _anim = Tween<double>(
    begin: 0.3,
    end: 1.0,
  ).animate(_ctrl);

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _anim,
    child: Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(color: _purple, shape: BoxShape.circle),
    ),
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}
