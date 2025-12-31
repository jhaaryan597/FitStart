import 'package:flutter/material.dart';
import 'package:FitStart/services/local_booking_service.dart';
import 'package:intl/intl.dart';
import 'package:FitStart/theme.dart';
import 'package:FitStart/components/no_transaction_message.dart';

class TabHistoryView extends StatefulWidget {
  const TabHistoryView({Key? key}) : super(key: key);

  @override
  State<TabHistoryView> createState() => _TabHistoryViewState();
}

class _TabHistoryViewState extends State<TabHistoryView> with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;
  String _selectedPeriod = 'All Time';
  
  @override
  bool get wantKeepAlive => false; // Don't keep alive to ensure fresh data

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }
  
  @override
  void didUpdateWidget(TabHistoryView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload when widget updates
    _loadHistory();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload when returning to this screen
    if (mounted) {
      _loadHistory();
    }
  }

  Future<void> _loadHistory() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);

    try {
      // Use LocalBookingService with fallback
      final result = await LocalBookingService.getBookingsWithFallback();
      
      if (result['success'] == true && mounted) {
        final List<dynamic> allBookings = result['data'] ?? [];
        
        // Filter for paid/completed bookings and normalize data
        final paidBookings = allBookings.where((booking) {
          final paymentStatus = booking['payment']?['status'] ?? booking['payment_status'];
          final bookingStatus = booking['bookingStatus'] ?? booking['booking_status'];
          return bookingStatus == 'confirmed' || 
                 bookingStatus == 'completed' ||
                 paymentStatus == 'completed' || 
                 paymentStatus == 'paid';
        }).map((order) {
          // Normalize data format
          return {
            'id': order['_id'] ?? order['id'],
            'venue_name': order['venue']?['name'] ?? order['venue_name'] ?? 'Unknown Venue',
            'venue_id': order['venue']?['_id'] ?? order['venue']?['id'] ?? order['venue_id'],
            'booking_date': order['bookingDate'] ?? order['booking_date'],
            'booking_times': order['timeSlots'] != null 
                ? (order['timeSlots'] as List).map((slot) => '${slot['startTime']} - ${slot['endTime']}').toList()
                : (order['booking_times'] ?? []),
            'total_amount': order['pricing']?['totalAmount']?.toInt() ?? order['total_amount'] ?? 0,
            'payment_status': 'paid',
            'payment_method': order['payment']?['method'] ?? order['payment_method'] ?? 'unknown',
            'booking_status': order['bookingStatus'] ?? order['booking_status'] ?? 'confirmed',
            'created_at': order['createdAt'] ?? order['created_at'] ?? DateTime.now().toIso8601String(),
            'venue_address': order['venue']?['address'] ?? order['venue_address'] ?? '',
          };
        }).toList();
        
        setState(() {
          _history = paidBookings;
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading history: $e');
      if (mounted) setState(() => _isLoading = false);
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
    super.build(context); // Required for AutomaticKeepAliveClientMixin
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
