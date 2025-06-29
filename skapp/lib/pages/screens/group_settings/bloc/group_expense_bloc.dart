import 'package:flutter_bloc/flutter_bloc.dart';
import '../group_expense_service.dart';
import 'group_expense_event.dart';
import 'group_expense_state.dart';
import '../group_settings_api.dart';

class GroupExpenseBloc extends Bloc<GroupExpenseEvent, GroupExpenseState> {
  final GroupExpenseService _service;
  final GroupSettingsApi _groupSettingsApi = GroupSettingsApi();

  GroupExpenseBloc(this._service) : super(GroupExpenseInitial()) {
    on<LoadGroupExpenses>(_onLoadGroupExpenses);
    on<LoadGroupBalances>(_onLoadGroupBalances);
    on<AddGroupExpense>(_onAddGroupExpense);
  }

  Future<void> _onLoadGroupExpenses(
    LoadGroupExpenses event,
    Emitter<GroupExpenseState> emit,
  ) async {
    try {
      emit(GroupExpenseLoading());
      
      // Fetch all required data
      final expenses = await _service.getGroupExpenses(event.groupId);
      final balances = await _service.getGroupBalances(event.groupId);
      final groupDetails = await _groupSettingsApi.getGroupDetails(event.groupId);
      
      // Validate responses
      if (expenses == null || balances == null || groupDetails == null) {
        throw 'Failed to fetch expense data';
      }

      // Safely extract and validate the lists
      final List<dynamic>? rawExpenses = expenses['expenses'] as List<dynamic>?;
      final List<dynamic>? rawBalances = balances['balances'] as List<dynamic>?;
      final List<dynamic>? rawMembers = groupDetails['members'] as List<dynamic>?;

      if (rawExpenses == null || rawBalances == null || rawMembers == null) {
        throw 'Invalid response format';
      }

      emit(GroupExpensesLoaded(
        expenses: rawExpenses.map((e) => e as Map<String, dynamic>).toList(),
        balances: rawBalances.map((b) => b as Map<String, dynamic>).toList(),
        members: rawMembers.map((m) => m as Map<String, dynamic>).toList(),
      ));
    } catch (e) {
      emit(GroupExpenseError(e.toString()));
    }
  }

  Future<void> _onLoadGroupBalances(
    LoadGroupBalances event,
    Emitter<GroupExpenseState> emit,
  ) async {
    try {
      emit(GroupExpenseLoading());
      final balances = await _service.getGroupBalances(event.groupId);
      
      if (balances == null) {
        throw 'Failed to fetch balance data';
      }
      
      final currentState = state;
      if (currentState is GroupExpensesLoaded) {
        final List<dynamic>? rawBalances = balances['balances'] as List<dynamic>?;
        if (rawBalances == null) {
          throw 'Invalid balance response format';
        }
        
        emit(GroupExpensesLoaded(
          expenses: currentState.expenses,
          balances: rawBalances.map((b) => b as Map<String, dynamic>).toList(),
          members: currentState.members,
        ));
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
        splitType: event.splitType,
        splits: event.splits,
      );
      
      add(LoadGroupExpenses(event.groupId));
    } catch (e) {
      emit(GroupExpenseError(e.toString()));
    }
  }
}
