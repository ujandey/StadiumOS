import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/models.dart';
import '../../services/providers/user_provider.dart';
import '../../services/providers/alert_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    final alertProv = context.watch<AlertProvider>();

    return Scaffold(
      backgroundColor: AppColors.bg900,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildProfileHeader(user),
            const SizedBox(height: 24),
            _buildSection('SEAT', [
              _buildInfoRow(Icons.event_seat_outlined, user.seatInfo.display),
              _buildInfoRow(Icons.door_sliding_outlined, user.seatInfo.gateDisplay),
            ]),
            const SizedBox(height: 16),
            _buildSection('ALERTS', [
              _buildToggle('Food & concessions', user.alertsFood,
                  (v) { user.setAlertPref('food', v); alertProv.setMuted(AlertType.food, !v); },
                  AppColors.alertFood),
              _buildToggle('Timing windows', user.alertsTiming,
                  (v) { user.setAlertPref('timing', v); alertProv.setMuted(AlertType.timing, !v); },
                  AppColors.alertTiming),
              _buildToggle('Exit routing', user.alertsExit,
                  (v) { user.setAlertPref('exit', v); alertProv.setMuted(AlertType.exit, !v); },
                  AppColors.alertExit),
              _buildToggle('View advisories', user.alertsView,
                  (v) { user.setAlertPref('view', v); alertProv.setMuted(AlertType.view, !v); },
                  AppColors.alertView),
            ]),
            const SizedBox(height: 16),
            _buildSection('ACCESSIBILITY', [
              _buildToggle('Accessible routes only', user.accessibilityMode,
                  (v) => user.setAccessibilityMode(v), AppColors.accent),
              _buildInfoRow(Icons.elevator_outlined, 'Elevators, ramps, wide concourses'),
            ]),
            const SizedBox(height: 16),
            _buildSection('EVENT HISTORY', [
              _buildEventStat('Alerts received', '${alertProv.totalReceived}'),
              _buildEventStat('Alerts dismissed',
                  '${alertProv.allAlerts.where((a) => a.isDismissed).length}'),
              _buildEventStat('Categories muted', '${alertProv.mutedCategories.length}'),
            ]),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.privacy_tip_outlined, size: 16),
              label: const Text('Privacy & data'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.bg400),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserProvider user) {
    return Row(children: [
      Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.accentAlpha(0.15),
          border: Border.all(color: AppColors.accentAlpha(0.4), width: 2),
        ),
        child: const Icon(Icons.person_outline, color: AppColors.accent, size: 28),
      ),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Anonymous Fan',
            style: AppTypography.headingSmall.copyWith(color: AppColors.textPrimary)),
        Text('Attending: Man Utd vs Arsenal',
            style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text('IN VENUE',
              style: AppTypography.label.copyWith(color: AppColors.success, fontSize: 9)),
        ),
      ])),
    ]);
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title,
            style: AppTypography.label.copyWith(color: AppColors.textMuted, letterSpacing: 1.2)),
      ),
      Container(
        decoration: BoxDecoration(
          color: AppColors.bg700,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.bg400),
        ),
        child: Column(children: List.generate(children.length, (i) => Column(children: [
          children[i],
          if (i < children.length - 1)
            const Divider(height: 1, color: AppColors.bg400, indent: 16, endIndent: 16),
        ]))),
      ),
    ]);
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Text(text, style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary)),
      ]),
    );
  }

  Widget _buildToggle(String label, bool value, ValueChanged<bool> onChanged, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 12),
        Expanded(child: Text(label,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary))),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.accent,
          activeTrackColor: AppColors.accentAlpha(0.3),
          inactiveTrackColor: AppColors.bg500,
          inactiveThumbColor: AppColors.textMuted,
        ),
      ]),
    );
  }

  Widget _buildEventStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Expanded(child: Text(label,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary))),
        Text(value,
            style: AppTypography.headingSmall.copyWith(color: AppColors.textPrimary)),
      ]),
    );
  }
}
