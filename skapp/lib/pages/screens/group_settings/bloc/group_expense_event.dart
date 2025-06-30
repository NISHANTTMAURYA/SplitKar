import 'package:equatable/equatable.dart';
import '../../expense_components/add_expense_sheet.dart';

abstract class GroupExpenseEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadGroupExpenses extends GroupExpenseEvent {
  final int groupId;
  LoadGroupExpenses(this.groupId);

  @override
  List<Object?> get props => [groupId];
}

class LoadGroupBalances extends GroupExpenseEvent {
  final int groupId;
  LoadGroupBalances(this.groupId);

  @override
  List<Object?> get props => [groupId];
}

class AddGroupExpense extends GroupExpenseEvent {
  final int groupId;
  final String description;
  final double amount;
  final int payerId;
  final List<int> userIds;
  final SplitMethod splitType;
  final List<Map<String, dynamic>>? splits;

  AddGroupExpense({
    required this.groupId,
    required this.description,
    required this.amount,
    required this.payerId,
    required this.userIds,
    required this.splitType,
    this.splits,
  });

  @override
  List<Object?> get props => [groupId, description, amount, payerId, userIds, splitType, splits];
}

class EditGroupExpense extends GroupExpenseEvent {
  final String expenseId;
  final int groupId;
  final String description;
  final double amount;

  EditGroupExpense({
    required this.expenseId,
    required this.groupId,
    required this.description,
    required this.amount,
  });

  @override
  List<Object?> get props => [expenseId, groupId, description, amount];
}
