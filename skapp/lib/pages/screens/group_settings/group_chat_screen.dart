import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
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
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
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
                            '₹1,234.56 total spent',
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
          AnimatedCrossFade(
            firstChild: const SizedBox(height: 0),
            secondChild: _buildExpandedSummary(),
            crossFadeState: _isExpenseSummaryExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedSummary() {
    final appColors = Theme.of(context).extension<AppColorScheme>()!;
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 360;
    final textScaleFactor = mediaQuery.textScaleFactor.clamp(0.8, 1.2);
    
    // TODO: This will be dynamic from backend
    final balanceDetails = [
      {
        'user': 'You',
        'netBalance': 500.0,
        'owes': [],
        'isOwed': [
          {'from': 'John', 'amount': 300.0},
          {'from': 'Alice', 'amount': 200.0},
        ],
      },
      {
        'user': 'John',
        'netBalance': -300.0,
        'owes': [
          {'to': 'You', 'amount': 300.0},
        ],
        'isOwed': [],
      },
      {
        'user': 'Alice',
        'netBalance': -200.0,
        'owes': [
          {'to': 'You', 'amount': 200.0},
        ],
        'isOwed': [],
      },
    ];

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 8),
          // Net balances
          ...balanceDetails.map((user) => _buildBalanceItem(
            name: user['user'] as String,
            amount: user['netBalance'] as double,
            isPositive: (user['netBalance'] as double) >= 0,
            appColors: appColors,
          )),
          const SizedBox(height: 16),
          // Detailed settlements
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
            
            // Add "owes to" settlements
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
            
            // Add "is owed by" settlements
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
            backgroundColor: (isPositive ? appColors.accent : appColors.borderColor3)?.withOpacity(0.1),
            child: Icon(
              isPositive ? Icons.arrow_upward : Icons.arrow_downward,
              color: isPositive ? appColors.accent : appColors.borderColor3,
              size: 16,
                  ),
                ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.cabin(
                fontSize: 14,
                color: appColors.textColor,
            ),
          ),
          ),
          Text(
            '${isPositive ? '+' : ''}₹${amount.abs()}',
            style: GoogleFonts.cabin(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isPositive ? appColors.accent : appColors.borderColor3,
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
        color: appColors.cardColor2?.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: appColors.borderColor2?.withOpacity(0.1) ?? Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.arrow_forward,
            size: 20 * textScaleFactor,
            color: appColors.iconColor?.withOpacity(0.7),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.cabin(
                  fontSize: 14 * textScaleFactor,
                  color: appColors.textColor,
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
            '₹$amount',
            style: GoogleFonts.cabin(
              fontSize: 14 * textScaleFactor,
              fontWeight: FontWeight.w600,
              color: appColors.textColor,
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
      return Center(
        child: Text(
          'No expenses yet',
          style: GoogleFonts.cabin(
            color: Theme.of(context).extension<AppColorScheme>()!.textColor,
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
      groupedExpenses.putIfAbsent(dayDate, () => []).add(expense);
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

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 80),
      reverse: false, // Keep false since we're sorting oldest to newest
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final dayExpenses = groupedExpenses[date]!;

        return Column(
          children: [
            DateSeparator(date: date),
            ...dayExpenses.map((expense) => ExpenseMessage(
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
            )),
          ],
        );
      },
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
          // Scroll to bottom when expenses are loaded
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }
      },
      child: Scaffold(
        appBar: _buildAppBar(context),
        body: Column(
          children: [
            _buildSearchBar(),
            _buildExpenseSummaryCard(),
            Expanded(
              child: BlocBuilder<GroupExpenseBloc, GroupExpenseState>(
                builder: (context, state) {
                  if (state is GroupExpenseLoading) {
                    return const Center(child: CustomLoader());
                  } else if (state is GroupExpensesLoaded) {
                    return _buildExpensesList(state.expenses);
                  } else if (state is GroupExpenseError) {
                    return Center(child: Text(state.message));
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            final state = context.read<GroupExpenseBloc>().state;
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
                  // Scroll to bottom after adding new expense
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                  });
                }
              });
            }
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
        ),
      ),
    );
  }
}
