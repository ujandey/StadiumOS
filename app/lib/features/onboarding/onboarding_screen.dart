import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingScreen({super.key, required this.onComplete});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  int _step = 0;
  final _codeController = TextEditingController();
  final _squadController = TextEditingController();
  bool _detecting = false;
  bool _detected = false;
  String? _codeError;
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _slideAnim = Tween<Offset>(begin: const Offset(0.08, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(_fadeCtrl);
    _fadeCtrl.forward();
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    _fadeCtrl.dispose();
    _codeController.dispose();
    _squadController.dispose();
    super.dispose();
  }

  void _nextStep() {
    HapticFeedback.lightImpact();

    // Validate event code on step 0
    if (_step == 0) {
      final code = _codeController.text.trim();
      if (code.isEmpty) {
        setState(() => _codeError = 'Enter a 6-character code or scan QR');
        return;
      }
      if (code.length < 3) {
        setState(() => _codeError = 'Code must be at least 3 characters');
        return;
      }
      setState(() => _codeError = null);
    }

    if (_step == 2) { widget.onComplete(); return; }
    setState(() => _step++);
    _slideCtrl.reset(); _slideCtrl.forward();
    _fadeCtrl.reset(); _fadeCtrl.forward();
    if (_step == 1) _simulateBLEDetection();
  }

  void _simulateBLEDetection() {
    setState(() => _detecting = true);
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() { _detecting = false; _detected = true; });
    });
  }

  String get _stepTitle {
    if (_step == 0) return 'Scan your ticket\nor enter event code';
    if (_step == 1) return 'Confirm your seat';
    return 'Join your squad';
  }

  String get _stepSubtitle {
    if (_step == 0) return 'Instant. No account. No email.';
    if (_step == 1) return 'Detecting your section via BLE.';
    return 'Already have a join code? Enter it now.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg900,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  _buildHeader(),
                  const SizedBox(height: 40),
                  _buildStepIndicator(),
                  const SizedBox(height: 36),
                  Expanded(child: _buildStep()),
                  _buildCTA(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.accentAlpha(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.accentAlpha(0.3)),
            ),
            child: Text('STADIUM',
                style: AppTypography.label.copyWith(color: AppColors.accent)),
          ),
          Text('OS',
              style: AppTypography.headingMedium.copyWith(color: AppColors.accent)),
        ]),
        const SizedBox(height: 16),
        Text(_stepTitle,
            style: AppTypography.headingLarge.copyWith(color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Text(_stepSubtitle,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: List.generate(3, (i) => Padding(
        padding: const EdgeInsets.only(right: 6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: i == _step ? 24 : 8,
          height: 4,
          decoration: BoxDecoration(
            color: i == _step
                ? AppColors.accent
                : i < _step ? AppColors.accentDim : AppColors.bg400,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      )),
    );
  }

  Widget _buildStep() {
    if (_step == 0) return _buildScanStep();
    if (_step == 1) return _buildSeatStep();
    return _buildSquadStep();
  }

  Widget _buildScanStep() {
    return Column(children: [
      Container(
        height: 160,
        decoration: BoxDecoration(
          color: AppColors.bg700,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.bg400),
        ),
        child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.qr_code_scanner_outlined, size: 56, color: AppColors.accent),
          const SizedBox(height: 12),
          Text('Scan QR at gate entry',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
        ])),
      ),
      const SizedBox(height: 20),
      Row(children: [
        Expanded(child: Divider(color: AppColors.bg400)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('OR', style: AppTypography.label.copyWith(color: AppColors.textMuted)),
        ),
        Expanded(child: Divider(color: AppColors.bg400)),
      ]),
      const SizedBox(height: 20),
      TextField(
        controller: _codeController,
        onChanged: (_) { if (_codeError != null) setState(() => _codeError = null); },
        style: const TextStyle(
            color: AppColors.textPrimary, letterSpacing: 4, fontSize: 20, fontWeight: FontWeight.w700),
        textAlign: TextAlign.center,
        textCapitalization: TextCapitalization.characters,
        maxLength: 6,
        decoration: InputDecoration(
          hintText: 'A B C 1 2 3',
          hintStyle: const TextStyle(letterSpacing: 4, color: AppColors.textMuted),
          counterText: '',
          errorText: _codeError,
        ),
      ),
    ]);
  }

  Widget _buildSeatStep() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.bg700,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accentAlpha(0.3)),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _detecting
            ? Column(key: const ValueKey('detecting'), mainAxisSize: MainAxisSize.min, children: [
                SizedBox(
                  width: 48, height: 48,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                ),
                const SizedBox(height: 16),
                Text('Detecting your location via BLE...',
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
              ])
            : Column(key: const ValueKey('detected'), mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle, color: AppColors.accentAlpha(0.1),
                  ),
                  child: const Icon(Icons.location_on_outlined, color: AppColors.accent, size: 28),
                ),
                const SizedBox(height: 16),
                Text("You're in",
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text('Section 114, Row C',
                    style: AppTypography.headingMedium.copyWith(color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text('Gate A · East Stand',
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
              ]),
      ),
    );
  }

  Widget _buildSquadStep() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bg700,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.bg400),
      ),
      child: Column(children: [
        Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.accentAlpha(0.1)),
            child: const Icon(Icons.group_outlined, color: AppColors.accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Join a squad',
                style: AppTypography.headingSmall.copyWith(color: AppColors.textPrimary)),
            Text('Enter the 6-digit code from your group',
                style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
          ])),
        ]),
        const SizedBox(height: 20),
        TextField(
          controller: _squadController,
          style: const TextStyle(
              color: AppColors.textPrimary, letterSpacing: 4, fontSize: 20, fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
          textCapitalization: TextCapitalization.characters,
          maxLength: 6,
          decoration: const InputDecoration(
            hintText: 'JOIN CODE',
            hintStyle: TextStyle(letterSpacing: 4, color: AppColors.textMuted),
            counterText: '',
          ),
        ),
        const SizedBox(height: 16),
        const Divider(color: AppColors.bg400),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add_circle_outline, size: 18),
          label: const Text('Create new squad'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            foregroundColor: AppColors.accent,
            side: const BorderSide(color: AppColors.bg400),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ]),
    );
  }

  Widget _buildCTA() {
    return Column(children: [
      ElevatedButton(
        onPressed: (_step != 1 || _detected) ? _nextStep : null,
        child: Text(_step == 2 ? 'Enter the Stadium' : 'Continue'),
      ),
      if (_step == 2) ...[
        const SizedBox(height: 12),
        TextButton(
          onPressed: widget.onComplete,
          child: Text('Skip — go solo',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
        ),
      ],
    ]);
  }
}
