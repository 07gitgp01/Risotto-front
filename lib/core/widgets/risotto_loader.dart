import 'package:flutter/material.dart';

import '../theme/risotto_colors.dart';

/// Risotto loader (brand kit, logo « La rencontre »): the saffron and basil circles
/// move towards each other and their charcoal intersection appears.
/// Usage: `const RisottoLoader(size: 64)`.
class RisottoLoader extends StatefulWidget {
  const RisottoLoader({super.key, this.size = 64, this.semanticsLabel});

  final double size;

  /// Announced by screen readers; defaults to "Chargement".
  final String? semanticsLabel;

  @override
  State<RisottoLoader> createState() => _RisottoLoaderState();
}

class _RisottoLoaderState extends State<RisottoLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticsLabel ?? 'Chargement',
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, _) =>
              CustomPaint(painter: _LoaderPainter(_controller.value)),
        ),
      ),
    );
  }
}

class _LoaderPainter extends CustomPainter {
  _LoaderPainter(this.t);

  /// Animation progress, 0 → 1.
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    // Drawn on a 120 × 120 grid, scaled to the widget size.
    final k = size.width / 120;
    // Back and forth (0 → 1 → 0), eased.
    final p = Curves.easeInOut.transform(t < .5 ? t * 2 : (1 - t) * 2);
    final left = Offset((30 + 16 * p) * k, 60 * k);
    final right = Offset((90 - 16 * p) * k, 60 * k);
    final r = 26 * k;

    canvas
      ..drawCircle(left, r, Paint()..color = RisottoColors.saffron)
      ..drawCircle(right, r, Paint()..color = RisottoColors.basil)
      ..save()
      ..clipPath(Path()..addOval(Rect.fromCircle(center: left, radius: r)))
      ..drawCircle(right, r, Paint()..color = RisottoColors.charcoal)
      ..restore();
  }

  @override
  bool shouldRepaint(_LoaderPainter old) => old.t != t;
}
