import 'package:flutter/material.dart';

/// Loader Risotto : deux cercles qui se rejoignent, l'intersection apparaît.
/// Usage : const RisottoLoader(size: 64)
class RisottoLoader extends StatefulWidget {
  const RisottoLoader({super.key, this.size = 64});
  final double size;

  @override
  State<RisottoLoader> createState() => _RisottoLoaderState();
}

class _RisottoLoaderState extends State<RisottoLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Chargement',
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) => CustomPaint(painter: _LoaderPainter(_c.value)),
        ),
      ),
    );
  }
}

class _LoaderPainter extends CustomPainter {
  _LoaderPainter(this.t);
  final double t;

  static const saffron = Color(0xFFE8A317);
  static const basil = Color(0xFF2F6B4F);
  static const charcoal = Color(0xFF1F2421);

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 120;
    // aller-retour : 0 -> 1 -> 0 avec adoucissement
    final p = Curves.easeInOut.transform(t < .5 ? t * 2 : (1 - t) * 2);
    final left = Offset((30 + 16 * p) * k, 60 * k);
    final right = Offset((90 - 16 * p) * k, 60 * k);
    final r = 26 * k;

    canvas.drawCircle(left, r, Paint()..color = saffron);
    canvas.drawCircle(right, r, Paint()..color = basil);

    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: left, radius: r)));
    canvas.drawCircle(right, r, Paint()..color = charcoal);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LoaderPainter old) => old.t != t;
}
