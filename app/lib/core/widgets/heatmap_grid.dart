import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../../models/models.dart';

class HeatmapGrid extends StatefulWidget {
  final List<VenueZone> zones;
  final bool showLabels;
  final int crossAxisCount;

  const HeatmapGrid({
    super.key,
    required this.zones,
    this.showLabels = false,
    this.crossAxisCount = 6,
  });

  @override
  State<HeatmapGrid> createState() => _HeatmapGridState();
}

class _HeatmapGridState extends State<HeatmapGrid> {
  String? _inspectedZoneId;

  Color _densityColor(DensityLevel d) {
    switch (d) {
      case DensityLevel.empty:    return AppColors.densityEmpty;
      case DensityLevel.low:      return AppColors.densityLow;
      case DensityLevel.moderate: return AppColors.densityModerate;
      case DensityLevel.high:     return AppColors.densityHigh;
      case DensityLevel.critical: return AppColors.densityCritical;
    }
  }

  String _densityLabel(DensityLevel d) {
    switch (d) {
      case DensityLevel.empty:    return 'Empty';
      case DensityLevel.low:      return 'Low';
      case DensityLevel.moderate: return 'Med';
      case DensityLevel.high:     return 'High';
      case DensityLevel.critical: return 'Crit';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: widget.crossAxisCount,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: widget.showLabels ? 0.85 : 1.0,
          ),
          itemCount: widget.zones.length,
          itemBuilder: (_, i) {
            final zone = widget.zones[i];
            final color = _densityColor(zone.density);
            final isInspected = _inspectedZoneId == zone.id;
            final isCritical = zone.density == DensityLevel.critical;

            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _inspectedZoneId = isInspected ? null : zone.id;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isInspected
                        ? AppColors.accent
                        : color.withValues(alpha: 0.4),
                    width: isInspected ? 1.5 : 0.5,
                  ),
                  boxShadow: isCritical ? [
                    BoxShadow(
                      color: AppColors.danger.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ] : null,
                ),
                child: Stack(
                  children: [
                    if (widget.showLabels)
                      Center(
                        child: Text(zone.id,
                          style: AppTypography.caption.copyWith(
                            color: Colors.white.withValues(alpha: 0.8), fontSize: 9,
                          ),
                        ),
                      ),
                    if (isInspected)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.bg900.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(zone.name,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.accent, fontSize: 8, fontWeight: FontWeight.w700),
                                textAlign: TextAlign.center,
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text('${zone.estimatedCount}',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textPrimary, fontSize: 10, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        if (widget.showLabels) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Text('DENSITY', style: AppTypography.label.copyWith(color: AppColors.textMuted)),
              const SizedBox(width: 12),
              ...DensityLevel.values.map((d) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                      color: _densityColor(d),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(_densityLabel(d),
                    style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontSize: 10)),
                ]),
              )),
            ],
          ),
        ],
      ],
    );
  }
}
