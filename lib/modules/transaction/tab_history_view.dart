import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:FitStart/theme.dart';
import 'package:FitStart/components/no_transaction_message.dart';

class TabHistoryView extends StatefulWidget {
  const TabHistoryView({Key? key}) : super(key: key);

  @override
  State<TabHistoryView> createState() => _TabHistoryViewState();
}

class _TabHistoryViewState extends State<TabHistoryView> {
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;
  String _selectedPeriod = 'All Time';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Get orders with paid status
      final response = await Supabase.instance.client
          .from('orders')
          .select()
          .eq('user_id', user.id)
          .eq('payment_status', 'paid')
          .order('created_at', ascending: false);

      setState(() {
        _history = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading history: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredHistory {
    if (_selectedPeriod == 'All Time') return _history;

    final now = DateTime.now();
    return _history.where((order) {
      final createdAt = DateTime.parse(order['created_at']);
      switch (_selectedPeriod) {
        case 'This Week':
          return now.difference(createdAt).inDays <= 7;
        case 'This Month':
          return createdAt.month == now.month && createdAt.year == now.year;
        case 'Last 3 Months':
          return now.difference(createdAt).inDays <= 90;
        default:
          return true;
      }
    }).toList();
  }

  Map<String, List<Map<String, dynamic>>> get _groupedHistory {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var order in _filteredHistory) {
      final createdAt = DateTime.parse(order['created_at']);
      final monthYear = DateFormat('MMMM yyyy').format(createdAt);

      if (!grouped.containsKey(monthYear)) {
        grouped[monthYear] = [];
      }
      grouped[monthYear]!.add(order);
    }

    return grouped;
  }

  int get _totalSpent {
    return _filteredHistory.fold(
        0, (sum, order) => sum + (order['total_amount'] as int));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          // Stats Card
          if (_history.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor500, primaryColor500.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor500.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        'Total Bookings',
                        '${_filteredHistory.length}',
                        Icons.receipt_long,
                      ),
                      Container(
                          width: 1,
                          height: 40,
                          color: colorWhite.withOpacity(0.3)),
                      _buildStatItem(
                        'Total Spent',
                        '₹$_totalSpent',
                        Icons.currency_rupee,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          // Period Filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPeriodChip('All Time'),
                  const SizedBox(width: 8),
                  _buildPeriodChip('This Week'),
                  const SizedBox(width: 8),
                  _buildPeriodChip('This Month'),
                  const SizedBox(width: 8),
                  _buildPeriodChip('Last 3 Months'),
                ],
              ),
            ),
          ),
          // History List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredHistory.isEmpty
                    ? Center(
                        child: SingleChildScrollView(
                          child: NoTranscationMessage(
                            messageTitle: "No Payment History, yet.",
                            messageDesc:
                                "Your completed orders will appear here.\nStart booking to see your history!",
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadHistory,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _groupedHistory.length,
                          itemBuilder: (context, index) {
                            final monthYear =
                                _groupedHistory.keys.elementAt(index);
                            final orders = _groupedHistory[monthYear]!;
                            return _buildMonthSection(monthYear, orders);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: colorWhite, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: titleTextStyle.copyWith(
            color: colorWhite,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: normalTextStyle.copyWith(
            color: colorWhite.withOpacity(0.9),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodChip(String label) {
    final isSelected = _selectedPeriod == label;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedPeriod = label);
      },
      selectedColor: primaryColor500.withOpacity(0.2),
      checkmarkColor: primaryColor500,
      labelStyle: TextStyle(
        color: isSelected ? primaryColor500 : textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 13,
      ),
    );
  }

  Widget _buildMonthSection(
      String monthYear, List<Map<String, dynamic>> orders) {
    final monthTotal = orders.fold<int>(
        0, (sum, order) => sum + (order['total_amount'] as int));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                monthYear,
                style: subTitleTextStyle.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '₹$monthTotal',
                style: normalTextStyle.copyWith(
                  color: primaryColor500,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        ...orders.map((order) => _buildHistoryCard(order)).toList(),
      ],
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> order) {
    final bookingTimes = List<String>.from(order['booking_times'] ?? []);
    final createdAt = DateTime.parse(order['created_at']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: neutral200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order['venue_name'],
                    style: normalTextStyle.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order['booking_date'],
                    style: descTextStyle.copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    bookingTimes.join(', '),
                    style: descTextStyle.copyWith(fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Amount and Date
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${order['total_amount']}',
                  style: priceTextStyle.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd MMM').format(createdAt),
                  style: descTextStyle.copyWith(fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
