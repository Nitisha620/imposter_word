import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../state/player_info.dart';
import '../state/room_state.dart';

// ─── Colour palette (shared with HomeScreen) ─────────────────────────────────
const _bg       = Color(0xFF0B0F1A);
const _card     = Color(0xFF111827);
const _border   = Color(0xFF1E2740);
const _purple   = Color(0xFF7C6EF5);
const _purpleDim = Color(0xFF4B44A0);
const _white70  = Color(0xB3FFFFFF);
const _white38  = Color(0x61FFFFFF);
const _white12  = Color(0x1FFFFFFF);
const _green    = Color(0xFF34D399);
const _errorBg  = Color(0xFFE53935);

const _avatarColors = [
  Color(0xFF6D62F5), Color(0xFFF87171), Color(0xFF34D399), Color(0xFFFBBF24),
  Color(0xFF38BDF8), Color(0xFFF472B6), Color(0xFFA3E635), Color(0xFFFB923C),
  Color(0xFFE879F9), Color(0xFF2DD4BF),
];

const _timerPresets = [0, 60, 120, 180, 300];

// ─── Data models (keep in sync with your game_state.dart) ─────────────────────



class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
  });
}

// ─── LobbyScreen ─────────────────────────────────────────────────────────────

class LobbyScreen extends StatefulWidget {
  final String roomCode;
  final String myId;
  final bool isHost;
  final RoomState roomState;
  final List<ChatMessage> chatMessages;
  final String? error;

  final VoidCallback onStart;
  final void Function(int count) onImposterCount;
  final void Function(String id) onKick;
  final void Function(int secs) onTimerChange;
  final void Function(int max) onPlayerCount;
  final void Function(String mode) onGameMode;
  final void Function(String text) onSendChat;

  const LobbyScreen({
    super.key,
    required this.roomCode,
    required this.myId,
    required this.isHost,
    required this.roomState,
    this.chatMessages = const [],
    this.error,
    required this.onStart,
    required this.onImposterCount,
    required this.onKick,
    required this.onTimerChange,
    required this.onPlayerCount,
    required this.onGameMode,
    required this.onSendChat,
  });

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  bool _copied = false;
  String? _kickConfirm;
  Timer? _kickTimer;
  final _chatCtrl    = TextEditingController();
  final _chatScrollCtrl = ScrollController();
  bool _showChat = false;

  // ── derived ────────────────────────────────────────────────────────────────
  List<PlayerInfo> get _players =>
      widget.roomState.players.values.toList()
        ..sort((a, b) => a.joinedAt.compareTo(b.joinedAt));

  int get _maxImp {
    final n = _players.length;
    if (n >= 8) return 3;
    if (n >= 6) return 2;
    return 1;
  }

  int get _impCount => widget.roomState.imposterCount.clamp(1, _maxImp);
  int get _timerSecs => widget.roomState.timerSecs;
  int get _maxPlayers => widget.roomState.maxPlayers;
  String get _gameMode => widget.roomState.gameMode;
  int get _emptySlots => (_maxPlayers - _players.length).clamp(0, _maxPlayers);

  // ── copy ───────────────────────────────────────────────────────────────────
  void _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.roomCode));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  // ── kick ───────────────────────────────────────────────────────────────────
  void _handleKick(String id) {
    if (_kickConfirm == id) {
      widget.onKick(id);
      setState(() => _kickConfirm = null);
      _kickTimer?.cancel();
    } else {
      setState(() => _kickConfirm = id);
      _kickTimer?.cancel();
      _kickTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _kickConfirm = null);
      });
    }
  }

  // ── chat ───────────────────────────────────────────────────────────────────
  void _sendChat() {
    final text = _chatCtrl.text.trim();
    if (text.isEmpty) return;
    widget.onSendChat(text);
    _chatCtrl.clear();
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_chatScrollCtrl.hasClients) {
        _chatScrollCtrl.animateTo(
          _chatScrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── timer label ────────────────────────────────────────────────────────────
  String _timerLabel(int t) {
    if (t == 0) return 'No timer';
    if (t < 60) return '${t}s';
    return '${t ~/ 60} min';
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      _buildCodeHero(),
                      const SizedBox(height: 16),
                      _buildPlayerGrid(),
                      if (widget.error != null) ...[
                        const SizedBox(height: 12),
                        _buildErrorBox(),
                      ],
                      const SizedBox(height: 16),
                      _buildSettingsCard(),
                      const SizedBox(height: 12),
                      _buildChatCard(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              _buildActionBar(),
            ],
          ),
        ),
      ),
    );
  }

  // ── CODE HERO ──────────────────────────────────────────────────────────────

  Widget _buildCodeHero() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Text(
            'LOBBY ACCESS CODE',
            style: GoogleFonts.barlow(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _white38,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.roomCode,
                style: GoogleFonts.barlow(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  color: _purple,
                  letterSpacing: 4,
                  shadows: const [
                    Shadow(blurRadius: 16, color: _purple),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _copy,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _white12,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _border),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    _copied ? Icons.check_rounded : Icons.content_copy_rounded,
                    color: _copied ? _green : _white70,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Waiting for players to join the lobby...',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: _white70,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // ── PLAYER GRID ────────────────────────────────────────────────────────────

  Widget _buildPlayerGrid() {
    final allSlots = <Widget>[];

    for (int i = 0; i < _players.length; i++) {
      allSlots.add(_buildPlayerCard(_players[i], i));
    }
    for (int i = 0; i < _emptySlots; i++) {
      allSlots.add(_buildEmptySlot());
    }

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 0.82,
      children: allSlots,
    );
  }

  Widget _buildPlayerCard(PlayerInfo p, int idx) {
    final isHost    = p.id == widget.roomState.host;
    final avatarClr = _avatarColors[idx % _avatarColors.length];
    final isKicking = _kickConfirm == p.id;

    return Container(
      decoration: BoxDecoration(
        color: isHost ? _purple.withOpacity(0.08) : _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHost ? _purple.withOpacity(0.4) : _border,
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // HOST badge
          if (isHost)
            Positioned(
              top: -18,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _purple,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'HOST',
                    style: GoogleFonts.barlow(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),

          // Kick button
          if (widget.isHost && p.id != widget.myId)
            Positioned(
              top: -6,
              right: -6,
              child: GestureDetector(
                onTap: () => _handleKick(p.id),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isKicking
                        ? _purple.withOpacity(0.9)
                        : Colors.white.withOpacity(0.08),
                    shape: BoxShape.circle,
                    border: Border.all(color: _border),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    isKicking ? '?' : '✕',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: isKicking ? Colors.white : _white70,
                    ),
                  ),
                ),
              ),
            ),

          // Main content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Avatar circle
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: avatarClr,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  p.name[0].toUpperCase(),
                  style: GoogleFonts.barlow(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                p.name,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              // READY pill
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: _green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'READY',
                    style: GoogleFonts.barlow(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: _green,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySlot() {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border, style: BorderStyle.solid),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_add_alt_1_rounded, color: _white38, size: 22),
          const SizedBox(height: 6),
          Text(
            'WAITING',
            style: GoogleFonts.barlow(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: _white38,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  // ── SETTINGS CARD ──────────────────────────────────────────────────────────

  Widget _buildSettingsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GAME SETTINGS',
            style: GoogleFonts.barlow(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: _purple,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 18),

          // Game Mode
          _SettingGroup(
            label: 'GAME MODE',
            child: _PillRow(
              items: const [
                _PillItem('knows',  '😈 Knows'),
                _PillItem('secret', '🤫 Secret'),
                _PillItem('blind',  '🫥 Blind'),
              ],
              selected: _gameMode,
              enabled: widget.isHost,
              onTap: widget.onGameMode,
            ),
          ),

          const SizedBox(height: 16),

          // Round Timer
          _SettingGroup(
            label: 'ROUND TIMER',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _timerPresets.map((t) {
                final active = _timerSecs == t;
                return _Pill(
                  label: _timerLabel(t),
                  active: active,
                  enabled: widget.isHost,
                  onTap: () => widget.onTimerChange(t),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Number of Impostors
          _SettingGroup(
            label: 'NUMBER OF IMPOSTORS',
            child: _PillRow(
              items: [1, 2, 3]
                  .where((n) => n <= _maxImp)
                  .map((n) => _PillItem(n.toString(), n.toString()))
                  .toList(),
              selected: _impCount.toString(),
              enabled: widget.isHost,
              onTap: (v) => widget.onImposterCount(int.parse(v)),
            ),
          ),

          const SizedBox(height: 16),

          // Max Players
          _SettingGroup(
            label: 'MAX PLAYERS',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [3, 4, 5, 6, 7, 8, 9, 10].map((n) {
                final active  = _maxPlayers == n;
                final enabled = widget.isHost && _players.length <= n;
                return _Pill(
                  label: n.toString(),
                  active: active,
                  enabled: enabled,
                  onTap: () => widget.onPlayerCount(n),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── CHAT CARD ──────────────────────────────────────────────────────────────

  Widget _buildChatCard() {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header — tap to expand/collapse
          GestureDetector(
            onTap: () => setState(() => _showChat = !_showChat),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: [
                  Text(
                    'LOBBY CHAT',
                    style: GoogleFonts.barlow(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _purple,
                      letterSpacing: 2,
                    ),
                  ),
                  if (widget.chatMessages.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: _purple.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${widget.chatMessages.length}',
                        style: GoogleFonts.barlow(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _purple,
                        ),
                      ),
                    ),
                  const Spacer(),
                  Icon(
                    _showChat ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: _white38,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          if (_showChat) ...[
            Divider(color: _border, height: 1),

            // Messages
            SizedBox(
              height: 180,
              child: widget.chatMessages.isEmpty
                  ? Center(
                      child: Text(
                        'No messages yet…',
                        style: GoogleFonts.inter(fontSize: 13, color: _white38),
                      ),
                    )
                  : ListView.builder(
                      controller: _chatScrollCtrl,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      itemCount: widget.chatMessages.length,
                      itemBuilder: (_, i) {
                        final msg   = widget.chatMessages[i];
                        final isMe  = msg.senderId == widget.myId;
                        final pIdx  = _players.indexWhere((p) => p.id == msg.senderId);
                        final color = _avatarColors[(pIdx >= 0 ? pIdx : 0) %
                            _avatarColors.length];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: isMe
                              ? Align(
                                  alignment: Alignment.centerRight,
                                  child: _ChatBubble(
                                      text: msg.text, isMe: true, color: color),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      msg.senderName,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: color,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    _ChatBubble(
                                        text: msg.text, isMe: false, color: color),
                                  ],
                                ),
                        );
                      },
                    ),
            ),

            Divider(color: _border, height: 1),

            // Input row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 2),
                      decoration: BoxDecoration(
                        color: _bg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _border),
                      ),
                      child: TextField(
                        controller: _chatCtrl,
                        style: GoogleFonts.inter(
                            color: Colors.white, fontSize: 13),
                        cursorColor: _purple,
                        maxLength: 200,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendChat(),
                        decoration: InputDecoration(
                          hintText: 'Send a message...',
                          hintStyle:
                              GoogleFonts.inter(color: _white38, fontSize: 13),
                          border: InputBorder.none,
                          counterText: '',
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _chatCtrl,
                    builder: (_, val, __) {
                      final empty = val.text.trim().isEmpty;
                      return GestureDetector(
                        onTap: empty ? null : _sendChat,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: empty
                                ? _white12
                                : _purple.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '→',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: empty ? _white38 : Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── ERROR BOX ──────────────────────────────────────────────────────────────

  Widget _buildErrorBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _errorBg.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _errorBg.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: _errorBg, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.error!,
              style: GoogleFonts.inter(color: _errorBg, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ── ACTION BAR ─────────────────────────────────────────────────────────────

  Widget _buildActionBar() {
    final canStart = _players.length >= 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: _bg,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isHost)
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: canStart ? widget.onStart : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: canStart ? _purple : _purpleDim.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: canStart
                          ? _purple.withOpacity(0.8)
                          : _border,
                    ),
                    boxShadow: canStart
                        ? [
                            BoxShadow(
                              color: _purple.withOpacity(0.35),
                              blurRadius: 20,
                              spreadRadius: 0,
                            )
                          ]
                        : [],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    canStart
                        ? 'START MATCH'
                        : 'WAITING FOR ${3 - _players.length} MORE PLAYERS…',
                    style: GoogleFonts.barlow(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: canStart ? Colors.white : _white38,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            )
          else
            Container(
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
                  Text(
                    'Waiting for the host to start the match…',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: _white70),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Text(
            '${_players.length} / $_maxPlayers PLAYERS READY',
            textAlign: TextAlign.center,
            style: GoogleFonts.barlow(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _white38,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _chatCtrl.dispose();
    _chatScrollCtrl.dispose();
    _kickTimer?.cancel();
    super.dispose();
  }
}

// ─── Reusable sub-widgets ─────────────────────────────────────────────────────

class _PillItem {
  final String value;
  final String label;
  const _PillItem(this.value, this.label);
}

/// Row of pill buttons.
class _PillRow extends StatelessWidget {
  final List<_PillItem> items;
  final String selected;
  final bool enabled;
  final void Function(String) onTap;

  const _PillRow({
    required this.items,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        return _Pill(
          label: item.label,
          active: selected == item.value,
          enabled: enabled,
          onTap: () => onTap(item.value),
        );
      }).toList(),
    );
  }
}

/// Single pill button.
class _Pill extends StatelessWidget {
  final String label;
  final bool active;
  final bool enabled;
  final VoidCallback onTap;

  const _Pill({
    required this.label,
    required this.active,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? _purple.withOpacity(0.25)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? _purple : _border,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.barlow(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: active
                ? Colors.white
                : enabled
                    ? _white70
                    : _white38,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

/// Setting label + child widget group.
class _SettingGroup extends StatelessWidget {
  final String label;
  final Widget child;

  const _SettingGroup({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.barlow(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: _white38,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

/// Chat message bubble.
class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final Color color;

  const _ChatBubble(
      {required this.text, required this.isMe, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.65,
      ),
      decoration: BoxDecoration(
        color: isMe
            ? _purple.withOpacity(0.22)
            : Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.only(
          topLeft:     const Radius.circular(12),
          topRight:    const Radius.circular(12),
          bottomLeft:  Radius.circular(isMe ? 12 : 2),
          bottomRight: Radius.circular(isMe ? 2 : 12),
        ),
        border: Border.all(
          color: isMe ? _purple.withOpacity(0.3) : _border,
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(fontSize: 13, color: Colors.white, height: 1.4),
      ),
    );
  }
}

/// Animated pulsing green dot for the "waiting" pill.
class _PulseDot extends StatefulWidget {
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(_ctrl);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: _purple,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}