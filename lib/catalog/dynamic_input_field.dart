import 'package:flutter/material.dart';
import 'package:onyxfi_frontend/core/constants/colors.dart';
import 'package:onyxfi_frontend/core/theme/app_theme.dart';
import 'package:onyxfi_frontend/widgets/glass_container.dart';

/// ──────────────────────────────────────────────────────────
/// OnyxFi — Dynamic Input Field (Ambient Transparent Glass)
/// ──────────────────────────────────────────────────────────
/// GenUI catalog component for numeric/text input.
/// Solar Orange cursor and submit button accent.
/// ──────────────────────────────────────────────────────────

class DynamicInputField extends StatefulWidget {
  final String label;
  final String hint;
  final String? suffix;
  final String inputType;
  final ValueChanged<String>? onChanged;

  /// Callback invoked when the user taps the submit button.
  final Function(String)? onSubmit;

  const DynamicInputField({
    super.key,
    required this.label,
    this.hint = '',
    this.suffix,
    this.inputType = 'number',
    this.onChanged,
    this.onSubmit,
  });

  factory DynamicInputField.fromJson(
    Map<String, dynamic> json, {
    Function(String)? onSubmit,
  }) {
    return DynamicInputField(
      label: json['label'] as String? ?? json['placeholder'] as String? ?? 'Değer girin',
      hint: json['hint'] as String? ?? json['placeholder'] as String? ?? '',
      suffix: json['suffix'] as String? ?? json['currency'] as String?,
      inputType: json['inputType'] as String? ?? json['input_type'] as String? ?? 'number',
      onSubmit: onSubmit,
    );
  }

  @override
  State<DynamicInputField> createState() => _DynamicInputFieldState();
}

class _DynamicInputFieldState extends State<DynamicInputField> {
  final _controller = TextEditingController();
  bool _hasValue = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final value = _controller.text.trim();
    if (value.isEmpty || widget.onSubmit == null) return;
    final suffix = widget.suffix ?? '';
    final message = '${widget.label}: $value $suffix'.trim();
    widget.onSubmit!(message);
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      opacity: 0.06,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.label,
            style: AppTheme.bodySm.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.silverMist,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Input field
              Expanded(
                child: TextField(
                  controller: _controller,
                  keyboardType: widget.inputType == 'number'
                      ? TextInputType.number
                      : TextInputType.text,
                  onChanged: (v) {
                    setState(() => _hasValue = v.trim().isNotEmpty);
                    widget.onChanged?.call(v);
                  },
                  onSubmitted: (_) => _handleSubmit(),
                  style: AppTheme.heading.copyWith(fontSize: 28, color: AppColors.snowWhite),
                  // Solar Orange cursor
                  cursorColor: AppColors.solarOrange,
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: AppTheme.heading.copyWith(
                      fontSize: 28,
                      color: AppColors.stoneGrey,
                    ),
                    suffixText: widget.suffix,
                    suffixStyle: AppTheme.subheading.copyWith(color: AppColors.stoneGrey),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),

              // Submit button — Solar Orange
              if (widget.onSubmit != null)
                AnimatedOpacity(
                  opacity: _hasValue ? 1.0 : 0.3,
                  duration: const Duration(milliseconds: 200),
                  child: GestureDetector(
                    onTap: _hasValue ? _handleSubmit : null,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: _hasValue ? AppColors.orangeGradient : null,
                        color: _hasValue ? null : AppColors.deepSlate,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: _hasValue ? [AppColors.orangeGlowSubtle] : [],
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: AppColors.solidWhite,
                        size: 20,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
