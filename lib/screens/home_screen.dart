import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Data ────────────────────────────────────────────────────────────────────

const _kRules = [
  _Rule(
    '🎯',
    'The Goal',
    'Innocents find who has a different word. The imposter must blend in without getting caught.',
  ),
  _Rule(
    '🔑',
    'Your Word',
    'Each player privately sees their secret word. Innocents all get the same word. The imposter gets a similar but different one.',
  ),
  _Rule(
    '💬',
    'Discussion',
    'Take turns describing your word without saying it directly. Listen carefully — someone\'s description might not quite fit!',
  ),
  _Rule(
    '🗳️',
    'Voting',
    'Everyone votes for who they think is the imposter. Most votes gets eliminated.',
  ),
  _Rule(
    '🏆',
    'Winning',
    'Innocents win by eliminating all imposters. Imposters win if they survive to equal the innocents.',
  ),
  _Rule(
    '😈',
    'Imposter Knows',
    'You see the IMPOSTER label and get a different word. Describe carefully and blend in.',
  ),
  _Rule(
    '🤫',
    'Secret Mode',
    'You get a slightly different word but no label. You might accidentally give yourself away!',
  ),
  _Rule(
    '🫥',
    'Blind Mode',
    'You see no word at all. Listen to others and bluff your way through discussion.',
  ),
];

class _Rule {
  final String icon, title, desc;
  const _Rule(this.icon, this.title, this.desc);
}

// ─── Colours / constants ─────────────────────────────────────────────────────

const _bg = Color(0xFF0B0F1A);
const _border = Color(0xFF1E2740);
const _purple = Color(0xFF7C6EF5);
const _white70 = Color(0xB3FFFFFF);
const _white38 = Color(0x61FFFFFF);
const _inputBg = Color(0xFF0E1422);
const _errorBg = Color(0xFFE53935);

// ─── HomeScreen ──────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  /// Called when the user taps HOST NOW.
  final void Function(String name, String mode)? onCreate;

  /// Called when the user taps ENTER ROOM.
  final void Function(String code, String name)? onJoin;

  const HomeScreen({super.key, this.onCreate, this.onJoin});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _nameFocus = FocusNode();
  final _codeFocus = FocusNode();
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  String _error = '';
  bool _showRules = false;

  // ── helpers ────────────────────────────────────────────────────────────────

  void _setError(String msg) => setState(() => _error = msg);
  void _clearError() => setState(() => _error = '');

  void _handleCreate() {
    if (_nameCtrl.text.trim().isEmpty) {
      _setError('Enter your name first!');
      return;
    }
    _clearError();
    widget.onCreate?.call(_nameCtrl.text.trim(), 'knows');
  }

  void _handleJoin() {
    if (_nameCtrl.text.trim().isEmpty) {
      _setError('Enter your name first!');
      return;
    }
    if (_codeCtrl.text.trim().isEmpty) {
      _setError('Enter a room code!');
      return;
    }
    _clearError();
    widget.onJoin?.call(_codeCtrl.text.trim(), _nameCtrl.text.trim());
  }

  void _handleInitiate() {
    if (_codeCtrl.text.trim().isNotEmpty)
      _handleJoin();
    else
      _handleCreate();
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bg,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            // ── Subtle radial glow at the top ──────────────────────────────
            Positioned(
              top: -120,
              left: 0,
              right: 0,
              height: 420,
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [_purple.withOpacity(0.18), Colors.transparent],
                    radius: 0.9,
                    center: Alignment.topCenter,
                  ),
                ),
              ),
            ),

            // ── Main scrollable content ────────────────────────────────────
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 48),
                    _buildHero(),
                    const SizedBox(height: 32),
                    _buildNameField(),
                    const SizedBox(height: 20),
                    _buildCreateCard(),
                    const SizedBox(height: 14),
                    _buildJoinCard(),
                    const SizedBox(height: 20),
                    if (_error.isNotEmpty) _buildErrorBox(),
                    const SizedBox(height: 100), // room for FAB
                  ],
                ),
              ),
            ),

            // ── ? FAB ──────────────────────────────────────────────────────
            Positioned(right: 20, bottom: 20, child: _buildHelpFab()),

            // ── Rules modal ────────────────────────────────────────────────
            if (_showRules) _buildRulesModal(),
          ],
        ),
      ),
    );
  }

  // ── HERO ───────────────────────────────────────────────────────────────────

  Widget _buildHero() {
    return Column(
      children: [
        // "IMPOSTOR" — solid white, heavy weight
        Text(
          'IMPOSTOR',
          textAlign: TextAlign.center,
          style: GoogleFonts.barlow(
            fontSize: 38,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),

        // "WORD" — outlined/glowing cyan-purple
        Stack(
          alignment: Alignment.center,
          children: [
            // outer glow layer
            Text(
              'WORD',
              textAlign: TextAlign.center,
              style: GoogleFonts.barlow(
                fontSize: 38,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 3
                  ..color = _purple.withOpacity(0.55),
                shadows: const [
                  Shadow(blurRadius: 32, color: _purple),
                  Shadow(
                    blurRadius: 64,
                    color: Color.fromARGB(255, 128, 106, 227),
                  ),
                ],
              ),
            ),
            // crisp fill layer
            Text(
              'WORD',
              textAlign: TextAlign.center,
              style: GoogleFonts.barlow(
                fontSize: 38,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: _purple,
                shadows: const [
                  Shadow(blurRadius: 8, color: _purple),
                  Shadow(
                    blurRadius: 24,
                    color: Color.fromARGB(255, 231, 229, 241),
                  ),
                  Shadow(
                    blurRadius: 48,
                    color: Color.fromARGB(255, 128, 106, 227),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Text(
          'Trust no one. The word is the key, but the silence is deadly.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 13.5,
            color: _white70,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // ── NAME INPUT ─────────────────────────────────────────────────────────────

  Widget _buildNameField() {
    return _GlassContainer(
      borderRadius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: Row(
        children: [
          const Icon(Icons.person, color: _white38, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _nameCtrl,
              focusNode: _nameFocus,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
              cursorColor: _purple,
              maxLength: 14,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _handleInitiate(),
              decoration: InputDecoration(
                hintText: 'Enter your name…',
                hintStyle: GoogleFonts.inter(color: _white38, fontSize: 14),
                border: InputBorder.none,
                counterText: '',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── CREATE CARD ────────────────────────────────────────────────────────────

  Widget _buildCreateCard() {
    return _GlassContainer(
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconBadge(icon: Icons.add_circle_outline_rounded, color: _purple),
          const SizedBox(height: 14),
          Text(
            'Create a Private Room',
            style: GoogleFonts.barlow(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Host a secure match for your friends. Change mode and round settings in the lobby.',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: _white70,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _ActionButton(label: 'HOST NOW', suffix: '→', onTap: _handleCreate),
        ],
      ),
    );
  }

  // ── JOIN CARD ──────────────────────────────────────────────────────────────

  Widget _buildJoinCard() {
    return _GlassContainer(
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconBadge(icon: Icons.key_rounded, color: _purple),
          const SizedBox(height: 14),
          Text(
            'Join a Private Room',
            style: GoogleFonts.barlow(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          // Room code input — styled like the React version (pill shaped)
          Container(
            decoration: BoxDecoration(
              color: _inputBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            child: TextField(
              controller: _codeCtrl,
              focusNode: _codeFocus,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 13,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
              ),
              cursorColor: _purple,
              maxLength: 6,
              textCapitalization: TextCapitalization.characters,
              onChanged: (v) => _codeCtrl.value = _codeCtrl.value.copyWith(
                text: v.toUpperCase(),
                selection: TextSelection.collapsed(offset: v.length),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _handleJoin(),
              decoration: InputDecoration(
                hintText: 'ENTER ROOM CODE',
                hintStyle: GoogleFonts.inter(
                  color: _white38,
                  fontSize: 13,
                  letterSpacing: 2,
                ),
                border: InputBorder.none,
                counterText: '',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _ActionButton(label: 'ENTER ROOM', suffix: '↪', onTap: _handleJoin),
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
              _error,
              style: GoogleFonts.inter(color: _errorBg, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ── HELP FAB ───────────────────────────────────────────────────────────────

  Widget _buildHelpFab() {
    return GestureDetector(
      onTap: () => setState(() => _showRules = true),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.08),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        alignment: Alignment.center,
        child: Text(
          '?',
          style: GoogleFonts.barlow(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // ── RULES MODAL ────────────────────────────────────────────────────────────

  Widget _buildRulesModal() {
    return GestureDetector(
      onTap: () => setState(() => _showRules = false),
      child: Container(
        color: Colors.black.withOpacity(0.78),
        child: SafeArea(
          child: Center(
            child: GestureDetector(
              onTap: () {}, // prevent tap-through
              child: Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF121826),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 16, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'How to Play',
                              style: GoogleFonts.barlow(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _showRules = false),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.07),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.close,
                                color: _white70,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(color: _border, height: 1),

                    // scrollable body
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.6,
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _RuleSection(
                              label: 'Game Rules',
                              rules: _kRules.sublist(0, 5),
                            ),
                            const SizedBox(height: 20),
                            _RuleSection(
                              label: 'Game Modes',
                              rules: _kRules.sublist(5),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _purple.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _purple.withOpacity(0.3),
                                ),
                              ),
                              child: RichText(
                                text: TextSpan(
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    color: _white70,
                                    height: 1.5,
                                  ),
                                  children: const [
                                    TextSpan(text: '💡 '),
                                    TextSpan(
                                      text: 'Pro tip: ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    TextSpan(
                                      text:
                                          'Even innocents should hesitate slightly — acting too confident makes you look suspicious!',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _nameFocus.dispose();
    _codeFocus.dispose();
    super.dispose();
  }
}

// ─── Reusable sub-widgets ─────────────────────────────────────────────────────

/// Frosted-glass card / input container.
class _GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsets padding;

  const _GlassContainer({
    required this.child,
    this.borderRadius = 16,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: _border),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Small square icon badge (matches React's `home-action-icon`).
class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: color, size: 24),
    );
  }
}

/// "HOST NOW →" / "ENTER ROOM ↪" text button.
class _ActionButton extends StatelessWidget {
  final String label;
  final String suffix;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.suffix,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label  $suffix',
            style: GoogleFonts.barlow(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _purple,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

/// Section inside the rules modal.
class _RuleSection extends StatelessWidget {
  final String label;
  final List<_Rule> rules;

  const _RuleSection({required this.label, required this.rules});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.barlow(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _white38,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        ...rules.map(
          (r) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.icon, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.title,
                        style: GoogleFonts.barlow(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        r.desc,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: _white70,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
