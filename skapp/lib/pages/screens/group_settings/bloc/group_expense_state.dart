import 'package:equatable/equatable.dart';

class UserBalance {
  final String username;
  final double netBalance;
  final List<Map<String, dynamic>> owes;
  final List<Map<String, dynamic>> isOwed;

  UserBalance({
    required this.username,
    required this.netBalance,
    required this.owes,
    required this.isOwed,
  });
}

class GroupedExpenses {
  final DateTime date;
  final List<Map<String, dynamic>> expenses;

  GroupedExpenses({
    required this.date,
    required this.expenses,
  });
}

class GroupSummary {
  final double totalSpent;
  final int totalSettlements;
  final List<UserBalance> balances;

  GroupSummary({
    required this.totalSpent,
    required this.totalSettlements,
    required this.balances,
  });

  factory GroupSummary.fromData({
    required List<Map<String, dynamic>> expenses,
    required List<Map<String, dynamic>> balances,
    required List<UserBalance> userBalances,
  }) {
    double total = 0;
    for (var expense in expenses) {
      total += double.parse(expense['total_amount'].toString());
    }

    int settlements = balances.where((b) => 
      double.parse(b['balance_amount'].toString()).abs() > 0.01
    ).length;

    return GroupSummary(
      totalSpent: total,
      totalSettlements: settlements,
      balances: userBalances,
    );
  }
}

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
  final List<Map<String, dynamic>> members;
  final List<Map<String, dynamic>> balances;
  final List<GroupedExpenses> groupedExpenses;
  final GroupSummary summary;

  GroupExpensesLoaded({
    required this.expenses,
    required this.members,
    required this.balances,
    required this.groupedExpenses,
    required this.summary,
  });

  @override
  List<Object?> get props => [expenses, members, balances, groupedExpenses, summary];
}
