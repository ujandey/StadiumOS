import 'package:flutter/material.dart';

/// Animated number widget that smoothly transitions between integer values.
class AnimatedCount extends StatelessWidget {
  final int count;
  final TextStyle style;
  final Duration duration;

  const AnimatedCount({
    super.key,
    required this.count,
    required this.style,
    this.duration = const Duration(milliseconds: 600),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: count, end: count),
      duration: duration,
      builder: (context, value, child) {
        return Text('$value', style: style);
      },
    );
  }
}

/// Animated score digit that scales up briefly on change.
class AnimatedScore extends StatefulWidget {
  final int score;
  final TextStyle style;

  const AnimatedScore({super.key, required this.score, required this.style});

  @override
  State<AnimatedScore> createState() => _AnimatedScoreState();
}

class _AnimatedScoreState extends State<AnimatedScore>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  int _prevScore = 0;

  @override
  void initState() {
    super.initState();
    _prevScore = widget.score;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 60),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(AnimatedScore old) {
    super.didUpdateWidget(old);
    if (widget.score != _prevScore) {
      _prevScore = widget.score;
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Text('${widget.score}', style: widget.style),
    );
  }
}
