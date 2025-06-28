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
    _loadData();
  }

  Future<void> _loadData() async {
    // TODO: Load actual data from backend
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    
    setState(() {
      _members = [
        {'username': 'You', 'profile_code': 'USER123', 'profile_pic': ''},
        {'username': 'John', 'profile_code': 'JOHN456', 'profile_pic': ''},
        {'username': 'Alice', 'profile_code': 'ALICE789', 'profile_pic': ''},
      ];
      
      _expenses = [
        {
          'id': '1',
          'title': 'Dinner at Restaurant',
          'amount': 1500.0,
          'paid_by': 'You',
          'paid_by_profile_pic': '',
          'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
          'is_user_expense': true,
          'split_with': [
            {'name': 'John', 'amount': 500.0, 'profilePic': ''},
            {'name': 'Alice', 'amount': 500.0, 'profilePic': ''},
            {'name': 'You', 'amount': 500.0, 'profilePic': ''},
          ],
        },
        {
          'id': '2',
          'title': 'Movie Tickets',
          'amount': 900.0,
          'paid_by': 'John',
          'paid_by_profile_pic': '',
          'timestamp': DateTime.now().subtract(const Duration(days: 1)),
          'is_user_expense': false,
          'split_with': [
            {'name': 'John', 'amount': 300.0, 'profilePic': ''},
            {'name': 'Alice', 'amount': 300.0, 'profilePic': ''},
            {'name': 'You', 'amount': 300.0, 'profilePic': ''},
          ],
        },
        {
          'id': '3',
          'title': 'Groceries',
          'amount': 2400.0,
          'paid_by': 'Alice',
          'paid_by_profile_pic': '',
          'timestamp': DateTime.now().subtract(const Duration(days: 2)),
          'is_user_expense': false,
          'split_with': [
            {'name': 'John', 'amount': 800.0, 'profilePic': ''},
            {'name': 'Alice', 'amount': 800.0, 'profilePic': ''},
            {'name': 'You', 'amount': 800.0, 'profilePic': ''},
          ],
        },
      ];
      
      _isLoading = false;
    });
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
          title: GestureDetector(
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
                      '${_members.length} members',
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

  Widget _buildExpensesList() {
    if (_isLoading) {
      return const Center(child: CustomLoader());
    }

    if (_expenses.isEmpty) {
      return Center(
        child: Text(
          'No expenses yet',
          style: GoogleFonts.cabin(
            color: Theme.of(context).extension<AppColorScheme>()!.textColor,
          ),
        ),
      );
    }

    // Group expenses by date
    final groupedExpenses = <DateTime, List<Map<String, dynamic>>>{};
    for (var expense in _expenses) {
      final date = DateTime(
        expense['timestamp'].year,
        expense['timestamp'].month,
        expense['timestamp'].day,
      );
      groupedExpenses.putIfAbsent(date, () => []).add(expense);
    }

    // Sort dates in descending order
    final sortedDates = groupedExpenses.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 80), // Space for FAB
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final expenses = groupedExpenses[date]!;

        return Column(
          children: [
            DateSeparator(date: date),
            ...expenses.map((expense) => ExpenseMessage(
              title: expense['title'],
              amount: expense['amount'],
              paidBy: expense['paid_by'],
              paidByProfilePic: expense['paid_by_profile_pic'],
              splitWith: List<Map<String, dynamic>>.from(expense['split_with']),
              timestamp: expense['timestamp'],
              isUserExpense: expense['is_user_expense'],
              onTap: () {
                ExpenseDetailsSheet.show(
                  context,
                  expense,
                  onEdit: () {
                    // TODO: Implement edit functionality
                    // For now, we'll just show the add expense sheet with pre-filled data
                    AddExpenseSheet.show(
                      context,
                      widget.groupId,
                      _members,
                    ).then((shouldRefresh) {
                      if (shouldRefresh ?? false) {
                        _loadData();
                      }
                    });
                  },
                  onDelete: () {
                    // TODO: Implement delete functionality
                    _loadData();
                  },
                );
              },
              onLongPress: () {
                // Show a quick action menu
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
                          AddExpenseSheet.show(
                            context,
                            widget.groupId,
                            _members,
                          ).then((shouldRefresh) {
                            if (shouldRefresh ?? false) {
                              _loadData();
                            }
                          });
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.delete, color: Colors.red),
                        title: const Text('Delete Expense', style: TextStyle(color: Colors.red)),
                        onTap: () {
                          Navigator.pop(context);
                          // TODO: Implement delete functionality
                          _loadData();
                        },
                      ),
                    ],
                  ),
                );
              },
            )),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorScheme>()!;
    
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildExpenseSummaryCard(),
          Expanded(
            child: _buildExpensesList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          AddExpenseSheet.show(
            context,
            widget.groupId,
            _members,
          ).then((shouldRefresh) {
            if (shouldRefresh ?? false) {
              _loadData();
            }
          });
        },
        backgroundColor: appColors.cardColor2,
        label: Row(
          children: [
            Icon(Icons.add, color: appColors.inverseColor),
            const SizedBox(width: 8),
            Text(
              'Add Expense',
              style: GoogleFonts.cabin(
                color: appColors.inverseColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
