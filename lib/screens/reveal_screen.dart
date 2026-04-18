import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/player_info.dart';
import '../state/room_state.dart';

// ── Palette ────────────────────────────────────────────────────────────────
const _bg = Color(0xFF0F0D1A);
const _surface = Color(0xFF1A1730);
const _surfaceAlt = Color(0xFF1E1B2E);
const _border = Color(0xFF2E2A45);
const _accent = Color(0xFF9B8FFF);
const _accentSoft = Color(0xFF6D5FFD);
const _text = Color(0xFFE8E4FF);
const _textMuted = Color(0xFF8B86A8);
const _green = Color(0xFF34D399);
const _amber = Color(0xFFFBBF24);
const _red = Color(0xFFF87171);
const _pink = Color(0xFFE879F9);

const _avatarColors = [
  Color(0xFF6D62F5),
  Color(0xFFF87171),
  Color(0xFF34D399),
  Color(0xFFFBBF24),
  Color(0xFF38BDF8),
  Color(0xFFF472B6),
  Color(0xFFA3E635),
  Color(0xFFFB923C),
  Color(0xFFE879F9),
  Color(0xFF2DD4BF),
];

// ── Fake data models (replace with your actual state) ─────────────────────

// ── Screen ─────────────────────────────────────────────────────────────────
class RevealScreen extends ConsumerStatefulWidget {
  final RoomState roomState;
  final String myId;
  final bool isHost;
  final VoidCallback onDone;
  final VoidCallback onMarkReady;
  final VoidCallback onChangeWord;
  final VoidCallback onBackToLobby;

  const RevealScreen({
    super.key,
    required this.roomState,
    required this.myId,
    required this.isHost,
    required this.onDone,
    required this.onMarkReady,
    required this.onChangeWord,
    required this.onBackToLobby,
  });

  @override
  ConsumerState<RevealScreen> createState() => _RevealScreenState();
}

class _RevealScreenState extends ConsumerState<RevealScreen>
    with TickerProviderStateMixin {
  bool _confirmed = false;

  late final AnimationController _lockCtrl;
  late final Animation<double> _lockScale;
  late final AnimationController _cardCtrl;
  late final Animation<double> _cardFade;
  late final Animation<Offset> _cardSlide;

  // Add this field to _RevealScreenState:
  bool _doneFired = false;

  @override
  void initState() {
    super.initState();

    _lockCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _lockScale = Tween(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _lockCtrl, curve: Curves.easeInOut));

    _cardCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _cardFade = CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut);
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(RevealScreen old) {
    super.didUpdateWidget(old);

    // Mirrors React's useState(false) resetting on remount —
    // when assignments change (new word/new round), reset local reveal state
    final oldAssignments = old.roomState.assignments;
    final newAssignments = widget.roomState.assignments;

    // Detect new round: assignments replaced entirely (e.g. after changeWord or playAgain)
    // Compare mainWord as a proxy — if it changed, new assignments were issued
    final wordChanged = old.roomState.mainWord != widget.roomState.mainWord;
    final assignmentsCleared = oldAssignments != null && newAssignments == null;

    if (wordChanged || assignmentsCleared) {
      setState(() {
        _confirmed = false;
        _doneFired = false;
      });
      // Restart the lock animation
      _lockCtrl.repeat(reverse: true);
      _cardCtrl.reset();
    }

    // Also reset _doneFired if revealReady was wiped (host changed word mid-round)
    // Mirrors: onChangeWord resetting revealReady: {}
    final wasReady = (old.roomState.revealReady?.length ?? 0) > 0;
    final nowEmpty = (widget.roomState.revealReady?.length ?? 0) == 0;
    if (wasReady && nowEmpty && _doneFired) {
      setState(() => _doneFired = false);
    }
  }

  @override
  void dispose() {
    _lockCtrl.dispose();
    _cardCtrl.dispose();
    super.dispose();
  }

  void _reveal() {
    setState(() => _confirmed = true);
    _lockCtrl.stop();
    _cardCtrl.forward();
  }

  // ── Derived state ──────────────────────────────────────────────────────
  Assignment get _myAssignment =>
      widget.roomState.assignments?[widget.myId] ??
      const Assignment(role: 'innocent', word: '');

  bool get _isImposter => _myAssignment.role == 'imposter';
  String get _gameMode => widget.roomState.gameMode;

  bool get _iMeReady => widget.roomState.revealReady?[widget.myId] ?? false;
  // Fix — mirrors: Object.keys(revealReady).length
  int get _readyCount => widget.roomState.revealReady?.length ?? 0;
  /* int get _readyCount =>
      widget.roomState.revealReady?.values.where((v) => v).length ?? 0; */
  int get _totalPlayers => widget.roomState.assignments?.length ?? 0;
  bool get _allReady => _readyCount >= _totalPlayers;

  String get _roleLabel {
    if (!_isImposter) return '🕵️ INNOCENT';
    if (_gameMode == 'knows' || _gameMode == 'blind') return '😈 IMPOSTER';
    return '🕵️ INNOCENT';
  }

  String? get _displayWord {
    if (_isImposter && _gameMode == 'blind') return null;
    return _myAssignment.word;
  }

  bool get _isImposterCard => _isImposter && _gameMode == 'knows';

  String get _hintText {
    if (!_isImposter) return 'Describe this word without saying it directly.';
    if (_gameMode == 'knows') return 'You have a different word — blend in!';
    if (_gameMode == 'secret') {
      return 'Describe this word without saying it directly.';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    // Side effect: when all ready and host, trigger onDone
    /* if (_allReady && widget.isHost) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onDone());
    } */

    if (_allReady && widget.isHost && !_doneFired) {
      _doneFired = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onDone();
      });
    }

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTitle(),
              const SizedBox(height: 24),
              _confirmed ? _buildRevealedCard() : _buildLockedCard(),
              const SizedBox(height: 28),
              _buildRoster(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Title ──────────────────────────────────────────────────────────────
  Widget _buildTitle() => Column(
    children: [
      ShaderMask(
        shaderCallback: (b) =>
            const LinearGradient(colors: [_accent, _pink]).createShader(b),
        child: const Text(
          'Your Word',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
      ),
      const SizedBox(height: 8),
      const Text(
        'Prepare yourself. Once revealed, the game begins. Keep it secret.',
        textAlign: TextAlign.center,
        style: TextStyle(color: _textMuted, fontSize: 13.5, height: 1.5),
      ),
    ],
  );

  // ── Locked card ────────────────────────────────────────────────────────
  Widget _buildLockedCard() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _border),
    ),
    child: Column(
      children: [
        ScaleTransition(
          scale: _lockScale,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _surfaceAlt,
              border: Border.all(color: _border, width: 1.5),
            ),
            child: const Center(
              child: Text('🔒', style: TextStyle(fontSize: 32)),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Tap to reveal',
          style: TextStyle(
            color: _text,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Hidden until you are ready',
          style: TextStyle(color: _textMuted, fontSize: 13),
        ),
        const SizedBox(height: 24),
        _PrimaryButton(label: 'REVEAL MY WORD', onTap: _reveal),
      ],
    ),
  );

  // ── Revealed card ──────────────────────────────────────────────────────
  Widget _buildRevealedCard() {
    final isBlindImposter = _isImposter && _gameMode == 'blind';

    return FadeTransition(
      opacity: _cardFade,
      child: SlideTransition(
        position: _cardSlide,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isImposterCard
                  ? _red.withOpacity(0.4)
                  : _accent.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (_isImposterCard ? _red : _accent).withOpacity(0.08),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              // Role badge
              if (isBlindImposter)
                _RoleBadge(label: '😈 IMPOSTER', isImposter: true)
              else
                _RoleBadge(label: _roleLabel, isImposter: _isImposterCard),
              const SizedBox(height: 20),

              // Word display
              if (isBlindImposter) ...[
                const Text(
                  '—',
                  style: TextStyle(fontSize: 44, color: _textMuted),
                ),
                const SizedBox(height: 12),
                const Text(
                  'No word for you. Listen carefully and bluff!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _textMuted, fontSize: 13.5),
                ),
              ] else ...[
                Text(
                  _displayWord ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                    color: _text,
                  ),
                ),
                if (_hintText.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    _hintText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: _textMuted, fontSize: 13),
                  ),
                ],
              ],

              const SizedBox(height: 24),

              // Ready / waiting
              if (!_iMeReady)
                _PrimaryButton(
                  label: "I'VE READ MY WORD — READY ✓",
                  onTap: widget.onMarkReady,
                )
              else
                _buildWaitingBlock(),

              // Host change-word button
              if (widget.isHost) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _doneFired = false;
                      _confirmed =
                          false; // lock the card again for the host too
                    });
                    widget.onChangeWord();
                  },
                  icon: const Text('🔁', style: TextStyle(fontSize: 14)),
                  label: const Text(
                    'Change Word',
                    style: TextStyle(color: _textMuted, fontSize: 13),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWaitingBlock() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // Ready count — centered
      Text(
        '$_readyCount/$_totalPlayers players ready',
        textAlign: TextAlign.center,
        style: const TextStyle(color: _textMuted, fontSize: 13),
      ),
      const SizedBox(height: 8),
      // Thin progress line
      ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: LinearProgressIndicator(
          value: _totalPlayers == 0 ? 0 : _readyCount / _totalPlayers,
          backgroundColor: _border,
          valueColor: const AlwaysStoppedAnimation(_accent),
          minHeight: 3,
        ),
      ),
      const SizedBox(height: 14),
      // Full-width waiting container
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF12101F),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PulseDot(),
            const SizedBox(width: 10),
            const Text(
              'Waiting for everyone to read their word…',
              style: TextStyle(color: _text, fontSize: 13),
            ),
          ],
        ),
      ),
    ],
  );

  // ── Roster ─────────────────────────────────────────────────────────────
  Widget _buildRoster() {
    final playersList = widget.roomState.players.values.toList()
      ..sort((a, b) => a.joinedAt.compareTo(b.joinedAt));
    // final players = widget.roomState.players.entries;
    // ..sort((a, b) => a.joinedAt.compareTo(b.joinedAt));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Player Roster',
              style: TextStyle(
                color: _text,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _surfaceAlt,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: _border),
              ),
              child: Text(
                '$_readyCount / $_totalPlayers READY',
                style: const TextStyle(
                  color: _textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.78,
          ),
          itemCount: playersList.length,
          itemBuilder: (context, i) {
            final p = playersList.elementAt(i);
            final isMe = p.id == widget.myId;
            final isHost = p.id == widget.roomState.host;
            final isReady = widget.roomState.revealReady?[p.id] ?? false;
            final color = _avatarColors[i % _avatarColors.length];
            return _PlayerCard(
              player: p,
              isMe: isMe,
              isHost: isHost,
              isReady: isReady,
              avatarColor: color,
            );
          },
        ),
      ],
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────

class _RoleBadge extends StatelessWidget {
  final String label;
  final bool isImposter;
  const _RoleBadge({required this.label, required this.isImposter});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(
      color: (isImposter ? _red : _accent).withOpacity(0.12),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(
        color: (isImposter ? _red : _accent).withOpacity(0.35),
      ),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: isImposter ? _red : _accent,
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    ),
  );
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: _accent.withOpacity(0.18),
        foregroundColor: _accent,
        side: const BorderSide(color: _accent, width: 1.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
        padding: const EdgeInsets.symmetric(vertical: 15),
        elevation: 0,
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          letterSpacing: 0.8,
        ),
      ),
    ),
  );
}

class _PulseDot extends StatefulWidget {
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _anim,
    child: Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: _accent),
    ),
  );
}

class _PlayerCard extends StatelessWidget {
  final PlayerInfo player;
  final bool isMe, isHost, isReady;
  final Color avatarColor;
  const _PlayerCard({
    required this.player,
    required this.isMe,
    required this.isHost,
    required this.isReady,
    required this.avatarColor,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: isMe ? _accentSoft.withOpacity(0.12) : _surfaceAlt,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: isMe ? _accent.withOpacity(0.4) : _border,
        width: 1.2,
      ),
    ),
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
    child: Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: avatarColor,
                ),
                child: Center(
                  child: Text(
                    player.name[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // Name
              Text(
                isMe ? '${player.name} (You)' : player.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _text,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              // Status chip
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isReady ? _green : _amber,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isReady ? 'READY' : 'WAITING...',
                    style: TextStyle(
                      color: isReady ? _green : _amber,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // HOST badge
          if (isHost)
            Positioned(
              top: -18,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _accentSoft,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Text(
                    'HOST',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
