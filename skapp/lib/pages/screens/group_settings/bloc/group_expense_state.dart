import 'package:equatable/equatable.dart';

abstract class GroupExpenseState extends Equatable {
  @override
  List<Object?> get props => [];
}

class GroupExpenseInitial extends GroupExpenseState {}

class GroupExpenseLoading extends GroupExpenseState {}

class GroupExpenseError extends GroupExpenseState {
  final String message;
  GroupExpenseError(this.message);

  @override
  List<Object?> get props => [message];
}

class GroupExpensesLoaded extends GroupExpenseState {
  final List<Map<String, dynamic>> expenses;
  final List<Map<String, dynamic>> balances;
  final List<Map<String, dynamic>> members;

  GroupExpensesLoaded({
    required this.expenses,
    required this.balances,
    required this.members,
  });

  @override
  List<Object?> get props => [expenses, balances, members];
}
