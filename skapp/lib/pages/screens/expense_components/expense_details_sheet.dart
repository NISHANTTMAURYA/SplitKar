import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:skapp/utils/app_colors.dart';

class ExpenseDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> expense;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ExpenseDetailsSheet({
    super.key,
    required this.expense,
    this.onEdit,
    this.onDelete,
  });

  static Future<void> show(
    BuildContext context,
    Map<String, dynamic> expense, {
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => ExpenseDetailsSheet(
          expense: expense,
          onEdit: onEdit,
          onDelete: onDelete,
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${timestamp.day} ${months[timestamp.month - 1]} ${timestamp.year} at '
           '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorScheme>()!;
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 360;
    final textScaleFactor = mediaQuery.textScaleFactor.clamp(0.8, 1.2);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: appColors.borderColor2?.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Expense Details',
                      style: GoogleFonts.cabin(
                        fontSize: 20 * textScaleFactor,
                        fontWeight: FontWeight.bold,
                        color: appColors.textColor,
                      ),
                    ),
                  ),
                  if (onEdit != null || onDelete != null)
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: appColors.iconColor),
                      onSelected: (value) {
                        Navigator.pop(context);
                        if (value == 'edit' && onEdit != null) {
                          onEdit!();
                        } else if (value == 'delete' && onDelete != null) {
                          onDelete!();
                        }
                      },
                      itemBuilder: (context) => [
                        if (onEdit != null)
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                        if (onDelete != null)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Amount card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: appColors.cardColor2?.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: appColors.borderColor2?.withOpacity(0.2) ?? Colors.transparent,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '₹${expense['amount']}',
                            style: GoogleFonts.cabin(
                              fontSize: 32 * textScaleFactor,
                              fontWeight: FontWeight.bold,
                              color: appColors.textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            expense['title'],
                            style: GoogleFonts.cabin(
                              fontSize: 16 * textScaleFactor,
                              color: appColors.textColor2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Paid by section
                    Text(
                      'Paid by',
                      style: GoogleFonts.cabin(
                        fontSize: 16 * textScaleFactor,
                        fontWeight: FontWeight.w600,
                        color: appColors.textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: appColors.cardColor2?.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: appColors.borderColor2?.withOpacity(0.1) ?? Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: appColors.cardColor2?.withOpacity(0.1),
                            backgroundImage: expense['paid_by_profile_pic'] != null &&
                                          expense['paid_by_profile_pic'].isNotEmpty
                                ? CachedNetworkImageProvider(expense['paid_by_profile_pic'])
                                : null,
                            child: expense['paid_by_profile_pic'] == null ||
                                   expense['paid_by_profile_pic'].isEmpty
                                ? Text(
                                    expense['paid_by'][0].toUpperCase(),
                                    style: TextStyle(
                                      color: appColors.textColor,
                                      fontSize: 18 * textScaleFactor,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                expense['paid_by'],
                                style: GoogleFonts.cabin(
                                  fontSize: 16 * textScaleFactor,
                                  fontWeight: FontWeight.w500,
                                  color: appColors.textColor,
                                ),
                              ),
                              Text(
                                _formatTimestamp(expense['timestamp']),
                                style: GoogleFonts.cabin(
                                  fontSize: 12 * textScaleFactor,
                                  color: appColors.textColor2,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Split details
                    Text(
                      'Split Details',
                      style: GoogleFonts.cabin(
                        fontSize: 16 * textScaleFactor,
                        fontWeight: FontWeight.w600,
                        color: appColors.textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...expense['split_with'].map<Widget>((person) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: appColors.cardColor2?.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: appColors.borderColor2?.withOpacity(0.1) ?? Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: appColors.cardColor2?.withOpacity(0.1),
                            backgroundImage: person['profilePic'] != null &&
                                          person['profilePic'].isNotEmpty
                                ? CachedNetworkImageProvider(person['profilePic'])
                                : null,
                            child: person['profilePic'] == null ||
                                   person['profilePic'].isEmpty
                                ? Text(
                                    person['name'][0].toUpperCase(),
                                    style: TextStyle(
                                      color: appColors.textColor,
                                      fontSize: 14 * textScaleFactor,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              person['name'],
                              style: GoogleFonts.cabin(
                                fontSize: 14 * textScaleFactor,
                                color: appColors.textColor,
                              ),
                            ),
                          ),
                          Text(
                            '₹${person['amount']}',
                            style: GoogleFonts.cabin(
                              fontSize: 14 * textScaleFactor,
                              fontWeight: FontWeight.w600,
                              color: appColors.textColor,
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 