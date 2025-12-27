const admin = require('firebase-admin');

const initializeFirebase = () => {
  try {
    // Check if Firebase credentials are configured
    if (!process.env.FIREBASE_PROJECT_ID || 
        !process.env.FIREBASE_PRIVATE_KEY || 
        !process.env.FIREBASE_CLIENT_EMAIL ||
        process.env.FIREBASE_PROJECT_ID === 'your-firebase-project-id') {
      console.log('⚠️  Firebase credentials not configured - notifications disabled');
      return;
    }

    // Initialize Firebase Admin SDK
    admin.initializeApp({
      credential: admin.credential.cert({
        projectId: process.env.FIREBASE_PROJECT_ID,
        privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
        clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      }),
    });

    console.log('✅ Firebase Admin SDK initialized');
  } catch (error) {
    console.error('❌ Firebase initialization error:', error.message);
    console.log('⚠️  Continuing without Firebase - notifications disabled');
  }
};

// Send push notification to a single device
const sendNotification = async (fcmToken, notification) => {
  try {
    const message = {
      token: fcmToken,
      notification: {
        title: notification.title,
        body: notification.body,
      },
      data: notification.data || {},
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          channelId: 'fitstart_notifications',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
          },
        },
      },
    };

    const response = await admin.messaging().send(message);
    console.log('✅ Notification sent successfully:', response);
    return response;
  } catch (error) {
    console.error('❌ Error sending notification:', error);
    throw error;
  }
};

// Send notification to multiple devices
const sendMulticastNotification = async (fcmTokens, notification) => {
  try {
    const message = {
      tokens: fcmTokens,
      notification: {
        title: notification.title,
        body: notification.body,
      },
      data: notification.data || {},
      android: {
        priority: 'high',
      },
    };

    const response = await admin.messaging().sendMulticast(message);
    console.log(`✅ Sent ${response.successCount} notifications successfully`);
    
    if (response.failureCount > 0) {
      console.log(`⚠️  Failed to send ${response.failureCount} notifications`);
    }
    
    return response;
  } catch (error) {
    console.error('❌ Error sending multicast notification:', error);
    throw error;
  }
};

// Send notification to a topic
const sendTopicNotification = async (topic, notification) => {
  try {
    const message = {
      topic: topic,
      notification: {
        title: notification.title,
        body: notification.body,
      },
      data: notification.data || {},
    };

    const response = await admin.messaging().send(message);
    console.log('✅ Topic notification sent successfully:', response);
    return response;
  } catch (error) {
    console.error('❌ Error sending topic notification:', error);
    throw error;
  }
};

module.exports = {
  initializeFirebase,
  sendNotification,
  sendMulticastNotification,
  sendTopicNotification,
  admin,
};
