import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:FitStart/modules/chat/chat_view.dart';

/// Service for handling communication actions like WhatsApp chat and phone calls
class CommunicationService {
  
  /// Launch WhatsApp chat with the given phone number
  /// 
  /// [phoneNumber] should be in the format +91XXXXXXXXXX or XXXXXXXXXX
  /// [message] is optional initial message to send
  static Future<void> openWhatsApp({
    required String phoneNumber,
    String? message,
  }) async {
    try {
      // Clean phone number - remove spaces, dashes, and ensure format
      String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      
      // Add +91 if not present and number starts with digit
      if (!cleanNumber.startsWith('+') && cleanNumber.startsWith('91')) {
        cleanNumber = '+$cleanNumber';
      } else if (!cleanNumber.startsWith('+') && !cleanNumber.startsWith('91')) {
        cleanNumber = '+91$cleanNumber';
      }
      
      // Create WhatsApp URL
      String whatsappUrl = 'https://wa.me/$cleanNumber';
      if (message != null && message.isNotEmpty) {
        final encodedMessage = Uri.encodeComponent(message);
        whatsappUrl += '?text=$encodedMessage';
      }
      
      final Uri uri = Uri.parse(whatsappUrl);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch WhatsApp. Please make sure WhatsApp is installed.';
      }
    } catch (e) {
      throw 'Failed to open WhatsApp: $e';
    }
  }
  
  /// Open internal chat with venue owner
  /// 
  /// [venueId] unique identifier for the venue
  /// [venueType] should be 'gym' or 'sports_venue'
  /// [venueName] display name of the venue
  /// [venueEmail] email address of the venue for chat
  /// [initialMessage] optional first message to send
  static Future<void> openInternalChat({
    required BuildContext context,
    required String venueId,
    required String venueType,
    required String venueName,
    String? venueEmail,
    String? initialMessage,
  }) async {
    try {
      // Navigate to chat view directly - ChatView handles auth internally
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ChatView(
            venueId: venueId,
            venueType: venueType,
            venueName: venueName,
            venueEmail: venueEmail,
            initialMessage: initialMessage,
          ),
        ),
      );
    } catch (e) {
      throw 'Failed to open chat: $e';
    }
  }
  
  /// Launch phone dialer with the given phone number
  /// 
  /// [phoneNumber] should be in the format +91XXXXXXXXXX or XXXXXXXXXX
  static Future<void> makePhoneCall({
    required String phoneNumber,
  }) async {
    try {
      // Clean phone number - remove spaces, dashes
      String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      
      // Create tel URL
      final Uri uri = Uri.parse('tel:$cleanNumber');
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw 'Could not launch phone dialer.';
      }
    } catch (e) {
      throw 'Failed to make phone call: $e';
    }
  }
  
  /// Show error dialog when communication fails
  static void showErrorDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Communication Error'),
          content: Text(error),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
  
  /// Show bottom sheet with communication options
  static void showCommunicationOptions({
    required BuildContext context,
    required String phoneNumber,
    required String venueName,
    required String venueId,
    required String venueType,
    String? venueEmail,
    String? initialMessage,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.white.withOpacity(0.9),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Contact $venueName',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  phoneNumber,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Internal Chat Option
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.chat_bubble,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  title: const Text('Chat in App'),
                  subtitle: const Text('Private messaging without sharing your number'),
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      String message = initialMessage ?? 
                          'Hi! I\'m interested in $venueName. Could you please provide more information?';
                      await openInternalChat(
                        context: context,
                        venueId: venueId,
                        venueType: venueType,
                        venueName: venueName,
                        venueEmail: venueEmail,
                        initialMessage: message,
                      );
                    } catch (e) {
                      showErrorDialog(context, e.toString());
                    }
                  },
                ),
                
                const SizedBox(height: 8),
                
                // WhatsApp Option
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.chat,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  title: const Text('Chat on WhatsApp'),
                  subtitle: const Text('Send a message instantly'),
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      String message = initialMessage ?? 
                          'Hi! I\'m interested in $venueName. Could you please provide more information?';
                      await openWhatsApp(
                        phoneNumber: phoneNumber,
                        message: message,
                      );
                    } catch (e) {
                      showErrorDialog(context, e.toString());
                    }
                  },
                ),
                
                const SizedBox(height: 8),
                
                // Phone Call Option
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF007AFF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.phone,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  title: const Text('Call Now'),
                  subtitle: const Text('Make a direct phone call'),
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      await makePhoneCall(phoneNumber: phoneNumber);
                    } catch (e) {
                      showErrorDialog(context, e.toString());
                    }
                  },
                ),
                
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        );
      },
    );
  }
  
  /// Create communication action buttons for inline usage
  static Widget buildCommunicationButtons({
    required BuildContext context,
    required String phoneNumber,
    required String venueName,
    required String venueId,
    required String venueType,
    String? initialMessage,
    MainAxisAlignment alignment = MainAxisAlignment.spaceEvenly,
  }) {
    return Column(
      children: [
        // First row: WhatsApp and Call
        Row(
          mainAxisAlignment: alignment,
          children: [
            // WhatsApp Button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  try {
                    String message = initialMessage ?? 
                        'Hi! I\'m interested in $venueName. Could you please provide more information?';
                    await openWhatsApp(
                      phoneNumber: phoneNumber,
                      message: message,
                    );
                  } catch (e) {
                    showErrorDialog(context, e.toString());
                  }
                },
                icon: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.chat,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                label: const Text('WhatsApp'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF25D366)),
                  foregroundColor: const Color(0xFF25D366),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                ),
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Call Button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  try {
                    await makePhoneCall(phoneNumber: phoneNumber);
                  } catch (e) {
                    showErrorDialog(context, e.toString());
                  }
                },
                icon: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF007AFF),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.phone,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                label: const Text('Call'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF007AFF)),
                  foregroundColor: const Color(0xFF007AFF),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Second row: Internal Chat
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              try {
                String message = initialMessage ?? 
                    'Hi! I\'m interested in $venueName. Could you please provide more information?';
                await openInternalChat(
                  context: context,
                  venueId: venueId,
                  venueType: venueType,
                  venueName: venueName,
                  initialMessage: message,
                );
              } catch (e) {
                showErrorDialog(context, e.toString());
              }
            },
            icon: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                Icons.chat_bubble,
                color: Colors.white,
                size: 16,
              ),
            ),
            label: const Text('Chat in App (Private)'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF6C63FF)),
              foregroundColor: const Color(0xFF6C63FF),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
          ),
        ),
      ],
    );
  }
}