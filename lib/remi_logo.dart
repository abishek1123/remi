import 'package:flutter/material.dart';

/// Remi brand mark: a knowledge-graph constellation (a lit central node
/// linking scattered satellites) on a blurple gradient rounded square.
class RemiLogo extends StatelessWidget {
  final double size;
  const RemiLogo({super.key, this.size = 76});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4A4180), Color(0xFF8F83D6)],
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: const Color(0x665D5294),
            blurRadius: size * 0.45,
            offset: Offset(0, size * 0.14),
          ),
        ],
      ),
      child: CustomPaint(painter: _GraphPainter()),
    );
  }
}

class _GraphPainter extends CustomPainter {
  // Normalized node positions (0..1). First is the central lit node.
  static const _nodes = [
    Offset(0.50, 0.50),
    Offset(0.26, 0.30),
    Offset(0.77, 0.33),
    Offset(0.72, 0.74),
    Offset(0.29, 0.71),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    Offset p(Offset n) => Offset(n.dx * w, n.dy * w);

    final linePaint = Paint()
      ..color = const Color(0xFFE7E5FE).withValues(alpha: 0.7)
      ..strokeWidth = w * 0.025
      ..strokeCap = StrokeCap.round;
    for (var i = 1; i < _nodes.length; i++) {
      canvas.drawLine(p(_nodes[0]), p(_nodes[i]), linePaint);
    }

    final nodePaint = Paint()..color = const Color(0xFFF5F4FF);
    // central node glow + larger radius
    canvas.drawCircle(
      p(_nodes[0]),
      w * 0.12,
      Paint()..color = const Color(0xFFF5F4FF).withValues(alpha: 0.25),
    );
    canvas.drawCircle(p(_nodes[0]), w * 0.075, nodePaint);
    for (var i = 1; i < _nodes.length; i++) {
      canvas.drawCircle(p(_nodes[i]), w * 0.05, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
