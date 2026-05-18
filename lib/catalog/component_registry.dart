import 'package:flutter/material.dart';
import 'package:onyxfi_frontend/catalog/goal_selection_card.dart';
import 'package:onyxfi_frontend/catalog/dynamic_input_field.dart';
import 'package:onyxfi_frontend/catalog/financial_projection_chart.dart';
import 'package:onyxfi_frontend/catalog/alert_action_badge.dart';

/// ──────────────────────────────────────────────────────────
/// OnyxFi — GenUI Component Registry
/// ──────────────────────────────────────────────────────────
/// Maps JSON `type` keys from Gemini API responses to the
/// corresponding Flutter widgets in the catalog.
///
/// Now supports an optional `onSubmit` callback that gets
/// threaded to interactive widgets (goal_selection, dynamic_input)
/// so user interactions flow back to the AI conversation.
///
/// Usage:
/// ```dart
/// final widget = ComponentRegistry.build(
///   jsonPayload,
///   onSubmit: (msg) => _sendToAI(msg),
/// );
/// ```
/// ──────────────────────────────────────────────────────────

class ComponentRegistry {
  ComponentRegistry._();

  /// Builds a Flutter widget from a structured JSON payload.
  ///
  /// [onSubmit] — Optional callback for interactive widgets.
  /// When provided, widgets like GoalSelectionCard and DynamicInputField
  /// will include a submit/confirm button that sends user input
  /// back to the AI via this callback.
  static Widget build(
    Map<String, dynamic> json, {
    Function(String)? onSubmit,
  }) {
    final type = json['type'] as String?;
    final data = json['data'] as Map<String, dynamic>? ?? {};

    if (type == null) {
      return _errorWidget('Missing "type" key in JSON payload.');
    }

    switch (type) {
      case 'goal_selection':
        return GoalSelectionCard.fromJson(data, onSubmit: onSubmit);

      case 'dynamic_input':
        return DynamicInputField.fromJson(data, onSubmit: onSubmit);

      case 'projection_chart':
        return FinancialProjectionChart.fromJson(data);

      case 'alert_badge':
        return AlertActionBadge.fromJson(data);

      default:
        return _errorWidget('Unknown component type: "$type"');
    }
  }

  /// Builds a list of widgets from a components array.
  static List<Widget> buildAll(
    List<Map<String, dynamic>> components, {
    Function(String)? onSubmit,
  }) {
    return components.map((json) => build(json, onSubmit: onSubmit)).toList();
  }

  static Widget _errorWidget(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
