import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/os_badge.dart';
import '../../core/widgets/heatmap_grid.dart';
import '../../services/providers/game_provider.dart';
import '../../services/providers/density_provider.dart';
import '../../services/providers/squad_provider.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  _LayerMode _activeLayer = _LayerMode.density;
  bool _showRoute = false;
  bool _showBottomSheet = false;

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>().state;
    final density = context.watch<DensityProvider>();

    return Scaffold(
      backgroundColor: AppColors.bg900,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(game),
          _buildLayerToggles(),
          Expanded(child: _buildMapArea(density)),
          if (_showBottomSheet) _buildETASheet(density),
        ]),
      ),
    );
  }

  Widget _buildHeader(game) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(children: [
        Expanded(
          child: Text('Venue Map',
              style: AppTypography.headingMedium.copyWith(color: AppColors.textPrimary)),
        ),
        LiveBadge(clock: game.clock),
      ]),
    );
  }

  Widget _buildLayerToggles() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: _LayerMode.values.map((mode) {
        final isActive = _activeLayer == mode;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => setState(() => _activeLayer = mode),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? AppColors.accent : AppColors.bg700,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: isActive ? AppColors.accent : AppColors.bg400),
              ),
              child: Text(mode.label,
                  style: AppTypography.label.copyWith(
                    color: isActive ? AppColors.bg900 : AppColors.textSecondary,
                  )),
            ),
          ),
        );
      }).toList()),
    );
  }

  Widget _buildMapArea(DensityProvider density) {
    return GestureDetector(
      onTap: () => setState(() => _showBottomSheet = !_showBottomSheet),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bg700,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.bg400),
          ),
          child: Stack(children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildStadiumMap(density),
              ),
            ),
            if (_showRoute) _buildActiveRoute(),
            if (_activeLayer == _LayerMode.squad) ..._buildSquadDots(),
            Positioned(bottom: 12, right: 12, child: _buildFAB()),
          ]),
        ),
      ),
    );
  }

  Widget _buildStadiumMap(DensityProvider density) {
    return Column(children: [
      Text('LIVE', style: AppTypography.label.copyWith(color: AppColors.success)),
      const SizedBox(height: 12),
      Expanded(
        child: Stack(children: [
          HeatmapGrid(zones: density.zones, showLabels: true, crossAxisCount: 4),
          Positioned(left: 60, top: 80, child: _PulsingDot()),
        ]),
      ),
      const SizedBox(height: 12),
      _buildDensityLegend(),
    ]);
  }

  Widget _buildDensityLegend() {
    return Row(children: [
      Text('DENSITY:', style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
      const SizedBox(width: 8),
      ...['LOW', 'MED', 'HIGH'].map((l) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 10, height: 10,
            decoration: BoxDecoration(
              color: l == 'LOW' ? AppColors.densityLow : l == 'MED' ? AppColors.densityModerate : AppColors.densityHigh,
              borderRadius: BorderRadius.circular(2),
            )),
          const SizedBox(width: 4),
          Text(l, style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontSize: 10)),
        ]),
      )),
    ]);
  }

  List<Widget> _buildSquadDots() {
    final squad = context.watch<SquadProvider>();
    final positions = [const Offset(0.3, 0.5), const Offset(0.35, 0.55), const Offset(0.7, 0.3), const Offset(0.5, 0.7)];
    return List.generate(squad.members.length.clamp(0, 4), (i) {
      final m = squad.members[i];
      final pos = positions[i];
      return Positioned(
        left: MediaQuery.of(context).size.width * pos.dx - 20,
        top: 200 * pos.dy,
        child: Column(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: m.isMe ? AppColors.accent : AppColors.bg500,
              border: Border.all(color: m.isMe ? AppColors.accent : AppColors.bg400, width: 2),
            ),
            child: Center(child: Text(m.initials, style: AppTypography.caption.copyWith(color: m.isMe ? AppColors.bg900 : AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 10))),
          ),
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

  Widget _buildActiveRoute() {
    return Positioned(
      left: 0, right: 0, top: 0, bottom: 0,
      child: CustomPaint(painter: _RoutePainter()),
    );
  }

  Widget _buildFAB() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showRoute = !_showRoute;
          if (_showRoute) _showBottomSheet = true;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(_showRoute ? Icons.close : Icons.navigation_outlined, color: AppColors.bg900, size: 16),
          const SizedBox(width: 6),
          Text(_showRoute ? 'Clear' : 'Route', style: AppTypography.label.copyWith(color: AppColors.bg900)),
        ]),
      ),
    );
  }

  Widget _buildETASheet(DensityProvider density) {
    final walkMin = density.estimateWalkMinutes('2', 'B').toStringAsFixed(0);
    final coldest = density.coldZones.isNotEmpty ? density.coldZones.first.name : 'Gate B';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bg700,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accentAlpha(0.3)),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$walkMin min walk', style: AppTypography.headingSmall.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text('Via $coldest — lowest congestion',
              style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
        ])),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(72, 44),
            padding: const EdgeInsets.symmetric(horizontal: 20),
          ),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [Text('GO'), SizedBox(width: 4), Icon(Icons.arrow_forward, size: 14)]),
        ),
      ]),
    );
  }
}

enum _LayerMode { density, route, squad }

extension _LayerModeLabel on _LayerMode {
  String get label {
    switch (this) {
      case _LayerMode.density: return 'DENSITY';
      case _LayerMode.route: return 'MY ROUTE';
      case _LayerMode.squad: return 'SQUAD';
    }
  }
}

class _PulsingDot extends StatefulWidget {
  @override State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _scale = Tween<double>(begin: 0.8, end: 1.4).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Stack(alignment: Alignment.center, children: [
      ScaleTransition(
        scale: _scale,
        child: Container(width: 24, height: 24, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.accentAlpha(0.2))),
      ),
      Container(width: 12, height: 12, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.accent)),
    ]);
  }
}

class _RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.7)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const dashWidth = 8.0;
    const dashSpace = 5.0;
    final path = Path()
      ..moveTo(size.width * 0.2, size.height * 0.6)
      ..quadraticBezierTo(size.width * 0.4, size.height * 0.4, size.width * 0.6, size.height * 0.3);

    _drawDashedPath(canvas, path, paint, dashWidth, dashSpace);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint, double dashWidth, double dashSpace) {
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final start = distance;
        final end = (distance + dashWidth).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(start, end), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
