import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onyxfi_frontend/main.dart';
import 'package:onyxfi_frontend/core/constants/colors.dart';
import 'package:onyxfi_frontend/core/theme/app_theme.dart';
import 'package:onyxfi_frontend/core/network/gemini_client.dart';
import 'package:onyxfi_frontend/catalog/component_registry.dart';
import 'package:onyxfi_frontend/models/chat_message.model.dart';
import 'package:onyxfi_frontend/models/onboarding_state.dart';
import 'package:onyxfi_frontend/widgets/glass_container.dart';
import 'package:onyxfi_frontend/widgets/chat_bubble.dart';

/// ──────────────────────────────────────────────────────────
/// OnyxFi — Dashboard / GenUI Chat View
/// ──────────────────────────────────────────────────────────
/// Ambient Transparent Glass aesthetic:
///   Layer 0 — Dynamic background image (Black & Orange abstract)
///   Layer 1 — Legibility overlay (dark, moderate opacity)
///   Layer 2 — Ambient Solar Orange glow accents
///   Layer 3 — SafeArea with transparent glass UI
/// ──────────────────────────────────────────────────────────

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});
  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView>
    with TickerProviderStateMixin {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focus = FocusNode();
  final List<ChatMessage> _messages = [];
  bool _loading = false;
  int _navIdx = 0;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _greet();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _focus.dispose();
    _pulse.dispose();
    super.dispose();
  }

  // ── Auto-Greeting ──────────────────────────────────────
  Future<void> _greet() async {
    setState(() => _loading = true);
    try {
      final p = await GeminiClient().sendAndParseGenUI(
        'Kullanıcıyı OnyxFi\'ye hoş geldin mesajıyla karşıla ve hemen ardından '
        'goal_selection bileşenini kullanarak birincil finansal hedeflerini sor. '
        'Hedefler arasında Ev, Araba, Emeklilik, Eğitim, Seyahat, Acil Fon olsun.',
      );
      if (mounted) {
        setState(() => _messages.add(ChatMessage.fromAIResponse(p)));
        _scroll();
      }
    } catch (e) {
      debugPrint('[DashboardView] Greeting error: $e');
      if (mounted) {
        setState(() => _messages.add(ChatMessage(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              role: MessageRole.assistant,
              content: 'Merhaba! 👋 Ben OnyxFi AI. Finansal hedeflerinize ulaşmanızda size yardımcı olabilirim.',
              timestamp: DateTime.now(),
            )));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Send User Message (from text input) ────────────────
  Future<void> _send() async {
    final t = _msgCtrl.text.trim();
    if (t.isEmpty || _loading) return;
    _msgCtrl.clear();
    await _sendToAI(t);
  }

  // ── Send from GenUI Widget Callback ────────────────────
  Future<void> _sendFromWidget(String message) async {
    if (_loading) return;
    _persistToState(message);
    await _sendToAI(message);
  }

  // ── Core AI Communication ─────────────────────────────
  Future<void> _sendToAI(String userMessage) async {
    setState(() {
      _messages.add(ChatMessage.user(userMessage));
      _loading = true;
    });
    _scroll();

    try {
      final p = await GeminiClient().sendAndParseGenUI(userMessage);
      if (mounted) {
        setState(() => _messages.add(ChatMessage.fromAIResponse(p)));
        _scroll();
      }
    } catch (e) {
      debugPrint('[DashboardView] AI error: $e');
      if (mounted) {
        setState(() => _messages.add(ChatMessage(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              role: MessageRole.assistant,
              content: 'Bir hata oluştu. Lütfen tekrar deneyin.',
              timestamp: DateTime.now(),
            )));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Persist Widget Data to Provider ────────────────────
  void _persistToState(String message) {
    final state = context.read<OnboardingStateNotifier>();
    final lower = message.toLowerCase();

    if (lower.contains('hedef')) {
      final goalIds = <String>[];
      if (lower.contains('ev') || lower.contains('home') || lower.contains('house')) goalIds.add('home');
      if (lower.contains('araba') || lower.contains('car')) goalIds.add('car');
      if (lower.contains('emeklilik') || lower.contains('retire')) goalIds.add('retirement');
      if (lower.contains('eğitim') || lower.contains('edu')) goalIds.add('education');
      if (lower.contains('seyahat') || lower.contains('travel')) goalIds.add('travel');
      if (lower.contains('acil') || lower.contains('emergency')) goalIds.add('emergency');
      if (goalIds.isNotEmpty) {
        state.setGoals(goalIds);
        state.advanceStep();
      }
    }

    final numbers = RegExp(r'[\d]+\.?[\d]*').allMatches(message);
    if (numbers.isNotEmpty) {
      final value = double.tryParse(numbers.first.group(0) ?? '');
      if (value != null) {
        if (lower.contains('maaş') || lower.contains('salary') || lower.contains('gelir')) {
          state.setMonthlySalary(value);
          state.advanceStep();
        } else if (lower.contains('gider') || lower.contains('harcama') || lower.contains('expense')) {
          state.setMonthlyExpenses(value);
          state.advanceStep();
        } else if (lower.contains('birikim') || lower.contains('tasarruf') || lower.contains('saving')) {
          state.setCurrentSavings(value);
          state.advanceStep();
        }
      }
    }
  }

  void _scroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Build ──────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width > 800;
    final bgImage = context.watch<AppState>().backgroundImage;

    return Scaffold(
      body: Stack(
        children: [
          // ── Layer 0: Dynamic Background Image ──────────
          // Remains fully intact for dynamic background switching.
          Positioned.fill(
            child: Image.asset(
              bgImage,
              fit: BoxFit.cover,
              errorBuilder: (context, e, stackTrace) => Container(
                // Fallback: near-black with warm orange undertone
                decoration: const BoxDecoration(gradient: AppColors.midnightGradient),
              ),
            ),
          ),

          // ── Layer 1: Legibility Overlay ────────────────
          // Moderate dark overlay — lets abstract background show through
          // the transparent glass, while keeping text legible.
          Positioned.fill(
            child: Container(
              color: AppColors.legibilityOverlay, // black @ 40%
            ),
          ),

          // ── Layer 2: Ambient Solar Orange Glows ────────
          // Top-right glow
          Positioned(
            top: -120,
            right: -120,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.solarOrange.withValues(alpha: 0.20),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Bottom-left glow
          Positioned(
            bottom: -150,
            left: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFF4500).withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Layer 3: UI Content ─────────────────────────
          SafeArea(
            child: wide
                ? Row(children: [_sidebar(), Expanded(child: _main())])
                : Column(children: [Expanded(child: _main()), _bottomNav()]),
          ),
        ],
      ),
    );
  }

  // ── Sidebar (Desktop) ──────────────────────────────────
  Widget _sidebar() {
    final icons = [Icons.chat_rounded, Icons.dashboard_rounded, Icons.settings_rounded];
    final labels = ['Sohbet', 'Dashboard', 'Ayarlar'];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GlassContainer.heavy(
        width: 220,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(children: [
          // Logo — Solar Orange
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppColors.orangeGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [AppColors.orangeGlow],
            ),
            child: const Icon(Icons.auto_awesome, color: AppColors.solidWhite, size: 28),
          ),
          const SizedBox(height: 12),
          Text('OnyxFi', style: AppTheme.subheading),
          const SizedBox(height: 4),
          Text('AI Finans', style: AppTheme.caption),
          const SizedBox(height: 32),

          // Nav Items
          ...List.generate(3, (i) {
            final a = _navIdx == i;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => setState(() => _navIdx = i),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: a ? AppColors.solarOrangeActive : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: a
                        ? Border.all(color: AppColors.solarOrange.withValues(alpha: 0.30))
                        : null,
                  ),
                  child: Row(children: [
                    Icon(
                      icons[i],
                      color: a ? AppColors.solarOrange : AppColors.stoneGrey,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      labels[i],
                      style: AppTheme.bodySm.copyWith(
                        color: a ? AppColors.solarOrange : AppColors.stoneGrey,
                        fontWeight: a ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ]),
                ),
              ),
            );
          }),

          const Spacer(),

          // AI status indicator — Solar Orange pulse
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.solarOrange.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.solarOrange.withValues(alpha: 0.25)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              AnimatedBuilder(
                animation: _pulse,
                builder: (context, child) => Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.solarOrange.withValues(alpha: 0.6 + _pulse.value * 0.4),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'AI Aktif',
                style: AppTheme.caption.copyWith(
                  color: AppColors.solarOrange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  // ── Bottom Nav (Mobile) ────────────────────────────────
  Widget _bottomNav() {
    final icons = [Icons.chat_rounded, Icons.dashboard_rounded, Icons.settings_rounded];
    return GlassContainer(
      borderRadius: 0,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(
          3,
          (i) => IconButton(
            onPressed: () => setState(() => _navIdx = i),
            icon: Icon(
              icons[i],
              color: _navIdx == i ? AppColors.solarOrange : AppColors.stoneGrey,
            ),
          ),
        ),
      ),
    );
  }

  // ── Main Content ───────────────────────────────────────
  Widget _main() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hoş Geldiniz 👋', style: AppTheme.heading),
                  const SizedBox(height: 4),
                  Text('OnyxFi AI ile finansal hedeflerinizi konuşun', style: AppTheme.body),
                ],
              ),
            ),
            GlassContainer(
              padding: const EdgeInsets.all(10),
              borderRadius: 12,
              child: Icon(Icons.notifications_outlined, color: AppColors.stoneGrey, size: 22),
            ),
          ]),
          const SizedBox(height: 16),

          // Chat area
          Expanded(
            child: GlassContainer(
              opacity: 0.04,
              padding: EdgeInsets.zero,
              child: Column(children: [
                _chatHeader(),
                Expanded(
                  child: _messages.isEmpty && !_loading
                      ? _empty()
                      : ListView.builder(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length + (_loading ? 1 : 0),
                          itemBuilder: (_, i) {
                            if (i == _messages.length && _loading) return _typing();
                            return _msgItem(_messages[i]);
                          },
                        ),
                ),
                _input(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Chat Header ────────────────────────────────────────
  Widget _chatHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.frostBorder)),
      ),
      child: Row(children: [
        // AI Avatar — Solar Orange
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: AppColors.orangeGradient,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [AppColors.orangeGlowSubtle],
          ),
          child: const Icon(Icons.auto_awesome, color: AppColors.solidWhite, size: 18),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'OnyxFi AI',
              style: AppTheme.bodySm.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.snowWhite,
              ),
            ),
            Row(children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.growthMint,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Aktif',
                style: AppTheme.caption.copyWith(color: AppColors.growthMint, fontSize: 11),
              ),
            ]),
          ],
        ),
        const Spacer(),
        IconButton(
          onPressed: () {
            GeminiClient().resetChat();
            context.read<OnboardingStateNotifier>().reset();
            setState(() => _messages.clear());
            _greet();
          },
          icon: Icon(Icons.refresh_rounded, color: AppColors.stoneGrey, size: 20),
          tooltip: 'Sohbeti Sıfırla',
        ),
      ]),
    );
  }

  // ── Message Item (Text + GenUI Widget) ─────────────────
  Widget _msgItem(ChatMessage m) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: m.role == MessageRole.user
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          ChatBubble(message: m),
          if (m.hasGenUI) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: ComponentRegistry.build(
                m.genUIPayload!,
                onSubmit: _sendFromWidget,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Empty State ────────────────────────────────────────
  Widget _empty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, child) => Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppColors.orangeGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.solarOrange.withValues(
                      alpha: 0.25 + (_pulse.value * 0.20),
                    ),
                    blurRadius: 28 + (_pulse.value * 14),
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome, color: AppColors.solidWhite, size: 36),
            ),
          ),
          const SizedBox(height: 24),
          Text('OnyxFi AI ile Sohbet', style: AppTheme.subheading),
          const SizedBox(height: 8),
          Text(
            'Finansal hedefleriniz hakkında soru sorun',
            style: AppTheme.body.copyWith(color: AppColors.stoneGrey),
          ),
        ],
      ),
    );
  }

  // ── Typing Indicator ──────────────────────────────────
  Widget _typing() {
    return Align(
      alignment: Alignment.centerLeft,
      child: GlassContainer(
        opacity: 0.05,
        borderRadius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            3,
            (i) => Padding(
              padding: EdgeInsets.only(left: i > 0 ? 4 : 0),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.3, end: 1.0),
                duration: Duration(milliseconds: 600 + (i * 200)),
                curve: Curves.easeInOut,
                builder: (_, v, child) => Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.solarOrange.withValues(alpha: v),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Input Area ─────────────────────────────────────────
  Widget _input() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.frostBorder)),
      ),
      child: Row(children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.glassLight,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.frostBorder),
            ),
            child: TextField(
              controller: _msgCtrl,
              focusNode: _focus,
              style: AppTheme.body.copyWith(color: AppColors.snowWhite),
              decoration: InputDecoration(
                hintText: 'Mesajınızı yazın...',
                hintStyle: AppTheme.body.copyWith(color: AppColors.stoneGrey),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
              onSubmitted: (_) => _send(),
              textInputAction: TextInputAction.send,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Send button — Solar Orange
        GestureDetector(
          onTap: _loading ? null : _send,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: _loading ? null : AppColors.orangeGradient,
              color: _loading ? AppColors.deepSlate : null,
              borderRadius: BorderRadius.circular(14),
              boxShadow: _loading
                  ? []
                  : [
                      BoxShadow(
                        color: AppColors.solarOrange.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
            ),
            child: Icon(
              _loading ? Icons.hourglass_top_rounded : Icons.send_rounded,
              color: AppColors.solidWhite,
              size: 22,
            ),
          ),
        ),
      ]),
    );
  }
}
