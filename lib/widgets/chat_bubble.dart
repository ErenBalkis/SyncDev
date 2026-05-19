import 'package:flutter/material.dart';
import 'package:onyxfi_frontend/core/constants/colors.dart';
import 'package:onyxfi_frontend/core/theme/app_theme.dart';
import 'package:onyxfi_frontend/models/chat_message.model.dart';
import 'package:onyxfi_frontend/widgets/glass_container.dart';

/// ──────────────────────────────────────────────────────────
/// OnyxFi — Chat Bubble (Ambient Transparent Glass)
/// ──────────────────────────────────────────────────────────
/// User messages — right-aligned, Solar Orange frost border + glow.
/// AI messages — left-aligned, white frost glass, no accent glow.
/// All text is white-based for legibility on dark background.
/// ──────────────────────────────────────────────────────────
class ChatBubble extends StatelessWidget {
  final OnyxChatMessage message;

  const ChatBubble({super.key, required this.message});

  bool get _isUser => message.role == OnyxMessageRole.user;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: _isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: GlassContainer(
          opacity: _isUser ? 0.10 : 0.05,
          borderRadius: 16,
          borderColor: _isUser
              ? AppColors.solarOrange.withValues(alpha: 0.40)
              : AppColors.frostBorder,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          margin: const EdgeInsets.symmetric(vertical: 4),
          glowShadows: _isUser
              ? [
                  BoxShadow(
                    color: AppColors.solarOrange.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.content,
                style: AppTheme.bodySm.copyWith(
                  color: _isUser ? AppColors.snowWhite : AppColors.silverMist,
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  _formatTime(message.timestamp),
                  style: AppTheme.caption.copyWith(
                    color: AppColors.stoneGrey,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
