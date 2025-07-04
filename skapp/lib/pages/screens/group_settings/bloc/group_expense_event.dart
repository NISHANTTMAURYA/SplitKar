import 'package:equatable/equatable.dart';
import '../../expense_components/add_expense_sheet.dart';

abstract class GroupExpenseEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadGroupExpenses extends GroupExpenseEvent {
  final int groupId;
  final bool resetPagination;

  LoadGroupExpenses(this.groupId, {this.resetPagination = false});

  @override
  List<Object?> get props => [groupId, resetPagination];
}

class LoadExpenseCategories extends GroupExpenseEvent {}

class LoadMoreExpenses extends GroupExpenseEvent {
  final int groupId;
  final int nextPage;
  final String? searchQuery;

  LoadMoreExpenses({
    required this.groupId,
    required this.nextPage,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [groupId, nextPage, searchQuery];
}

class SearchExpenses extends GroupExpenseEvent {
  final int groupId;
  final String query;

  SearchExpenses({required this.groupId, required this.query});

  @override
  List<Object?> get props => [groupId, query];
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
  final List<Map<String, dynamic>> payments;
  final List<int> userIds;
  final SplitMethod splitType;
  final List<Map<String, dynamic>>? splits;
  final int? categoryId;

  AddGroupExpense({
    required this.groupId,
    required this.description,
    required this.amount,
    required this.payments,
    required this.userIds,
    required this.splitType,
    this.splits,
    this.categoryId,
  });

  @override
  List<Object?> get props => [
    groupId,
    description,
    amount,
    payments,
    userIds,
    splitType,
    splits,
    categoryId,
  ];
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

class DeleteGroupExpense extends GroupExpenseEvent {
  final String expenseId;
  final int groupId;

  DeleteGroupExpense({required this.expenseId, required this.groupId});

  @override
  List<Object?> get props => [expenseId, groupId];
}

class DebouncedSearchExpenses extends GroupExpenseEvent {
  final int groupId;
  final String query;

  DebouncedSearchExpenses({required this.groupId, required this.query});

  @override
  List<Object?> get props => [groupId, query];
}
