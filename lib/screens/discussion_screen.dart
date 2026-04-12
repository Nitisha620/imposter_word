import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_message.dart';

// ── Palette ────────────────────────────────────────────────────────────────
const _bg = Color(0xFF0A0814);
const _surface = Color(0xFF13111F);
const _surfaceAlt = Color(0xFF1A1730);
const _border = Color(0xFF2E2A45);
const _accent = Color(0xFF9B8FFF);
const _accentSoft = Color(0xFF6D5FFD);
const _text = Color(0xFFE8E4FF);
const _textMuted = Color(0xFF8B86A8);
const _green = Color(0xFF34D399);
const _red = Color(0xFFF87171);

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

class EliminatedEntry {
  final String id, name;
  const EliminatedEntry({required this.id, required this.name});
}

// ── Screen ─────────────────────────────────────────────────────────────────
class DiscussionScreen extends ConsumerStatefulWidget {
  final dynamic roomState; // your RoomState type
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

  // ── Derived helpers ───────────────────────────────────────────────────
  // Replace these getters with your actual RoomState field access
  DateTime? get _endTime =>
      DateTime.now(); /*  widget.roomState?.discussionEnd as DateTime?; */
  int get _timerSecs => (widget.roomState?.timerSecs as int?) ?? 120;
  bool get _hasTimer => _endTime != null && _timerSecs > 0;
  bool get _urgent => _hasTimer && _timeLeft <= 20;
  int get _elimCount => _eliminatedEntries.length;

  Map<String, dynamic> get _players =>
      (widget.roomState?.players as Map<String, dynamic>?) ?? {};

  bool get _isImposter => false;
  /* (_assignments[widget.myId]?['role'] as String?) == 'imposter'; */

  List<EliminatedEntry> get _eliminatedEntries {
    final raw = /* (widget.roomState?.eliminatedSoFar as List?) ?? */ [];
    return raw.map((e) {
      if (e is Map) {
        return EliminatedEntry(
          id: e['id'] as String,
          name: e['name'] as String,
        );
      }
      return EliminatedEntry(id: e as String, name: 'Unknown');
    }).toList();
  }

  List<MapEntry<String, dynamic>> get _allPlayers {
    final list = _players.entries.toList();
    /* ist.sort(
      (a, b) => ((a.value['joinedAt'] as int?) ?? 0).compareTo(
        (b.value['joinedAt'] as int?) ?? 0,
      ),
    ); */
    return list;
  }

  List<MapEntry<String, dynamic>> get _activePlayers {
    final elimIds = _eliminatedEntries.map((e) => e.id).toSet();
    return _allPlayers.where((e) => !elimIds.contains(e.key)).toList();
  }

  int _avatarIndex(String id) {
    final idx = _allPlayers.indexWhere((e) => e.key == id);
    return idx >= 0 ? idx : 0;
  }

  String get _roundLabel =>
      _elimCount > 0 ? 'ROUND ${_elimCount + 1}' : 'ROUND 01';

  // ── Lifecycle ─────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _initTimer();
  }

  void _initTimer() {
    if (!_hasTimer) {
      _timer = null;
      return;
    }
    _timeLeft = _calcTimeLeft();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      final t = _calcTimeLeft();
      if (mounted) setState(() => _timeLeft = t);
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
    if (widget.chatMessages.length != old.chatMessages.length) {
      Future.delayed(const Duration(milliseconds: 80), _scrollToBottom);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
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
      color: _surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _border),
    ),
    child: Row(
      children: [
        _RoleBadge(
          label: widget.isEliminated
              ? '💀 SPECTATING'
              : _isImposter
              ? '😈 IMPOSTER'
              : '🕵️ INNOCENT',
          variant: widget.isEliminated
              ? _BadgeVariant.dead
              : _isImposter
              ? _BadgeVariant.imposter
              : _BadgeVariant.innocent,
        ),
        const Spacer(),
        if (_hasTimer)
          _TimerBlock(timeLeft: _timeLeft, urgent: _urgent)
        else
          _RoundPill(label: _roundLabel),
      ],
    ),
  );

  // ── PLAYERS CARD — avatars as circles in a horizontal row ──────────────
  Widget _buildPlayersCard() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 12),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PLAYERS',
          style: TextStyle(
            color: _accent,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            // Active players
            ..._activePlayers.map((entry) {
              final p = {
                "name": "Law",
              }; /* entry.value as Map<String, dynamic>; */
              final id = entry.key;
              // ignore: unnecessary_cast
              final name = p['name'] as String? ?? '?';
              final color =
                  _avatarColors[_avatarIndex(id) % _avatarColors.length];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _AvatarCircle(
                  name: name,
                  color: color,
                  isEliminated: false,
                ),
              );
            }),
            // Eliminated players (faded)
            ..._eliminatedEntries.map((e) {
              final idx = _avatarIndex(e.id);
              final color = _avatarColors[idx % _avatarColors.length];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _AvatarCircle(
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
      color: _surface,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
      ),
      border: Border.all(color: _border),
    ),
    child: widget.chatMessages.isEmpty
        ? const Center(
            child: Text(
              '💬  Speak up — discuss who you think the imposter is.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _textMuted, fontSize: 13.5),
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
              final color = _avatarColors[idx % _avatarColors.length];
              return _ChatBubble(msg: msg, isMe: isMe, avatarColor: color);
            },
          ),
  );

  // ── INPUT ROW ──────────────────────────────────────────────────────────
  Widget _buildInputRow() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 12),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(16),
        bottomRight: Radius.circular(16),
      ),
      border: Border(
        left: BorderSide(color: _border),
        right: BorderSide(color: _border),
        bottom: BorderSide(color: _border),
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
            style: const TextStyle(color: _text, fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'Say something…',
              hintStyle: TextStyle(color: _textMuted),
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
                  color: canSend ? _accentSoft : _border,
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
            color: _accentSoft,
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
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PulseDot(),
          const SizedBox(width: 10),
          Text(
            widget.isEliminated
                ? 'Spectating…'
                : 'Host will start voting when ready',
            style: const TextStyle(
              color: _text,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────

enum _BadgeVariant { innocent, imposter, dead }

class _RoleBadge extends StatelessWidget {
  final String label;
  final _BadgeVariant variant;
  const _RoleBadge({required this.label, required this.variant});

  Color get _color => switch (variant) {
    _BadgeVariant.imposter => _red,
    _BadgeVariant.dead => _textMuted,
    _BadgeVariant.innocent => _accent,
  };

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: _color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: _color.withOpacity(0.4)),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: _color,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
      ),
    ),
  );
}

class _TimerBlock extends StatelessWidget {
  final int timeLeft;
  final bool urgent;
  const _TimerBlock({required this.timeLeft, required this.urgent});

  @override
  Widget build(BuildContext context) {
    final mins = timeLeft ~/ 60;
    final secs = timeLeft % 60;
    final color = urgent ? _red : _text;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          "$mins:${secs.toString().padLeft(2, '0')}",
          style: TextStyle(
            color: color,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
            height: 1,
          ),
        ),
        const SizedBox(width: 4),
        Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Text(
            urgent ? '⚡ SOON' : 'LEFT',
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _RoundPill extends StatelessWidget {
  final String label;
  const _RoundPill({required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: _surfaceAlt,
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: _border),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: _green,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: _text,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _AvatarCircle extends StatelessWidget {
  final String name;
  final Color color;
  final bool isEliminated;
  const _AvatarCircle({
    required this.name,
    required this.color,
    required this.isEliminated,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: isEliminated ? color.withOpacity(0.3) : color,
    ),
    child: Center(
      child: Text(
        name[0].toUpperCase(),
        style: TextStyle(
          color: isEliminated ? Colors.white.withOpacity(0.4) : Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );
}

// ignore: unused_element
class _PlayerRow extends StatelessWidget {
  final String name, sublabel;
  final Color avatarColor;
  final bool isMe, isEliminated;
  const _PlayerRow({
    required this.name,
    required this.avatarColor,
    required this.sublabel,
    required this.isMe,
    required this.isEliminated,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 7),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    decoration: BoxDecoration(
      color: isMe ? _accent.withOpacity(0.08) : _surfaceAlt,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isMe ? _accent.withOpacity(0.3) : Colors.transparent,
      ),
    ),
    child: Row(
      children: [
        // Avatar
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isEliminated ? avatarColor.withOpacity(0.35) : avatarColor,
          ),
          child: Center(
            child: Text(
              name[0].toUpperCase(),
              style: TextStyle(
                color: isEliminated
                    ? Colors.white.withOpacity(0.4)
                    : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Name + sublabel
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  color: isEliminated ? _textMuted : _text,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                sublabel,
                style: const TextStyle(color: _textMuted, fontSize: 10.5),
              ),
            ],
          ),
        ),
        // Online dot (active only)
        if (!isEliminated)
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: _green,
            ),
          ),
      ],
    ),
  );
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage msg;
  final bool isMe;
  final Color avatarColor;
  const _ChatBubble({
    required this.msg,
    required this.isMe,
    required this.avatarColor,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isMe) ...[
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: avatarColor,
            ),
            child: Center(
              child: Text(
                msg.senderName[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              isMe ? 'You' : msg.senderName,
              style: TextStyle(
                color: avatarColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Container(
              constraints: const BoxConstraints(maxWidth: 260),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMe ? _accentSoft.withOpacity(0.2) : _surfaceAlt,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isMe ? 12 : 4),
                  topRight: Radius.circular(isMe ? 4 : 12),
                  bottomLeft: const Radius.circular(12),
                  bottomRight: const Radius.circular(12),
                ),
                border: Border.all(
                  color: isMe ? _accent.withOpacity(0.25) : _border,
                ),
              ),
              child: Text(
                msg.text,
                style: const TextStyle(
                  color: _text,
                  fontSize: 13.5,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
        if (isMe) ...[
          const SizedBox(width: 8),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: avatarColor,
            ),
            child: Center(
              child: Text(
                msg.senderName[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ],
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
      width: 7,
      height: 7,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: _accent),
    ),
  );
}
