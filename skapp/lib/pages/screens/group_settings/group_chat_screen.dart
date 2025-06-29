import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skapp/widgets/custom_loader.dart';
import 'package:skapp/components/mobile.dart';
import 'package:skapp/pages/screens/group_settings/group_settings_page.dart';
import 'package:skapp/utils/app_colors.dart';
import 'package:skapp/pages/screens/expense_components/expense_message.dart';
import 'package:skapp/pages/screens/expense_components/date_separator.dart';
import 'package:skapp/pages/screens/expense_components/add_expense_sheet.dart';
import 'package:skapp/pages/screens/expense_components/expense_details_sheet.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skapp/pages/screens/group_settings/bloc/group_expense_bloc.dart';
import 'package:skapp/pages/screens/group_settings/bloc/group_expense_state.dart';
import 'package:skapp/pages/screens/group_settings/bloc/group_expense_event.dart';

class GroupChatScreen extends StatefulWidget {
  final String chatName;
  final String? chatImageUrl;
  final int groupId;

  const GroupChatScreen({
    super.key,
    required this.chatName,
    this.chatImageUrl,
    required this.groupId,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isExpenseSummaryExpanded = false;
  bool _isSearchVisible = false;
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<Map<String, dynamic>> _expenses = [];
  List<Map<String, dynamic>> _members = [];

  @override
  void initState() {
    super.initState();
    // Load expenses when screen opens
    context.read<GroupExpenseBloc>().add(
      LoadGroupExpenses(widget.groupId),
    );
  }

  void _scrollToBottom() {
    if (!mounted) return;
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      if (maxScroll > 0) {
        _scrollController.animateTo(
          maxScroll,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final double avatarSize = MobileUtils.getScreenWidth(context) * 0.1;
    final appColors = Theme.of(context).extension<AppColorScheme>()!;

    return PreferredSize(
      preferredSize: Size.fromHeight(MobileUtils.getScreenHeight(context) * 0.08),
        child: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: MobileUtils.getScreenHeight(context) * 0.08,
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: appColors.inverseColor),
          onPressed: () => Navigator.of(context).pop(),
          ),
        titleSpacing: 0.0,
          title: BlocBuilder<GroupExpenseBloc, GroupExpenseState>(
            builder: (context, state) {
              final memberCount = state is GroupExpensesLoaded ? state.members.length : 0;
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GroupSettingsPage(groupId: widget.groupId),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(right: MobileUtils.getScreenWidth(context) * 0.02),
                      child: CircleAvatar(
                        radius: avatarSize / 2,
                        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                        child: ClipOval(
                          child: (widget.chatImageUrl != null &&
                                  widget.chatImageUrl!.isNotEmpty &&
                                  widget.chatImageUrl!.startsWith('http'))
                              ? CachedNetworkImage(
                                  imageUrl: widget.chatImageUrl!,
                                  placeholder: (context, url) => CustomLoader(
                                    size: avatarSize * 0.6,
                                    isButtonLoader: true,
                                  ),
                                  errorWidget: (context, url, error) => Icon(
                                    Icons.groups_2_outlined,
                                    size: avatarSize * 0.6,
                                    color: appColors.iconColor2,
                                  ),
                                  width: avatarSize,
                                  height: avatarSize,
                                  fit: BoxFit.cover,
                                )
                              : Icon(
                                  Icons.groups_2_outlined,
                                  size: avatarSize * 0.6,
                                  color: appColors.iconColor2,
                                ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.chatName,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: GoogleFonts.cabin(
                              color: appColors.inverseColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$memberCount members',
                            style: GoogleFonts.cabin(
                              color: appColors.inverseColor?.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearchVisible ? Icons.close : Icons.search,
              color: appColors.inverseColor,
            ),
            onPressed: () {
              setState(() {
                _isSearchVisible = !_isSearchVisible;
                if (!_isSearchVisible) {
                  _searchController.clear();
                  // TODO: Clear search results
                }
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: appColors.inverseColor),
            onPressed: () {
              // TODO: Show more options menu
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseSummaryCard() {
    final appColors = Theme.of(context).extension<AppColorScheme>()!;
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 360;
    final textScaleFactor = mediaQuery.textScaleFactor.clamp(0.8, 1.2);
    
    return BlocBuilder<GroupExpenseBloc, GroupExpenseState>(
      builder: (context, state) {
        double totalSpent = 0;
        int totalSettlements = 0;
        
        if (state is GroupExpensesLoaded) {
          for (var expense in state.expenses) {
            totalSpent += double.parse(expense['total_amount'].toString());
          }
          totalSettlements = state.balances.where((b) => 
            double.parse(b['balance_amount'].toString()).abs() > 0.01
          ).length;
        }
        
        return Container(
          width: double.infinity,
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Container(
            margin: EdgeInsets.all(isSmallScreen ? 12 : 16),
            decoration: BoxDecoration(
              color: appColors.cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: appColors.shadowColor?.withOpacity(0.1) ?? Colors.transparent,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _isExpenseSummaryExpanded = !_isExpenseSummaryExpanded;
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: appColors.cardColor2?.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.account_balance_wallet,
                              color: appColors.iconColor,
                              size: 24 * textScaleFactor,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Group Balance',
                                  style: GoogleFonts.cabin(
                                    fontSize: 16 * textScaleFactor,
                                    fontWeight: FontWeight.w600,
                                    color: appColors.textColor,
                                  ),
                                ),
                                Text(
                                  '₹${totalSpent.toStringAsFixed(2)} total spent • $totalSettlements pending settlements',
                                  style: GoogleFonts.cabin(
                                    fontSize: 14 * textScaleFactor,
                                    color: appColors.textColor2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AnimatedRotation(
                            turns: _isExpenseSummaryExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 300),
                            child: Icon(
                              Icons.keyboard_arrow_down,
                              color: appColors.iconColor,
                              size: 24 * textScaleFactor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_isExpenseSummaryExpanded)
                  _buildExpandedSummary(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExpandedSummary() {
    final appColors = Theme.of(context).extension<AppColorScheme>()!;
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 360;
    final textScaleFactor = mediaQuery.textScaleFactor.clamp(0.8, 1.2);
    final maxHeight = mediaQuery.size.height * 0.6;

    return BlocBuilder<GroupExpenseBloc, GroupExpenseState>(
      builder: (context, state) {
        if (state is! GroupExpensesLoaded) {
          return const SizedBox(
            key: ValueKey('loading'),
            height: 100,
            child: Center(child: CustomLoader()),
          );
        }

        // Calculate total spent
        double totalSpent = 0;
        for (var expense in state.expenses) {
          totalSpent += double.parse(expense['total_amount'].toString());
        }

        // Process balances
        final List<Map<String, dynamic>> balanceDetails = [];
        final Map<int, Map<String, dynamic>> userBalances = {};

        // Initialize user balances
        for (var member in state.members) {
          userBalances[member['id']] = {
            'user': member['username'],
            'netBalance': 0.0,
            'owes': <Map<String, dynamic>>[],
            'isOwed': <Map<String, dynamic>>[],
          };
        }

        // Process each balance
        for (var balance in state.balances) {
          final user1 = balance['user1'];
          final user2 = balance['user2'];
          final amount = double.parse(balance['balance_amount'].toString());

          if (amount > 0) {
            userBalances[user1['id']]?['netBalance'] = (userBalances[user1['id']]?['netBalance'] ?? 0.0) - amount;
            userBalances[user2['id']]?['netBalance'] = (userBalances[user2['id']]?['netBalance'] ?? 0.0) + amount;
            
            userBalances[user1['id']]?['owes'].add({
              'to': user2['username'],
              'amount': amount,
            });
            userBalances[user2['id']]?['isOwed'].add({
              'from': user1['username'],
              'amount': amount,
            });
          } else if (amount < 0) {
            final absAmount = amount.abs();
            userBalances[user2['id']]?['netBalance'] = (userBalances[user2['id']]?['netBalance'] ?? 0.0) - absAmount;
            userBalances[user1['id']]?['netBalance'] = (userBalances[user1['id']]?['netBalance'] ?? 0.0) + absAmount;
            
            userBalances[user2['id']]?['owes'].add({
              'to': user1['username'],
              'amount': absAmount,
            });
            userBalances[user1['id']]?['isOwed'].add({
              'from': user2['username'],
              'amount': absAmount,
            });
          }
        }

        balanceDetails.addAll(userBalances.values);
        balanceDetails.sort((a, b) => (b['netBalance'] as double).compareTo(a['netBalance'] as double));

        return Container(
          key: const ValueKey('expanded_summary'),
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: maxHeight,
          ),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: appColors.cardColor2?.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: appColors.borderColor2?.withOpacity(0.2) ?? Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        color: appColors.iconColor,
                        size: 20 * textScaleFactor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Total Spent: ₹${totalSpent.toStringAsFixed(2)}',
                          style: GoogleFonts.cabin(
                            fontSize: 16 * textScaleFactor,
                            fontWeight: FontWeight.w600,
                            color: appColors.textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Net Balances',
                  style: GoogleFonts.cabin(
                    fontSize: 16 * textScaleFactor,
                    fontWeight: FontWeight.w600,
                    color: appColors.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                ...balanceDetails.map((user) => _buildBalanceItem(
                  name: user['user'] as String,
                  amount: user['netBalance'] as double,
                  isPositive: (user['netBalance'] as double) >= 0,
                  appColors: appColors,
                )),
                const SizedBox(height: 16),
                Text(
                  'Settlement Details',
                  style: GoogleFonts.cabin(
                    fontSize: 16 * textScaleFactor,
                    fontWeight: FontWeight.w600,
                    color: appColors.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                ...balanceDetails.expand((user) {
                  final List<Widget> settlements = [];
                  
                  for (final owes in (user['owes'] as List)) {
                    settlements.add(
                      _buildSettlementItem(
                        from: user['user'] as String,
                        to: owes['to'] as String,
                        amount: owes['amount'] as double,
                        appColors: appColors,
                        textScaleFactor: textScaleFactor,
                        isSmallScreen: isSmallScreen,
                      ),
                    );
                  }
                  
                  for (final owed in (user['isOwed'] as List)) {
                    settlements.add(
                      _buildSettlementItem(
                        from: owed['from'] as String,
                        to: user['user'] as String,
                        amount: owed['amount'] as double,
                        appColors: appColors,
                        textScaleFactor: textScaleFactor,
                        isSmallScreen: isSmallScreen,
                      ),
                    );
                  }
                  
                  return settlements;
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBalanceItem({
    required String name,
    required double amount,
    required bool isPositive,
    required AppColorScheme appColors,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: (isPositive ? Colors.green : Colors.red).withOpacity(0.2),
            child: Icon(
              isPositive ? Icons.arrow_upward : Icons.arrow_downward,
              color: isPositive ? Colors.green : Colors.red,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.cabin(
                fontSize: 14,
                color: appColors.inverseColor,
              ),
            ),
          ),
          Text(
            '${isPositive ? '+' : ''}₹${amount.abs().toStringAsFixed(2)}',
            style: GoogleFonts.cabin(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isPositive ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettlementItem({
    required String from,
    required String to,
    required double amount,
    required AppColorScheme appColors,
    required double textScaleFactor,
    required bool isSmallScreen,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
      decoration: BoxDecoration(
        color: appColors.cardColor?.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: appColors.cardColor?.withOpacity(0.2) ?? Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.arrow_forward,
            size: 20 * textScaleFactor,
            color: appColors.inverseColor?.withOpacity(0.7),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.cabin(
                  fontSize: 14 * textScaleFactor,
                  color: appColors.inverseColor,
                ),
                children: [
                  TextSpan(
                    text: from,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const TextSpan(text: ' owes '),
                  TextSpan(
                    text: to,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: GoogleFonts.cabin(
              fontSize: 14 * textScaleFactor,
              fontWeight: FontWeight.w600,
              color: appColors.inverseColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final appColors = Theme.of(context).extension<AppColorScheme>()!;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _isSearchVisible ? 60 : 0,
      child: _isSearchVisible
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search expenses...',
                  prefixIcon: Icon(Icons.search, color: appColors.iconColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: appColors.borderColor ?? Colors.transparent,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: appColors.borderColor?.withOpacity(0.2) ?? Colors.transparent,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: appColors.borderColor ?? Colors.transparent,
                    ),
                  ),
                ),
                onChanged: (value) {
                  // TODO: Implement search functionality
                },
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildExpensesList(List<Map<String, dynamic>> expenses) {
    if (expenses.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              'No expenses yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    }

    // Sort expenses by date first (oldest to newest)
    expenses.sort((a, b) {
      final dateA = DateTime.parse(a['date']);
      final dateB = DateTime.parse(b['date']);
      return dateA.compareTo(dateB);
    });

    // Group expenses by date
    final groupedExpenses = <DateTime, List<Map<String, dynamic>>>{};
    for (var expense in expenses) {
      final date = DateTime.parse(expense['date']);
      final dayDate = DateTime(date.year, date.month, date.day);
      if (!groupedExpenses.containsKey(dayDate)) {
        groupedExpenses[dayDate] = [];
      }
      groupedExpenses[dayDate]!.add(expense);
    }

    // Sort dates in ascending order (oldest first)
    final sortedDates = groupedExpenses.keys.toList()
      ..sort((a, b) => a.compareTo(b));

    // Sort expenses within each day by time (oldest first)
    for (var date in sortedDates) {
      groupedExpenses[date]!.sort((a, b) {
        final timeA = DateTime.parse(a['date']);
        final timeB = DateTime.parse(b['date']);
        return timeA.compareTo(timeB);
      });
    }

    // Convert the grouped expenses into a list of widgets
    final List<Widget> children = [];
    for (var date in sortedDates) {
      final dayExpenses = groupedExpenses[date]!;
      children.add(DateSeparator(date: date));
      children.addAll(dayExpenses.map((expense) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: ExpenseMessage(
          title: expense['description'] ?? 'Untitled Expense',
          amount: expense['total_amount'] != null 
            ? double.parse(expense['total_amount'].toString())
            : 0.0,
          paidBy: expense['payer_name'] ?? 'Unknown',
          paidByProfilePic: expense['payer_profile_pic'] ?? '',
          splitWith: (expense['owed_breakdown'] as List<dynamic>?)?.map((breakdown) => {
            'name': breakdown['name'] ?? 'Unknown',
            'amount': breakdown['amount'] ?? '0',
            'profilePic': breakdown['profilePic'] ?? '',
          }).toList() ?? [],
          timestamp: DateTime.parse(expense['date']),
          isUserExpense: expense['is_user_expense'] ?? false,
          onTap: () => _showExpenseDetails(expense),
          onLongPress: () => _showQuickActions(expense),
        ),
      )));
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => children[index],
        childCount: children.length,
      ),
    );
  }

  void _showExpenseDetails(Map<String, dynamic> expense) {
    final state = context.read<GroupExpenseBloc>().state;
    if (state is GroupExpensesLoaded) {
      ExpenseDetailsSheet.show(
        context,
        expense,
        onEdit: () {
          AddExpenseSheet.show(
            context,
            widget.groupId,
            state.members,
          ).then((shouldRefresh) {
            if (shouldRefresh ?? false) {
              context.read<GroupExpenseBloc>().add(
                LoadGroupExpenses(widget.groupId),
              );
            }
          });
        },
        onDelete: () {
          // TODO: Implement delete functionality
          context.read<GroupExpenseBloc>().add(
            LoadGroupExpenses(widget.groupId),
          );
        },
      );
    }
  }

  void _showQuickActions(Map<String, dynamic> expense) {
    final state = context.read<GroupExpenseBloc>().state;
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Expense'),
            onTap: () {
              Navigator.pop(context);
              if (state is GroupExpensesLoaded) {
                AddExpenseSheet.show(
                  context,
                  widget.groupId,
                  state.members,
                ).then((shouldRefresh) {
                  if (shouldRefresh ?? false) {
                    context.read<GroupExpenseBloc>().add(
                      LoadGroupExpenses(widget.groupId),
                    );
                  }
                });
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete Expense', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              // TODO: Implement delete functionality
              context.read<GroupExpenseBloc>().add(
                LoadGroupExpenses(widget.groupId),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<GroupExpenseBloc, GroupExpenseState>(
      listener: (context, state) {
        if (state is GroupExpenseError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        } else if (state is GroupExpensesLoaded) {
          if (!_isLoading) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToBottom();
            });
            _isLoading = false;
          }
        }
      },
      child: Scaffold(
        appBar: _buildAppBar(context),
        body: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: BlocBuilder<GroupExpenseBloc, GroupExpenseState>(
                builder: (context, state) {
                  if (state is GroupExpenseLoading) {
                    return const Center(child: CustomLoader());
                  } else if (state is GroupExpensesLoaded) {
                    return CustomScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverPersistentHeader(
                          // pinned: true,
                          floating: true,
                          delegate: _SummaryHeaderDelegate(
                            child: _buildSummaryHeader(state),
                            isExpanded: _isExpenseSummaryExpanded,
                            onToggle: (value) {
                              setState(() {
                                _isExpenseSummaryExpanded = value;
                              });
                            },
                          ),
                        ),
                        if (_isExpenseSummaryExpanded)
                          SliverToBoxAdapter(
                            child: _buildExpandedSummaryContent(state),
                          ),
                        _buildExpensesList(state.expenses),
                        const SliverPadding(
                          padding: EdgeInsets.only(bottom: 80),
                        ),
                      ],
                    );
                  } else if (state is GroupExpenseError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
        floatingActionButton: BlocBuilder<GroupExpenseBloc, GroupExpenseState>(
          builder: (context, state) {
            if (state is! GroupExpensesLoaded) return const SizedBox.shrink();
            return FloatingActionButton.extended(
              onPressed: () {
                AddExpenseSheet.show(
                  context,
                  widget.groupId,
                  state.members,
                ).then((shouldRefresh) {
                  if (shouldRefresh ?? false) {
                    context.read<GroupExpenseBloc>().add(
                      LoadGroupExpenses(widget.groupId),
                    );
                  }
                });
              },
              backgroundColor: Theme.of(context).extension<AppColorScheme>()!.cardColor2,
              label: Row(
                children: [
                  Icon(Icons.add, color: Theme.of(context).extension<AppColorScheme>()!.inverseColor),
                  const SizedBox(width: 8),
                  Text(
                    'Add Expense',
                    style: GoogleFonts.cabin(
                      color: Theme.of(context).extension<AppColorScheme>()!.inverseColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryHeader(GroupExpensesLoaded state) {
    final appColors = Theme.of(context).extension<AppColorScheme>()!;
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 360;
    final textScaleFactor = mediaQuery.textScaleFactor.clamp(0.8, 1.2);

    double totalSpent = 0;
    int totalSettlements = 0;
    
    for (var expense in state.expenses) {
      totalSpent += double.parse(expense['total_amount'].toString());
    }
    totalSettlements = state.balances.where((b) => 
      double.parse(b['balance_amount'].toString()).abs() > 0.01
    ).length;

    final borderRadius = BorderRadius.vertical(
      top: const Radius.circular(20),
      bottom: Radius.circular(_isExpenseSummaryExpanded ? 0 : 20),
    );

    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12 : 16,
        vertical: isSmallScreen ? 4 : 8,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: 84,
        decoration: BoxDecoration(
          color: appColors.cardColor2,
          borderRadius: borderRadius,
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _isExpenseSummaryExpanded = !_isExpenseSummaryExpanded;
                });
              },
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: appColors.cardColor?.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet,
                        color: appColors.inverseColor,
                        size: 24 * textScaleFactor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Group Balance',
                            style: GoogleFonts.cabin(
                              fontSize: 16 * textScaleFactor,
                              fontWeight: FontWeight.w600,
                              color: appColors.inverseColor,
                            ),
                          ),
                          Text(
                            '₹${totalSpent.toStringAsFixed(2)} total spent • $totalSettlements pending settlements',
                            style: GoogleFonts.cabin(
                              fontSize: 14 * textScaleFactor,
                              color: appColors.inverseColor?.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _isExpenseSummaryExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: appColors.inverseColor,
                        size: 24 * textScaleFactor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedSummaryContent(GroupExpensesLoaded state) {
    final appColors = Theme.of(context).extension<AppColorScheme>()!;
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 360;
    final textScaleFactor = mediaQuery.textScaleFactor.clamp(0.8, 1.2);

    // Calculate total spent
    double totalSpent = 0;
    for (var expense in state.expenses) {
      totalSpent += double.parse(expense['total_amount'].toString());
    }

    // Process balances
    final List<Map<String, dynamic>> balanceDetails = [];
    final Map<int, Map<String, dynamic>> userBalances = {};

    // Initialize user balances
    for (var member in state.members) {
      userBalances[member['id']] = {
        'user': member['username'],
        'netBalance': 0.0,
        'owes': <Map<String, dynamic>>[],
        'isOwed': <Map<String, dynamic>>[],
      };
    }

    // Process each balance
    for (var balance in state.balances) {
      final user1 = balance['user1'];
      final user2 = balance['user2'];
      final amount = double.parse(balance['balance_amount'].toString());

      if (amount > 0) {
        userBalances[user1['id']]?['netBalance'] = (userBalances[user1['id']]?['netBalance'] ?? 0.0) - amount;
        userBalances[user2['id']]?['netBalance'] = (userBalances[user2['id']]?['netBalance'] ?? 0.0) + amount;
        
        userBalances[user1['id']]?['owes'].add({
          'to': user2['username'],
          'amount': amount,
        });
        userBalances[user2['id']]?['isOwed'].add({
          'from': user1['username'],
          'amount': amount,
        });
      } else if (amount < 0) {
        final absAmount = amount.abs();
        userBalances[user2['id']]?['netBalance'] = (userBalances[user2['id']]?['netBalance'] ?? 0.0) - absAmount;
        userBalances[user1['id']]?['netBalance'] = (userBalances[user1['id']]?['netBalance'] ?? 0.0) + absAmount;
        
        userBalances[user2['id']]?['owes'].add({
          'to': user1['username'],
          'amount': absAmount,
        });
        userBalances[user1['id']]?['isOwed'].add({
          'from': user2['username'],
          'amount': absAmount,
        });
      }
    }

    balanceDetails.addAll(userBalances.values);
    balanceDetails.sort((a, b) => (b['netBalance'] as double).compareTo(a['netBalance'] as double));

    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12 : 16,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: appColors.cardColor2,
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: appColors.cardColor?.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: appColors.cardColor?.withOpacity(0.2) ?? Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          color: appColors.inverseColor,
                          size: 20 * textScaleFactor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Total Spent: ₹${totalSpent.toStringAsFixed(2)}',
                            style: GoogleFonts.cabin(
                              fontSize: 16 * textScaleFactor,
                              fontWeight: FontWeight.w600,
                              color: appColors.inverseColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Net Balances',
                    style: GoogleFonts.cabin(
                      fontSize: 16 * textScaleFactor,
                      fontWeight: FontWeight.w600,
                      color: appColors.inverseColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...balanceDetails.map((user) => _buildBalanceItem(
                    name: user['user'] as String,
                    amount: user['netBalance'] as double,
                    isPositive: (user['netBalance'] as double) >= 0,
                    appColors: appColors,
                  )),
                  const SizedBox(height: 16),
                  Text(
                    'Settlement Details',
                    style: GoogleFonts.cabin(
                      fontSize: 16 * textScaleFactor,
                      fontWeight: FontWeight.w600,
                      color: appColors.inverseColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...balanceDetails.expand((user) {
                    final List<Widget> settlements = [];
                    
                    for (final owes in (user['owes'] as List)) {
                      settlements.add(
                        _buildSettlementItem(
                          from: user['user'] as String,
                          to: owes['to'] as String,
                          amount: owes['amount'] as double,
                          appColors: appColors,
                          textScaleFactor: textScaleFactor,
                          isSmallScreen: isSmallScreen,
                        ),
                      );
                    }
                    
                    for (final owed in (user['isOwed'] as List)) {
                      settlements.add(
                        _buildSettlementItem(
                          from: owed['from'] as String,
                          to: user['user'] as String,
                          amount: owed['amount'] as double,
                          appColors: appColors,
                          textScaleFactor: textScaleFactor,
                          isSmallScreen: isSmallScreen,
                        ),
                      );
                    }
                    
                    return settlements;
                  }).toList(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final bool isExpanded;
  final ValueChanged<bool> onToggle;

  _SummaryHeaderDelegate({
    required this.child,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox(
      height: maxExtent,
      child: child,
    );
  }

  @override
  double get maxExtent => 100.0; // Reduced from 120 to ensure proper layout

  @override
  double get minExtent => 100.0; // Must match maxExtent for pinned header

  @override
  bool shouldRebuild(covariant _SummaryHeaderDelegate oldDelegate) {
    return oldDelegate.isExpanded != isExpanded || 
           oldDelegate.child != child;
  }
}
