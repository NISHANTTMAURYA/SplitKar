import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skapp/utils/app_colors.dart';

class DateSeparator extends StatelessWidget {
  final DateTime date;

  const DateSeparator({
    super.key,
    required this.date,
  });

  String _formatDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      // Format: "Monday, 12 March" or "12 March 2023" for older dates
      final months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

      if (date.year == now.year && now.difference(date).inDays < 7) {
        return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
      } else {
        return '${date.day} ${months[date.month - 1]} ${date.year}';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorScheme>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: appColors.borderColor2?.withOpacity(0.2),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: appColors.cardColor2?.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: appColors.borderColor2?.withOpacity(0.2) ?? Colors.transparent,
              ),
            ),
            child: Text(
              _formatDate(),
              style: GoogleFonts.cabin(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: appColors.textColor2,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: appColors.borderColor2?.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }
} 