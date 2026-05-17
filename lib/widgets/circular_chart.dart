import 'dart:math';
import 'package:flutter/material.dart';
import '../theme.dart';

class CircularBudgetChart extends StatelessWidget {
  final double percentage;
  final double spent;
  final double total;
  final double size;
  final bool showLabel;

  const CircularBudgetChart({
    super.key,
    required this.percentage,
    required this.spent,
    required this.total,
    this.size = 140,
    this.showLabel = true,
  });

  String _formatAmount(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}k';
    return amount.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final isOver = percentage > 1.0;
    final arcColor = isOver ? AppColors.red : AppColors.orange;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CirclePainter(
            percentage: percentage.clamp(0.0, 1.0), color: arcColor),
        child: showLabel
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _formatAmount(spent),
                      style: TextStyle(
                        color: arcColor,
                        fontSize: size * 0.18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'from ${_formatAmount(total)}',
                      style: TextStyle(
                        color: AppColors.grey,
                        fontSize: size * 0.09,
                      ),
                    ),
                  ],
                ),
              )
            : null,
      ),
    );
  }
}

class _CirclePainter extends CustomPainter {
  final double percentage;
  final Color color;

  _CirclePainter({required this.percentage, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const strokeWidth = 12.0;

    final bgPaint = Paint()
      ..color = AppColors.greyDark.withOpacity(0.4)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * percentage,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class LargeCircularChart extends StatelessWidget {
  final double percentage; // bisa > 1.0
  final double size;

  const LargeCircularChart({
    super.key,
    required this.percentage,
    this.size = 160,
  });

  @override
  Widget build(BuildContext context) {
    final isOver = percentage > 1.0;
    final arcColor = isOver ? AppColors.red : AppColors.orange;
    final displayPct = (percentage * 100).round();

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _LargeCirclePainter(
            percentage: percentage.clamp(0.0, 1.0), color: arcColor),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$displayPct%',
                style: TextStyle(
                  color: arcColor,
                  fontSize: size * 0.18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                isOver ? 'Over!' : 'Used',
                style: TextStyle(
                  color: isOver ? AppColors.red : AppColors.grey,
                  fontSize: size * 0.09,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LargeCirclePainter extends CustomPainter {
  final double percentage;
  final Color color;

  _LargeCirclePainter({required this.percentage, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 14;
    const strokeWidth = 18.0;

    final bgPaint = Paint()
      ..color = AppColors.greyDark.withOpacity(0.4)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * percentage,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
