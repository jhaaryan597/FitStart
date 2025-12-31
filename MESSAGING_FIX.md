# Chat/Messaging System - Now with Backend API Support

## Problem
Messages were only being stored **locally on the device** (Hive local storage), so:
- User A sends message to Venue B → saved to User A's device only
- Venue B owner never receives the message because there's no backend synchronization
- The app was using `LocalChatService` exclusively without any API calls

## Solution
Implemented a complete backend messaging infrastructure with MongoDB persistence:

### ✅ Backend Changes

#### 1. New Files Created
- **`backend/src/routes/chatRoutes.js`** - All chat API endpoints
- **`backend/src/models/Conversation.js`** - MongoDB schema for conversations
- **`backend/src/models/Message.js`** - MongoDB schema for messages

#### 2. Backend API Endpoints
All endpoints require authentication (Bearer token):

**Starting a Conversation:**
```
POST /api/v1/chat/conversations
Body: {
  venueId: string,
  venueType: string,
  venueName: string,
  venueEmail: string,
  initialMessage?: string
}
```

**Sending Messages:**
```
POST /api/v1/chat/conversations/:conversationId/messages
Body: {
  message: string
}
```

**Fetching Conversations (as Customer):**
```
GET /api/v1/chat/conversations/user
Returns: Array of conversations where user is the customer
```

**Fetching Conversations (as Venue Owner):**
```
GET /api/v1/chat/conversations/owner
Returns: Array of conversations where user is the venue owner
```

**Getting Specific Conversation:**
```
GET /api/v1/chat/conversations/:conversationId
Returns: Conversation with all messages populated
```

**Marking as Read:**
```
PUT /api/v1/chat/conversations/:conversationId/read
```

#### 3. Database Models

**Conversation Document:**
```javascript
{
  venueId: string,
  venueType: string,
  venueName: string,
  venueEmail: string,
  userEmail: string,
  userName: string,
  lastMessage: string,
  lastMessageTime: Date,
  unreadCount: number,
  messages: [ObjectId], // references to Message documents
  timestamps: { createdAt, updatedAt }
}
```

**Message Document:**
```javascript
{
  conversationId: ObjectId,
  message: string,
  sender: 'user' | 'venue',
  senderEmail: string,
  senderName: string,
  isRead: boolean,
  timestamps: { createdAt, updatedAt }
}
```

### ✅ Frontend Changes

#### 1. New API Methods in `ApiService`
```dart
// Start conversation
static Future<Map<String, dynamic>> startConversation({
  required String venueId,
  required String venueType,
  required String venueName,
  required String venueEmail,
  String? initialMessage,
})

// Send message
static Future<Map<String, dynamic>> sendMessage({
  required String conversationId,
  required String message,
})

// Get user conversations
static Future<Map<String, dynamic>> getUserConversations()

// Get owner conversations  
static Future<Map<String, dynamic>> getOwnerConversations()

// Get specific conversation
static Future<Map<String, dynamic>> getConversation(String conversationId)

// Mark as read
static Future<Map<String, dynamic>> markConversationAsRead(String conversationId)
```

#### 2. Updated `chat_view.dart` - Hybrid Approach
The app now uses a **hybrid strategy**:
1. **Try API first** - Send message to backend (persistent, reaches other devices)
2. **Fallback to local storage** - If API fails, save locally (works offline)
3. **Auto-reply** - Still triggers after initial message sent

This ensures:
- ✅ Messages reach venue owners (via API)
- ✅ Works offline (local fallback)
- ✅ Instant feedback to user (no lag)
- ✅ Cross-device synchronization (API persistence)

## How Message Flow Works Now

### Customer Sends Message
1. User types message in chat
2. App calls `ApiService.sendMessage()` → saves to MongoDB
3. If API fails, falls back to `LocalChatService.sendMessage()` → saves locally
4. Message appears in user's chat immediately
5. **Venue owner can now see the message via GET `/api/v1/chat/conversations/owner`**

### Venue Owner Views Messages
1. When owner opens chat, app calls `ApiService.getOwnerConversations()`
2. Backend queries MongoDB for conversations where `venueEmail == ownerEmail`
3. Returns all conversations with customer messages
4. Owner can reply via `ApiService.sendMessage()` with `sender: 'venue'`

## Testing the Fix

### Test Scenario
1. **Device A (User):** aryanjha597@gmail.com
2. **Device B (Owner):** abhjha597@gmail.com

### Steps to Test
1. Open Device A (User account)
   - Start chat with venue (abhjha597@gmail.com)
   - Send message "Hi, interested in booking"
   
2. Open Device B (Owner account)
   - Go to Chat Inbox
   - Should see conversation from aryanjha597@gmail.com
   - See the message "Hi, interested in booking"
   - Reply with "Thanks for your interest!"
   
3. Switch back to Device A
   - Should see the owner's reply message
   - Message appears without needing to restart app

## Backend Setup Checklist

- [x] `Conversation` model created in MongoDB
- [x] `Message` model created in MongoDB
- [x] Chat routes created with all endpoints
- [x] Authentication middleware applied
- [x] Routes registered in server.js
- [ ] Start backend server: `npm start` in `/backend`
- [ ] Verify `/health` endpoint returns 200

## Deployment Notes

When deploying to Railway:
1. The new models will auto-create MongoDB collections
2. Ensure MongoDB is connected in `.env`
3. No schema migration needed (Mongoose handles it)
4. The frontend will automatically use production API URL from Railway

## Troubleshooting

**Messages still not appearing on owner's side:**
- Check backend is running: `curl https://your-api.railway.app/health`
- Verify JWT token is being sent in headers
- Check MongoDB connection in backend logs
- Messages should appear after a few seconds (2-second simulated reply delay)

**Offline/Local Fallback Working:**
- If backend is down, messages save locally
- When backend is back online, you may need to manually refresh chat to sync

**Performance:**
- Conversations are indexed by email and timestamp for fast queries
- Messages array contains ObjectIds (references), not full message objects for efficiency
- Consider pagination for old messages if performance degrades
