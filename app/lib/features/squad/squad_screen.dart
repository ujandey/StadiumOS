import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/squad_avatar.dart';
import '../../core/widgets/heatmap_grid.dart';
import '../../models/models.dart';
import '../../services/providers/squad_provider.dart';
import '../../services/providers/density_provider.dart';

class SquadScreen extends StatefulWidget {
  const SquadScreen({super.key});
  @override State<SquadScreen> createState() => _SquadScreenState();
}

class _SquadScreenState extends State<SquadScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final squad = context.watch<SquadProvider>();
    final proposal = squad.activeProposal;
    final showProposal = proposal != null && !proposal.isResolved;

    return Scaffold(
      backgroundColor: AppColors.bg900,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(squad),
          _buildTabBar(),
          _buildStatusSelector(squad),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [_buildMapTab(squad), _buildListTab(squad)],
            ),
          ),
          if (showProposal) _buildProposalCard(squad, proposal),
        ]),
      ),
    );
  }

  Widget _buildHeader(SquadProvider squad) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Your Squad',
              style: AppTypography.headingMedium.copyWith(color: AppColors.textPrimary)),
          Text('${squad.members.length} MEMBERS',
              style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.accentAlpha(0.1),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: AppColors.accentAlpha(0.3)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.link_outlined, size: 14, color: AppColors.accent),
            const SizedBox(width: 4),
            Text(squad.joinCode, style: AppTypography.label.copyWith(color: AppColors.accent)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        decoration: BoxDecoration(color: AppColors.bg700, borderRadius: BorderRadius.circular(12)),
        child: TabBar(
          controller: _tabCtrl,
          indicator: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(10)),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: AppColors.bg900,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: AppTypography.label,
          tabs: const [Tab(text: 'LIVE MAP'), Tab(text: 'LIST')],
        ),
      ),
    );
  }

  Widget _buildStatusSelector(SquadProvider squad) {
    final myStatus = squad.me?.status ?? IntentStatus.atSeat;
    final statuses = [
      (IntentStatus.atSeat, 'At Seat', Icons.chair_outlined),
      (IntentStatus.headingFood, 'Food', Icons.restaurant_outlined),
      (IntentStatus.bathroom, 'WC', Icons.wc_outlined),
      (IntentStatus.leavingEarly, 'Leaving', Icons.exit_to_app_outlined),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(children: [
        Text('STATUS ', style: AppTypography.label.copyWith(color: AppColors.textMuted, fontSize: 9)),
        ...statuses.map((s) {
          final isActive = myStatus == s.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                squad.setMyStatus(s.$1);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.accent.withValues(alpha: 0.15) : AppColors.bg700,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: isActive ? AppColors.accent : AppColors.bg400),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(s.$3, size: 11, color: isActive ? AppColors.accent : AppColors.textMuted),
                  const SizedBox(width: 3),
                  Text(s.$2, style: AppTypography.label.copyWith(
                    color: isActive ? AppColors.accent : AppColors.textMuted, fontSize: 9)),
                ]),
              ),
            ),
          );
        }),
      ]),
    );
  }

  Widget _buildMapTab(SquadProvider squad) {
    final density = context.watch<DensityProvider>();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.bg700,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.bg400),
            ),
            child: Stack(children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: HeatmapGrid(zones: density.zones.take(12).toList(), showLabels: true, crossAxisCount: 4),
              ),
              ..._buildMemberDots(squad),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: squad.members.map((m) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: SquadAvatar(member: m, size: 36),
          )).toList(),
        ),
      ]),
    );
  }

  List<Widget> _buildMemberDots(SquadProvider squad) {
    final positions = [const Offset(0.3, 0.5), const Offset(0.35, 0.55), const Offset(0.7, 0.3), const Offset(0.5, 0.7)];
    return List.generate(squad.members.length.clamp(0, 4), (i) {
      final m = squad.members[i];
      final pos = positions[i];
      return AnimatedPositioned(
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
        left: MediaQuery.of(context).size.width * pos.dx - 20,
        top: 200 * pos.dy,
        child: Column(children: [
          SquadAvatar(member: m, size: 28),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: AppColors.bg900.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(6)),
            child: Text(m.name, style: AppTypography.caption.copyWith(fontSize: 9, color: AppColors.textSecondary)),
          ),
        ]),
      );
    });
  }

  Widget _buildListTab(SquadProvider squad) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: squad.members.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final member = squad.members[i];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bg700,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: member.isMe ? AppColors.accentAlpha(0.3) : AppColors.bg400),
          ),
          child: Row(children: [
            SquadAvatar(member: member, size: 44),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(member.name, style: AppTypography.headingSmall.copyWith(color: AppColors.textPrimary)),
                if (member.isMe) Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.accentAlpha(0.1), borderRadius: BorderRadius.circular(4)),
                    child: Text('YOU', style: AppTypography.label.copyWith(color: AppColors.accent, fontSize: 9)),
                  ),
                ),
              ]),
              const SizedBox(height: 4),
              IntentStatusLabel(status: member.status),
              const SizedBox(height: 2),
              Text(member.location, style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
            ])),
            if (!member.isMe) Icon(Icons.navigation_outlined, color: AppColors.textMuted, size: 18),
          ]),
        );
      },
    );
  }

  Widget _buildProposalCard(SquadProvider squad, SquadProposal proposal) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bg700,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accentAlpha(0.3)),
      ),
      child: Column(children: [
        Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.bg500),
            child: Center(child: Text(proposal.proposer[0], style: AppTypography.label.copyWith(color: AppColors.textSecondary))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${proposal.proposer} suggests:', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
            Text('Meet at ${proposal.destination}', style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary)),
          ])),
          GestureDetector(
            onTap: () => squad.dismissProposal(),
            child: Icon(Icons.close, size: 18, color: AppColors.textMuted),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: Text('${proposal.agreeCount}/${proposal.totalCount} agree',
              style: AppTypography.caption.copyWith(color: AppColors.textSecondary))),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              squad.voteOnProposal(true);
            },
            style: ElevatedButton.styleFrom(minimumSize: const Size(80, 36), padding: const EdgeInsets.symmetric(horizontal: 20)),
            child: const Text('AGREE'),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              squad.voteOnProposal(false);
              squad.dismissProposal();
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(72, 36),
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.bg400),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text('SKIP'),
          ),
        ]),
      ]),
    );
  }
}
