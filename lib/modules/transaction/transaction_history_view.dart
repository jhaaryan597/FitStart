import 'package:flutter/material.dart';
import 'package:FitStart/modules/transaction/tab_history_view.dart';
import 'package:FitStart/modules/transaction/tab_order_view.dart';
import 'package:FitStart/theme.dart';

class TransactionHistoryView extends StatefulWidget {
  final int initialTab;

  const TransactionHistoryView({Key? key, this.initialTab = 0})
      : super(key: key);

  @override
  State<TransactionHistoryView> createState() => _TransactionHistoryViewState();
}

class _TransactionHistoryViewState extends State<TransactionHistoryView>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        toolbarHeight: kTextTabBarHeight + 20,
        title: Text(
          "Transaction",
          style: titleTextStyle,
        ),
        backgroundColor: backgroundColor,
        elevation: 0.0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: colorWhite,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: primaryColor500,
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelStyle: tabBarTextStyle.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
              unselectedLabelStyle: tabBarTextStyle.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
              labelColor: colorWhite,
              unselectedLabelColor: textSecondary,
              tabs: const [
                Tab(
                  text: "📋 Order",
                  height: 44,
                ),
                Tab(
                  text: "📜 History",
                  height: 44,
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          OrderView(),
          TabHistoryView(),
        ],
      ),
    );
  }
}
