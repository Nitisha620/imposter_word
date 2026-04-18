import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:word_imposter/state/room_state.dart';

import '../models/chat_message.dart';
import '../models/eliminated_entry.dart';
import '../state/player_info.dart';
import '../theme/app_colors.dart';
import '../widgets/avatar_circle.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/pulse_dot.dart';
import '../widgets/role_badge.dart';
import '../widgets/round_pill.dart';
import '../widgets/timer_block.dart';

// ── Screen ─────────────────────────────────────────────────────────────────
class DiscussionScreen extends ConsumerStatefulWidget {
  final RoomState roomState; // your RoomState type
  final String myId;
  final bool isHost;
  final bool isEliminated;
  final List<ChatMessage> chatMessages;
  final void Function(String text) onSendChat;
  final VoidCallback onStartVote;

  const DiscussionScreen({
    super.key,
    required this.roomState,
    required this.myId,
    required this.isHost,
    required this.isEliminated,
    this.chatMessages = const [],
    required this.onSendChat,
    required this.onStartVote,
  });

  @override
  ConsumerState<DiscussionScreen> createState() => _DiscussionScreenState();
}

class _DiscussionScreenState extends ConsumerState<DiscussionScreen>
    with SingleTickerProviderStateMixin {
  final _chatController = TextEditingController();
  final _scrollController = ScrollController();
  late Timer? _timer;
  int _timeLeft = 0;

  bool _voteFired = false;

  // ── Derived helpers ───────────────────────────────────────────────────
  DateTime? get _endTime {
    final ms = widget.roomState.discussionEnd;
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  int get _timerSecs => widget.roomState.timerSecs;
  bool get _hasTimer => _endTime != null && _timerSecs > 0;
  bool get _urgent => _hasTimer && _timeLeft <= 20;
  int get _elimCount => _eliminatedEntries.length;

  bool get _isImposter =>
      widget.roomState.assignments?[widget.myId]?.role == 'imposter';

  // Fix _eliminatedEntries:
  List<EliminatedEntry> get _eliminatedEntries => widget
      .roomState
      .eliminatedSoFar
      .map(
        (e) => EliminatedEntry(
          id: e['id']?.toString() ?? '',
          name: e['name']?.toString() ?? 'Unknown',
        ),
      )
      .toList();

  List<PlayerInfo> get _allPlayersList =>
      widget.roomState.players.values.toList()
        ..sort((a, b) => a.joinedAt.compareTo(b.joinedAt));

  List<PlayerInfo> get _activePlayersList {
    final elimIds = _eliminatedEntries.map((e) => e.id).toSet();
    return _allPlayersList.where((p) => !elimIds.contains(p.id)).toList();
  }

  int _avatarIndex(String id) {
    final idx = _allPlayersList.indexWhere((p) => p.id == id);
    return idx >= 0 ? idx : 0;
  }

  String get _roundLabel =>
      _elimCount > 0 ? 'ROUND ${_elimCount + 1}' : 'ROUND 01';

  String get _hintText {
    if (widget.roomState.tieVote) {
      return 'It was a tie! Discuss again and vote.';
    }
    if (_isImposter) return 'Blend in. Don\'t reveal your word.';
    return 'Analyze clues. Find the imposter.';
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _initTimer();
  }

  void _initTimer() {
    _voteFired = false; // reset every time timer is initialized

    if (!_hasTimer) {
      _timer = null;
      return;
    }

    _timeLeft = _calcTimeLeft();

    // Skip the first tick — prevents firing immediately if discussionEnd
    // is already in the past when we initialize (e.g. after a tie vote restart)
    bool firstTick = true;

    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted) return;
      final t = _calcTimeLeft();
      setState(() => _timeLeft = t);

      if (firstTick) {
        firstTick = false;
        return;
      }

      // Guard: don't fire if we already fired, or if we're not the host,
      // or if the phase has changed away from discussion
      if (t == 0 && widget.isHost && !_voteFired) {
        _voteFired = true;
        _timer?.cancel();
        // Post-frame to avoid calling setState/navigation during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onStartVote();
        });
      }
    });
  }

  int _calcTimeLeft() {
    if (_endTime == null) return 0;
    return (_endTime!.difference(DateTime.now()).inSeconds).clamp(0, 99999);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendChat() {
    final text = _chatController.text.trim();
    if (text.isEmpty || widget.isEliminated) return;
    widget.onSendChat(text);
    _chatController.clear();
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void didUpdateWidget(covariant DiscussionScreen old) {
    super.didUpdateWidget(old);

    // ── Stop timer if phase changed away from discussion ──────────────
    // This happens when host kicks → results, or vote fires → voting
    if (widget.roomState.phase != 'discussion') {
      _timer?.cancel();
      _timer = null;
      return; // no need to do anything else
    }

    // ── Restart timer when discussionEnd changes ───────────────────────
    if (old.roomState.discussionEnd != widget.roomState.discussionEnd) {
      _timer?.cancel();
      _initTimer();
    }

    // ── Auto-scroll on new chat messages ──────────────────────────────
    if (widget.chatMessages.length != old.chatMessages.length) {
      Future.delayed(const Duration(milliseconds: 80), _scrollToBottom);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top: role+timer card
            _buildRoleTimerCard(),
            const SizedBox(height: 8),
            // Players row card
            _buildPlayersCard(),
            const SizedBox(height: 8),
            // Chat — fills remaining space
            Expanded(child: _buildChat()),
            // Input row (attached below chat)
            _buildInputRow(),
            // Vote action bar
            _buildActionBar(),
          ],
        ),
      ),
    );
  }

  // ── TOP: ROLE + TIMER CARD ─────────────────────────────────────────────
  Widget _buildRoleTimerCard() => Container(
    margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RoleBadge(
              label: widget.isEliminated
                  ? '💀 SPECTATING'
                  : _isImposter
                  ? '😈 IMPOSTER'
                  : '🕵️ INNOCENT',
              isImposter: _isImposter,
              variant: widget.isEliminated
                  ? BadgeVariant.dead
                  : _isImposter
                  ? BadgeVariant.imposter
                  : BadgeVariant.innocent,
            ),
            const SizedBox(height: 8),
            Text(
              _hintText,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
        const Spacer(),
        if (_hasTimer)
          TimerBlock(timeLeft: _timeLeft, urgent: _urgent)
        else
          RoundPill(label: _roundLabel),
      ],
    ),
  );

  // ── PLAYERS CARD — avatars as circles in a horizontal row ──────────────
  Widget _buildPlayersCard() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 12),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PLAYERS',
          style: TextStyle(
            color: AppColors.accent,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            // Active players
            ..._activePlayersList.map((p) {
              final id = p.id;
              final name = p.name;
              final color =
                  AppColors.avatarColors[_avatarIndex(id) %
                      AppColors.avatarColors.length];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: AvatarCircle(
                  name: name,
                  color: color,
                  isEliminated: false,
                ),
              );
            }),
            // Eliminated players (faded)
            ..._eliminatedEntries.map((e) {
              final idx = _avatarIndex(e.id);
              final color =
                  AppColors.avatarColors[idx % AppColors.avatarColors.length];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: AvatarCircle(
                  name: e.name,
                  color: color,
                  isEliminated: true,
                ),
              );
            }),
          ],
        ),
      ],
    ),
  );

  // ── CHAT ───────────────────────────────────────────────────────────────
  Widget _buildChat() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
      ),
      border: Border.all(color: AppColors.border),
    ),
    child: widget.chatMessages.isEmpty
        ? const Center(
            child: Text(
              '💬  Speak up — discuss who you think the imposter is.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 13.5),
            ),
          )
        : ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(14),
            itemCount: widget.chatMessages.length,
            itemBuilder: (context, i) {
              final msg = widget.chatMessages[i];
              final isMe = msg.senderId == widget.myId;
              final idx = _avatarIndex(msg.senderId);
              final color =
                  AppColors.avatarColors[idx % AppColors.avatarColors.length];
              return ChatBubble(msg: msg, isMe: isMe, avatarColor: color);
            },
          ),
  );

  // ── INPUT ROW ──────────────────────────────────────────────────────────
  Widget _buildInputRow() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 12),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(16),
        bottomRight: Radius.circular(16),
      ),
      border: Border(
        left: BorderSide(color: AppColors.border),
        right: BorderSide(color: AppColors.border),
        bottom: BorderSide(color: AppColors.border),
      ),
    ),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: _chatController,
            enabled: !widget.isEliminated,
            maxLength: 200,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            onSubmitted: (_) => _sendChat(),
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'Say something…',
              hintStyle: TextStyle(color: AppColors.textMuted),
              border: InputBorder.none,
              isDense: true,
              counterText: '',
              contentPadding: EdgeInsets.symmetric(vertical: 4),
            ),
          ),
        ),
        const SizedBox(width: 10),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _chatController,
          builder: (_, val, __) {
            final canSend = val.text.trim().isNotEmpty && !widget.isEliminated;
            return GestureDetector(
              onTap: canSend ? _sendChat : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: canSend ? AppColors.accentSoft : AppColors.border,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            );
          },
        ),
      ],
    ),
  );

  // ── ACTION BAR ─────────────────────────────────────────────────────────
  Widget _buildActionBar() {
    if (widget.isHost) {
      return GestureDetector(
        onTap: widget.onStartVote,
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: AppColors.accentSoft,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Text(
              'START VOTING →',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PulseDot(),
          const SizedBox(width: 10),
          Text(
            widget.isEliminated
                ? 'Spectating…'
                : 'Host will start voting when ready',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
