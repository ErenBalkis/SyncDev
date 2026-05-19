import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:onyxfi_frontend/core/constants/colors.dart';
import 'package:onyxfi_frontend/core/theme/app_theme.dart';
import 'package:onyxfi_frontend/widgets/glass_container.dart';

/// ──────────────────────────────────────────────────────────
/// OnyxFi — Goal Selection Card (Ambient Transparent Glass)
/// ──────────────────────────────────────────────────────────
/// GenUI catalog component for financial goal selection.
/// Solar Orange accent for selected states and confirm button.
/// ──────────────────────────────────────────────────────────

class GoalSelectionCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<GoalOption> goals;
  final ValueChanged<List<String>>? onSelectionChanged;

  /// Callback invoked when the user confirms their selection.
  final Function(String)? onSubmit;

  const GoalSelectionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.goals,
    this.onSelectionChanged,
    this.onSubmit,
  });

  static CatalogItem toCatalogItem({Function(String)? onSubmit}) {
    return CatalogItem(
      name: 'GoalSelectionCard',
      dataSchema: S.object(
        properties: {
          'title': S.string(description: 'Kart başlığı'),
          'subtitle': S.string(description: 'Alt başlık açıklaması'),
          'goals': S.list(
            items: S.object(
              properties: {
                'id': S.string(description: 'Hedef ID'),
                'label': S.string(description: 'Hedef adı'),
                'emoji': S.string(description: 'Emoji'),
              },
            ),
            description: 'Kullanıcının seçebileceği finansal hedefler',
          ),
        },
      ),
      widgetBuilder: (itemContext) {
        final map = itemContext.data as Map<String, dynamic>? ?? {};
        return GoalSelectionCard.fromJson(map, onSubmit: onSubmit);
      },
    );
  }

  factory GoalSelectionCard.fromJson(
    Map<String, dynamic> json, {
    Function(String)? onSubmit,
  }) {
    final goalsRaw = json['goals'] as List<dynamic>? ?? [];
    final optionsRaw = json['options'] as List<dynamic>?;

    List<GoalOption> parsedGoals;
    if (goalsRaw.isNotEmpty) {
      parsedGoals = goalsRaw
          .map((g) => g is Map<String, dynamic>
              ? GoalOption.fromJson(g)
              : GoalOption(id: g.toString().toLowerCase(), label: g.toString(), emoji: '🎯'))
          .toList();
    } else if (optionsRaw != null && optionsRaw.isNotEmpty) {
      parsedGoals = optionsRaw
          .map((o) => GoalOption(
              id: o.toString().toLowerCase().replaceAll(' ', '_'),
              label: o.toString(),
              emoji: _emojiForGoal(o.toString())))
          .toList();
    } else {
      parsedGoals = GoalOption.defaults;
    }

    return GoalSelectionCard(
      title: json['title'] as String? ?? 'Hedefinizi Seçin',
      subtitle: json['subtitle'] as String? ?? 'Bir veya daha fazla hedef seçin',
      goals: parsedGoals,
      onSubmit: onSubmit,
    );
  }

  static String _emojiForGoal(String label) {
    final l = label.toLowerCase();
    if (l.contains('house') || l.contains('ev') || l.contains('home')) return '🏠';
    if (l.contains('car') || l.contains('araba')) return '🚗';
    if (l.contains('retire') || l.contains('emekli')) return '🏖️';
    if (l.contains('edu') || l.contains('eğitim')) return '🎓';
    if (l.contains('travel') || l.contains('seyahat')) return '✈️';
    if (l.contains('emergency') || l.contains('acil')) return '🛡️';
    if (l.contains('invest') || l.contains('yatırım')) return '📈';
    if (l.contains('debt') || l.contains('borç')) return '💳';
    return '🎯';
  }

  @override
  State<GoalSelectionCard> createState() => _GoalSelectionCardState();
}

class _GoalSelectionCardState extends State<GoalSelectionCard>
    with TickerProviderStateMixin {
  final Set<String> _selectedIds = {};
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  void _toggleGoal(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
    widget.onSelectionChanged?.call(_selectedIds.toList());
  }

  void _confirmSelection() {
    if (_selectedIds.isEmpty || widget.onSubmit == null) return;
    final selectedLabels = widget.goals
        .where((g) => _selectedIds.contains(g.id))
        .map((g) => g.label)
        .toList();
    final message = '${selectedLabels.join(", ")} hedeflerini seçtim.';
    widget.onSubmit!(message);
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      opacity: 0.06,
      padding: const EdgeInsets.all(AppTheme.cardPaddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header — Solar Orange icon
          Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.solarOrange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.flag_rounded, color: AppColors.solarOrange, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title, style: AppTheme.subheading),
                  const SizedBox(height: 2),
                  Text(widget.subtitle, style: AppTheme.caption),
                ],
              ),
            ),
          ]),

          const SizedBox(height: 28),

          // Goals Grid
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: widget.goals
                .map((g) => _GoalChip(
                      goal: g,
                      isSelected: _selectedIds.contains(g.id),
                      onTap: () => _toggleGoal(g.id),
                    ))
                .toList(),
          ),

          // Counter + Confirm — Solar Orange
          if (_selectedIds.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                // Shimmer counter badge — Solar Orange
                AnimatedBuilder(
                  animation: _shimmerController,
                  builder: (_, child) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.solarOrange.withValues(alpha: 0.08),
                          AppColors.solarOrange.withValues(alpha: 0.20),
                          AppColors.solarOrange.withValues(alpha: 0.08),
                        ],
                        stops: [0.0, _shimmerController.value, 1.0],
                      ),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.solarOrange.withValues(alpha: 0.30),
                      ),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.check_circle, color: AppColors.solarOrange, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        '${_selectedIds.length} hedef seçildi',
                        style: AppTheme.bodySm.copyWith(
                          color: AppColors.solarOrange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ]),
                  ),
                ),

                const Spacer(),

                // Confirm button — Solar Orange solid
                if (widget.onSubmit != null)
                  GestureDetector(
                    onTap: _confirmSelection,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: AppColors.orangeGradient,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [AppColors.orangeGlowSubtle],
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.send_rounded, color: AppColors.solidWhite, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Onayla',
                          style: AppTheme.bodySm.copyWith(
                            color: AppColors.solidWhite,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ]),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Goal Chip ────────────────────────────────────────────
class _GoalChip extends StatefulWidget {
  final GoalOption goal;
  final bool isSelected;
  final VoidCallback onTap;

  const _GoalChip({
    required this.goal,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_GoalChip> createState() => _GoalChipState();
}

class _GoalChipState extends State<_GoalChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sel = widget.isSelected;

    return GestureDetector(
      onTapDown: (_) => _scaleCtrl.forward(),
      onTapUp: (_) {
        _scaleCtrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _scaleCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (_, child) => Transform.scale(scale: _scaleAnim.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                width: 100,
                height: 110,
                decoration: BoxDecoration(
                  // Solar Orange fill when selected, transparent glass when not
                  color: sel
                      ? AppColors.solarOrange.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: sel
                        ? AppColors.solarOrange.withValues(alpha: 0.55)
                        : AppColors.frostBorder,
                    width: sel ? 2.0 : 1.0,
                  ),
                  boxShadow: sel
                      ? [
                          BoxShadow(
                            color: AppColors.solarOrange.withValues(alpha: 0.25),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : [AppColors.glassShadow],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(widget.goal.emoji, style: const TextStyle(fontSize: 32)),
                    const SizedBox(height: 8),
                    Text(
                      widget.goal.label,
                      style: AppTheme.bodySm.copyWith(
                        color: sel ? AppColors.solarOrange : AppColors.silverMist,
                        fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    AnimatedOpacity(
                      opacity: sel ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        margin: const EdgeInsets.only(top: 4),
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: AppColors.solarOrange,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: AppColors.solidWhite, size: 12),
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
}

// ── GoalOption Model ─────────────────────────────────────
class GoalOption {
  final String id;
  final String label;
  final String emoji;
  final String? iconName;

  const GoalOption({
    required this.id,
    required this.label,
    required this.emoji,
    this.iconName,
  });

  factory GoalOption.fromJson(Map<String, dynamic> json) {
    return GoalOption(
      id: json['id'] as String? ?? 'unknown',
      label: json['label'] as String? ?? 'Hedef',
      emoji: json['emoji'] as String? ?? '🎯',
      iconName: json['icon'] as String?,
    );
  }

  static List<GoalOption> get defaults => const [
        GoalOption(id: 'home', label: 'Ev', emoji: '🏠'),
        GoalOption(id: 'car', label: 'Araba', emoji: '🚗'),
        GoalOption(id: 'retirement', label: 'Emeklilik', emoji: '🏖️'),
        GoalOption(id: 'education', label: 'Eğitim', emoji: '🎓'),
        GoalOption(id: 'travel', label: 'Seyahat', emoji: '✈️'),
        GoalOption(id: 'emergency', label: 'Acil Fon', emoji: '🛡️'),
      ];
}
