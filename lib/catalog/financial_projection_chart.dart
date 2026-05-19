import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:onyxfi_frontend/core/constants/colors.dart';
import 'package:onyxfi_frontend/core/theme/app_theme.dart';
import 'package:onyxfi_frontend/widgets/glass_container.dart';

/// GenUI Catalog — Dynamic line chart for financial projections.
/// Solar Orange chart line, gradient fill, and dot colors.
class FinancialProjectionChart extends StatelessWidget {
  final String chartType;
  final String title;
  final List<FlSpot> spots;
  final List<String> labels;

  const FinancialProjectionChart({
    super.key,
    this.chartType = 'line',
    required this.title,
    required this.spots,
    this.labels = const [],
  });

  static CatalogItem toCatalogItem() {
    return CatalogItem(
      name: 'FinancialProjectionChart',
      dataSchema: S.object(
        properties: {
          'title': S.string(description: 'Grafik başlığı'),
          'points': S.list(
            items: S.object(
              properties: {
                'x': S.number(description: 'X ekseni değeri'),
                'y': S.number(description: 'Y ekseni değeri'),
              },
            ),
            description: 'Grafik veri noktaları',
          ),
          'labels': S.list(
            items: S.string(),
            description: 'X ekseni etiketleri',
          ),
        },
      ),
      widgetBuilder: (itemContext) {
        final map = itemContext.data as Map<String, dynamic>? ?? {};
        return FinancialProjectionChart.fromJson(map);
      },
    );
  }

  factory FinancialProjectionChart.fromJson(Map<String, dynamic> json) {
    final points = json['points'] as List<dynamic>? ?? [];
    List<FlSpot> parsedSpots = [];
    if (points.isNotEmpty) {
      parsedSpots = points.map((p) {
        final m = p as Map<String, dynamic>;
        return FlSpot(
          (m['x'] as num?)?.toDouble() ?? 0,
          (m['y'] as num?)?.toDouble() ?? 0,
        );
      }).toList();
    } else {
      final series = json['series'] as List<dynamic>?;
      if (series != null && series.isNotEmpty) {
        final values = (series[0] as Map<String, dynamic>)['values'] as List<dynamic>? ?? [];
        parsedSpots = List.generate(
          values.length,
          (i) => FlSpot(i.toDouble(), (values[i] as num).toDouble()),
        );
      }
    }
    final rawLabels = json['labels'] as List<dynamic>? ?? json['x_axis'] as List<dynamic>? ?? [];

    return FinancialProjectionChart(
      chartType: json['chartType'] as String? ?? json['chart_type'] as String? ?? 'line',
      title: json['title'] as String? ?? 'Projeksiyon',
      spots: parsedSpots,
      labels: rawLabels.map((l) => l.toString()).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      opacity: 0.06,
      padding: const EdgeInsets.all(AppTheme.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: AppTheme.subheading),
          const SizedBox(height: 24),
          SizedBox(height: 200, child: _buildLineChart()),
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    final dataSpots = spots.isNotEmpty
        ? spots
        : const [
            FlSpot(0, 1000),
            FlSpot(1, 2200),
            FlSpot(2, 3800),
            FlSpot(3, 5100),
            FlSpot(4, 7500),
          ];

    return LineChart(LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 2000,
        getDrawingHorizontalLine: (value) => FlLine(
          color: AppColors.frostBorder,
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: labels.isNotEmpty,
            getTitlesWidget: (value, meta) {
              final idx = value.toInt();
              if (idx < 0 || idx >= labels.length) return const SizedBox();
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(labels[idx], style: AppTheme.caption),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: dataSpots,
          isCurved: true,
          // Solar Orange chart line
          color: AppColors.solarOrange,
          barWidth: 3,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
              radius: 4,
              color: AppColors.solarOrange,
              strokeWidth: 2,
              strokeColor: AppColors.midnightInk,
            ),
          ),
          // Solar Orange gradient fill below chart line
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
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (spot) => AppColors.obsidianSurface.withValues(alpha: 0.92),
          tooltipRoundedRadius: 12,
          getTooltipItems: (touchedSpots) => touchedSpots
              .map((s) => LineTooltipItem(
                    '₺${s.y.toStringAsFixed(0)}',
                    AppTheme.bodySm.copyWith(
                      color: AppColors.solarOrange,
                      fontWeight: FontWeight.w700,
                    ),
                  ))
              .toList(),
        ),
      ),
    ));
  }
}
