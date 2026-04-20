import { Request, Response } from 'express';
import { generateAlertCopy } from '../services/gemini.service';
import { sendPushNotification } from '../services/firebase.service';
import * as admin from 'firebase-admin';

/**
 * Handles incoming push requests from Google Cloud Pub/Sub.
 * Includes security validation, rate limiting logic, and error handling.
 */
export const handlePubSubTrigger = async (req: Request, res: Response): Promise<void> => {
  try {
    // 1. Validation & Security: Parse and validate Pub/Sub message structure
    const message = req.body.message;
    if (!message || !message.data) {
      res.status(400).json({ error: 'Invalid Pub/Sub message format' });
      return;
    }

    // Decode base64 payload
    const decodedData = Buffer.from(message.data, 'base64').toString('utf-8');
    let triggerData;
    try {
      triggerData = JSON.parse(decodedData);
    } catch (e) {
      res.status(400).json({ error: 'Payload must be valid JSON' });
      return;
    }

    const { uid, triggerType, location, context } = triggerData;

    if (!uid || !triggerType || !location) {
      res.status(400).json({ error: 'Missing required fields in payload (uid, triggerType, location)' });
      return;
    }

    // 2. Efficiency & Responsibility: Rate Limiting (Throttle Check)
    // Check Firestore to ensure this user hasn't received an alert of this type recently.
    // In a real high-throughput scenario, Redis or Memcached might be preferred, but Firestore works for MVP.
    const db = admin.firestore();
    const throttleRef = db.collection('fans').doc(uid).collection('throttles').doc(triggerType);
    
    const throttleDoc = await throttleRef.get();
    if (throttleDoc.exists) {
      const lastSent = throttleDoc.data()?.lastSent?.toDate();
      const now = new Date();
      // Enforce a 15-minute cooldown per alert category
      if (lastSent && (now.getTime() - lastSent.getTime()) < 15 * 60 * 1000) {
        console.log(`[Throttle] Alert ${triggerType} suppressed for ${uid} (Cooldown active)`);
        res.status(200).send('Alert suppressed due to rate limiting');
        return;
      }
    }

    // 3. Google Services: Generate personalized, accessible copy via Gemini AI
    const alertBody = await generateAlertCopy(triggerType, location, context || '');

    // 4. Google Services: Dispatch via Firebase Cloud Messaging
    const success = await sendPushNotification(uid, 'StadiumOS Update', alertBody, { triggerType });

    if (success) {
      // Record the successful send for throttling
      await throttleRef.set({ lastSent: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
      res.status(200).send('Alert processed successfully');
    } else {
      res.status(500).json({ error: 'Failed to send FCM message' });
    }
  } catch (error) {
    console.error('[Alert Controller] Error processing trigger:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};
