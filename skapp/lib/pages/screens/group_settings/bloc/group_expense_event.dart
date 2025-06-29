import 'package:equatable/equatable.dart';

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
  final String? splitType;
  final List<Map<String, dynamic>>? splits;

  AddGroupExpense({
    required this.groupId,
    required this.description,
    required this.amount,
    required this.payerId,
    required this.userIds,
    this.splitType,
    this.splits,
  });

  @override
  List<Object?> get props => [groupId, description, amount, payerId, userIds, splitType, splits];
}
