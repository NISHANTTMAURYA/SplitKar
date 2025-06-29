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
    _isLoading = true;  // Set initial loading state
    // Load expenses when screen opens
    context.read<GroupExpenseBloc>().add(
      LoadGroupExpenses(widget.groupId),
    );
  }

  void _scrollToBottom() {
    // if (!mounted) return;
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   if (_scrollController.hasClients) {
    //     _scrollController.animateTo(
    //       _scrollController.position.maxScrollExtent,
    //       duration: const Duration(milliseconds: 300),
    //       curve: Curves.easeOut,
    //     );
    //   }
    // });
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
          totalSpent = state.summary.totalSpent;
          totalSettlements = state.summary.totalSettlements;
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

        return Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: BoxDecoration(
            color: appColors.cardColor2?.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: appColors.borderColor2?.withOpacity(0.1) ?? Colors.transparent,
            ),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Spent',
                  style: GoogleFonts.cabin(
                    fontSize: 16 * textScaleFactor,
                    fontWeight: FontWeight.w600,
                    color: appColors.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '₹${state.summary.totalSpent.toStringAsFixed(2)}',
                  style: GoogleFonts.cabin(
                    fontSize: 24 * textScaleFactor,
                    fontWeight: FontWeight.bold,
                    color: appColors.textColor,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Balance Summary',
                  style: GoogleFonts.cabin(
                    fontSize: 16 * textScaleFactor,
                    fontWeight: FontWeight.w600,
                    color: appColors.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                ...state.summary.balances.map((userBalance) => _buildBalanceItem(
                  name: userBalance.username,
                  amount: userBalance.netBalance,
                  isPositive: userBalance.netBalance >= 0,
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
                ...state.summary.balances.expand((userBalance) {
                  final List<Widget> settlements = [];
                  
                  // Only show "owes" relationships to avoid duplicates
                  for (final owes in userBalance.owes) {
                    settlements.add(
                      _buildSettlementItem(
                        from: userBalance.username,
                        to: owes['to'] as String,
                        amount: owes['amount'] as double,
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

  Widget _buildExpensesList(List<GroupedExpenses> groupedExpenses) {
    if (groupedExpenses.isEmpty) {
      return SliverToBoxAdapter(
        child: _NoExpensesView(),
      );
    }

    // Convert the grouped expenses into a list of widgets
    final List<Widget> children = [];
    for (var group in groupedExpenses) {
      children.add(DateSeparator(date: group.date));
      children.addAll(group.expenses.map((expense) => Padding(
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
          timestamp: DateTime.parse(expense['date']).toLocal(),
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
          // Scroll to bottom both when first loaded and when new expense is added
          // _scrollToBottom();
          _isLoading = false;
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
                        _buildExpensesList(state.groupedExpenses),
                        const SliverPadding(
                          padding: EdgeInsets.only(bottom: 100),
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
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  Widget _buildSummaryHeader(GroupExpensesLoaded state) {
    final appColors = Theme.of(context).extension<AppColorScheme>()!;
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 360;
    final textScaleFactor = mediaQuery.textScaleFactor.clamp(0.8, 1.2);

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
                            '₹${state.summary.totalSpent.toStringAsFixed(2)} total spent • ${state.summary.totalSettlements} pending settlements',
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
                            'Total Spent: ₹${state.summary.totalSpent.toStringAsFixed(2)}',
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
                  ...state.summary.balances.map((userBalance) => _buildBalanceItem(
                    name: userBalance.username,
                    amount: userBalance.netBalance,
                    isPositive: userBalance.netBalance >= 0,
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
                  ...state.summary.balances.expand((userBalance) {
                    final List<Widget> settlements = [];
                    
                    // Only show "owes" relationships to avoid duplicates
                    for (final owes in userBalance.owes) {
                      settlements.add(
                        _buildSettlementItem(
                          from: userBalance.username,
                          to: owes['to'] as String,
                          amount: owes['amount'] as double,
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

  Widget _buildFloatingActionButton() {
    return BlocBuilder<GroupExpenseBloc, GroupExpenseState>(
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
    );
  }
}

class _NoExpensesView extends StatelessWidget {
  const _NoExpensesView();

  static Widget expensesImage(BuildContext context, {double? opacity}) {
    final double height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;
    return Center(
      child: Opacity(
        opacity: opacity ?? 1.0,
        child: Image.asset(
          'assets/images/freinds.png',
          width: width * 0.9,
          height: height * 0.4,
        ),
      ),
    );
  }

  static Widget expensesText(BuildContext context) {
    final double height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;
    final double baseSize = width < height ? width : height;
    return Center(
      child: Text(
        'Start splitting expenses with your group!',
        style: GoogleFonts.cabin(
          fontSize: baseSize * 0.035,
          color: Theme.of(context).extension<AppColorScheme>()?.textColor,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: height * 0.05),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _NoExpensesView.expensesImage(context),
          SizedBox(height: width * 0.05),
          _NoExpensesView.expensesText(context),
          SizedBox(height: width * 0.05),
        ],
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
