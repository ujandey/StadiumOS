import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/os_badge.dart';
import '../../core/widgets/alert_card.dart';
import '../../models/models.dart';
import '../../services/providers/game_provider.dart';
import '../../services/providers/alert_provider.dart';
import '../../services/providers/user_provider.dart';

class PulseScreen extends StatelessWidget {
  const PulseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>().state;
    final alertProv = context.watch<AlertProvider>();
    final alerts = alertProv.alerts;

    return Scaffold(
      backgroundColor: AppColors.bg900,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(game, alertProv),
          _buildMuteFilter(context, alertProv),
          Expanded(child: _buildAlertList(context, alerts, alertProv)),
          _buildFooter(),
        ]),
      ),
    );
  }

  Widget _buildHeader(GameState game, AlertProvider alertProv) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Your Pulse',
                style: AppTypography.headingMedium.copyWith(color: AppColors.textPrimary)),
            Text('${alertProv.unreadCount} ALERTS',
                style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
          ]),
        ),
        LiveBadge(clock: game.clock),
      ]),
    );
  }

  Widget _buildMuteFilter(BuildContext context, AlertProvider alertProv) {
    final types = [
      _TypeFilter(type: AlertType.food, label: 'FOOD', color: AppColors.alertFood),
      _TypeFilter(type: AlertType.timing, label: 'TIMING', color: AppColors.alertTiming),
      _TypeFilter(type: AlertType.exit, label: 'EXIT', color: AppColors.alertExit),
      _TypeFilter(type: AlertType.view, label: 'VIEW', color: AppColors.alertView),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(children: types.map((t) {
        final isMuted = alertProv.isMuted(t.type);
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              alertProv.toggleMute(t.type);
              // Sync to user prefs
              final userProv = context.read<UserProvider>();
              userProv.setAlertPref(t.type.name, !isMuted ? false : true);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isMuted ? AppColors.bg500 : t.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: isMuted ? AppColors.bg400 : t.color.withValues(alpha: 0.4)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (isMuted) Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(Icons.volume_off_outlined, size: 10, color: AppColors.textMuted),
                ),
                Text(t.label,
                    style: AppTypography.label.copyWith(
                        color: isMuted ? AppColors.textMuted : t.color, fontSize: 10)),
              ]),
            ),
          ),
        );
      }).toList()),
    );
  }

  Widget _buildAlertList(BuildContext context, List<PulseAlert> alerts, AlertProvider alertProv) {
    if (alerts.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.notifications_off_outlined, size: 48, color: AppColors.textMuted),
        const SizedBox(height: 12),
        Text('No alerts right now',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted)),
        const SizedBox(height: 4),
        Text('New alerts will appear here',
            style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
      ]));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      itemCount: alerts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final alert = alerts[i];
        return Dismissible(
          key: ValueKey(alert.id),
          direction: DismissDirection.endToStart,
          onDismissed: (_) {
            HapticFeedback.mediumImpact();
            alertProv.dismiss(alert.id);
          },
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.delete_outline, color: AppColors.danger, size: 22),
          ),
          child: AlertCard(alert: alert),
        );
      },
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text('Swipe left to dismiss · Tap filter to mute',
          style: AppTypography.caption.copyWith(color: AppColors.textMuted),
          textAlign: TextAlign.center),
    );
  }
}

class _TypeFilter {
  final AlertType type;
  final String label;
  final Color color;
  const _TypeFilter({required this.type, required this.label, required this.color});
}
