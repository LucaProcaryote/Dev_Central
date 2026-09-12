import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/app_config.dart';
import 'theme.dart';

/// The mark that identifies one application of the suite.
///
/// A teal disc, a ring of beads, and the application's own symbol in the
/// middle. All five share the disc and the ring - what differs is the glyph,
/// which is why a screenshot of any of them still reads as the same hospital.
///
/// This is the same drawing as the favicon and the installed-application icon:
/// `tools/generate_icons.py` in Dev_Central rasterises it from the same
/// geometry and the same Material glyph, so the tab and the title bar cannot
/// drift apart.
class AppBadge extends StatelessWidget {
  const AppBadge({super.key, required this.app, this.size = 28});

  final HospitalApp app;

  /// Width and height in logical pixels. Below [_beadThreshold] the beads are
  /// dropped: at 20px they stop being a ring and turn into noise around the
  /// glyph, and the glyph is the part that carries the meaning.
  final double size;

  static const double _beadThreshold = 22;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BadgePainter(drawBeads: size >= _beadThreshold),
        child: Center(
          child: Icon(
            HospitalTheme.iconFor(app),
            size: size * 0.46,
            color: Colors.white,
          ),
        ),
      ),
      // The glyph already names the application to a sighted user through the
      // title beside it, so the badge itself is decoration.
    );
  }
}

class _BadgePainter extends CustomPainter {
  const _BadgePainter({required this.drawBeads});

  final bool drawBeads;

  /// Eight beads, alternating large and small, on a ring just inside the rim.
  static const int _beadCount = 8;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final centre = rect.center;
    final radius = size.shortestSide / 2;

    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[HospitalTheme.brandLight, HospitalTheme.brandDeep],
        ).createShader(rect),
    );

    if (!drawBeads) return;

    final ring = radius * 0.80;
    for (var i = 0; i < _beadCount; i++) {
      final angle = (i * 2 * math.pi / _beadCount) - math.pi / 2;
      final big = i.isEven;
      canvas.drawCircle(
        centre + Offset(ring * math.cos(angle), ring * math.sin(angle)),
        radius * (big ? 0.088 : 0.055),
        Paint()..color = Colors.white.withValues(alpha: big ? 0.92 : 0.51),
      );
    }
  }

  @override
  bool shouldRepaint(_BadgePainter oldDelegate) =>
      oldDelegate.drawBeads != drawBeads;
}
