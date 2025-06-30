import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skapp/utils/app_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skapp/pages/screens/group_settings/bloc/group_expense_bloc.dart';
import 'package:skapp/pages/screens/group_settings/bloc/group_expense_event.dart';
import 'package:skapp/pages/screens/group_settings/bloc/group_expense_state.dart';
import 'package:skapp/services/auth_service.dart';
import 'package:skapp/widgets/app_notification.dart';
import 'package:skapp/services/notification_service.dart';

enum SplitMethod { equal, percentage }

class AddExpenseSheet extends StatefulWidget {
  final int groupId;
  final List<Map<String, dynamic>> members;
  final Map<String, dynamic>? existingExpense;

  const AddExpenseSheet({
    super.key,
    required this.groupId,
    required this.members,
    this.existingExpense,
  });

  static Future<bool?> show(
    BuildContext context,
    int groupId,
    List<Map<String, dynamic>> members,
    {Map<String, dynamic>? existingExpense}
  ) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (BuildContext sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (_, controller) => AddExpenseSheet(
          groupId: groupId,
          members: members,
          existingExpense: existingExpense,
        ),
      ),
    );
  }

  @override
  State<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final Map<String, bool> _selectedMembers = {};
  SplitMethod _splitMethod = SplitMethod.equal;
  final Map<String, TextEditingController> _percentageControllers = {};
  bool _isProcessing = false;
  final _authService = AuthService();
  final _scrollController = ScrollController();
  String? _percentageError;

  @override
  void initState() {
    super.initState();
    print('DEBUG: Existing expense data in AddExpenseSheet: ${widget.existingExpense}');
    // Initialize selected members map
    for (var member in widget.members) {
      _selectedMembers[member['profile_code']] = true;
      _percentageControllers[member['profile_code']] = TextEditingController();
    }

    // Pre-fill data if editing an existing expense
    if (widget.existingExpense != null) {
      print('DEBUG: Pre-filling expense data: ${widget.existingExpense}');
      _titleController.text = widget.existingExpense!['description'] ?? '';
      _amountController.text = (widget.existingExpense!['total_amount'] ?? '0').toString();
      
      // Set split method
      _splitMethod = widget.existingExpense!['split_type'] == 'percentage' 
          ? SplitMethod.percentage 
          : SplitMethod.equal;

      // Set selected members and their percentages
      final owedBreakdown = widget.existingExpense!['owed_breakdown'] as List<dynamic>?;
      if (owedBreakdown != null) {
        for (var member in widget.members) {
          final profileCode = member['profile_code'];
          final breakdown = owedBreakdown.firstWhere(
            (b) => b['user_id'] == member['id'],
            orElse: () => null,
          );
          _selectedMembers[profileCode] = breakdown != null;

          if (_splitMethod == SplitMethod.percentage && breakdown != null) {
            final splits = widget.existingExpense!['splits'] as List<dynamic>?;
            if (splits != null) {
              final split = splits.firstWhere(
                (s) => s['user_id'] == member['id'],
                orElse: () => null,
              );
              if (split != null) {
                _percentageControllers[profileCode]?.text = split['percentage'].toString();
              }
            }
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _percentageControllers.values.forEach((controller) => controller.dispose());
    _scrollController.dispose();
    super.dispose();
  }

  int _getTotalPercentage() {
    int total = 0;
    for (var entry in _selectedMembers.entries) {
      if (entry.value) {
        final text = _percentageControllers[entry.key]?.text ?? '';
        final value = int.tryParse(text) ?? 0;
        total += value;
      }
    }
    return total;
  }

  Widget _buildMemberTile(Map<String, dynamic> member) {
    final appColors = Theme.of(context).extension<AppColorScheme>()!;
    final profileCode = member['profile_code'];
    final isSelected = _selectedMembers[profileCode] ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: appColors.cardColor2?.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? appColors.borderColor2?.withOpacity(0.3) ?? Colors.transparent
              : appColors.borderColor3?.withOpacity(0.1) ?? Colors.transparent,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: appColors.cardColor2?.withOpacity(0.2),
          child: Text(
            member['username'][0].toUpperCase(),
            style: TextStyle(color: appColors.textColor),
          ),
        ),
        title: Text(
          member['username'],
          style: GoogleFonts.cabin(color: appColors.textColor),
        ),
        subtitle: _splitMethod == SplitMethod.percentage && isSelected
            ? TextField(
                controller: _percentageControllers[profileCode],
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  FilteringTextInputFormatter.allow(RegExp(r'^[0-9]{0,3}\u0000?')),
                ],
                decoration: InputDecoration(
                  suffixText: '%',
                  hintText: 'Percentage',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  hintStyle: TextStyle(color: appColors.textColor2),
                ),
                style: GoogleFonts.cabin(color: appColors.textColor),
                onTap: () {
                  // Scroll to make the text field visible when focused
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (_scrollController.hasClients) {
                      _scrollController.animateTo(
                        _scrollController.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                  });
                },
                onChanged: (value) {
                  setState(() {
                    _percentageError = null;
                    final entered = int.tryParse(value) ?? 0;
                    int runningTotal = 0;
                    for (var entry in _selectedMembers.entries) {
                      if (entry.value) {
                        if (entry.key == profileCode) {
                          runningTotal += entered;
                        } else {
                          final other = int.tryParse(_percentageControllers[entry.key]?.text ?? '') ?? 0;
                          runningTotal += other;
                        }
                      }
                    }
                    if (runningTotal > 100) {
                      // Revert the change
                      _percentageControllers[profileCode]?.text = '';
                      _percentageError = 'Total percentage cannot exceed 100%';
                      NotificationService().showAppNotification(
                        context,
                        message: 'Total percentage cannot exceed 100%',
                        icon: Icons.warning,
                      );
                    }
                  });
                },
              )
            : null,
        trailing: Checkbox(
          value: isSelected,
          onChanged: (value) {
            setState(() {
              _selectedMembers[profileCode] = value ?? false;
            });
          },
        ),
      ),
    );
  }

  Future<int?> _getCurrentUserId() async {
    final userId = await _authService.getUserId();
    if (userId == null) return null;
    return int.parse(userId);
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorScheme>()!;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final isEditMode = widget.existingExpense != null;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomPadding),
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
              // Title
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  isEditMode ? 'Edit Expense' : 'Add New Expense',
                  style: GoogleFonts.cabin(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: appColors.textColor,
                  ),
                ),
              ),
              // Form
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title field
                        TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            labelText: 'Description',
                            hintText: 'What was this expense for?',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a description';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Amount field
                        TextFormField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: InputDecoration(
                            labelText: 'Amount',
                            prefixText: '₹',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter an amount';
                            }
                            try {
                              final amount = double.parse(value);
                              if (amount <= 0) {
                                return 'Amount must be greater than 0';
                              }
                            } catch (e) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        // Split method selector - only show in create mode
                        if (!isEditMode) ...[
                          Text(
                            'Split Method',
                            style: GoogleFonts.cabin(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: appColors.textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: RadioListTile<SplitMethod>(
                                  title: Text(
                                    'Equal',
                                    style: GoogleFonts.cabin(color: appColors.textColor),
                                  ),
                                  value: SplitMethod.equal,
                                  groupValue: _splitMethod,
                                  onChanged: (value) {
                                    setState(() {
                                      _splitMethod = value!;
                                    });
                                  },
                                ),
                              ),
                              Expanded(
                                child: RadioListTile<SplitMethod>(
                                  title: Text(
                                    'Percentage Split',
                                    style: GoogleFonts.cabin(
                                      color: appColors.textColor,
                                      fontSize: 15,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  value: SplitMethod.percentage,
                                  groupValue: _splitMethod,
                                  onChanged: (value) {
                                    setState(() {
                                      _splitMethod = value!;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (!isEditMode && _splitMethod == SplitMethod.percentage) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                'Total: ',
                                style: GoogleFonts.cabin(
                                  fontWeight: FontWeight.w600,
                                  color: appColors.textColor,
                                ),
                              ),
                              Text(
                                '${_getTotalPercentage()}%',
                                style: GoogleFonts.cabin(
                                  fontWeight: FontWeight.bold,
                                  color: _getTotalPercentage() == 100
                                      ? Theme.of(context).colorScheme.secondary
                                      : Theme.of(context).colorScheme.error,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ),
                          if (_percentageError != null || (_getTotalPercentage() != 100 && _getTotalPercentage() > 0))
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.error.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                child: Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded, size: 18, color: Theme.of(context).colorScheme.error),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        _percentageError ?? 'Total percentage must be exactly 100%',
                                        style: GoogleFonts.cabin(
                                          color: Theme.of(context).colorScheme.error,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),
                        ],
                        // Members list - only show in create mode
                        if (!isEditMode) ...[
                          Text(
                            'Split With',
                            style: GoogleFonts.cabin(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: appColors.textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...widget.members.map((member) => _buildMemberTile(member)),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              // Submit button
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: _isProcessing
                      ? null
                      : () async {
                          if (_formKey.currentState?.validate() ?? false) {
                            if (!isEditMode && _splitMethod == SplitMethod.percentage) {
                              if (_getTotalPercentage() != 100) {
                                NotificationService().showAppNotification(
                                  context,
                                  message: 'Total percentage must be exactly 100%',
                                  icon: Icons.warning,
                                );
                                return;
                              }
                              // Validate each percentage is between 0 and 100
                              for (var entry in _selectedMembers.entries) {
                                if (entry.value) {
                                  final text = _percentageControllers[entry.key]?.text ?? '';
                                  final value = int.tryParse(text) ?? 0;
                                  if (value < 0 || value > 100) {
                                    NotificationService().showAppNotification(
                                      context,
                                      message: 'Each percentage must be between 0 and 100',
                                      icon: Icons.warning,
                                    );
                                    return;
                                  }
                                }
                              }
                            }
                            setState(() {
                              _isProcessing = true;
                            });

                            try {
                              final currentUserId = await _getCurrentUserId();
                              if (currentUserId == null) {
                                throw 'Failed to get current user ID';
                              }

                              final amount = double.tryParse(_amountController.text);
                              if (amount == null) {
                                throw 'Invalid amount format';
                              }

                              if (isEditMode) {
                                // Edit existing expense
                                context.read<GroupExpenseBloc>().add(
                                  EditGroupExpense(
                                    expenseId: widget.existingExpense!['expense_id'].toString(),
                                    groupId: widget.groupId,
                                    description: _titleController.text.trim(),
                                    amount: amount,
                                  ),
                                );
                              } else {
                                // Add new expense
                                final selectedMembers = widget.members
                                    .where((m) => _selectedMembers[m['profile_code']] ?? false)
                                    .toList();
                                
                                final List<int> userIds = selectedMembers
                                    .map<int>((m) => m['id'] as int)
                                    .toList();

                                if (!userIds.contains(currentUserId)) {
                                  userIds.add(currentUserId);
                                }

                                List<Map<String, dynamic>>? splits;
                                if (_splitMethod == SplitMethod.percentage) {
                                  splits = selectedMembers.map((m) {
                                    final percentage = int.tryParse(
                                      _percentageControllers[m['profile_code']]?.text ?? '0'
                                    ) ?? 0;
                                    return {
                                      'user_id': m['id'],
                                      'percentage': percentage,
                                    };
                                  }).toList();
                                }

                                context.read<GroupExpenseBloc>().add(
                                  AddGroupExpense(
                                    groupId: widget.groupId,
                                    description: _titleController.text.trim(),
                                    amount: amount,
                                    payerId: currentUserId,
                                    userIds: userIds,
                                    splitType: _splitMethod,
                                    splits: splits,
                                  ),
                                );
                              }

                              // Listen for state changes before popping
                              bool hasError = false;
                              await for (final state in context.read<GroupExpenseBloc>().stream) {
                                if (state is GroupExpenseError) {
                                  hasError = true;
                                  NotificationService().showAppNotification(
                                    context,
                                    message: 'Failed to add expense: ${state.message}',
                                    icon: Icons.error,
                                  );
                                  break;
                                }
                                if (state is GroupExpensesLoaded) {
                                  // Successfully added and loaded new expenses
                                  if (mounted) {
                                    NotificationService().showAppNotification(
                                      context,
                                      message: isEditMode ? 'Expense updated successfully!' : 'Expense added successfully!',
                                      icon: Icons.check_circle,
                                    );
                                    Navigator.pop(context, true);
                                  }
                                  break;
                                }
                              }
                            } catch (e) {
                              NotificationService().showAppNotification(
                                context,
                                message: 'Failed to ${isEditMode ? 'update' : 'add'} expense: $e',
                                icon: Icons.error,
                              );
                            } finally {
                              setState(() {
                                _isProcessing = false;
                              });
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appColors.cardColor2,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isProcessing
                      ? const CircularProgressIndicator()
                      : Text(
                          isEditMode ? 'Save Changes' : 'Add Expense',
                          style: GoogleFonts.cabin(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 