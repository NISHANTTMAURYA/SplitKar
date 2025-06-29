import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skapp/utils/app_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skapp/pages/screens/group_settings/bloc/group_expense_bloc.dart';
import 'package:skapp/pages/screens/group_settings/bloc/group_expense_event.dart';
import 'package:skapp/services/auth_service.dart';

class AddExpenseSheet extends StatefulWidget {
  final int groupId;
  final List<Map<String, dynamic>> members;

  const AddExpenseSheet({
    super.key,
    required this.groupId,
    required this.members,
  });

  static Future<bool?> show(
    BuildContext context,
    int groupId,
    List<Map<String, dynamic>> members,
  ) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (_, controller) => AddExpenseSheet(
          groupId: groupId,
          members: members,
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
  String _splitMethod = 'equal'; // 'equal' or 'custom'
  final Map<String, TextEditingController> _customAmountControllers = {};
  bool _isProcessing = false;
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    // Initialize selected members map
    for (var member in widget.members) {
      _selectedMembers[member['profile_code']] = true;
      _customAmountControllers[member['profile_code']] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _customAmountControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  void _updateCustomAmounts() {
    if (_splitMethod == 'equal' && _amountController.text.isNotEmpty) {
      final totalAmount = double.tryParse(_amountController.text) ?? 0;
      final selectedCount = _selectedMembers.values.where((selected) => selected).length;
      if (selectedCount > 0) {
        final perPersonAmount = (totalAmount / selectedCount).toStringAsFixed(2);
        for (var entry in _selectedMembers.entries) {
          if (entry.value) {
            _customAmountControllers[entry.key]?.text = perPersonAmount;
          } else {
            _customAmountControllers[entry.key]?.text = '0';
          }
        }
      }
    }
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
        subtitle: _splitMethod == 'custom' && isSelected
            ? TextField(
                controller: _customAmountControllers[profileCode],
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  prefixText: '₹',
                  hintText: 'Amount',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  hintStyle: TextStyle(color: appColors.textColor2),
                ),
                style: GoogleFonts.cabin(color: appColors.textColor),
              )
            : null,
        trailing: Checkbox(
          value: isSelected,
          onChanged: (value) {
            setState(() {
              _selectedMembers[profileCode] = value ?? false;
              _updateCustomAmounts();
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
            // Title
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Add New Expense',
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
                        onChanged: (_) => _updateCustomAmounts(),
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
                      // Split method selector
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
                            child: RadioListTile(
                              title: Text(
                                'Equal',
                                style: GoogleFonts.cabin(color: appColors.textColor),
                              ),
                              value: 'equal',
                              groupValue: _splitMethod,
                              onChanged: (value) {
                                setState(() {
                                  _splitMethod = value.toString();
                                  _updateCustomAmounts();
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile(
                              title: Text(
                                'Custom',
                                style: GoogleFonts.cabin(color: appColors.textColor),
                              ),
                              value: 'custom',
                              groupValue: _splitMethod,
                              onChanged: (value) {
                                setState(() {
                                  _splitMethod = value.toString();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Members list
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
                          setState(() {
                            _isProcessing = true;
                          });

                          try {
                            // Get current user ID
                            final currentUserId = await _getCurrentUserId();
                            if (currentUserId == null) {
                              throw 'Failed to get current user ID';
                            }

                            // Safely parse amount with null check
                            final amount = double.tryParse(_amountController.text);
                            if (amount == null) {
                              throw 'Invalid amount format';
                            }

                            // Get selected user IDs and their splits
                            final selectedMembers = widget.members
                                .where((m) => _selectedMembers[m['profile_code']] ?? false)
                                .toList();
                            
                            final List<int> userIds = selectedMembers
                                .map<int>((m) => m['id'] as int)
                                .toList();

                            // Make sure current user is included in the split
                            if (!userIds.contains(currentUserId)) {
                              userIds.add(currentUserId);
                            }

                            List<Map<String, dynamic>>? splits;
                            if (_splitMethod == 'custom') {
                              splits = selectedMembers.map((m) {
                                final splitAmount = double.tryParse(
                                  _customAmountControllers[m['profile_code']]?.text ?? '0'
                                ) ?? 0.0;
                                final percentage = (splitAmount / amount * 100).toStringAsFixed(2);
                                return {
                                  'user_id': m['id'],
                                  'percentage': percentage,
                                };
                              }).toList();
                            }

                            // Add expense using bloc
                            context.read<GroupExpenseBloc>().add(
                              AddGroupExpense(
                                groupId: widget.groupId,
                                description: _titleController.text.trim(),
                                amount: amount,
                                payerId: currentUserId, // Use current user as payer
                                userIds: userIds,
                                splitType: _splitMethod == 'custom' ? 'percentage' : 'equal',
                                splits: splits,
                              ),
                            );

                            Navigator.pop(context, true);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to add expense: $e')),
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
                        'Add Expense',
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
    );
  }
} 