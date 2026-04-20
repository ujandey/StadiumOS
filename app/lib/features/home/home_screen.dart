import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/os_badge.dart';
import '../../core/widgets/alert_card.dart';
import '../../core/widgets/heatmap_grid.dart';
import '../../core/widgets/animated_count.dart';
import '../../models/models.dart';
import '../../services/providers/game_provider.dart';
import '../../services/providers/density_provider.dart';
import '../../services/providers/alert_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>().state;
    final density = context.watch<DensityProvider>();
    final alertProv = context.watch<AlertProvider>();
    final topAlert = alertProv.alerts.isNotEmpty ? alertProv.alerts.first : null;
    final zones = density.zones.take(12).toList();

    return Scaffold(
      backgroundColor: AppColors.bg900,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildScoreCard(game)),
            if (topAlert != null) SliverToBoxAdapter(child: _buildAlertBanner(topAlert)),
            SliverToBoxAdapter(child: _buildTimingWindow(density, game)),
            SliverToBoxAdapter(child: _buildMiniHeatmap(zones, context)),
            SliverToBoxAdapter(child: _buildQuickActions(context)),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard(GameState game) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bg700,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.bg400),
      ),
      child: Column(children: [
        LiveBadge(clock: game.clock),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Expanded(
            child: Text(game.homeTeam,
                style: AppTypography.headingSmall.copyWith(color: AppColors.textPrimary),
                textAlign: TextAlign.center),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              AnimatedScore(
                score: game.homeScore,
                style: AppTypography.score.copyWith(color: AppColors.textPrimary),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('–', style: AppTypography.score.copyWith(color: AppColors.textMuted)),
              ),
              AnimatedScore(
                score: game.awayScore,
                style: AppTypography.score.copyWith(color: AppColors.textPrimary),
              ),
            ]),
          ),
          Expanded(
            child: Text(game.awayTeam,
                style: AppTypography.headingSmall.copyWith(color: AppColors.textPrimary),
                textAlign: TextAlign.center),
          ),
        ]),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('Section 114 · Gate A · Row C',
              style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
        ]),
      ]),
    );
  }

  Widget _buildAlertBanner(PulseAlert alert) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: AlertCard(alert: alert),
    );
  }

  Widget _buildTimingWindow(DensityProvider density, GameState game) {
    final window = density.bestTimingWindow;
    final targetMin = density.bestTimingMinute;
    final minutesAway = targetMin - game.clockMinute;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bg700,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentAlpha(0.2)),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accentAlpha(0.1),
          ),
          child: const Icon(Icons.access_time_outlined, color: AppColors.accent, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Best bathroom window',
              style: AppTypography.label.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(minutesAway > 0 ? '${targetMin}th min — $minutesAway min away' : window,
              style: AppTypography.headingSmall.copyWith(color: AppColors.textPrimary)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.accentAlpha(0.1),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: AppColors.accentAlpha(0.3)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text('Go', style: AppTypography.label.copyWith(color: AppColors.accent)),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward, size: 12, color: AppColors.accent),
          ]),
        ),
      ]),
    );
  }

  Widget _buildMiniHeatmap(List<VenueZone> zones, BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bg700,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.bg400),
      ),
      child: Column(children: [
        Row(children: [
          Text('CROWD DENSITY',
              style: AppTypography.label.copyWith(color: AppColors.textSecondary)),
          const Spacer(),
          InkWell(
            onTap: () {},
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text('Full map',
                  style: AppTypography.caption.copyWith(color: AppColors.accent)),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward, size: 12, color: AppColors.accent),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        HeatmapGrid(zones: zones, showLabels: false, crossAxisCount: 6),
      ]),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickAction(icon: Icons.navigation_outlined, label: 'ROUTE', color: AppColors.accent),
      _QuickAction(icon: Icons.group_outlined, label: 'SQUAD', color: AppColors.success),
      _QuickAction(icon: Icons.exit_to_app_outlined, label: 'EXIT', color: AppColors.danger),
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(children: actions.map((a) => Expanded(
        child: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: _QuickActionButton(action: a),
        ),
      )).toList()),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  const _QuickAction({required this.icon, required this.label, required this.color});
}

class _QuickActionButton extends StatelessWidget {
  final _QuickAction action;
  const _QuickActionButton({required this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: action.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: action.color.withValues(alpha: 0.25)),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(action.icon, color: action.color, size: 22),
        const SizedBox(height: 4),
        Text(action.label,
            style: AppTypography.label.copyWith(color: action.color, fontSize: 10)),
      ]),
    );
  }
}
