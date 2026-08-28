import 'package:flutter/material.dart';

class AppProgressBar extends StatelessWidget {
  final int percentage;
  final bool showLabel;

  const AppProgressBar({
    super.key,
    required this.percentage,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = percentage.clamp(0, 100);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel)
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progress',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                Text(
                  '$clamped%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        Container(
          height: 6,
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: clamped / 100.0,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.white : const Color(0xFF18181B),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
