import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skapp/utils/app_colors.dart';

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
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid amount';
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
                    : () {
                        if (_formKey.currentState?.validate() ?? false) {
                          // TODO: Implement expense creation
                          Navigator.pop(context, true);
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