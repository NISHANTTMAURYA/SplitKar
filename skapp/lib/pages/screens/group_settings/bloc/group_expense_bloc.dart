import 'package:flutter_bloc/flutter_bloc.dart';
import '../group_expense_service.dart';
import 'group_expense_event.dart';
import 'group_expense_state.dart';
import '../group_settings_api.dart';
import 'dart:developer' as dev;
import '../../expense_components/add_expense_sheet.dart';

class GroupExpenseBloc extends Bloc<GroupExpenseEvent, GroupExpenseState> {
  final GroupExpenseService _service;
  final GroupSettingsApi _groupSettingsApi = GroupSettingsApi();

  GroupExpenseBloc(this._service) : super(GroupExpenseInitial()) {
    on<LoadGroupExpenses>(_onLoadGroupExpenses);
    on<LoadMoreExpenses>(_onLoadMoreExpenses);
    on<SearchExpenses>(_onSearchExpenses);
    on<LoadGroupBalances>(_onLoadGroupBalances);
    on<AddGroupExpense>(_onAddGroupExpense);
    on<EditGroupExpense>(_onEditGroupExpense);
    on<DeleteGroupExpense>(_onDeleteGroupExpense);
    on<LoadExpenseCategories>(_onLoadExpenseCategories);
  }

  List<GroupedExpenses> _processExpenses(List<dynamic> rawExpenses) {
    dev.log('Processing expenses: $rawExpenses');

    final expenses = rawExpenses.map((e) {
      if (e is! Map<String, dynamic>) {
        dev.log('Invalid expense format: $e');
        return <String, dynamic>{
          'date': DateTime.now().toIso8601String(),
          'total_amount': '0',
          'description': 'Invalid Expense',
        };
      }
      return e;
    }).toList();

    // Sort expenses by date (newest to oldest)
    expenses.sort((a, b) {
      final dateA = DateTime.parse(a['date'] as String);
      final dateB = DateTime.parse(b['date'] as String);
      return dateB.compareTo(dateA);
    });

    // Group expenses by date (using local time for grouping)
    final groupedExpenses = <DateTime, List<Map<String, dynamic>>>{};
    for (var expense in expenses) {
      final utcDate = DateTime.parse(expense['date'] as String);
      final localDate = utcDate.toLocal();
      final dayDate = DateTime(localDate.year, localDate.month, localDate.day);

      dev.log(
        'Expense: ${expense['description']} - UTC: $utcDate, Local: $localDate, DayDate: $dayDate',
      );

      if (!groupedExpenses.containsKey(dayDate)) {
        groupedExpenses[dayDate] = [];
      }
      groupedExpenses[dayDate]!.add(expense);
    }

    // Sort dates in descending order (newest first)
    final sortedDates = groupedExpenses.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    dev.log('Grouped dates: $sortedDates');

    // Sort expenses within each day by time (newest first)
    for (var date in sortedDates) {
      groupedExpenses[date]!.sort((a, b) {
        final timeA = DateTime.parse(a['date'] as String);
        final timeB = DateTime.parse(b['date'] as String);
        return timeB.compareTo(timeA);
      });
    }

    return sortedDates
        .map(
          (date) =>
              GroupedExpenses(date: date, expenses: groupedExpenses[date]!),
        )
        .toList();
  }

  List<UserBalance> _processBalances(
    List<dynamic> members,
    List<dynamic> balances,
  ) {
    dev.log('Processing balances with members: $members');
    dev.log('Processing balances with balances: $balances');

    final Map<int, UserBalance> userBalances = {};

    // Initialize user balances
    for (var member in members) {
      if (member is! Map<String, dynamic>) {
        dev.log('Invalid member format: $member');
        continue;
      }

      final id = member['id'];
      if (id == null) {
        dev.log('Member missing ID: $member');
        continue;
      }

      userBalances[id] = UserBalance(
        username: member['username'] as String? ?? 'Unknown',
        netBalance: 0.0,
        owes: [],
        isOwed: [],
      );
    }

    // Process each balance
    for (var balance in balances) {
      if (balance is! Map<String, dynamic>) {
        dev.log('Invalid balance format: $balance');
        continue;
      }

      final user1 = balance['user1'] as Map<String, dynamic>?;
      final user2 = balance['user2'] as Map<String, dynamic>?;
      final amount =
          double.tryParse(balance['balance_amount']?.toString() ?? '0') ?? 0.0;

      if (user1 == null || user2 == null) {
        dev.log('Invalid user data in balance: $balance');
        continue;
      }

      if (amount > 0) {
        final user1Balance = userBalances[user1['id']];
        final user2Balance = userBalances[user2['id']];

        if (user1Balance != null && user2Balance != null) {
          userBalances[user1['id']] = UserBalance(
            username: user1Balance.username,
            netBalance: user1Balance.netBalance - amount,
            owes: [
              ...user1Balance.owes,
              {'to': user2['username'], 'amount': amount},
            ],
            isOwed: user1Balance.isOwed,
          );

          userBalances[user2['id']] = UserBalance(
            username: user2Balance.username,
            netBalance: user2Balance.netBalance + amount,
            owes: user2Balance.owes,
            isOwed: [
              ...user2Balance.isOwed,
              {'from': user1['username'], 'amount': amount},
            ],
          );
        }
      } else if (amount < 0) {
        final absAmount = amount.abs();
        final user1Balance = userBalances[user1['id']];
        final user2Balance = userBalances[user2['id']];

        if (user1Balance != null && user2Balance != null) {
          userBalances[user2['id']] = UserBalance(
            username: user2Balance.username,
            netBalance: user2Balance.netBalance - absAmount,
            owes: [
              ...user2Balance.owes,
              {'to': user1['username'], 'amount': absAmount},
            ],
            isOwed: user2Balance.isOwed,
          );

          userBalances[user1['id']] = UserBalance(
            username: user1Balance.username,
            netBalance: user1Balance.netBalance + absAmount,
            owes: user1Balance.owes,
            isOwed: [
              ...user1Balance.isOwed,
              {'from': user2['username'], 'amount': absAmount},
            ],
          );
        }
      }
    }

    return userBalances.values.toList();
  }

  GroupSummary _calculateSummary(
    List<dynamic> expenses,
    List<dynamic> balances,
    List<UserBalance> processedBalances,
  ) {
    dev.log('Calculating summary with expenses: $expenses');
    dev.log('Calculating summary with balances: $balances');

    return GroupSummary.fromData(
      expenses: expenses.map((e) => e as Map<String, dynamic>).toList(),
      balances: balances.map((b) => b as Map<String, dynamic>).toList(),
      userBalances: processedBalances,
    );
  }

  Future<void> _onLoadGroupExpenses(
    LoadGroupExpenses event,
    Emitter<GroupExpenseState> emit,
  ) async {
    try {
      emit(GroupExpenseLoading());

      final expenses = await _service.getGroupExpenses(
        event.groupId,
        page: 1,
        pageSize: 5,
      );
      final members = await _groupSettingsApi.getGroupDetails(event.groupId);
      final balances = await _service.getGroupBalances(event.groupId);

      if (expenses == null || members == null || balances == null) {
        throw 'Failed to fetch data';
      }

      final expensesList =
          (expenses['expenses'] as List<dynamic>?)?.map((e) {
            if (e is! Map<String, dynamic>) {
              dev.log('Invalid expense format: $e');
              return <String, dynamic>{
                'date': DateTime.now().toIso8601String(),
                'total_amount': '0',
                'description': 'Invalid Expense',
              };
            }
            return e;
          }).toList() ??
          [];

      final membersList =
          (members['members'] as List<dynamic>?)?.map((m) {
            if (m is! Map<String, dynamic>) {
              dev.log('Invalid member format: $m');
              return <String, dynamic>{'id': -1, 'username': 'Invalid Member'};
            }
            return m;
          }).toList() ??
          [];

      final balancesList =
          (balances['balances'] as List<dynamic>?)?.map((b) {
            if (b is! Map<String, dynamic>) {
              dev.log('Invalid balance format: $b');
              return <String, dynamic>{
                'user1': {'id': -1, 'username': 'Invalid User'},
                'user2': {'id': -1, 'username': 'Invalid User'},
                'balance_amount': '0',
              };
            }
            return b;
          }).toList() ??
          [];

      final processedBalances = _processBalances(membersList, balancesList);
      final groupedExpenses = _processExpenses(expensesList);
      final summary = _calculateSummary(
        expensesList,
        balancesList,
        processedBalances,
      );

      final hasMore = expenses['pagination']?['has_next'] ?? false;

      emit(
        GroupExpensesLoaded(
          expenses: expensesList,
          members: membersList,
          balances: balancesList,
          groupedExpenses: groupedExpenses,
          summary: summary,
          hasMoreExpenses: hasMore,
          currentPage: 1,
        ),
      );
    } catch (e, stackTrace) {
      dev.log('Error in _onLoadGroupExpenses: $e\n$stackTrace');
      emit(GroupExpenseError(e.toString()));
    }
  }

  Future<void> _onLoadMoreExpenses(
    LoadMoreExpenses event,
    Emitter<GroupExpenseState> emit,
  ) async {
    try {
      if (state is! GroupExpensesLoaded) return;
      final currentState = state as GroupExpensesLoaded;

      final expenses = await _service.getGroupExpenses(
        event.groupId,
        page: event.nextPage,
        pageSize: 5,
        searchQuery: event.searchQuery,
      );

      if (expenses == null) throw 'Failed to fetch more expenses';

      final newExpenses =
          (expenses['expenses'] as List<dynamic>?)?.map((e) {
            if (e is! Map<String, dynamic>) {
              return <String, dynamic>{
                'date': DateTime.now().toIso8601String(),
                'total_amount': '0',
                'description': 'Invalid Expense',
              };
            }
            return e;
          }).toList() ??
          [];

      // Combine existing and new expenses
      final allExpenses = [...currentState.expenses, ...newExpenses];
      final groupedExpenses = _processExpenses(allExpenses);

      emit(
        currentState.copyWith(
          expenses: allExpenses,
          groupedExpenses: groupedExpenses,
          hasMoreExpenses: expenses['pagination']['has_next'] ?? false,
          currentPage: event.nextPage,
        ),
      );
    } catch (e) {
      dev.log('Error in _onLoadMoreExpenses: $e');
      // Don't emit error state, just log it
    }
  }

  Future<void> _onSearchExpenses(
    SearchExpenses event,
    Emitter<GroupExpenseState> emit,
  ) async {
    try {
      if (state is! GroupExpensesLoaded) return;
      final currentState = state as GroupExpensesLoaded;

      if (event.query.isEmpty) {
        emit(currentState.copyWith(searchResults: null, searchQuery: null));
        return;
      }

      final searchResponse = await _service.getGroupExpenses(
        event.groupId,
        searchQuery: event.query,
        searchMode: 'chat',
      );

      if (searchResponse == null) throw 'Failed to search expenses';

      if (!searchResponse.containsKey('expenses')) {
        throw 'Invalid response format: missing expenses key';
      }

      final searchExpenses = searchResponse['expenses'] as List<dynamic>;
      final searchResults = searchExpenses.map((e) {
        final Map<String, dynamic> expense = Map<String, dynamic>.from(e);
        return SearchResult(
          expenseId: expense['id'].toString(),
          description: expense['description'] ?? 'Untitled Expense',
          amount: double.parse(expense['total_amount'].toString()),
          payerName: expense['payer_name'] ?? 'Unknown',
          date: DateTime.parse(expense['date']),
        );
      }).toList();

      emit(
        currentState.copyWith(
          searchResults: searchResults,
          searchQuery: event.query,
        ),
      );
    } catch (e) {
      dev.log('Error in _onSearchExpenses: $e');
      // Don't emit error state, just log it
    }
  }

  Future<void> _onLoadGroupBalances(
    LoadGroupBalances event,
    Emitter<GroupExpenseState> emit,
  ) async {
    try {
      if (state is GroupExpensesLoaded) {
        final currentState = state as GroupExpensesLoaded;
        final balances = await _service.getGroupBalances(event.groupId);
        final processedBalances = _processBalances(
          currentState.members,
          balances['balances'],
        );
        final summary = _calculateSummary(
          currentState.expenses,
          balances['balances'],
          processedBalances,
        );

        emit(
          GroupExpensesLoaded(
            expenses: currentState.expenses,
            members: currentState.members,
            balances: balances['balances'],
            groupedExpenses: currentState.groupedExpenses,
            summary: summary,
          ),
        );
      }
    } catch (e) {
      emit(GroupExpenseError(e.toString()));
    }
  }

  Future<void> _onAddGroupExpense(
    AddGroupExpense event,
    Emitter<GroupExpenseState> emit,
  ) async {
    try {
      emit(GroupExpenseLoading());
      await _service.addGroupExpense(
        groupId: event.groupId,
        description: event.description,
        amount: event.amount,
        payerId: event.payerId,
        userIds: event.userIds,
        splitType: event.splitType == SplitMethod.percentage
            ? 'percentage'
            : 'equal',
        splits: event.splits,
        categoryId: event.categoryId,
      );

      add(LoadGroupExpenses(event.groupId));
    } catch (e) {
      emit(GroupExpenseError(e.toString()));
    }
  }

  Future<void> _onEditGroupExpense(
    EditGroupExpense event,
    Emitter<GroupExpenseState> emit,
  ) async {
    try {
      emit(GroupExpenseLoading());
      await _service.editGroupExpense(
        expenseId: event.expenseId,
        groupId: event.groupId,
        description: event.description,
        amount: event.amount,
      );

      // Reload expenses to get the updated state
      add(LoadGroupExpenses(event.groupId));
    } catch (e) {
      emit(GroupExpenseError(e.toString()));
    }
  }

  Future<void> _onDeleteGroupExpense(
    DeleteGroupExpense event,
    Emitter<GroupExpenseState> emit,
  ) async {
    print(
      '[BLOC DEBUG] _onDeleteGroupExpense called: expenseId=${event.expenseId}, groupId=${event.groupId}',
    );
    try {
      emit(GroupExpenseLoading());
      await _service.deleteGroupExpense(expenseId: event.expenseId);
      print('[BLOC DEBUG] deleteGroupExpense service call completed');
      add(LoadGroupExpenses(event.groupId));
    } catch (e) {
      print('[BLOC DEBUG] Error in _onDeleteGroupExpense: $e');
      emit(GroupExpenseError(e.toString()));
    }
  }

  Future<void> _onLoadExpenseCategories(
    LoadExpenseCategories event,
    Emitter<GroupExpenseState> emit,
  ) async {
    try {
      emit(GroupExpenseLoading());
      final categories = await _service.getExpenseCategories();
      emit(ExpenseCategoriesLoaded(categories));
    } catch (e) {
      emit(GroupExpenseError(e.toString()));
    }
  }
}
