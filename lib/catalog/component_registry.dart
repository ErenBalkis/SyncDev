import 'package:genui/genui.dart';
import 'package:onyxfi_frontend/catalog/goal_selection_card.dart';
import 'package:onyxfi_frontend/catalog/dynamic_input_field.dart';
import 'package:onyxfi_frontend/catalog/financial_projection_chart.dart';
import 'package:onyxfi_frontend/catalog/alert_action_badge.dart';

/// ──────────────────────────────────────────────────────────
/// OnyxFi — GenUI Widget Catalog
/// ──────────────────────────────────────────────────────────
/// Replaces the manual ComponentRegistry JSON parsing logic.
/// Returns a [Catalog] that registers our custom widgets with
/// the official GenUI SDK so they can be rendered as A2UI Surfaces.
/// ──────────────────────────────────────────────────────────

class OnyxCatalog {
  OnyxCatalog._();

  static Catalog buildCatalog({Function(String)? onSubmit}) {
    return Catalog(
      [
        GoalSelectionCard.toCatalogItem(onSubmit: onSubmit),
        DynamicInputField.toCatalogItem(onSubmit: onSubmit),
        FinancialProjectionChart.toCatalogItem(),
        AlertActionBadge.toCatalogItem(),
      ],
      catalogId: 'com.onyxfi.catalog',
    );
  }
}
