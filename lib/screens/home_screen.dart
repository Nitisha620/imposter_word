import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:word_imposter/state/game_controller.dart';
import 'package:word_imposter/theme/app_text_styles.dart';

import '../data/rule_data.dart';
import '../state/game_state.dart';
import '../theme/app_colors.dart';
import '../widgets/action_button.dart';
import '../widgets/game_loader.dart';
import '../widgets/glass_container.dart';
import '../widgets/icon_badge.dart';
import '../widgets/rules_section.dart';

// ─── HomeScreen ──────────────────────────────────────────────────────────────
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _nameFocus = FocusNode();
  final _codeFocus = FocusNode();
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  bool _isLoading = false;
  String _loadingMessage = '';

  @override
  void initState() {
    super.initState();
    // Clear error when user starts typing name
    _nameCtrl.addListener(_clearErrorIfFixed);
    // Clear error when user starts typing room code
    _codeCtrl.addListener(_clearErrorIfFixed);

    // myName is in state if user left a lobby this session, empty on fresh launch
    final savedName = ref.read(gameProvider).myName;
    if (savedName.isNotEmpty) {
      _nameCtrl.text = savedName;
    }
  }

  void _clearErrorIfFixed() {
    final error = ref.read(gameProvider).error;
    if (error.isNotEmpty) {
      ref.read(gameProvider.notifier).clearError();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _nameFocus.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    ref.listen<GameState>(gameProvider, (previous, next) {
      if (next.isLoading != previous?.isLoading ||
          next.loadingMessage != previous?.loadingMessage) {
        setState(() {
          _isLoading = next.isLoading;
          _loadingMessage =
              next.loadingMessage; // e.g. 'Creating Room…' / 'Joining Room…'
        });
      }
    });
    ref.listen<String>(gameProvider.select((s) => s.error), (previous, next) {
      if (next.isNotEmpty) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.errorRed.withOpacity(0.15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: AppColors.errorRed.withOpacity(0.5)),
            ),
            content: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.errorRed,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(next, style: AppTextStyles.errorText)),
              ],
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        // Error was cleared (user fixed the field)
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
    });
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.bg,
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
                    colors: [
                      AppColors.purple.withAlpha(80),
                      Colors.transparent,
                    ],
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
                  ],
                ),
              ),
            ),

            // ── ? FAB ──────────────────────────────────────────────────────
            Positioned(right: 20, bottom: 20, child: _buildHelpFab()),

            // ── Overlay loader (always last so it's on top) ──
            if (_isLoading) GameLoader(message: _loadingMessage),
          ],
        ),
      ),
    );
  }

  // ── HERO ───────────────────────────────────────────────────────────────────
  Widget _buildHero() {
    return Column(
      children: [
        Text(
          'WORD',
          textAlign: TextAlign.center,
          style: AppTextStyles.heroTitle,
        ),
        Text(
          'IMPOSTER',
          textAlign: TextAlign.center,
          style: AppTextStyles.heroTitle,
        ),
        const SizedBox(height: 12),
        Text(
          'Trust no one. The word is the key, but the silence is deadly.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMd,
        ),
      ],
    );
  }

  // ── NAME INPUT ─────────────────────────────────────────────────────────────
  Widget _buildNameField() {
    return GlassContainer(
      borderRadius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: Row(
        children: [
          const Icon(Icons.person, color: AppColors.white38, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _nameCtrl,
              focusNode: _nameFocus,
              style: AppTextStyles.inputText,
              cursorColor: AppColors.purple,
              maxLength: 14,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: 'Enter your name…',
                hintStyle: AppTextStyles.inputHint,
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
    return GlassContainer(
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(
            icon: Icons.add_circle_outline_rounded,
            color: AppColors.purple,
          ),
          const SizedBox(height: 14),
          Text('Create a Private Room', style: AppTextStyles.cardTitle),
          const SizedBox(height: 6),
          Text(
            'Host a secure match for your friends. Change mode and round settings in the lobby.',
            style: AppTextStyles.bodySm,
          ),
          const SizedBox(height: 16),
          ActionButton(
            label: 'HOST NOW',
            suffix: Icons.arrow_forward,
            onTap: () {
              ref
                  .read(gameProvider.notifier)
                  .createRoom(_nameCtrl.text.trim(), 'knows');
            },
          ),
        ],
      ),
    );
  }

  // ── JOIN CARD ──────────────────────────────────────────────────────────────
  Widget _buildJoinCard() {
    return GlassContainer(
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(icon: Icons.key_rounded, color: AppColors.purple),
          const SizedBox(height: 14),
          Text('Join a Private Room', style: AppTextStyles.cardTitle),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.inputBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            child: TextField(
              controller: _codeCtrl,
              focusNode: _codeFocus,
              style: AppTextStyles.roomCode,
              cursorColor: AppColors.purple,
              maxLength: 6,
              textCapitalization: TextCapitalization.characters,
              onChanged: (v) => _codeCtrl.value = _codeCtrl.value.copyWith(
                text: v.toUpperCase(),
                selection: TextSelection.collapsed(offset: v.length),
              ),
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: 'ENTER ROOM CODE',
                hintStyle: AppTextStyles.inputHint,
                border: InputBorder.none,
                counterText: '',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 14),
          ActionButton(
            label: 'ENTER ROOM',
            suffix: Icons.redo,
            onTap: () {
              ref
                  .read(gameProvider.notifier)
                  .joinRoom(_codeCtrl.text.trim(), _nameCtrl.text.trim());
            },
          ),
        ],
      ),
    );
  }

  // ── HELP FAB ───────────────────────────────────────────────────────────────
  Widget _buildHelpFab() {
    return GestureDetector(
      onTap: _showRulesDialog,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.08),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        alignment: Alignment.center,
        child: Icon(Icons.question_mark, size: 20),
      ),
    );
  }

  void _showRulesDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.78),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF121826),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
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
                        style: AppTextStyles.dialogTitle,
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          Navigator.of(context).pop(), // ✅ clean dismiss
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
                          color: AppColors.white70,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: AppColors.border, height: 1),
              // scrollable body — same as before, just moved inside Dialog
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RuleSection(
                        label: 'Game Rules',
                        rules: kRules.sublist(0, 5),
                      ),
                      const SizedBox(height: 20),
                      RuleSection(
                        label: 'Game Modes',
                        rules: kRules.sublist(5),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
