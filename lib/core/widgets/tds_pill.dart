import 'package:flutter/material.dart';

import '../theme/tds_colors.dart';

/// Pastilla pequeña de color (estado, cuenta regresiva, etc.).
class TdsPill extends StatelessWidget {
  const TdsPill({super.key, required this.child, this.color = TdsColors.surfaceContainerHighest});

  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
      child: child,
    );
  }
}

/// Punto de color; con [pulse] parpadea (como `animate-pulse`).
class TdsDot extends StatelessWidget {
  const TdsDot({super.key, required this.color, this.size = 8, this.pulse = false});

  final Color color;
  final double size;
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
    return pulse ? TdsPulse(child: dot) : dot;
  }
}

/// Hace parpadear suavemente a su hijo.
class TdsPulse extends StatefulWidget {
  const TdsPulse({super.key, required this.child});

  final Widget child;

  @override
  State<TdsPulse> createState() => _TdsPulseState();
}

class _TdsPulseState extends State<TdsPulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat(reverse: true);

  late final Animation<double> _opacidad = Tween(begin: 1.0, end: 0.35)
      .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(opacity: _opacidad, child: widget.child);
}
