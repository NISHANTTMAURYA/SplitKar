import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:skapp/utils/app_colors.dart';

class ExpenseMessage extends StatelessWidget {
  final String title;
  final double amount;
  final String paidBy;
  final String paidByProfilePic;
  final List<Map<String, dynamic>> splitWith;
  final DateTime timestamp;
  final bool isUserExpense;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;
  final Map<String, dynamic>? category;

  const ExpenseMessage({
    super.key,
    required this.title,
    required this.amount,
    required this.paidBy,
    required this.paidByProfilePic,
    required this.splitWith,
    required this.timestamp,
    required this.isUserExpense,
    this.onLongPress,
    this.onTap,
    this.category,
  });

  String _formatTimestamp(DateTime timestamp) {
    // Convert UTC timestamp to local time
    final localTime = timestamp.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(localTime.year, localTime.month, localTime.day);

    String timeStr = '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}';

    // Compare dates by their components to avoid timezone issues
    if (messageDate.year == today.year && 
        messageDate.month == today.month && 
        messageDate.day == today.day) {
      return timeStr;
    } else if (messageDate.year == yesterday.year && 
               messageDate.month == yesterday.month && 
               messageDate.day == yesterday.day) {
      return 'Yesterday $timeStr';
    } else if (now.difference(messageDate).inDays < 7) {
      final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return '${days[messageDate.weekday - 1]} $timeStr';
    } else {
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${messageDate.day} ${months[messageDate.month - 1]} $timeStr';
    }
  }

  Widget _buildPayerInfo(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorScheme>()!;
    final isSmallScreen = MediaQuery.of(context).size.width < 360;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Paid by:',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: isSmallScreen ? 14 : 16,
              backgroundColor: appColors.cardColor2?.withOpacity(0.1),
              backgroundImage: paidByProfilePic.startsWith('http')
                  ? CachedNetworkImageProvider(paidByProfilePic) as ImageProvider
                  : const AssetImage('assets/images/default_profile.png'),
            ),
            const SizedBox(width: 4),
            Text(
              '$paidBy (₹$amount)',
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorScheme>()!;
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 360;
    final textScaleFactor = mediaQuery.textScaleFactor.clamp(0.8, 1.2);
    final horizontalPadding = isSmallScreen ? 8.0 : 16.0;

    return Align(
      alignment: isUserExpense ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          left: isUserExpense ? mediaQuery.size.width * 0.15 : horizontalPadding,
          right: isUserExpense ? horizontalPadding : mediaQuery.size.width * 0.15,
          top: 8,
          bottom: 8,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onLongPress: onLongPress,
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Ink(
              decoration: BoxDecoration(
                color: isUserExpense
                    ? appColors.cardColor2?.withOpacity(0.1)
                    : appColors.cardColor3?.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isUserExpense
                    ? appColors.borderColor2?.withOpacity(0.2) ?? Colors.transparent
                    : appColors.borderColor3?.withOpacity(0.2) ?? Colors.transparent,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with amount and timestamp
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                    decoration: BoxDecoration(
                      color: isUserExpense
                          ? appColors.cardColor2?.withOpacity(0.15)
                          : appColors.cardColor3?.withOpacity(0.15),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹$amount',
                          style: GoogleFonts.cabin(
                            fontSize: 18 * textScaleFactor,
                            fontWeight: FontWeight.bold,
                            color: isUserExpense
                                ? appColors.borderColor2
                                : appColors.borderColor3,
                          ),
                        ),
                        Text(
                          _formatTimestamp(timestamp),
                          style: GoogleFonts.cabin(
                            fontSize: 12 * textScaleFactor,
                            color: appColors.textColor2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Padding(
                    padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (category != null) ...[
                          Row(
                            children: [
                              Text(
                                category!['icon'] ?? '📝',
                                style: const TextStyle(fontSize: 18),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                category!['name'] ?? '',
                                style: GoogleFonts.cabin(
                                  fontSize: 14 * textScaleFactor,
                                  color: appColors.textColor2,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                        ],
                        Text(
                          title,
                          style: GoogleFonts.cabin(
                            fontSize: 16 * textScaleFactor,
                            fontWeight: FontWeight.w600,
                            color: appColors.textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildPayerInfo(context),
                        const SizedBox(height: 8),
                        Text(
                          'Split with:',
                          style: GoogleFonts.cabin(
                            fontSize: 14 * textScaleFactor,
                            color: appColors.textColor2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: splitWith.map((person) {
                            return Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 6 : 8,
                                vertical: isSmallScreen ? 3 : 4,
                              ),
                              decoration: BoxDecoration(
                                color: appColors.cardColor2?.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: appColors.borderColor2?.withOpacity(0.2) ?? Colors.transparent,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: isSmallScreen ? 8 : 10,
                                    backgroundColor: appColors.cardColor2?.withOpacity(0.2),
                                    backgroundImage: person['profilePic'] != null &&
                                                   person['profilePic'].toString().startsWith('http')
                                        ? CachedNetworkImageProvider(person['profilePic'])
                                        : null,
                                    child: (person['profilePic'] == null ||
                                           !person['profilePic'].toString().startsWith('http'))
                                        ? Text(
                                            person['name'][0].toUpperCase(),
                                            style: TextStyle(
                                              color: appColors.textColor,
                                              fontSize: (isSmallScreen ? 8 : 10) * textScaleFactor,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${person['name']} (₹${person['amount']})',
                                    style: GoogleFonts.cabin(
                                      fontSize: (isSmallScreen ? 10 : 12) * textScaleFactor,
                                      color: appColors.textColor,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 