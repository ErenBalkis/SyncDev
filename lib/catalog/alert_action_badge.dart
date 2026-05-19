import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:onyxfi_frontend/core/constants/colors.dart';
import 'package:onyxfi_frontend/core/theme/app_theme.dart';
import 'package:onyxfi_frontend/widgets/glass_container.dart';

/// GenUI Catalog — Alert/Action badge (Midnight Ledger Dark Theme).
class AlertActionBadge extends StatelessWidget {
  final String severity;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AlertActionBadge({super.key, this.severity = 'info', required this.title, required this.message, this.actionLabel, this.onAction});

  static CatalogItem toCatalogItem() {
    return CatalogItem(
      name: 'AlertActionBadge',
      dataSchema: S.object(
        properties: {
          'severity': S.string(description: 'info, warning, success, veya danger'),
          'title': S.string(description: 'Uyarı başlığı'),
          'message': S.string(description: 'Uyarı mesajı'),
        },
      ),
      widgetBuilder: (itemContext) {
        final map = itemContext.data as Map<String, dynamic>? ?? {};
        return AlertActionBadge.fromJson(map);
      },
    );
  }

  factory AlertActionBadge.fromJson(Map<String, dynamic> json) {
    return AlertActionBadge(severity: json['severity'] as String? ?? 'info', title: json['title'] as String? ?? 'Bildirim', message: json['message'] as String? ?? '', actionLabel: json['actionLabel'] as String?);
  }

  Color get _accentColor {
    switch (severity) {
      case 'warning': return AppColors.amberFlame;
      case 'success': return AppColors.growthMint;
      case 'danger': return AppColors.crimsonPulse;
      default: return AppColors.solarOrange;
    }
  }

  IconData get _icon {
    switch (severity) {
      case 'warning': return Icons.warning_amber_rounded;
      case 'success': return Icons.check_circle_outline;
      case 'danger': return Icons.error_outline;
      default: return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      opacity: 0.06,
      padding: const EdgeInsets.all(20),
      borderColor: _accentColor.withValues(alpha: 0.3),
      glowShadows: [BoxShadow(color: _accentColor.withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, 4))],
      child: Row(children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: _accentColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)), child: Icon(_icon, color: _accentColor, size: 22)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(title, style: AppTheme.bodySm.copyWith(fontWeight: FontWeight.w600, color: AppColors.snowWhite)),
          const SizedBox(height: 4),
          Text(message, style: AppTheme.caption.copyWith(color: AppColors.silverMist)),
        ])),
        if (actionLabel != null) TextButton(onPressed: onAction, style: TextButton.styleFrom(foregroundColor: _accentColor), child: Text(actionLabel!)),
      ]),
    );
  }
}
