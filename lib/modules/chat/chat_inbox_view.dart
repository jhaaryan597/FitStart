import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:FitStart/services/local_chat_service.dart';
import 'package:FitStart/modules/chat/chat_view.dart';
import 'package:FitStart/theme.dart';

/// Chat Inbox - shows all conversations for the current user
/// User can be both a customer (chatting with venues) and a venue owner (receiving inquiries)
class ChatInboxView extends StatefulWidget {
  const ChatInboxView({Key? key}) : super(key: key);

  @override
  State<ChatInboxView> createState() => _ChatInboxViewState();
}

class _ChatInboxViewState extends State<ChatInboxView> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _customerConversations = [];
  List<Map<String, dynamic>> _ownerConversations = [];
  bool _isLoading = true;
  String? _userEmail;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadConversations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);
    
    try {
      // Get current user email
      final userBox = await Hive.openBox('user_cache');
      _userEmail = userBox.get('email') as String?;
      
      if (_userEmail == null) {
        setState(() => _isLoading = false);
        return;
      }
      
      // Get all conversations where user is the customer
      final customerResult = await LocalChatService.getUserConversations(_userEmail!);
      if (customerResult['success']) {
        _customerConversations = List<Map<String, dynamic>>.from(customerResult['data'] ?? []);
      }
      
      // Get all conversations where user is the venue owner (someone messaged them)
      final ownerResult = await LocalChatService.getOwnerConversations(_userEmail!);
      if (ownerResult['success']) {
        _ownerConversations = List<Map<String, dynamic>>.from(ownerResult['data'] ?? []);
      }
    } catch (e) {
      print('Error loading conversations: $e');
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Messages',
          style: titleTextStyle,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: backgroundColor,
          statusBarIconBrightness: Brightness.dark,
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: neonGreen,
          unselectedLabelColor: textSecondary,
          indicatorColor: neonGreen,
          indicatorWeight: 3,
          labelStyle: normalTextStyle.copyWith(fontWeight: FontWeight.w600),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_outline, size: 20),
                  const SizedBox(width: 8),
                  const Text('My Chats'),
                  if (_getUnreadCount(_customerConversations) > 0) ...[
                    const SizedBox(width: 8),
                    _buildUnreadBadge(_getUnreadCount(_customerConversations)),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.business_outlined, size: 20),
                  const SizedBox(width: 8),
                  const Text('Inquiries'),
                  if (_getUnreadCount(_ownerConversations) > 0) ...[
                    const SizedBox(width: 8),
                    _buildUnreadBadge(_getUnreadCount(_ownerConversations)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: neonGreen))
          : TabBarView(
              controller: _tabController,
              children: [
                // My Chats - where user is customer
                _buildConversationsList(
                  _customerConversations,
                  emptyMessage: 'No conversations yet',
                  emptySubtitle: 'Start chatting with venues by tapping the chat icon on any venue',
                  isOwnerView: false,
                ),
                // Inquiries - where user is venue owner
                _buildConversationsList(
                  _ownerConversations,
                  emptyMessage: 'No inquiries yet',
                  emptySubtitle: 'When customers message your venue, they\'ll appear here',
                  isOwnerView: true,
                ),
              ],
            ),
    );
  }

  Widget _buildUnreadBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count > 9 ? '9+' : count.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  int _getUnreadCount(List<Map<String, dynamic>> conversations) {
    return conversations.fold(0, (sum, conv) => sum + ((conv['unreadCount'] ?? 0) as int));
  }

  Widget _buildConversationsList(
    List<Map<String, dynamic>> conversations, {
    required String emptyMessage,
    required String emptySubtitle,
    required bool isOwnerView,
  }) {
    if (conversations.isEmpty) {
      return _buildEmptyState(emptyMessage, emptySubtitle);
    }

    return RefreshIndicator(
      onRefresh: _loadConversations,
      color: neonGreen,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: conversations.length,
        itemBuilder: (context, index) {
          final conversation = conversations[index];
          return _buildConversationTile(conversation, isOwnerView);
        },
      ),
    );
  }

  Widget _buildEmptyState(String message, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: neonGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                size: 48,
                color: neonGreen,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: titleTextStyle.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: descTextStyle,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationTile(Map<String, dynamic> conversation, bool isOwnerView) {
    final venueName = conversation['venueName'] ?? 'Unknown';
    final lastMessage = conversation['lastMessage'] ?? '';
    final lastMessageTime = DateTime.tryParse(conversation['lastMessageTime'] ?? '') ?? DateTime.now();
    final unreadCount = conversation['unreadCount'] ?? 0;
    final userEmail = conversation['userEmail'] ?? '';
    final venueEmail = conversation['venueEmail'] ?? '';
    
    // For owner view, show who sent the message
    final displayName = isOwnerView ? 'Customer: $userEmail' : venueName;
    final displaySubtitle = isOwnerView ? venueName : venueEmail;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatView(
              conversationId: conversation['_id'],
              venueId: conversation['venueId'],
              venueType: conversation['venueType'],
              venueName: venueName,
              venueEmail: venueEmail,
            ),
          ),
        ).then((_) => _loadConversations());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
          border: unreadCount > 0 
            ? Border.all(color: neonGreen.withOpacity(0.5), width: 2)
            : null,
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isOwnerView 
                  ? Colors.blue.withOpacity(0.2)
                  : neonGreen.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isOwnerView ? Icons.person : Icons.business,
                color: isOwnerView ? Colors.blue : neonGreen,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          isOwnerView ? displaySubtitle : displayName,
                          style: normalTextStyle.copyWith(
                            fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatTime(lastMessageTime),
                        style: descTextStyle.copyWith(
                          fontSize: 12,
                          color: unreadCount > 0 ? neonGreen : textSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (isOwnerView) ...[
                    const SizedBox(height: 2),
                    Text(
                      displayName,
                      style: descTextStyle.copyWith(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMessage.isNotEmpty ? lastMessage : 'No messages yet',
                          style: descTextStyle.copyWith(
                            fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: neonGreen,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inDays > 7) {
      return '${time.day}/${time.month}/${time.year}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
