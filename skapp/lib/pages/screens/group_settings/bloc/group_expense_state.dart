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

class SearchResult {
  final String expenseId;
  final String description;
  final double amount;
  final String payerName;
  final DateTime date;

  SearchResult({
    required this.expenseId,
    required this.description,
    required this.amount,
    required this.payerName,
    required this.date,
  });

  factory SearchResult.fromExpense(Map<String, dynamic> expense, int index) {
    return SearchResult(
      expenseId: expense['id'].toString(),
      description: expense['description'] ?? 'Untitled Expense',
      amount: double.parse(expense['total_amount'].toString()),
      payerName: expense['payer_name'] ?? 'Unknown',
      date: DateTime.parse(expense['date']),
    );
  }
}

class GroupedExpenses {
  final DateTime date;
  final List<Map<String, dynamic>> expenses;

  GroupedExpenses({required this.date, required this.expenses});
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

    int settlements = balances
        .where((b) => double.parse(b['balance_amount'].toString()).abs() > 0.01)
        .length;

    return GroupSummary(
      totalSpent: total,
      totalSettlements: settlements,
      balances: userBalances,
    );
  }
}

class GroupExpenseState extends Equatable {
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

class ExpenseCategoriesLoaded extends GroupExpenseState {
  final List<Map<String, dynamic>> categories;

  ExpenseCategoriesLoaded(this.categories);

  @override
  List<Object?> get props => [categories];
}

class GroupExpensesLoaded extends GroupExpenseState {
  final List<Map<String, dynamic>> expenses;
  final List<Map<String, dynamic>> members;
  final List<Map<String, dynamic>> balances;
  final List<GroupedExpenses> groupedExpenses;
  final GroupSummary summary;
  final List<SearchResult>? searchResults;
  final bool hasMoreExpenses;
  final int currentPage;
  final String? searchQuery;

  GroupExpensesLoaded({
    required this.expenses,
    required this.members,
    required this.balances,
    required this.groupedExpenses,
    required this.summary,
    this.searchResults,
    bool? hasMoreExpenses,
    this.currentPage = 1,
    this.searchQuery,
  }) : this.hasMoreExpenses = hasMoreExpenses ?? false;

  @override
  List<Object?> get props => [
    expenses,
    members,
    balances,
    groupedExpenses,
    summary,
    searchResults,
    hasMoreExpenses,
    currentPage,
    searchQuery,
  ];

  GroupExpensesLoaded copyWith({
    List<Map<String, dynamic>>? expenses,
    List<Map<String, dynamic>>? members,
    List<Map<String, dynamic>>? balances,
    List<GroupedExpenses>? groupedExpenses,
    GroupSummary? summary,
    List<SearchResult>? searchResults,
    bool? hasMoreExpenses,
    int? currentPage,
    String? searchQuery,
  }) {
    return GroupExpensesLoaded(
      expenses: expenses ?? this.expenses,
      members: members ?? this.members,
      balances: balances ?? this.balances,
      groupedExpenses: groupedExpenses ?? this.groupedExpenses,
      summary: summary ?? this.summary,
      searchResults: searchResults ?? this.searchResults,
      hasMoreExpenses: hasMoreExpenses ?? this.hasMoreExpenses,
      currentPage: currentPage ?? this.currentPage,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}
