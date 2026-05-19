import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:genui/genui.dart' as genui;
import 'package:genui/genui.dart' hide ChatMessage;
import 'package:onyxfi_frontend/main.dart';
import 'package:onyxfi_frontend/core/constants/colors.dart';
import 'package:onyxfi_frontend/core/theme/app_theme.dart';
import 'package:onyxfi_frontend/core/network/gemini_client.dart';
import 'package:onyxfi_frontend/catalog/component_registry.dart';
import 'package:onyxfi_frontend/models/chat_message.model.dart';
import 'package:onyxfi_frontend/models/onboarding_state.dart';
import 'package:onyxfi_frontend/widgets/glass_container.dart';
import 'package:onyxfi_frontend/widgets/chat_bubble.dart';
import 'package:fl_chart/fl_chart.dart';

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
  
  // GenUI Infrastructure
  late final SurfaceController _surfaceController;
  late final Conversation _conversation;
  
  // Unified history: contains String (Surface IDs) or OnyxChatMessage (Text bubbles)
  final List<dynamic> _history = [];
  String _currentAiText = '';
  
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

    _initGenUI();
    _greet();
  }

  void _initGenUI() {
    final adapter = GeminiClient().buildTransportAdapter();
    _surfaceController = SurfaceController(
      catalogs: [OnyxCatalog.buildCatalog(onSubmit: _sendFromWidget)],
    );
    _conversation = Conversation(
      controller: _surfaceController,
      transport: adapter,
    );

    // Listen to surface rendering and streaming text events
    _conversation.events.listen((event) {
      if (!mounted) return;
      debugPrint('[Dashboard] Event: ${event.runtimeType}');
      if (event is ConversationSurfaceAdded) {
        debugPrint('[Dashboard] ✅ Surface added: ${event.surfaceId}');
        setState(() => _history.add(event.surfaceId));
        _scroll();
      } else if (event is ConversationSurfaceRemoved) {
        debugPrint('[Dashboard] Surface removed: ${event.surfaceId}');
        setState(() => _history.remove(event.surfaceId));
      } else if (event is ConversationContentReceived) {
        debugPrint('[Dashboard] Text: "${event.text.substring(0, event.text.length.clamp(0, 80))}"');
        setState(() => _currentAiText = event.text);
        _scroll();
      } else if (event is ConversationComponentsUpdated) {
        debugPrint('[Dashboard] ✅ Components updated on: ${event.surfaceId}');
        setState(() {}); // Trigger rebuild to reflect updated components
        _scroll();
      } else if (event is ConversationWaiting) {
        debugPrint('[Dashboard] ⏳ Waiting for AI...');
        setState(() => _loading = true);
        _currentAiText = '';
      } else if (event is ConversationError) {
        debugPrint('[Dashboard] ❌ Error: ${event.error}');
        setState(() {
          _loading = false;
          _history.add(OnyxChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            role: OnyxMessageRole.assistant,
            content: 'Bir hata oluştu: ${event.error}',
            timestamp: DateTime.now(),
          ));
        });
      }
    });

    // Detect when generation completes
    _conversation.state.addListener(() {
      if (!mounted) return;
      if (!_conversation.state.value.isWaiting && _loading) {
        setState(() {
          _loading = false;
          if (_currentAiText.trim().isNotEmpty) {
             _history.add(OnyxChatMessage(
               id: DateTime.now().millisecondsSinceEpoch.toString(),
               role: OnyxMessageRole.assistant,
               content: _currentAiText.trim(),
               timestamp: DateTime.now(),
             ));
          }
          _currentAiText = '';
        });
        _scroll();
      }
    });
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
    // Send a hidden prompt to trigger the initial onboarding flow
    await _sendToAI(
      'Kullanıcıyı OnyxFi\'ye hoş geldin mesajıyla karşıla ve hemen ardından '
      'GoalSelectionCard widget\'ını iki adımlı A2UI protokolü ile '
      '(createSurface + updateComponents) render ederek birincil finansal '
      'hedeflerini sor. Hedefler: Ev, Araba, Emeklilik, Eğitim, Seyahat, Acil Fon.',
      hidden: true,
    );
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
  Future<void> _sendToAI(String userMessage, {bool hidden = false}) async {
    if (!hidden) {
      setState(() => _history.add(OnyxChatMessage.user(userMessage)));
      _scroll();
    }
    
    // Use the official GenUI ChatMessage to send to the SDK
    await _conversation.sendRequest(genui.ChatMessage.user(userMessage));
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
          Positioned.fill(
            child: Image.asset(
              bgImage,
              fit: BoxFit.cover,
              errorBuilder: (context, e, stackTrace) => Container(
                decoration: const BoxDecoration(gradient: AppColors.midnightGradient),
              ),
            ),
          ),
          
          // ── Layer 1: Ambient Overlay ──────────
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.40)),
          ),
          
          // ── Layer 2: Solar Orange Glows ──────────
          Positioned.fill(
            child: CustomPaint(painter: OrangeGlowPainter()),
          ),
          
          // ── Layer 3: Glass UI ──────────
          SafeArea(
            child: wide
                ? Row(children: [_sidebar(), Expanded(child: _currentView())])
                : Column(children: [Expanded(child: _currentView()), _bottomNav()]),
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
                    border: a ? Border.all(color: AppColors.solarOrange.withValues(alpha: 0.30)) : null,
                  ),
                  child: Row(children: [
                    Icon(icons[i], color: a ? AppColors.solarOrange : AppColors.stoneGrey, size: 20),
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
              Text('AI Aktif', style: AppTheme.caption.copyWith(color: AppColors.solarOrange, fontWeight: FontWeight.w500)),
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
            icon: Icon(icons[i], color: _navIdx == i ? AppColors.solarOrange : AppColors.stoneGrey),
          ),
        ),
      ),
    );
  }

  // ── View Router ────────────────────────────────────────
  Widget _currentView() {
    switch (_navIdx) {
      case 1:
        return _analyticsView();
      case 2:
        return _settingsView();
      default:
        return _main();
    }
  }

  // ── Analytics Dashboard ────────────────────────────────
  Widget _analyticsView() {
    final state = context.watch<OnboardingStateNotifier>();
    final salary = state.monthlySalary ?? 0;
    final expenses = state.monthlyExpenses ?? 0;
    final savings = state.currentSavings ?? 0;
    final goalIds = state.selectedGoalIds;
    final netMonthly = salary - expenses;

    // Emoji mapping for goal IDs
    const goalEmojis = {
      'home': '🏠', 'car': '🚗', 'retirement': '🏖️',
      'education': '🎓', 'travel': '✈️', 'emergency': '🛡️',
    };

    // Financial health score (simple heuristic)
    int healthScore = 50;
    if (salary > 0) healthScore += 15;
    if (expenses < salary * 0.7) healthScore += 15;
    if (savings > salary * 3) healthScore += 10;
    if (goalIds.isNotEmpty) healthScore += 10;
    healthScore = healthScore.clamp(0, 100);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Section 1: Header & Health Score ───────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Varlık Simülasyonu', style: AppTheme.heading),
                      const SizedBox(height: 4),
                      Text('Finansal durumunuzun canlı özeti', style: AppTheme.body),
                    ],
                  ),
                ),
                GlassContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  borderRadius: 16,
                  glowShadows: [AppColors.orangeGlowSubtle],
                  child: Column(
                    children: [
                      Text(
                        '$healthScore',
                        style: AppTheme.balanceText.copyWith(
                          fontSize: 28,
                          color: AppColors.solarOrange,
                        ),
                      ),
                      Text('/100', style: AppTheme.caption),
                      const SizedBox(height: 2),
                      Text(
                        'Sağlık Skoru',
                        style: AppTheme.caption.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Section 2: Financial Metrics Grid ──────────────
            GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.45,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _metricCard(
                  icon: Icons.trending_up_rounded,
                  label: 'Aylık Gelir',
                  value: _formatTL(salary),
                  accentColor: AppColors.growthMint,
                ),
                _metricCard(
                  icon: Icons.trending_down_rounded,
                  label: 'Aylık Gider',
                  value: _formatTL(expenses),
                  accentColor: AppColors.crimsonPulse,
                ),
                _metricCard(
                  icon: Icons.savings_rounded,
                  label: 'Mevcut Birikim',
                  value: _formatTL(savings),
                  accentColor: AppColors.solarOrange,
                ),
                _goalsCard(goalIds, goalEmojis),
              ],
            ),
            const SizedBox(height: 24),

            // ── Section 3: 12-Month Projection Chart ──────────
            GlassContainer(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.solarOrange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.show_chart_rounded, color: AppColors.solarOrange, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '12 Aylık Birikim Projeksiyonu',
                              style: AppTheme.bodySm.copyWith(
                                color: AppColors.snowWhite,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              netMonthly > 0
                                  ? 'Aylık ${_formatTL(netMonthly)} net tasarruf'
                                  : 'Henüz veri girilmedi',
                              style: AppTheme.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 200,
                    child: _buildProjectionChart(savings, netMonthly),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Section 4: Net Savings Summary Badge ─────────
            GlassContainer(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: AppColors.orangeGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [AppColors.orangeGlowSubtle],
                    ),
                    child: const Icon(Icons.rocket_launch_rounded, color: AppColors.solidWhite, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Yıl Sonu Tahmini Birikim',
                          style: AppTheme.bodySm.copyWith(
                            color: AppColors.snowWhite,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTL(savings + (netMonthly * 12)),
                          style: AppTheme.balanceText.copyWith(fontSize: 24, color: AppColors.solarOrange),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ── Metric Card Builder ───────────────────────────────
  Widget _metricCard({
    required IconData icon,
    required String label,
    required String value,
    required Color accentColor,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(height: 8),
          Text(label, style: AppTheme.caption),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTheme.subheading.copyWith(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  // ── Goals Card ───────────────────────────────────────
  Widget _goalsCard(List<String> goalIds, Map<String, String> emojiMap) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.amberFlame.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.flag_rounded, color: AppColors.amberFlame, size: 20),
          ),
          const SizedBox(height: 8),
          Text('Aktif Hedefler', style: AppTheme.caption),
          const SizedBox(height: 4),
          goalIds.isEmpty
              ? Text('Henüz seçilmedi', style: AppTheme.bodySm.copyWith(color: AppColors.stoneGrey))
              : Flexible(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: goalIds.map((id) {
                      final emoji = emojiMap[id] ?? '🎯';
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.solarOrange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.solarOrange.withValues(alpha: 0.25)),
                        ),
                        child: Text(emoji, style: const TextStyle(fontSize: 16)),
                      );
                    }).toList(),
                  ),
                ),
        ],
      ),
    );
  }

  // ── Projection Chart ─────────────────────────────────
  Widget _buildProjectionChart(double initialSavings, double netMonthly) {
    // Generate 12 data points: month 0 = current savings, months 1–12 compound
    final spots = List.generate(13, (i) {
      return FlSpot(i.toDouble(), initialSavings + (netMonthly * i));
    });

    final maxY = spots.isEmpty ? 100.0 : spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final minY = spots.isEmpty ? 0.0 : spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final yRange = (maxY - minY).abs();
    final effectiveMaxY = maxY + (yRange * 0.15).clamp(1000, double.infinity);
    final effectiveMinY = (minY - (yRange * 0.05)).clamp(0, double.infinity).toDouble();

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: 12,
        minY: effectiveMinY,
        maxY: effectiveMaxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: yRange > 0 ? yRange / 4 : 10000,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Colors.white.withValues(alpha: 0.05),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              getTitlesWidget: (value, meta) {
                if (value == meta.min || value == meta.max) return const SizedBox.shrink();
                return Text(
                  _formatCompact(value),
                  style: AppTheme.caption.copyWith(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 3,
              getTitlesWidget: (value, _) {
                final month = value.toInt();
                if (month == 0) return Text('Bugün', style: AppTheme.caption.copyWith(fontSize: 10));
                return Text('${month}ay', style: AppTheme.caption.copyWith(fontSize: 10));
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((spot) {
              return LineTooltipItem(
                _formatTL(spot.y),
                AppTheme.bodySm.copyWith(
                  color: AppColors.solarOrange,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: AppColors.solarOrange,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, show, barData, index) => FlDotCirclePainter(
                radius: spot.x % 3 == 0 ? 4 : 0, // Show dots at quarters
                color: AppColors.solarOrange,
                strokeWidth: 2,
                strokeColor: AppColors.solidWhite,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.solarOrange.withValues(alpha: 0.28),
                  AppColors.solarOrange.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  // ── TL Formatter ─────────────────────────────────────
  String _formatTL(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M ₺';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}K ₺';
    }
    return '${value.toStringAsFixed(0)} ₺';
  }

  String _formatCompact(double value) {
    if (value.abs() >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value.abs() >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
    return value.toStringAsFixed(0);
  }

  // ── Settings Placeholder ───────────────────────────────
  Widget _settingsView() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ayarlar', style: AppTheme.heading),
          const SizedBox(height: 4),
          Text('Uygulama tercihlerinizi yönetin', style: AppTheme.body),
          const SizedBox(height: 24),
          // Profile Card
          GlassContainer(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppColors.orangeGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [AppColors.orangeGlowSubtle],
                ),
                child: const Icon(Icons.person_rounded, color: AppColors.solidWhite, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kullanıcı Profili', style: AppTheme.subheading),
                    const SizedBox(height: 4),
                    Text('Kişisel bilgilerinizi düzenleyin', style: AppTheme.caption),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.stoneGrey, size: 24),
            ]),
          ),
          const SizedBox(height: 12),
          // Theme Toggle
          GlassContainer(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.solarOrange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.dark_mode_rounded, color: AppColors.solarOrange, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(child: Text('Koyu Tema', style: AppTheme.bodySm.copyWith(color: AppColors.snowWhite))),
              Switch(
                value: true,
                onChanged: (_) {},
                activeThumbColor: AppColors.solarOrange,
                activeTrackColor: AppColors.solarOrange.withValues(alpha: 0.30),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          // Notifications Toggle
          GlassContainer(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.solarOrange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.notifications_rounded, color: AppColors.solarOrange, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(child: Text('Bildirimler', style: AppTheme.bodySm.copyWith(color: AppColors.snowWhite))),
              Switch(
                value: true,
                onChanged: (_) {},
                activeThumbColor: AppColors.solarOrange,
                activeTrackColor: AppColors.solarOrange.withValues(alpha: 0.30),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          // About
          GlassContainer(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.solarOrange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.info_outline_rounded, color: AppColors.solarOrange, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hakkında', style: AppTheme.bodySm.copyWith(color: AppColors.snowWhite)),
                    const SizedBox(height: 2),
                    Text('OnyxFi v1.0.0 — Hackathon MVP', style: AppTheme.caption),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.stoneGrey, size: 24),
            ]),
          ),
        ],
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

          Expanded(
            child: GlassContainer(
              opacity: 0.04,
              padding: EdgeInsets.zero,
              child: Column(children: [
                _chatHeader(),
                Expanded(
                  child: _history.isEmpty && !_loading
                      ? _empty()
                      : ListView.builder(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.all(16),
                          itemCount: _history.length + (_currentAiText.isNotEmpty ? 1 : 0) + (_loading && _currentAiText.isEmpty ? 1 : 0),
                          itemBuilder: (_, i) {
                            if (i < _history.length) return _msgItem(_history[i]);
                            if (_currentAiText.isNotEmpty) {
                               return Padding(
                                 padding: const EdgeInsets.only(bottom: 12),
                                 child: ChatBubble(
                                   message: OnyxChatMessage(
                                     id: 'temp', 
                                     role: OnyxMessageRole.assistant, 
                                     content: _currentAiText, 
                                     timestamp: DateTime.now(),
                                   ),
                                 ),
                               );
                            }
                            return _typing();
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
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.frostBorder))),
      child: Row(children: [
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
            Text('OnyxFi AI', style: AppTheme.bodySm.copyWith(fontWeight: FontWeight.w600, color: AppColors.snowWhite)),
            Row(children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(color: AppColors.growthMint, shape: BoxShape.circle),
              ),
              const SizedBox(width: 4),
              Text('Aktif', style: AppTheme.caption.copyWith(color: AppColors.growthMint, fontSize: 11)),
            ]),
          ],
        ),
        const Spacer(),
        IconButton(
          onPressed: () {
            context.read<OnboardingStateNotifier>().reset();
            setState(() => _history.clear());
            _greet();
          },
          icon: Icon(Icons.refresh_rounded, color: AppColors.stoneGrey, size: 20),
          tooltip: 'Sohbeti Sıfırla',
        ),
      ]),
    );
  }

  // ── Message Item (Text + GenUI Surface) ────────────────
  Widget _msgItem(dynamic item) {
    if (item is String) {
      // It's a GenUI Surface ID
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Surface(surfaceContext: _surfaceController.contextFor(item)),
        ),
      );
    } else if (item is OnyxChatMessage) {
      // It's a plain text fallback bubble
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: item.role == OnyxMessageRole.user
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            ChatBubble(message: item),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
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
                    color: AppColors.solarOrange.withValues(alpha: 0.25 + (_pulse.value * 0.20)),
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
          Text('Finansal hedefleriniz hakkında soru sorun', style: AppTheme.body.copyWith(color: AppColors.stoneGrey)),
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
                  : [BoxShadow(color: AppColors.solarOrange.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Icon(_loading ? Icons.hourglass_top_rounded : Icons.send_rounded, color: AppColors.solidWhite, size: 22),
          ),
        ),
      ]),
    );
  }
}

// ── Background Glows (Layer 2) ───────────────────────────
class OrangeGlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.solarOrange.withValues(alpha: 0.15),
          AppColors.solarOrange.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: const Offset(150, 150), radius: 300))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100);
    canvas.drawCircle(const Offset(150, 150), 300, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
