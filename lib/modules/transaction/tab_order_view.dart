import 'package:flutter/material.dart';
import 'package:FitStart/services/local_booking_service.dart';
import 'package:intl/intl.dart';
import 'package:FitStart/theme.dart';
import 'package:FitStart/components/no_transaction_message.dart';

class OrderView extends StatefulWidget {
  const OrderView({Key? key}) : super(key: key);

  @override
  State<OrderView> createState() => _OrderViewState();
}

class _OrderViewState extends State<OrderView> with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  
  @override
  bool get wantKeepAlive => false; // Don't keep alive to ensure fresh data

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }
  
  @override
  void didUpdateWidget(OrderView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload when widget updates
    _loadOrders();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload when returning to this screen
    if (mounted) {
      _loadOrders();
    }
  }

  Future<void> _loadOrders() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);

    try {
      // Use LocalBookingService with fallback to demo data
      final result = await LocalBookingService.getBookingsWithFallback();
      
      if (result['success'] == true && mounted) {
        final List<dynamic> rawOrders = result['data'] ?? [];
        
        // Normalize data to match expected format
        final normalizedOrders = rawOrders.map((order) {
          // Handle both old (Supabase) and new (MongoDB) formats
          return {
            'id': order['_id'] ?? order['id'],
            'venue_name': order['venue']?['name'] ?? order['venue_name'] ?? 'Unknown Venue',
            'venue_id': order['venue']?['_id'] ?? order['venue']?['id'] ?? order['venue_id'],
            'venue_type': order['venue']?['type'] ?? order['venue_type'] ?? 'Sport',
            'booking_date': order['bookingDate'] ?? order['booking_date'],
            'booking_times': order['timeSlots'] != null 
                ? (order['timeSlots'] as List).map((slot) => '${slot['startTime']} - ${slot['endTime']}').toList()
                : (order['booking_times'] ?? []),
            'total_amount': order['pricing']?['totalAmount']?.toInt() ?? order['total_amount'] ?? 0,
            'payment_status': _mapPaymentStatus(order),
            'payment_method': order['payment']?['method'] ?? order['payment_method'] ?? 'unknown',
            'booking_status': order['bookingStatus'] ?? order['booking_status'] ?? 'pending',
            'created_at': order['createdAt'] ?? order['created_at'] ?? DateTime.now().toIso8601String(),
            'venue_address': order['venue']?['address'] ?? order['venue_address'] ?? '',
            'venue_phone': order['venue']?['phoneNumber'] ?? order['venue_phone'] ?? '',
            'razorpay_payment_id': order['payment']?['paymentId'] ?? order['razorpay_payment_id'],
          };
        }).toList();
        
        setState(() {
          _orders = normalizedOrders;
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading orders: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  String _mapPaymentStatus(Map<String, dynamic> order) {
    // Handle both formats
    final paymentStatus = order['payment']?['status'] ?? order['payment_status'];
    final bookingStatus = order['bookingStatus'] ?? order['booking_status'];
    
    if (paymentStatus == 'completed' || bookingStatus == 'confirmed') {
      return 'paid';
    } else if (paymentStatus == 'pending' && bookingStatus == 'pending') {
      return 'pending';
    } else {
      return paymentStatus ?? 'pending';
    }
  }

  List<Map<String, dynamic>> get _filteredOrders {
    if (_selectedFilter == 'All') return _orders;
    return _orders
        .where((order) =>
            order['payment_status'] ==
            _selectedFilter.toLowerCase().replaceAll(' ', '_'))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Paid'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Pay at Venue'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Pending'),
                ],
              ),
            ),
          ),
          // Orders List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredOrders.isEmpty
                    ? Center(
                        child: SingleChildScrollView(
                          child: NoTranscationMessage(
                            messageTitle: "No Transactions, yet.",
                            messageDesc:
                                "You have never placed an order. Let's explore the sport venue near you.",
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadOrders,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredOrders.length,
                          itemBuilder: (BuildContext context, int index) {
                            final order = _filteredOrders[index];
                            return _buildOrderCard(order);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedFilter = label);
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

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final paymentStatus = order['payment_status'] as String;
    final bookingTimes = List<String>.from(order['booking_times'] ?? []);
    final createdAt = DateTime.parse(order['created_at']);
    final statusColor = _getStatusColor(paymentStatus);
    final statusBgColor = statusColor.withOpacity(0.1);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: neutral200, width: 1),
      ),
      child: InkWell(
        onTap: () => _showOrderDetails(order),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      order['venue_name'],
                      style: subTitleTextStyle.copyWith(fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor, width: 1.5),
                    ),
                    child: Text(
                      _getStatusLabel(paymentStatus),
                      style: normalTextStyle.copyWith(
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Booking Date
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    order['booking_date'],
                    style: normalTextStyle.copyWith(
                      color: textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Time Slots
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      bookingTimes.join(', '),
                      style: normalTextStyle.copyWith(
                        color: textSecondary,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Divider
              Divider(color: neutral200, height: 1),
              const SizedBox(height: 12),
              // Footer Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Amount',
                        style: descTextStyle.copyWith(fontSize: 12),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '₹${order['total_amount']}',
                        style: priceTextStyle.copyWith(fontSize: 18),
                      ),
                    ],
                  ),
                  Text(
                    _formatDate(createdAt),
                    style: descTextStyle.copyWith(
                      fontSize: 12,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'paid':
        return successColor;
      case 'pay_at_venue':
        return oliveGold;
      case 'pending':
        return skyBlue;
      case 'failed':
        return errorColor;
      default:
        return neutral400;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'paid':
        return 'Paid';
      case 'pay_at_venue':
        return 'Pay at Venue';
      case 'pending':
        return 'Pending';
      case 'failed':
        return 'Failed';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today, ${DateFormat('h:mm a').format(date)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    final bookingTimes = List<String>.from(order['booking_times'] ?? []);
    final paymentStatus = order['payment_status'] as String;
    final paymentMethod = order['payment_method'] as String?;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: colorWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: neutral200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Title
            Text('Order Details', style: titleTextStyle),
            const SizedBox(height: 20),
            // Details
            _buildDetailRow('Venue', order['venue_name']),
            _buildDetailRow('Type', order['venue_type']),
            _buildDetailRow('Booking Date', order['booking_date']),
            _buildDetailRow('Time Slots', bookingTimes.join(', ')),
            _buildDetailRow('Total Amount', '₹${order['total_amount']}'),
            _buildDetailRow('Payment Status', _getStatusLabel(paymentStatus)),
            if (paymentMethod != null)
              _buildDetailRow(
                  'Payment Method',
                  paymentMethod == 'razorpay'
                      ? 'Online (Razorpay)'
                      : 'Pay at Venue'),
            if (order['razorpay_payment_id'] != null)
              _buildDetailRow('Payment ID', order['razorpay_payment_id']),
            const SizedBox(height: 24),
            // Close Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(borderRadiusSize),
                  ),
                ),
                child: Text('Close', style: buttonTextStyle),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: descTextStyle.copyWith(
                fontSize: 14,
                color: textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: normalTextStyle.copyWith(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
