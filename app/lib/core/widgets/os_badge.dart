import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class LiveBadge extends StatefulWidget {
  final String clock;
  const LiveBadge({super.key, required this.clock});
  @override State<LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<LiveBadge> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
    _fade = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeTransition(
          opacity: _fade,
          child: Container(
            width: 6, height: 6,
            decoration: const BoxDecoration(
              color: AppColors.danger, shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text('LIVE', style: AppTypography.label.copyWith(color: AppColors.danger)),
        const SizedBox(width: 8),
        Text(widget.clock, style: AppTypography.label.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}

class DensityPill extends StatelessWidget {
  final String label;
  final Color color;
  const DensityPill({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label, style: AppTypography.label.copyWith(color: color)),
    );
  }
}

class StatusPill extends StatelessWidget {
  final String label;
  const StatusPill({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.bg500,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.bg400),
      ),
      child: Text(label, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
    );
  }
}
