import 'package:flutter/material.dart';
import 'package:FitStart/services/notification_service.dart';

class SendNotificationView extends StatefulWidget {
  const SendNotificationView({Key? key}) : super(key: key);

  @override
  State<SendNotificationView> createState() => _SendNotificationViewState();
}

class _SendNotificationViewState extends State<SendNotificationView> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isSending = false;
  String _targetType = 'all'; // 'all' or 'specific'

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _sendNotification() async {
    if (_titleController.text.trim().isEmpty ||
        _bodyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter title and message'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    bool success = false;

    if (_targetType == 'all') {
      success = await NotificationService.sendNotificationToAllUsers(
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        data: {
          'type': 'campaign',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    }

    setState(() => _isSending = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '✅ Notification sent successfully!'
                : '❌ Failed to send notification',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      if (success) {
        _titleController.clear();
        _bodyController.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Campaign Notification'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Send push notifications to all FitStart users',
                        style: TextStyle(
                          color: Colors.blue.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Target type selection
            const Text(
              'Target Audience',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: DropdownButton<String>(
                  value: _targetType,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(
                      value: 'all',
                      child: Row(
                        children: [
                          Icon(Icons.people, size: 20),
                          SizedBox(width: 8),
                          Text('All Users'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _targetType = value);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Title field
            const Text(
              'Notification Title',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'e.g., Welcome to FitStart! 🏆',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                prefixIcon: const Icon(Icons.title),
              ),
              maxLength: 50,
            ),
            const SizedBox(height: 16),

            // Body field
            const Text(
              'Notification Message',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _bodyController,
              decoration: InputDecoration(
                hintText: 'e.g., Book your favorite sports venue now!',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                prefixIcon: const Icon(Icons.message),
              ),
              maxLines: 4,
              maxLength: 200,
            ),
            const SizedBox(height: 24),

            // Preview card
            const Text(
              'Preview',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 4,
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.notifications,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                title: Text(
                  _titleController.text.isEmpty
                      ? 'Notification Title'
                      : _titleController.text,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  _bodyController.text.isEmpty
                      ? 'Notification message will appear here'
                      : _bodyController.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Send button
            ElevatedButton.icon(
              onPressed: _isSending ? null : _sendNotification,
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send),
              label: Text(
                _isSending ? 'Sending...' : 'Send Notification',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Quick templates
            const Text(
              'Quick Templates',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTemplateChip(
                  context,
                  label: 'Welcome Message',
                  title: 'Welcome to FitStart! 🏆',
                  body: 'Book your favorite sports venue now!',
                ),
                _buildTemplateChip(
                  context,
                  label: 'Special Offer',
                  title: '🎉 Special Offer Alert!',
                  body: 'Get 20% off on your first booking this week!',
                ),
                _buildTemplateChip(
                  context,
                  label: 'New Venue',
                  title: '🏟️ New Venue Added!',
                  body: 'Check out the new cricket ground in your area!',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateChip(
    BuildContext context, {
    required String label,
    required String title,
    required String body,
  }) {
    return ActionChip(
      label: Text(label),
      avatar: const Icon(Icons.auto_awesome, size: 18),
      onPressed: () {
        setState(() {
          _titleController.text = title;
          _bodyController.text = body;
        });
      },
    );
  }
}
