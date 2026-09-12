import 'package:flutter/material.dart';

import '../../l10n/generated/hospital_localizations.dart';
import '../../models/codes.dart';
import '../../models/observation.dart';
import '../formatters.dart';
import '../theme.dart';

/// A single vital sign plotted over time.
///
/// One measurement per chart, always. Overlaying a heart rate on a temperature
/// would need two y-scales, and a two-scale chart lets you prove any
/// correlation you like by sliding one axis - so several vitals are shown as
/// several charts stacked, never as one chart with two axes.
///
/// The title names the measurement, so a single-series line needs no legend.
/// Readings outside the physiological range are ringed and labelled rather than
/// only recoloured, because colour alone is not an accessible way to say
/// "this one is abnormal".
class VitalTrendChart extends StatefulWidget {
  const VitalTrendChart({
    super.key,
    required this.type,
    required this.observations,
    this.height = 180,
    this.showNormalBand = true,
  });

  final VitalSignType type;

  /// Most recent first, as the repository returns them.
  final List<Observation> observations;

  final double height;

  /// Shades the physiologically normal range behind the line.
  final bool showNormalBand;

  @override
  State<VitalTrendChart> createState() => _VitalTrendChartState();
}

class _VitalTrendChartState extends State<VitalTrendChart> {
  /// Index into the chronological series that the pointer is nearest to.
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = HospitalLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;

    // The repository hands back newest-first; a time axis reads oldest-first.
    final series = widget.observations.reversed.toList(growable: false);

    if (series.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: Text(
            l10n.vitalsNone,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final latest = series.last;
    final abnormalCount = series.where((o) => o.isAbnormal).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                widget.type.display.forLanguage(language),
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              latest.formatted,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                // The value stays in ink; the mark beside it carries the state.
                color: theme.colorScheme.onSurface,
              ),
              maxLines: 1,
            ),
            if (latest.isAbnormal) ...<Widget>[
              Gap.w8,
              Icon(
                Icons.warning_amber_rounded,
                size: 16,
                color: HospitalTheme.criticalOf(context),
              ),
            ],
          ],
        ),
        Text(
          l10n.vitalsNormalRange(
            Formats.number(widget.type.normalLow, widget.type.decimals),
            Formats.number(widget.type.normalHigh, widget.type.decimals),
            widget.type.unit,
          ),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Gap.h8,
        SizedBox(
          height: widget.height,
          child: LayoutBuilder(
            builder: (context, constraints) => MouseRegion(
              onHover: (event) => _updateHover(event.localPosition, constraints, series),
              onExit: (_) => setState(() => _hoveredIndex = null),
              child: GestureDetector(
                onTapDown: (details) =>
                    _updateHover(details.localPosition, constraints, series),
                onHorizontalDragUpdate: (details) =>
                    _updateHover(details.localPosition, constraints, series),
                onHorizontalDragEnd: (_) => setState(() => _hoveredIndex = null),
                child: CustomPaint(
                  size: Size(constraints.maxWidth, widget.height),
                  painter: _VitalChartPainter(
                    type: widget.type,
                    series: series,
                    hoveredIndex: _hoveredIndex,
                    showNormalBand: widget.showNormalBand,
                    lineColor: HospitalTheme.seriesOf(context),
                    abnormalColor: HospitalTheme.criticalOf(context),
                    gridColor: theme.colorScheme.outlineVariant,
                    bandColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                    surfaceColor: theme.colorScheme.surface,
                    labelStyle: theme.textTheme.labelSmall!.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Gap.h8,
        Row(
          children: <Widget>[
            Flexible(
              child: Text(
                abnormalCount == 0
                    ? l10n.vitalsObservationCount(series.length)
                    : '${l10n.vitalsObservationCount(series.length)} · '
                        '$abnormalCount ${l10n.vitalsAbnormal.toLowerCase()}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: abnormalCount == 0
                      ? theme.colorScheme.onSurfaceVariant
                      : HospitalTheme.criticalOf(context),
                  fontWeight:
                      abnormalCount == 0 ? null : FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_hoveredIndex != null) ...<Widget>[
              Gap.w8,
              Flexible(
                child: Text(
                  '${series[_hoveredIndex!].formatted} · '
                  '${Formats.smart(context, series[_hoveredIndex!].effectiveDateTime)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  void _updateHover(
    Offset position,
    BoxConstraints constraints,
    List<Observation> series,
  ) {
    if (series.isEmpty) return;
    const leftPadding = _VitalChartPainter.leftPadding;
    const rightPadding = _VitalChartPainter.rightPadding;
    final plotWidth = constraints.maxWidth - leftPadding - rightPadding;
    if (plotWidth <= 0) return;
    final ratio = ((position.dx - leftPadding) / plotWidth).clamp(0.0, 1.0);
    final index = (ratio * (series.length - 1)).round();
    if (index != _hoveredIndex) setState(() => _hoveredIndex = index);
  }
}

class _VitalChartPainter extends CustomPainter {
  const _VitalChartPainter({
    required this.type,
    required this.series,
    required this.hoveredIndex,
    required this.showNormalBand,
    required this.lineColor,
    required this.abnormalColor,
    required this.gridColor,
    required this.bandColor,
    required this.surfaceColor,
    required this.labelStyle,
  });

  static const double leftPadding = 40;
  static const double rightPadding = 8;
  static const double topPadding = 8;
  static const double bottomPadding = 20;

  final VitalSignType type;
  final List<Observation> series;
  final int? hoveredIndex;
  final bool showNormalBand;
  final Color lineColor;
  final Color abnormalColor;
  final Color gridColor;
  final Color bandColor;
  final Color surfaceColor;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final plotRect = Rect.fromLTRB(
      leftPadding,
      topPadding,
      size.width - rightPadding,
      size.height - bottomPadding,
    );
    if (plotRect.width <= 0 || plotRect.height <= 0) return;

    // Scale to the data, widened to include the normal band so "inside range"
    // is visually obvious, then padded so the line never touches the frame.
    var minValue = series.first.value;
    var maxValue = series.first.value;
    for (final observation in series) {
      minValue = observation.value < minValue ? observation.value : minValue;
      maxValue = observation.value > maxValue ? observation.value : maxValue;
    }
    if (showNormalBand) {
      minValue = minValue < type.normalLow ? minValue : type.normalLow;
      maxValue = maxValue > type.normalHigh ? maxValue : type.normalHigh;
    }
    final span = (maxValue - minValue).abs() < 0.0001 ? 1.0 : maxValue - minValue;
    final low = minValue - span * 0.12;
    final high = maxValue + span * 0.12;

    double yFor(double value) =>
        plotRect.bottom - ((value - low) / (high - low)) * plotRect.height;

    double xFor(int index) => series.length == 1
        ? plotRect.center.dx
        : plotRect.left + (index / (series.length - 1)) * plotRect.width;

    // ---- Normal range band, behind everything ----
    if (showNormalBand) {
      final bandTop = yFor(type.normalHigh).clamp(plotRect.top, plotRect.bottom);
      final bandBottom =
          yFor(type.normalLow).clamp(plotRect.top, plotRect.bottom);
      canvas.drawRect(
        Rect.fromLTRB(plotRect.left, bandTop, plotRect.right, bandBottom),
        Paint()..color = bandColor,
      );
    }

    // ---- Recessive grid: three horizontal rules, no vertical clutter ----
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i <= 2; i++) {
      final value = low + (high - low) * (i / 2);
      final y = yFor(value);
      canvas.drawLine(Offset(plotRect.left, y), Offset(plotRect.right, y), gridPaint);
      _paintText(
        canvas,
        value.toStringAsFixed(type.decimals),
        Offset(leftPadding - 6, y),
        align: _TextAlign.right,
      );
    }

    // ---- The series line: 2px, no fill ----
    final path = Path();
    for (var i = 0; i < series.length; i++) {
      final point = Offset(xFor(i), yFor(series[i].value));
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    // ---- Markers ----
    // Only abnormal readings and the endpoints get a dot: a marker on every
    // one of two hundred points is noise, not information.
    for (var i = 0; i < series.length; i++) {
      final observation = series[i];
      final isEndpoint = i == series.length - 1;
      if (!observation.isAbnormal && !isEndpoint) continue;
      final centre = Offset(xFor(i), yFor(observation.value));
      final color = observation.isAbnormal ? abnormalColor : lineColor;
      // A surface ring keeps the marker readable where the line runs under it.
      canvas.drawCircle(centre, 5.5, Paint()..color = surfaceColor);
      canvas.drawCircle(centre, 4, Paint()..color = color);
      if (observation.isAbnormal) {
        canvas.drawCircle(
          centre,
          6.5,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }

    // ---- Crosshair for the hovered reading ----
    final index = hoveredIndex;
    if (index != null && index >= 0 && index < series.length) {
      final x = xFor(index);
      canvas.drawLine(
        Offset(x, plotRect.top),
        Offset(x, plotRect.bottom),
        Paint()
          ..color = lineColor.withValues(alpha: 0.45)
          ..strokeWidth = 1,
      );
      final centre = Offset(x, yFor(series[index].value));
      canvas.drawCircle(centre, 7, Paint()..color = surfaceColor);
      canvas.drawCircle(
        centre,
        5,
        Paint()
          ..color = series[index].isAbnormal ? abnormalColor : lineColor,
      );
    }

    // ---- Time axis: first and last only, which is all a trend needs ----
    _paintText(
      canvas,
      _shortTime(series.first.effectiveDateTime),
      Offset(plotRect.left, size.height - bottomPadding + 4),
      align: _TextAlign.left,
    );
    _paintText(
      canvas,
      _shortTime(series.last.effectiveDateTime),
      Offset(plotRect.right, size.height - bottomPadding + 4),
      align: _TextAlign.right,
    );
  }

  String _shortTime(DateTime value) {
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute';
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset anchor, {
    required _TextAlign align,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = switch (align) {
      _TextAlign.left => anchor.dx,
      _TextAlign.right => anchor.dx - painter.width,
    };
    painter.paint(canvas, Offset(dx, anchor.dy - painter.height / 2));
  }

  @override
  bool shouldRepaint(_VitalChartPainter oldDelegate) =>
      oldDelegate.series != series ||
      oldDelegate.hoveredIndex != hoveredIndex ||
      oldDelegate.lineColor != lineColor;
}

enum _TextAlign { left, right }

/// A compact "latest value + recent shape" tile for dashboards and the top of
/// the patient file. The sparkline carries the trend; the number carries the
/// reading; the icon and label carry the abnormal state.
class VitalTile extends StatelessWidget {
  const VitalTile({
    super.key,
    required this.type,
    required this.latest,
    this.history = const <Observation>[],
    this.onTap,
  });

  final VitalSignType type;
  final Observation? latest;

  /// Recent readings, newest first. Optional - the tile works without them.
  final List<Observation> history;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = HospitalLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final reading = latest;
    final isAbnormal = reading?.isAbnormal ?? false;
    final statusColor = isAbnormal
        ? HospitalTheme.criticalOf(context)
        : theme.colorScheme.onSurfaceVariant;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(Gap.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      type.display.forLanguage(language),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isAbnormal)
                    Icon(Icons.warning_amber_rounded, size: 16, color: statusColor),
                ],
              ),
              Gap.h8,
              if (reading == null)
                Text(
                  '—',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: <Widget>[
                    Text(
                      reading.value.toStringAsFixed(type.decimals),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      type.unit,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              if (history.length > 1) ...<Widget>[
                Gap.h8,
                SizedBox(
                  height: 28,
                  child: CustomPaint(
                    size: const Size(double.infinity, 28),
                    painter: _SparklinePainter(
                      values: history.reversed
                          .map((o) => o.value)
                          .toList(growable: false),
                      color: HospitalTheme.seriesOf(context),
                    ),
                  ),
                ),
              ],
              if (reading != null) ...<Widget>[
                Gap.h4,
                Text(
                  isAbnormal
                      ? '${l10n.vitalsAbnormal} · ${Formats.ago(context, reading.effectiveDateTime)}'
                      : Formats.ago(context, reading.effectiveDateTime),
                  style: theme.textTheme.labelSmall?.copyWith(color: statusColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({required this.values, required this.color});

  /// Oldest first.
  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    var minValue = values.first;
    var maxValue = values.first;
    for (final value in values) {
      minValue = value < minValue ? value : minValue;
      maxValue = value > maxValue ? value : maxValue;
    }
    final span = (maxValue - minValue).abs() < 0.0001 ? 1.0 : maxValue - minValue;

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      final y = size.height - ((values[i] - minValue) / span) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
    // Anchor the eye at the most recent value.
    final lastX = size.width;
    final lastY =
        size.height - ((values.last - minValue) / span) * size.height;
    canvas.drawCircle(Offset(lastX - 2, lastY), 2.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SparklinePainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}
