import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../../models/models.dart';

class AlertCard extends StatelessWidget {
  final PulseAlert alert;
  final bool compact;
  const AlertCard({super.key, required this.alert, this.compact = false});

  Color get _color {
    switch (alert.type) {
      case AlertType.food:    return AppColors.alertFood;
      case AlertType.timing:  return AppColors.alertTiming;
      case AlertType.exit:    return AppColors.alertExit;
      case AlertType.view:    return AppColors.alertView;
      case AlertType.goal:    return AppColors.accent;
      case AlertType.group:   return AppColors.success;
    }
  }

  String get _typeLabel {
    switch (alert.type) {
      case AlertType.food:    return 'FOOD';
      case AlertType.timing:  return 'TIMING';
      case AlertType.exit:    return 'EXIT';
      case AlertType.view:    return 'VIEW';
      case AlertType.goal:    return 'GOAL';
      case AlertType.group:   return 'SQUAD';
    }
  }

  IconData get _icon {
    switch (alert.type) {
      case AlertType.food:    return Icons.restaurant_outlined;
      case AlertType.timing:  return Icons.access_time_outlined;
      case AlertType.exit:    return Icons.exit_to_app_outlined;
      case AlertType.view:    return Icons.visibility_outlined;
      case AlertType.goal:    return Icons.sports_soccer_outlined;
      case AlertType.group:   return Icons.group_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.bg700,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_icon, color: _color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(_typeLabel,
                      style: AppTypography.label.copyWith(color: _color)),
                    const Spacer(),
                    Text(alert.timeAgo,
                      style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(alert.message,
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                  maxLines: compact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
