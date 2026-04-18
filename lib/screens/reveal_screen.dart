import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/room_state.dart';
import '../theme/app_colors.dart';
import '../widgets/player_card.dart';
import '../widgets/primary_button.dart';
import '../widgets/pulse_dot.dart';
import '../widgets/role_badge.dart';

// ── Reveal Screen ─────────────────────────────────────────────────────────────────
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

  int get _readyCount => widget.roomState.revealReady?.length ?? 0;

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
    if (_allReady && widget.isHost && !_doneFired) {
      _doneFired = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onDone();
      });
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
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
        shaderCallback: (b) => const LinearGradient(
          colors: [AppColors.accent, AppColors.pink],
        ).createShader(b),
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
        style: TextStyle(
          color: AppColors.textMuted,
          fontSize: 13.5,
          height: 1.5,
        ),
      ),
    ],
  );

  // ── Locked card ────────────────────────────────────────────────────────
  Widget _buildLockedCard() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.border),
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
              color: AppColors.surfaceAlt,
              border: Border.all(color: AppColors.border, width: 1.5),
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
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Hidden until you are ready',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 24),
        PrimaryButton(label: 'REVEAL MY WORD', onTap: _reveal),
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
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isImposterCard
                  ? AppColors.red.withOpacity(0.4)
                  : AppColors.accent.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (_isImposterCard ? AppColors.red : AppColors.accent)
                    .withOpacity(0.08),
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              // Role badge
              if (isBlindImposter)
                RoleBadge(label: '😈 IMPOSTER', isImposter: true)
              else
                RoleBadge(label: _roleLabel, isImposter: _isImposterCard),
              const SizedBox(height: 20),

              // Word display
              if (isBlindImposter) ...[
                const Text(
                  '—',
                  style: TextStyle(fontSize: 44, color: AppColors.textMuted),
                ),
                const SizedBox(height: 12),
                const Text(
                  'No word for you. Listen carefully and bluff!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13.5),
                ),
              ] else ...[
                Text(
                  _displayWord ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (_hintText.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    _hintText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],

              const SizedBox(height: 24),

              // Ready / waiting
              if (!_iMeReady)
                PrimaryButton(
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
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
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
        style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
      ),
      const SizedBox(height: 8),
      // Thin progress line
      ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: LinearProgressIndicator(
          value: _totalPlayers == 0 ? 0 : _readyCount / _totalPlayers,
          backgroundColor: AppColors.border,
          valueColor: const AlwaysStoppedAnimation(AppColors.accent),
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
            PulseDot(),
            const SizedBox(width: 10),
            const Text(
              'Waiting for everyone to read their word…',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
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
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                '$_readyCount / $_totalPlayers READY',
                style: const TextStyle(
                  color: AppColors.textMuted,
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
            final color =
                AppColors.avatarColors[i % AppColors.avatarColors.length];
            return PlayerCard(
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
