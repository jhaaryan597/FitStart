const mongoose = require('mongoose');

const conversationSchema = new mongoose.Schema(
  {
    venueId: {
      type: String,
      required: true,
    },
    venueType: {
      type: String,
      required: true,
    },
    venueName: {
      type: String,
      required: true,
    },
    venueEmail: {
      type: String,
      required: true,
    },
    userEmail: {
      type: String,
      required: true,
    },
    userName: {
      type: String,
      default: 'User',
    },
    lastMessage: {
      type: String,
      default: '',
    },
    lastMessageTime: {
      type: Date,
      default: Date.now,
    },
    unreadCount: {
      type: Number,
      default: 0,
    },
    messages: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Message',
      },
    ],
  },
  {
    timestamps: true,
  }
);

// Compound index for finding conversations by user and venue
conversationSchema.index({ userEmail: 1, venueId: 1 });
conversationSchema.index({ venueEmail: 1 });
conversationSchema.index({ lastMessageTime: -1 });

const Conversation = mongoose.model('Conversation', conversationSchema);

module.exports = Conversation;
