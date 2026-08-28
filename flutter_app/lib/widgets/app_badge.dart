import 'package:flutter/material.dart';

class AppBadge extends StatelessWidget {
  final String text;
  final String variant;

  const AppBadge({
    super.key,
    required this.text,
    this.variant = 'pending',
  });

  @override
  Widget build(BuildContext context) {
    final norm = variant.toLowerCase();
    Color bg;
    Color fg;
    Color border;

    switch (norm) {
      case 'low':
      case 'completed':
      case 'paid':
        bg = const Color(0xFF064E3B).withValues(alpha: 0.2);
        fg = const Color(0xFF34D399);
        border = const Color(0xFF059669);
        break;
      case 'medium':
      case 'pending':
      case 'partial':
        bg = const Color(0xFF78350F).withValues(alpha: 0.2);
        fg = const Color(0xFFFBBF24);
        border = const Color(0xFFD97706);
        break;
      case 'high':
      case 'defaulted':
      case 'overdue':
        bg = const Color(0xFF881337).withValues(alpha: 0.2);
        fg = const Color(0xFFF87171);
        border = const Color(0xFFE11D48);
        break;
      case 'active':
        bg = const Color(0xFF1E3A8A).withValues(alpha: 0.2);
        fg = const Color(0xFF60A5FA);
        border = const Color(0xFF2563EB);
        break;
      case 'rejected':
      case 'cancelled':
      default:
        bg = Colors.grey.withValues(alpha: 0.2);
        fg = Colors.grey.shade300;
        border = Colors.grey.shade600;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 1),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
