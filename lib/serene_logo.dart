import 'package:flutter/material.dart';

// ── Serene header unit: logo + name side by side ───────────────────────────────
// Drop this into AppBar's title: on every main tab screen.
// On login/signup, use SereneLogo(centered: true) for the centered hero.

const _accent     = Color(0xFF7C6FA0);
const _accentMild = Color(0xFFEDE9F5);

class SereneHeader extends StatelessWidget {
  const SereneHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        _SereneLogoIcon(size: 32),
        SizedBox(width: 10),
        Text(
          'Serene',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A2E),
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }
}

/// Large centered hero used on login / signup / reset-password screens.
class SereneLargeHero extends StatelessWidget {
  const SereneLargeHero({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: const [
        _SereneLogoIcon(size: 72),
        SizedBox(height: 14),
        Text(
          'Serene',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A2E),
            letterSpacing: -0.8,
          ),
        ),
      ],
    );
  }
}

class _SereneLogoIcon extends StatelessWidget {
  final double size;
  const _SereneLogoIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _accentMild,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: _accent.withOpacity(0.18),
            blurRadius: size * 0.35,
            offset: Offset(0, size * 0.1),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _SerenePainter(iconSize: size),
      ),
    );
  }
}

/// Draws a minimal crescent + three soundwave arcs inside the rounded square.
class _SerenePainter extends CustomPainter {
  final double iconSize;
  const _SerenePainter({required this.iconSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _accent
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width * 0.28;

    // Crescent: draw full circle then clip with offset circle
    final path = Path()
      ..addOval(Rect.fromCircle(center: Offset(cx - r * 0.12, cy - r * 0.05), radius: r));

    final clipPath = Path()
      ..addOval(Rect.fromCircle(center: Offset(cx + r * 0.32, cy - r * 0.05), radius: r * 0.82));

    final crescent = Path.combine(PathOperation.difference, path, clipPath);
    canvas.drawPath(crescent, paint);

    // Three soundwave arcs to the right
    final wavePaint = Paint()
      ..color = _accent.withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.width * 0.055;

    final waveX = cx + r * 0.8;
    final radii = [r * 0.30, r * 0.55, r * 0.80];
    for (final wr in radii) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(waveX, cy), radius: wr),
        -0.7, 1.4, false, wavePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}