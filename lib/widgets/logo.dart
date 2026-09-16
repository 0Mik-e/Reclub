import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Brand assets for reclub, drawn as vectors so the same code produces the
/// in-app logo, the launcher icons and the launch images.
///
/// Everything is authored on a 1024×1024 grid and scaled down by the painters.
class ReclubBrand {
  static const grid = 1024.0;

  static const tileTop = Color(0xFFFFD75A);
  static const tileBottom = Color(0xFFF39B12);
  static const glyph = Color(0xFF12141A);
  static const ball = Color(0xFF17C964);

  /// Amber tile with the concentric-ring texture used on club covers.
  static void paintTile(Canvas c, {double radiusFactor = 0.235}) {
    final rect = const Rect.fromLTWH(0, 0, grid, grid);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(grid * radiusFactor));
    c.save();
    c.clipRRect(rrect);
    c.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tileTop, tileBottom],
        ).createShader(rect),
    );

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 26
      ..color = Colors.white.withValues(alpha: 0.17);
    for (final r in const [600.0, 470.0, 340.0]) {
      c.drawCircle(const Offset(1010, 40), r, ring);
    }

    c.restore();
  }

  /// The paddle-and-ball mark, sized to fill the 1024 grid.
  static void paintGlyph(Canvas c, {Color color = glyph, Color accent = ball}) {
    final ink = Paint()..color = color;

    c.save();
    c.translate(556, 444);
    c.rotate(-0.32);
    // The holes are punched out of the paddle so the tile shows through.
    c.saveLayer(const Rect.fromLTRB(-420, -520, 420, 620), Paint());
    c.drawRRect(
      RRect.fromRectAndCorners(
        const Rect.fromLTRB(-210, -360, 210, 122),
        topLeft: const Radius.circular(172),
        topRight: const Radius.circular(172),
        bottomLeft: const Radius.circular(104),
        bottomRight: const Radius.circular(104),
      ),
      ink,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTRB(-64, 76, 64, 460), const Radius.circular(60)),
      ink,
    );
    final hole = Paint()..blendMode = BlendMode.clear;
    for (final o in const [
      Offset(0, -252),
      Offset(-108, -132),
      Offset(108, -132),
      Offset(0, -12),
    ]) {
      c.drawCircle(o, 46, hole);
    }
    c.restore();
    c.restore();

    const ballCenter = Offset(248, 646);
    c.drawCircle(ballCenter, 92, Paint()..color = accent);
    c.drawCircle(
      ballCenter,
      92,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12,
    );
  }

  /// Full launcher icon: tile + glyph.
  static void paintIcon(Canvas c, {double radiusFactor = 0.235}) {
    paintTile(c, radiusFactor: radiusFactor);
    c.save();
    c.translate(grid / 2, grid / 2);
    c.scale(0.82);
    c.translate(-grid / 2, -grid / 2);
    paintGlyph(c);
    c.restore();
  }
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter({required this.tile, required this.glyphColor, required this.radiusFactor});
  final bool tile;
  final Color glyphColor;
  final double radiusFactor;

  @override
  void paint(Canvas c, Size size) {
    c.save();
    c.scale(size.width / ReclubBrand.grid);
    if (tile) {
      ReclubBrand.paintIcon(c, radiusFactor: radiusFactor);
    } else {
      c.translate(ReclubBrand.grid / 2, ReclubBrand.grid / 2);
      c.scale(0.86);
      c.translate(-ReclubBrand.grid / 2, -ReclubBrand.grid / 2);
      ReclubBrand.paintGlyph(c, color: glyphColor);
    }
    c.restore();
  }

  @override
  bool shouldRepaint(_MarkPainter old) =>
      old.tile != tile || old.glyphColor != glyphColor || old.radiusFactor != radiusFactor;
}

/// Square brand mark. [tile] draws the amber background, otherwise only the
/// glyph is painted in [glyphColor].
class ReclubMark extends StatelessWidget {
  const ReclubMark({
    super.key,
    this.size = 56,
    this.tile = true,
    this.glyphColor = ReclubBrand.glyph,
    this.radiusFactor = 0.235,
    this.shadow = true,
  });

  final double size;
  final bool tile;
  final Color glyphColor;
  final double radiusFactor;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final mark = CustomPaint(
      size: Size.square(size),
      painter: _MarkPainter(tile: tile, glyphColor: glyphColor, radiusFactor: radiusFactor),
    );
    if (!tile || !shadow) return mark;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * radiusFactor),
        boxShadow: [
          BoxShadow(
            color: AppColors.yellowDeep.withValues(alpha: 0.35),
            blurRadius: size * 0.30,
            offset: Offset(0, size * 0.10),
          ),
        ],
      ),
      child: mark,
    );
  }
}

/// Mark plus the "reclub" wordmark.
class ReclubWordmark extends StatelessWidget {
  const ReclubWordmark({super.key, this.size = 34, this.color = AppColors.ink});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ReclubMark(size: size),
        SizedBox(width: size * 0.30),
        Text(
          'reclub',
          style: TextStyle(
            fontSize: size * 0.80,
            fontWeight: FontWeight.w900,
            letterSpacing: -size * 0.030,
            color: color,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}

/// The Google "G", drawn as four arcs plus the bar so it needs no asset.
class GoogleG extends StatelessWidget {
  const GoogleG({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: const _GooglePainter());
}

class _GooglePainter extends CustomPainter {
  const _GooglePainter();

  static const _blue = Color(0xFF4285F4);
  static const _red = Color(0xFFEA4335);
  static const _yellow = Color(0xFFFBBC05);
  static const _green = Color(0xFF34A853);

  @override
  void paint(Canvas c, Size size) {
    final s = size.width;
    final w = s * 0.22;
    final r = (s - w) / 2 - s * 0.02;
    final rect = Rect.fromCircle(center: Offset(s / 2, s / 2), radius: r);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.butt;

    double rad(double deg) => deg * math.pi / 180;
    c.drawArc(rect, rad(198), rad(92), false, arc..color = _red);
    c.drawArc(rect, rad(128), rad(70), false, arc..color = _yellow);
    c.drawArc(rect, rad(22), rad(106), false, arc..color = _green);
    c.drawArc(rect, rad(295), rad(88), false, arc..color = _blue);

    c.drawRect(
      Rect.fromLTRB(s / 2 - w * 0.1, s / 2 - w * 0.52, s / 2 + r + w / 2, s / 2 + w * 0.48),
      Paint()..color = _blue,
    );
  }

  @override
  bool shouldRepaint(_GooglePainter oldDelegate) => false;
}
