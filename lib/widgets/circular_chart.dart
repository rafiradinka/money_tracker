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
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}k';
    }
    return amount.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CirclePainter(percentage: percentage),
        child: showLabel
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _formatAmount(spent),
                      style: TextStyle(
                        color: AppColors.orange,
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

  _CirclePainter({required this.percentage});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const strokeWidth = 12.0;

    // Background circle
    final bgPaint = Paint()
      ..color = AppColors.greyDark.withOpacity(0.4)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = AppColors.orange
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * percentage;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class LargeCircularChart extends StatelessWidget {
  final double percentage;
  final double size;

  const LargeCircularChart({
    super.key,
    required this.percentage,
    this.size = 160,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _LargeCirclePainter(percentage: percentage),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${(percentage * 100).round()}%',
                style: TextStyle(
                  color: AppColors.orange,
                  fontSize: size * 0.2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Used',
                style: TextStyle(
                  color: AppColors.grey,
                  fontSize: size * 0.1,
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

  _LargeCirclePainter({required this.percentage});

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
      ..color = AppColors.orange
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * percentage;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
