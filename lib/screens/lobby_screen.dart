import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:word_imposter/theme/app_colors.dart';
import 'package:word_imposter/widgets/error_box.dart';

import '../models/chat_message.dart';
import '../models/pill_item.dart';
import '../state/player_info.dart';
import '../state/room_state.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/kick_bottom_sheet.dart';
import '../widgets/kick_dialog.dart';
import '../widgets/pill_row.dart';
import '../widgets/pulse_dot.dart';

const _timerPresets = [0, 60, 120, 180, 300];

// ─── LobbyScreen ─────────────────────────────────────────────────────────────
class LobbyScreen extends ConsumerStatefulWidget {
  final String roomCode;
  final String myId;
  final bool isHost;
  final RoomState roomState;
  final List<ChatMessage> chatMessages;
  final VoidCallback onLeave;
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
    required this.onLeave,
  });

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  bool _copied = false;

  final _chatCtrl = TextEditingController();
  final _chatScrollCtrl = ScrollController();

  bool _showChat = false;
  int _lastSeenCount = 0;
  int get _unreadCount {
    if (_showChat) {
      _lastSeenCount = widget.chatMessages.length;
      return 0;
    }
    return widget.chatMessages.length - _lastSeenCount;
  }

  bool get _isWideScreen => MediaQuery.of(context).size.width > 700;

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
  void _showKickSheet(
    BuildContext context,
    PlayerInfo player,
    Color avatarColor,
  ) {
    final isWebOrDesktop =
        Theme.of(context).platform == TargetPlatform.linux ||
        Theme.of(context).platform == TargetPlatform.windows ||
        Theme.of(context).platform == TargetPlatform.macOS;

    if (isWebOrDesktop) {
      _showKickDialog(context, player, avatarColor);
    } else {
      _showKickBottomSheet(context, player, avatarColor);
    }
  }

  void _showKickBottomSheet(
    BuildContext context,
    PlayerInfo player,
    Color avatarColor,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => KickBottomSheet(
        player: player,
        avatarColor: avatarColor,
        onKick: () {
          Navigator.pop(context);
          widget.onKick(player.id);
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  void _showKickDialog(
    BuildContext context,
    PlayerInfo player,
    Color avatarColor,
  ) {
    showDialog(
      context: context,
      builder: (_) => KickDialog(
        player: player,
        avatarColor: avatarColor,
        onKick: () {
          Navigator.pop(context);
          widget.onKick(player.id);
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
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

  @override
  void didUpdateWidget(LobbyScreen old) {
    super.didUpdateWidget(old);

    if (widget.isHost && _impCount > _maxImp) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onImposterCount(_maxImp);
      });
    }

    if (widget.chatMessages.length != old.chatMessages.length) {
      // If chat is open, mark all as seen immediately
      if (_showChat) _lastSeenCount = widget.chatMessages.length;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_chatScrollCtrl.hasClients) {
          _chatScrollCtrl.animateTo(
            _chatScrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        floatingActionButton: _isWideScreen || _showChat
            ? null
            : _buildChatFab(),
        body: SafeArea(
          child: _isWideScreen
              ? _buildWideLayout() // web: side-by-side
              : _buildMobileLayout(), // mobile: stack with overlay
        ),
      ),
    );
  }

  // ── CODE HERO ──────────────────────────────────────────────────────────────
  Widget _buildMobileLayout() {
    return Stack(
      children: [
        // Main lobby content
        Column(
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
                      ErrorBox(error: widget.error!),
                    ],
                    const SizedBox(height: 16),
                    _buildSettingsCard(),
                    const SizedBox(height: 80), // room for FAB
                  ],
                ),
              ),
            ),
            _buildActionBar(),
          ],
        ),

        // Chat overlay — slides up from bottom
        if (_showChat) _buildMobileChatOverlay(),
      ],
    );
  }

  Widget _buildMobileChatOverlay() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () => setState(() => _showChat = false),
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: () {}, // prevent tap-through
              child: Container(
                height: MediaQuery.of(context).size.height * 0.72,
                decoration: const BoxDecoration(
                  color: Color(0xFF0E1422),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    // Handle + header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 16, 0),
                      child: Column(
                        children: [
                          // Drag handle
                          Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: AppColors.white38,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Text(
                                'LOBBY CHAT',
                                style: GoogleFonts.barlow(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.purple,
                                  letterSpacing: 2,
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () => setState(() => _showChat = false),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: AppColors.white12,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    color: AppColors.white70,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Divider(color: AppColors.border, height: 20),
                    // Messages
                    Expanded(child: _buildChatMessagesList()),
                    // Input
                    _buildChatInputRow(),
                    SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatFab() {
    final unread = _unreadCount;
    return GestureDetector(
      onTap: () => setState(() {
        _showChat = true;
        _lastSeenCount = widget.chatMessages.length;
      }),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.purple,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.purple.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            const Center(
              child: Icon(Icons.chat_rounded, color: Colors.white, size: 24),
            ),
            if (unread > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    unread > 9 ? '9+' : '$unread',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left: main lobby content
        Expanded(
          flex: 3,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildCodeHero(),
                      const SizedBox(height: 16),
                      _buildPlayerGrid(),
                      if (widget.error != null) ...[
                        const SizedBox(height: 12),
                        ErrorBox(error: widget.error!),
                      ],
                      const SizedBox(height: 16),
                      _buildSettingsCard(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              _buildActionBar(),
            ],
          ),
        ),

        // Divider
        VerticalDivider(color: AppColors.border, width: 1),

        // Right: persistent chat panel
        SizedBox(width: 300, child: _buildWebChatPanel()),
      ],
    );
  }

  Widget _buildWebChatPanel() {
    return Container(
      color: const Color(0xFF0E1422),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.chat_rounded,
                  color: AppColors.purple,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'LOBBY CHAT',
                  style: GoogleFonts.barlow(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.purple,
                    letterSpacing: 2,
                  ),
                ),
                if (widget.chatMessages.isNotEmpty) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.purple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${widget.chatMessages.length}',
                      style: GoogleFonts.barlow(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.purple,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Messages
          Expanded(child: _buildChatMessagesList()),

          // Input
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: _buildChatInputRow(),
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessagesList() {
    if (widget.chatMessages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('💬', style: TextStyle(fontSize: 32)),
            const SizedBox(height: 10),
            Text(
              'No messages yet',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.white38,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Say hi to your lobby!',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.white38),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _chatScrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      itemCount: widget.chatMessages.length,
      itemBuilder: (_, i) {
        final msg = widget.chatMessages[i];
        final isMe = msg.senderId == widget.myId;
        final pIdx = _players.indexWhere((p) => p.id == msg.senderId);
        final color =
            AppColors.avatarColors[(pIdx >= 0 ? pIdx : 0) %
                AppColors.avatarColors.length];

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: isMe
              ? Align(
                  alignment: Alignment.centerRight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'You',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 3),
                      ChatBubble(text: msg.text, isMe: true, color: color),
                    ],
                  ),
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
                    const SizedBox(height: 3),
                    ChatBubble(text: msg.text, isMe: false, color: color),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildChatInputRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _chatCtrl,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                cursorColor: AppColors.purple,
                maxLength: 200,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendChat(),
                decoration: InputDecoration(
                  hintText: 'Send a message…',
                  hintStyle: GoogleFonts.inter(
                    color: AppColors.white38,
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                  counterText: '',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
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
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: empty ? AppColors.white12 : AppColors.purple,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: empty
                        ? []
                        : [
                            BoxShadow(
                              color: AppColors.purple.withOpacity(0.4),
                              blurRadius: 8,
                            ),
                          ],
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.send_rounded,
                    color: empty ? AppColors.white38 : Colors.white,
                    size: 18,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCodeHero() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 10,
            right: 10,
            child: GestureDetector(
              onTap: widget.onLeave,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.5)),
                ),
                child: Text(
                  'LEAVE',
                  style: GoogleFonts.barlow(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.redAccent,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              children: [
                Text(
                  'LOBBY ACCESS CODE',
                  style: GoogleFonts.barlow(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white38,
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
                        color: AppColors.purple,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _copy,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.white12,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          _copied
                              ? Icons.check_rounded
                              : Icons.content_copy_rounded,
                          color: _copied ? AppColors.green : AppColors.white70,
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
                    color: AppColors.white70,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
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
    final isHostPlayer = p.id == widget.roomState.host;
    final avatarClr =
        AppColors.avatarColors[idx % AppColors.avatarColors.length];
    final canKick = widget.isHost && p.id != widget.myId;

    return GestureDetector(
      // Host taps any other player's card to see kick option
      onTap: canKick ? () => _showKickSheet(context, p, avatarClr) : null,
      child: Container(
        decoration: BoxDecoration(
          color: isHostPlayer
              ? AppColors.purple.withOpacity(0.08)
              : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isHostPlayer
                ? AppColors.purple.withOpacity(0.4)
                : AppColors.border,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // HOST badge
            if (isHostPlayer)
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
                      color: AppColors.purple,
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

            // Small "⋮" indicator for host so they know card is tappable
            if (canKick)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.white12,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '⋮',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.white38,
                      height: 1,
                    ),
                  ),
                ),
              ),

            // Main content — unchanged
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'READY',
                      style: GoogleFonts.barlow(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.green,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySlot() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, style: BorderStyle.solid),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_add_alt_1_rounded,
            color: AppColors.white38,
            size: 22,
          ),
          const SizedBox(height: 6),
          Text(
            'WAITING',
            style: GoogleFonts.barlow(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppColors.white38,
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
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GAME SETTINGS',
            style: GoogleFonts.barlow(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.purple,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 18),

          // Game Mode
          _SettingGroup(
            label: 'GAME MODE',
            child: PillRow(
              items: const [
                PillItem('knows', '😈 Knows'),
                PillItem('secret', '🤫 Secret'),
                PillItem('blind', '🫥 Blind'),
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
                return Pill(
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
            child: PillRow(
              items: [1, 2, 3]
                  .where((n) => n <= _maxImp)
                  .map((n) => PillItem(n.toString(), n.toString()))
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
                final active = _maxPlayers == n;
                final enabled = widget.isHost && _players.length <= n;
                return Pill(
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

  // ── ACTION BAR ─────────────────────────────────────────────────────────────

  Widget _buildActionBar() {
    final canStart = _players.length >= 3;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.bg,
        border: Border(top: BorderSide(color: AppColors.border)),
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
                    color: canStart
                        ? AppColors.purple
                        : AppColors.purpleDim.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: canStart
                          ? AppColors.purple.withOpacity(0.8)
                          : AppColors.border,
                    ),
                    boxShadow: canStart
                        ? [
                            BoxShadow(
                              color: AppColors.purple.withOpacity(0.35),
                              blurRadius: 20,
                              spreadRadius: 0,
                            ),
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
                      color: canStart ? Colors.white : AppColors.white38,
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
                color: AppColors.white12,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PulseDot(),
                  const SizedBox(width: 10),
                  Text(
                    'Waiting for the host to start the match…',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.white70,
                    ),
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
              color: AppColors.white38,
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
    super.dispose();
  }
}

// ─── Reusable sub-widgets ─────────────────────────────────────────────────────

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
            color: AppColors.white38,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
