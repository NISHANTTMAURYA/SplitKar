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
    // Convert UTC date to local time
    final localDate = date.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(localDate.year, localDate.month, localDate.day);

    // Debug logging
    print('DateSeparator - Input date: $date');
    print('DateSeparator - Local date: $localDate');
    print('DateSeparator - Message date: $messageDate');
    print('DateSeparator - Today: $today');
    print('DateSeparator - Yesterday: $yesterday');

    // Compare dates by their components to avoid timezone issues
    if (messageDate.year == today.year && 
        messageDate.month == today.month && 
        messageDate.day == today.day) {
      print('DateSeparator - Returning: Today');
      return 'Today';
    } else if (messageDate.year == yesterday.year && 
               messageDate.month == yesterday.month && 
               messageDate.day == yesterday.day) {
      print('DateSeparator - Returning: Yesterday');
      return 'Yesterday';
    } else {
      // Format: "Monday, 12 March" or "12 March 2023" for older dates
      final months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

      if (localDate.year == now.year && now.difference(localDate).inDays < 7) {
        final result = '${days[localDate.weekday - 1]}, ${localDate.day} ${months[localDate.month - 1]}';
        print('DateSeparator - Returning: $result');
        return result;
      } else {
        final result = '${localDate.day} ${months[localDate.month - 1]} ${localDate.year}';
        print('DateSeparator - Returning: $result');
        return result;
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