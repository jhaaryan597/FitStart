import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:FitStart/services/chat_service.dart';
import 'package:FitStart/modules/chat/chat_view.dart';
import 'package:FitStart/theme.dart';

class ConversationsView extends StatefulWidget {
  const ConversationsView({Key? key}) : super(key: key);

  @override
  State<ConversationsView> createState() => _ConversationsViewState();
}

class _ConversationsViewState extends State<ConversationsView> {
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    try {
      final result = await ChatService.getUserConversations();
      
      if (result['success']) {
        setState(() {
          _conversations = List<Map<String, dynamic>>.from(result['data'] ?? []);
          _isLoading = false;
        });
      } else {
        _showError('Failed to load conversations: ${result['error']}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      _showError('Error loading conversations: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshConversations() async {
    setState(() {
      _isLoading = true;
    });
    await _loadConversations();
  }

  void _showError(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _openConversation(Map<String, dynamic> conversation) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatView(
          conversationId: conversation['_id'],
          venueName: conversation['venueName'],
        ),
      ),
    ).then((_) {
      // Refresh conversations when returning from chat
      _refreshConversations();
    });
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
        actions: [
          IconButton(
            onPressed: _refreshConversations,
            icon: const Icon(Icons.refresh, color: textPrimary),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _refreshConversations,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = _conversations[index];
                      return _buildConversationTile(conversation);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No conversations yet',
            style: titleTextStyle.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Start chatting with venue owners from their detail pages',
            style: descTextStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Explore Venues'),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationTile(Map<String, dynamic> conversation) {
    final lastMessage = conversation['lastMessage'] as Map<String, dynamic>?;
    final hasUnread = conversation['unreadCount'] != null && 
                     conversation['unreadCount'] > 0;
    final timestamp = conversation['updatedAt'] != null
        ? DateTime.parse(conversation['updatedAt'])
        : DateTime.now();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _openConversation(conversation),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  surfaceColor.withOpacity(0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasUnread ? neonGreen.withOpacity(0.3) : borderColor.withOpacity(0.3),
                width: hasUnread ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: (hasUnread ? neonGreen : primaryColor500).withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Venue Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: primaryColor500.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    conversation['venueType'] == 'gym'
                        ? Icons.fitness_center
                        : Icons.sports_soccer,
                    color: primaryColor500,
                    size: 24,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Conversation Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              conversation['venueName'] ?? 'Unknown Venue',
                              style: subTitleTextStyle.copyWith(
                                fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            ChatService.formatTimestamp(timestamp),
                            style: descTextStyle.copyWith(
                              fontSize: 12,
                              color: hasUnread ? neonGreen : textSecondary,
                              fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 4),
                      
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              lastMessage != null
                                  ? ChatService.getPreviewText(lastMessage['message'] ?? '')
                                  : 'No messages yet',
                              style: normalTextStyle.copyWith(
                                fontSize: 14,
                                color: hasUnread ? textPrimary : textSecondary,
                                fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          
                          if (hasUnread) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: neonGreen,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${conversation['unreadCount']}',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}