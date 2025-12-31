const mongoose = require('mongoose');

const messageSchema = new mongoose.Schema(
  {
    conversationId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Conversation',
      required: true,
    },
    message: {
      type: String,
      required: true,
      trim: true,
    },
    sender: {
      type: String,
      enum: ['user', 'venue'],
      required: true,
    },
    senderEmail: {
      type: String,
      required: true,
    },
    senderName: {
      type: String,
      default: 'User',
    },
    isRead: {
      type: Boolean,
      default: false,
    },
  },
  {
    timestamps: true,
  }
);

// Index for faster queries
messageSchema.index({ conversationId: 1, createdAt: 1 });

const Message = mongoose.model('Message', messageSchema);

module.exports = Message;
