import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:onyxfi_frontend/core/constants/colors.dart';
import 'package:onyxfi_frontend/core/theme/app_theme.dart';
import 'package:onyxfi_frontend/widgets/glass_container.dart';

/// GenUI Catalog — Dynamic line chart for financial projections (Midnight Ledger).
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

  factory FinancialProjectionChart.fromJson(Map<String, dynamic> json) {
    final points = json['points'] as List<dynamic>? ?? [];
    // Also support the "series" format from Gemini
    List<FlSpot> parsedSpots = [];
    if (points.isNotEmpty) {
      parsedSpots = points.map((p) {
        final m = p as Map<String, dynamic>;
        return FlSpot((m['x'] as num?)?.toDouble() ?? 0, (m['y'] as num?)?.toDouble() ?? 0);
      }).toList();
    } else {
      // Try the series format: {"series": [{"name": "...", "values": [...]}], "x_axis": [...]}
      final series = json['series'] as List<dynamic>?;
      if (series != null && series.isNotEmpty) {
        final values = (series[0] as Map<String, dynamic>)['values'] as List<dynamic>? ?? [];
        parsedSpots = List.generate(values.length, (i) => FlSpot(i.toDouble(), (values[i] as num).toDouble()));
      }
    }
    // Parse labels from either "labels" or "x_axis"
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text(title, style: AppTheme.subheading),
        const SizedBox(height: 24),
        SizedBox(height: 200, child: _buildLineChart()),
      ]),
    );
  }

  Widget _buildLineChart() {
    final dataSpots = spots.isNotEmpty ? spots : const [FlSpot(0, 1000), FlSpot(1, 2200), FlSpot(2, 3800), FlSpot(3, 5100), FlSpot(4, 7500)];

    return LineChart(LineChartData(
      gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 2000,
        getDrawingHorizontalLine: (value) => FlLine(color: AppColors.snowWhite.withValues(alpha: 0.05), strokeWidth: 1)),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: labels.isNotEmpty,
          getTitlesWidget: (value, meta) {
            final idx = value.toInt();
            if (idx < 0 || idx >= labels.length) return const SizedBox();
            return Padding(padding: const EdgeInsets.only(top: 8), child: Text(labels[idx], style: AppTheme.caption));
          })),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [LineChartBarData(
        spots: dataSpots, isCurved: true, color: AppColors.electricBlue, barWidth: 3,
        dotData: FlDotData(show: true, getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(radius: 4, color: AppColors.electricBlue, strokeWidth: 2, strokeColor: AppColors.midnightInk)),
        belowBarData: BarAreaData(show: true, gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.electricBlue.withValues(alpha: 0.25), AppColors.electricBlue.withValues(alpha: 0.0)])),
      )],
      lineTouchData: LineTouchData(touchTooltipData: LineTouchTooltipData(
        getTooltipColor: (spot) => AppColors.obsidianSurface.withValues(alpha: 0.9),
        tooltipRoundedRadius: 12,
        getTooltipItems: (touchedSpots) => touchedSpots.map((s) => LineTooltipItem('₺${s.y.toStringAsFixed(0)}', AppTheme.bodySm.copyWith(color: AppColors.electricBlue, fontWeight: FontWeight.w700))).toList(),
      )),
    ));
  }
}
