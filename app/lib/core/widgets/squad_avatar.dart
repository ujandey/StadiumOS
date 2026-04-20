import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../../models/models.dart';

class SquadAvatar extends StatelessWidget {
  final SquadMember member;
  final double size;

  const SquadAvatar({super.key, required this.member, this.size = 40});

  Color get _statusColor {
    switch (member.status) {
      case IntentStatus.atSeat:       return AppColors.success;
      case IntentStatus.headingFood:  return AppColors.alertFood;
      case IntentStatus.bathroom:     return AppColors.accent;
      case IntentStatus.leavingEarly: return AppColors.danger;
      case IntentStatus.onRoute:      return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: size, height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: member.isMe ? AppColors.accent : AppColors.bg500,
            border: Border.all(
              color: member.isMe ? AppColors.accent : AppColors.bg400, width: 2,
            ),
          ),
          child: Center(
            child: Text(member.initials,
              style: AppTypography.caption.copyWith(
                color: member.isMe ? AppColors.bg900 : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        Positioned(
          right: 0, bottom: 0,
          child: Container(
            width: size * 0.3, height: size * 0.3,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _statusColor,
              border: Border.all(color: AppColors.bg900, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class IntentStatusLabel extends StatelessWidget {
  final IntentStatus status;
  const IntentStatusLabel({super.key, required this.status});

  String get _label {
    switch (status) {
      case IntentStatus.atSeat:       return 'At seat';
      case IntentStatus.headingFood:  return 'Heading to food';
      case IntentStatus.bathroom:     return 'Bathroom';
      case IntentStatus.leavingEarly: return 'Leaving early';
      case IntentStatus.onRoute:      return 'On route';
    }
  }

  IconData get _icon {
    switch (status) {
      case IntentStatus.atSeat:       return Icons.chair_outlined;
      case IntentStatus.headingFood:  return Icons.restaurant_outlined;
      case IntentStatus.bathroom:     return Icons.wc_outlined;
      case IntentStatus.leavingEarly: return Icons.exit_to_app_outlined;
      case IntentStatus.onRoute:      return Icons.navigation_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_icon, size: 12, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(_label, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}
