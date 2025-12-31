const express = require('express');
const { body, validationResult } = require('express-validator');
const auth = require('../middleware/auth');
const Message = require('../models/Message');
const Conversation = require('../models/Conversation');

const router = express.Router();

// ==================== START CONVERSATION ====================
/**
 * POST /api/v1/chat/conversations
 * Start a new conversation between user and venue
 */
router.post(
  '/conversations',
  auth,
  [
    body('venueId').trim().notEmpty().withMessage('Venue ID is required'),
    body('venueType').trim().notEmpty().withMessage('Venue type is required'),
    body('venueName').trim().notEmpty().withMessage('Venue name is required'),
    body('venueEmail').isEmail().withMessage('Valid venue email is required'),
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ success: false, errors: errors.array() });
      }

      const { venueId, venueType, venueName, venueEmail, initialMessage } = req.body;
      const userEmail = req.user.email;

      // Check if conversation already exists
      let conversation = await Conversation.findOne({
        venueId,
        userEmail,
        venueEmail,
      });

      if (conversation) {
        return res.json({
          success: true,
          data: conversation,
          message: 'Existing conversation found',
        });
      }

      // Create new conversation
      conversation = new Conversation({
        venueId,
        venueType,
        venueName,
        venueEmail,
        userEmail,
        userName: userEmail.split('@')[0],
        lastMessage: initialMessage || '',
        lastMessageTime: new Date(),
      });

      await conversation.save();

      // Send initial message if provided
      if (initialMessage && initialMessage.trim()) {
        const message = new Message({
          conversationId: conversation._id,
          message: initialMessage,
          sender: 'user',
          senderEmail: userEmail,
          senderName: userEmail.split('@')[0],
        });

        await message.save();

        // Update conversation with message
        conversation.lastMessage = initialMessage;
        conversation.lastMessageTime = new Date();
        conversation.messages = [message._id];
        await conversation.save();
      }

      res.status(201).json({
        success: true,
        data: conversation,
        message: 'Conversation started',
      });
    } catch (error) {
      console.error('❌ Error starting conversation:', error);
      res.status(500).json({
        success: false,
        error: error.message,
      });
    }
  }
);

// ==================== SEND MESSAGE ====================
/**
 * POST /api/v1/chat/conversations/:conversationId/messages
 * Send a message in a conversation
 */
router.post(
  '/conversations/:conversationId/messages',
  auth,
  [
    body('message').trim().notEmpty().withMessage('Message cannot be empty'),
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ success: false, errors: errors.array() });
      }

      const { conversationId } = req.params;
      const { message } = req.body;
      const userEmail = req.user.email;

      // Find conversation
      const conversation = await Conversation.findById(conversationId);
      if (!conversation) {
        return res.status(404).json({
          success: false,
          error: 'Conversation not found',
        });
      }

      // Verify user is part of conversation
      if (conversation.userEmail !== userEmail && conversation.venueEmail !== userEmail) {
        return res.status(403).json({
          success: false,
          error: 'Unauthorized to send message in this conversation',
        });
      }

      // Create message
      const isVenueOwner = conversation.venueEmail === userEmail;
      const newMessage = new Message({
        conversationId,
        message,
        sender: isVenueOwner ? 'venue' : 'user',
        senderEmail: userEmail,
        senderName: userEmail.split('@')[0],
      });

      await newMessage.save();

      // Update conversation
      conversation.lastMessage = message;
      conversation.lastMessageTime = new Date();
      conversation.messages.push(newMessage._id);
      await conversation.save();

      res.status(201).json({
        success: true,
        data: newMessage,
        message: 'Message sent successfully',
      });
    } catch (error) {
      console.error('❌ Error sending message:', error);
      res.status(500).json({
        success: false,
        error: error.message,
      });
    }
  }
);

// ==================== GET USER CONVERSATIONS ====================
/**
 * GET /api/v1/chat/conversations/user
 * Get all conversations for current user (as customer)
 */
router.get('/conversations/user', auth, async (req, res) => {
  try {
    const userEmail = req.user.email;

    const conversations = await Conversation.find({
      userEmail,
    })
      .populate('messages')
      .sort({ lastMessageTime: -1 });

    res.json({
      success: true,
      data: conversations,
    });
  } catch (error) {
    console.error('❌ Error fetching user conversations:', error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

// ==================== GET OWNER CONVERSATIONS ====================
/**
 * GET /api/v1/chat/conversations/owner
 * Get all conversations for current user (as venue owner)
 */
router.get('/conversations/owner', auth, async (req, res) => {
  try {
    const ownerEmail = req.user.email;

    // Find conversations where this user is the venue owner
    const conversations = await Conversation.find({
      venueEmail: ownerEmail,
    })
      .populate('messages')
      .sort({ lastMessageTime: -1 });

    res.json({
      success: true,
      data: conversations,
    });
  } catch (error) {
    console.error('❌ Error fetching owner conversations:', error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

// ==================== GET CONVERSATION DETAILS ====================
/**
 * GET /api/v1/chat/conversations/:conversationId
 * Get a specific conversation with all messages
 */
router.get('/conversations/:conversationId', auth, async (req, res) => {
  try {
    const { conversationId } = req.params;
    const userEmail = req.user.email;

    const conversation = await Conversation.findById(conversationId).populate('messages');

    if (!conversation) {
      return res.status(404).json({
        success: false,
        error: 'Conversation not found',
      });
    }

    // Verify user is part of conversation
    if (
      conversation.userEmail !== userEmail &&
      conversation.venueEmail !== userEmail
    ) {
      return res.status(403).json({
        success: false,
        error: 'Unauthorized to view this conversation',
      });
    }

    res.json({
      success: true,
      data: conversation,
    });
  } catch (error) {
    console.error('❌ Error fetching conversation:', error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

// ==================== MARK AS READ ====================
/**
 * PUT /api/v1/chat/conversations/:conversationId/read
 * Mark conversation as read
 */
router.put('/conversations/:conversationId/read', auth, async (req, res) => {
  try {
    const { conversationId } = req.params;

    const conversation = await Conversation.findByIdAndUpdate(
      conversationId,
      { unreadCount: 0 },
      { new: true }
    );

    if (!conversation) {
      return res.status(404).json({
        success: false,
        error: 'Conversation not found',
      });
    }

    // Mark all messages as read
    await Message.updateMany(
      { conversationId },
      { isRead: true }
    );

    res.json({
      success: true,
      data: conversation,
    });
  } catch (error) {
    console.error('❌ Error marking as read:', error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

module.exports = router;
