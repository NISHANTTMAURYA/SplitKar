import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:skapp/utils/app_colors.dart';
import 'package:skapp/services/auth_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skapp/pages/screens/group_settings/bloc/group_expense_bloc.dart';
import 'package:skapp/pages/screens/group_settings/bloc/group_expense_event.dart';
import 'package:skapp/pages/screens/group_settings/bloc/group_expense_state.dart';

class ExpenseDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> expense;
  final VoidCallback? onEdit;
  final int? groupId;
  final bool? isAdmin;

  const ExpenseDetailsSheet({
    super.key,
    required this.expense,
    this.onEdit,
    this.groupId,
    this.isAdmin,
  });

  static Future<bool> canDelete(
    BuildContext context,
    Map<String, dynamic> expense,
  ) async {
    final authService = AuthService();
    final userId = await authService.getUserId();
    final creatorId = expense['created_by']?.toString();
    final groupAdminId = expense['group_admin_id']?.toString();
    final isCurrentUserCreator =
        userId != null && creatorId != null && userId == creatorId;
    final isCurrentUserGroupAdmin =
        userId != null && groupAdminId != null && userId == groupAdminId;
    debugPrint(
      '[DEBUG] canDelete: userId=[33m$userId[0m, creatorId=$creatorId, groupAdminId=$groupAdminId, isCurrentUserCreator=$isCurrentUserCreator, isCurrentUserGroupAdmin=$isCurrentUserGroupAdmin, expense=$expense',
    );
    return isCurrentUserCreator || isCurrentUserGroupAdmin;
  }

  static Future<void> show(
    BuildContext context,
    Map<String, dynamic> expense, {
    VoidCallback? onEdit,
    int? groupId,
    bool? isAdmin,
  }) {
    print('DEBUG: Expense data in details sheet: $expense');
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (BuildContext sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => ExpenseDetailsSheet(
          expense: expense,
          onEdit: onEdit != null
              ? () {
                  print('DEBUG: Expense data before edit: $expense');
                  onEdit();
                }
              : null,
          groupId: groupId,
          isAdmin: isAdmin,
        ),
      ),
    ).then((result) {
      // If the sheet was closed due to a successful delete, refresh the parent
      if (result == true && context.mounted) {
        context.read<GroupExpenseBloc>().add(LoadGroupExpenses(groupId!));
      }
    });
  }

  /// Public static method to show delete confirmation and trigger delete
  static Future<bool> showDeleteConfirmation(
    BuildContext context,
    Map<String, dynamic> expense, {
    int? groupId,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: const Text(
          'Are you sure you want to delete this expense? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final eid =
          expense['id']?.toString() ?? expense['expense_id']?.toString();
      if (groupId != null && eid != null) {
        // Don't pop the details sheet here, let the caller handle it
        if (context.mounted) {
          context.read<GroupExpenseBloc>().add(
            DeleteGroupExpense(expenseId: eid, groupId: groupId),
          );

          // Wait for the delete operation to complete
          bool success = false;
          await for (final state in context.read<GroupExpenseBloc>().stream) {
            if (state is GroupExpenseError) {
              return false;
            }
            if (state is GroupExpensesLoaded) {
              success = true;
              break;
            }
          }
          return success;
        }
      }
    }
    return false;
  }

  String _formatTimestamp(DateTime timestamp) {
    // Convert UTC timestamp to local time
    final localTime = timestamp.toLocal();
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${localTime.day} ${months[localTime.month - 1]} ${localTime.year} at '
        '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorScheme>()!;
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 360;
    final textScaleFactor = mediaQuery.textScaleFactor.clamp(0.8, 1.2);

    // Parse the date string to DateTime
    final timestamp = DateTime.parse(
      expense['date'] ?? DateTime.now().toIso8601String(),
    ).toLocal();

    return FutureBuilder<bool>(
      future: ExpenseDetailsSheet.canDelete(context, expense),
      builder: (context, snapshot) {
        final canDelete = snapshot.data ?? false;
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
                      if (onEdit != null || canDelete)
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert,
                            color: appColors.iconColor,
                          ),
                          onSelected: (value) async {
                            if (value == 'edit' && onEdit != null) {
                              Navigator.pop(context); // Only pop for edit
                              onEdit!();
                            } else if (value == 'delete' && canDelete) {
                              final success =
                                  await ExpenseDetailsSheet.showDeleteConfirmation(
                                    context,
                                    expense,
                                    groupId: groupId,
                                  );
                              if (success && context.mounted) {
                                Navigator.pop(
                                  context,
                                  true,
                                ); // Pop with success result
                              }
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
                            if (canDelete)
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
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
                              color:
                                  appColors.borderColor2?.withOpacity(0.2) ??
                                  Colors.transparent,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '₹${expense['total_amount']}',
                                style: GoogleFonts.cabin(
                                  fontSize: 32 * textScaleFactor,
                                  fontWeight: FontWeight.bold,
                                  color: appColors.textColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (expense['category'] != null) ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      expense['category']['icon'] ?? '📝',
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      expense['category']['name'] ?? '',
                                      style: GoogleFonts.cabin(
                                        fontSize: 15 * textScaleFactor,
                                        color: appColors.textColor2,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                              ],
                              Text(
                                expense['description'] ?? 'Untitled Expense',
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
                        Column(
                          children: [
                            for (var payer in (expense['payers'] as List<dynamic>? ?? []))
                              Container(
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
                                      radius: 20,
                                      backgroundColor: appColors.cardColor2?.withOpacity(0.1),
                                      backgroundImage: payer['profilePic'] != null &&
                                          payer['profilePic'].toString().startsWith('http')
                                          ? CachedNetworkImageProvider(payer['profilePic'])
                                          : null,
                                      child: (payer['profilePic'] == null ||
                                              !payer['profilePic'].toString().startsWith('http'))
                                          ? Text(
                                              ((payer['first_name'] ?? payer['username'] ?? 'U') as String)[0].toUpperCase(),
                                              style: TextStyle(
                                                color: appColors.textColor,
                                                fontSize: 18 * textScaleFactor,
                                              ),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${payer['first_name'] ?? payer['username'] ?? 'Unknown'} ${payer['last_name'] ?? ''}',
                                            style: GoogleFonts.cabin(
                                              fontSize: 16 * textScaleFactor,
                                              fontWeight: FontWeight.w500,
                                              color: appColors.textColor,
                                            ),
                                          ),
                                          Text(
                                            '₹${payer['amount_paid']}',
                                            style: GoogleFonts.cabin(
                                              fontSize: 14 * textScaleFactor,
                                              color: appColors.textColor2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
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
                        ...(expense['owed_breakdown'] as List<dynamic>? ?? [])
                            .map<Widget>(
                              (person) => Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: appColors.cardColor2?.withOpacity(
                                    0.05,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        appColors.borderColor2?.withOpacity(
                                          0.1,
                                        ) ??
                                        Colors.transparent,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: appColors.cardColor2
                                          ?.withOpacity(0.1),
                                      backgroundImage:
                                          person['profilePic'] != null &&
                                              person['profilePic']
                                                  .toString()
                                                  .startsWith('http')
                                          ? CachedNetworkImageProvider(
                                              person['profilePic'],
                                            )
                                          : null,
                                      child:
                                          person['profilePic'] == null ||
                                              !person['profilePic']
                                                  .toString()
                                                  .startsWith('http')
                                          ? Text(
                                              (person['name'] ?? 'U')[0]
                                                  .toUpperCase(),
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
                                        person['name'] ?? 'Unknown',
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
                              ),
                            )
                            .toList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
