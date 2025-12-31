import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:FitStart/services/local_chat_service.dart';
import 'package:FitStart/services/api_service.dart';
import 'package:FitStart/theme.dart';

class ChatView extends StatefulWidget {
  final String? conversationId;
  final String? venueId;
  final String? venueType;
  final String? venueName;
  final String? venueEmail;
  final String? initialMessage;

  const ChatView({
    Key? key,
    this.conversationId,
    this.venueId,
    this.venueType,
    this.venueName,
    this.venueEmail,
    this.initialMessage,
  }) : super(key: key);

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _currentConversationId;
  String? _userEmail;
  String? _venueEmail;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    try {
      // Try to get current user email from API
      final userResult = await ApiService.getCurrentUser();
      if (userResult['success'] && userResult['data'] != null) {
        _userEmail = userResult['data']['email'];
      } else {
        // Fallback: Try to get from local cache
        try {
          final box = await Hive.openBox('user_cache');
          final cachedEmail = box.get('email') as String?;
          _userEmail = cachedEmail ?? 'user@fitstart.com';
        } catch (_) {
          _userEmail = 'user@fitstart.com';
        }
      }
      
      _venueEmail = widget.venueEmail ?? 'abhjha597@gmail.com';
      
      if (widget.conversationId != null) {
        _currentConversationId = widget.conversationId;
        await _loadMessages();
      } else if (widget.venueId != null) {
        await _checkOrStartConversation();
      }
    } catch (e) {
      // Don't show error - just use default values
      _userEmail = 'user@fitstart.com';
      _venueEmail = widget.venueEmail ?? 'abhjha597@gmail.com';
      
      if (widget.venueId != null) {
        await _checkOrStartConversation();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkOrStartConversation() async {
    // Check for existing conversation locally
    final existingResult = await LocalChatService.findExistingConversation(
      venueId: widget.venueId!,
      venueType: widget.venueType ?? 'sports_venue',
      userEmail: _userEmail,
    );

    if (existingResult['success'] && existingResult['data'] != null) {
      _currentConversationId = existingResult['data']['_id'];
      await _loadMessages();
    } else {
      // Start new conversation
      await _startNewConversation();
    }
  }

  Future<void> _startNewConversation() async {
    final result = await LocalChatService.startConversation(
      venueId: widget.venueId!,
      venueType: widget.venueType ?? 'sports_venue',
      venueName: widget.venueName ?? 'Venue',
      venueEmail: _venueEmail!,
      userEmail: _userEmail!,
      initialMessage: widget.initialMessage,
    );

    if (result['success']) {
      _currentConversationId = result['data']['_id'];
      await _loadMessages();
    } else {
      _showError('Failed to start conversation: ${result['error']}');
    }
  }

  Future<void> _loadMessages() async {
    if (_currentConversationId == null) return;

    final result = await LocalChatService.getConversation(_currentConversationId!);

    if (result['success']) {
      if (mounted) {
        setState(() {
          _messages = List<Map<String, dynamic>>.from(result['data']['messages'] ?? []);
        });
        _scrollToBottom();
        
        // Mark as read
        LocalChatService.markAsRead(_currentConversationId!);
      }
    } else {
      _showError('Failed to load messages: ${result['error']}');
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    
    // Start conversation if not yet started
    if (_currentConversationId == null && widget.venueId != null) {
      // Try API first, fallback to local storage
      final apiResult = await ApiService.startConversation(
        venueId: widget.venueId!,
        venueType: widget.venueType ?? 'sports_venue',
        venueName: widget.venueName ?? 'Venue',
        venueEmail: _venueEmail!,
        initialMessage: message,
      );

      if (apiResult['success']) {
        _currentConversationId = apiResult['data']['_id'];
        _messageController.clear();
        // Trigger auto-reply from venue (after 2 seconds)
        LocalChatService.simulateVenueReply(
          conversationId: _currentConversationId!,
          venueEmail: _venueEmail!,
        );
        await _loadMessages();
        return;
      }

      // Fallback to local storage if API fails
      final localResult = await LocalChatService.startConversation(
        venueId: widget.venueId!,
        venueType: widget.venueType ?? 'sports_venue',
        venueName: widget.venueName ?? 'Venue',
        venueEmail: _venueEmail!,
        userEmail: _userEmail!,
        initialMessage: message,
      );
      
      if (localResult['success']) {
        _currentConversationId = localResult['data']['_id'];
        _messageController.clear();
        LocalChatService.simulateVenueReply(
          conversationId: _currentConversationId!,
          venueEmail: _venueEmail!,
        );
        await _loadMessages();
      }
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      // Try API first
      final apiResult = await ApiService.sendMessage(
        conversationId: _currentConversationId!,
        message: message,
      );

      if (apiResult['success']) {
        _messageController.clear();
        await _loadMessages();
        if (mounted) {
          setState(() {
            _isSending = false;
          });
        }
        return;
      }

      // Fallback to local storage if API fails
      final localResult = await LocalChatService.sendMessage(
        conversationId: _currentConversationId!,
        message: message,
        senderEmail: _userEmail!,
      );

      if (localResult['success']) {
        _messageController.clear();
        await _loadMessages();
      } else {
        _showError('Failed to send message: ${localResult['error']}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showError(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: Colors.red,
      ),
    );
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.venueName ?? 'Chat',
              style: titleTextStyle.copyWith(fontSize: 18),
            ),
            if (_venueEmail != null)
              Text(
                _venueEmail!,
                style: descTextStyle.copyWith(fontSize: 12),
              ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: neonGreen.withOpacity(0.2),
              child: Icon(
                Icons.business,
                size: 20,
                color: neonGreen,
              ),
            ),
          ),
        ],
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: backgroundColor,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          return _buildMessageBubble(message);
                        },
                      ),
          ),

          // Message Input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
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
              'Start a conversation',
              style: titleTextStyle.copyWith(
                color: textPrimary,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Send a message to ${widget.venueName ?? 'the venue owner'}',
              style: descTextStyle.copyWith(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Your message: $_userEmail',
              style: descTextStyle.copyWith(
                fontSize: 12,
                color: textSecondary,
              ),
            ),
            Text(
              'Venue owner: $_venueEmail',
              style: descTextStyle.copyWith(
                fontSize: 12,
                color: textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isMe = message['sender'] == 'user' || message['senderType'] == 'user';
    final timestamp = DateTime.tryParse(message['timestamp'] ?? '') ?? DateTime.now();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) _buildAvatar(false),
          if (!isMe) const SizedBox(width: 8),
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isMe ? [
                    neonGreen,
                    neonGreen.withOpacity(0.8),
                  ] : [
                    Colors.white,
                    surfaceColor.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                border: isMe ? null : Border.all(color: borderColor.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: (isMe ? neonGreen : primaryColor500).withOpacity(0.1),
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message['message'] ?? '',
                    style: normalTextStyle.copyWith(
                      color: isMe ? Colors.black : textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimestamp(timestamp),
                    style: descTextStyle.copyWith(
                      fontSize: 12,
                      color: isMe ? Colors.black54 : textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (isMe) const SizedBox(width: 8),
          if (isMe) _buildAvatar(true),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    
    if (diff.inDays > 0) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildAvatar(bool isMe) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isMe ? neonGreen.withOpacity(0.2) : primaryColor500.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isMe ? Icons.person : Icons.business,
        size: 18,
        color: isMe ? neonGreen : primaryColor500,
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            surfaceColor.withOpacity(0.5),
          ],
        ),
        border: const Border(
          top: BorderSide(color: borderColor, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor500.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: neonGreen, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.9),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onFieldSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: const BoxDecoration(
                color: neonGreen,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _isSending ? null : _sendMessage,
                icon: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Icon(
                        Icons.send,
                        color: Colors.black,
                        size: 20,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}