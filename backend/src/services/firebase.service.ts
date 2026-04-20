import * as admin from 'firebase-admin';

export const initializeFirebase = () => {
  if (!admin.apps.length) {
    admin.initializeApp();
    console.log('[Firebase] Initialized Admin SDK');
  }
};

/**
 * Sends a push notification via Firebase Cloud Messaging.
 * Implements safe targeting by validating inputs before sending.
 */
export const sendPushNotification = async (uid: string, title: string, body: string, data?: Record<string, string>) => {
  try {
    if (!uid || !body) throw new Error('UID and body are required for push notification.');

    // In a production environment, we use the FCM token stored in the user's Firestore profile.
    // For this prototype, we simulate sending to a topic subscribed to by the user.
    const topic = `user_${uid}`;
    
    await admin.messaging().send({
      notification: {
        title,
        body,
      },
      data: data || {},
      topic: topic,
    });
    console.log(`[FCM] Sent alert to topic ${topic}: ${body}`);
    return true;
  } catch (error) {
    console.error('[FCM] Error sending message:', error);
    return false;
  }
};
